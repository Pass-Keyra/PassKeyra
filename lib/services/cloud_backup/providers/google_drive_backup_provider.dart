import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as gauth;
import 'package:http/http.dart' as http;
import '../../../platform/platform_capabilities.dart';
import '../cloud_backup_provider.dart';
import '../models/cloud_backup_metadata.dart';
import '../../../models/backup_payload.dart';
import '../../secure_storage_service.dart';
import '../../google_signin_service.dart';
import '../../firebase/google_signin_windows.dart';
import '../../firebase/rest/cloud_debug_log.dart';

/// Implémentation du provider de backup pour Google Drive
///
/// Utilise GoogleSignInService pour l'authentification OAuth 2.0 unifiée
/// avec Firebase Auth. Les scopes Drive sont configurés dans GoogleSignInService.
/// et Google Drive API v3 pour les opérations de fichiers.
///
/// Sécurité: Les fichiers sont toujours chiffrés côté client
/// AVANT d'être uploadés (zero-knowledge encryption).
class GoogleDriveBackupProvider implements CloudBackupProvider {
  // Scopes requis pour Google Drive (configurés dans GoogleSignInService)
  static const List<String> _scopes = [
    drive.DriveApi.driveFileScope, // Accès limité aux fichiers créés par PassKeyra (zéro accès au reste du Drive)
  ];

  // Nom du dossier racine pour les backups PassKeyra
  static const String _appFolderName = 'PassKeyra_Backups';

  // Type MIME pour les fichiers JSON
  static const String _jsonMimeType = 'application/json';

  // Service de stockage sécurisé pour les tokens
  final SecureStorageService _storage = SecureStorageService();

  // API Drive (initialisée après authentification)
  drive.DriveApi? _driveApi;

  // ID du dossier PassKeyra_Backups (cached)
  String? _appFolderId;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  @override
  String get providerName => 'Google Drive';

  @override
  IconData get providerIcon => Icons.cloud;

  @override
  Color get providerColor => const Color(0xFF4285F4); // Bleu Google

  // Desktop : instance du flow OAuth Windows pour Google Drive.
  final _googleSignInWindows = GoogleSignInWindows();

  @override
  Future<bool> isAuthenticated() async {
    try {
      if (_driveApi != null) return true;

      // Desktop : tenter de restaurer la session OAuth Windows.
      if (isDesktop) {
        final result = await _googleSignInWindows.restoreSession();
        if (result != null && result.accessToken.isNotEmpty) {
          _initializeDriveApiFromAccessToken(result.accessToken);
          cloudLog('Drive isAuthenticated : session restauree OK');
          return true;
        }
        cloudLog('Drive isAuthenticated : pas de session a restaurer');
        return false;
      }

      // Mobile : flow existant via GoogleSignInService.
      _log('GoogleDriveBackupProvider - Vérification silencieuse session Google...');
      GoogleSignInAccount? currentAccount = await GoogleSignInService.instance.getCurrentAccount();

      if (currentAccount != null) {
        _log('GoogleDriveBackupProvider - Compte trouvé: ${currentAccount.email}');
        await _initializeDriveApi(currentAccount);
        return true;
      }

      final firebaseAuth = FirebaseAuth.instance;
      if (firebaseAuth.currentUser != null) {
        _log('GoogleDriveBackupProvider - Firebase connecté, tentative restauration Google...');
        try {
          currentAccount = await GoogleSignInService.instance.restoreSession();
          if (currentAccount != null) {
            await _initializeDriveApi(currentAccount);
            return true;
          }
        } catch (e) {
          _log('GoogleDriveBackupProvider - Impossible de restaurer session Google: $e');
        }
      }

      _log('GoogleDriveBackupProvider - Aucune session Google disponible');
      return false;
    } catch (e) {
      _log('GoogleDriveBackupProvider - isAuthenticated error: $e');
      return _driveApi != null;
    }
  }

  @override
  Future<bool> authenticate() async {
    try {
      // Desktop : OAuth web flow via navigateur (callback localhost).
      if (isDesktop) {
        _log('GoogleDriveBackupProvider - Starting Windows OAuth...');
        cloudLog('Drive authenticate (desktop) DEBUT');
        final result = await _googleSignInWindows.signIn();
        if (result == null) {
          _log('GoogleDriveBackupProvider - Authentication cancelled');
          cloudLog('Drive authenticate : GoogleSignIn retourne null');
          return false;
        }
        _initializeDriveApiFromAccessToken(result.accessToken);
        await _storage.saveGoogleDriveEmail(result.email);
        _log('GoogleDriveBackupProvider - Authenticated (Windows) as ${result.email}');
        cloudLog('Drive authenticate SUCCES email=${result.email}');
        return true;
      }

      // Mobile : flow existant via GoogleSignInService.
      _log('GoogleDriveBackupProvider - Checking Google Sign-In status...');
      GoogleSignInAccount? account = await GoogleSignInService.instance.getCurrentAccount();

      if (account == null) {
        _log('GoogleDriveBackupProvider - Starting Google Sign-In...');
        account = await GoogleSignInService.instance.signIn();
        if (account == null) {
          _log('GoogleDriveBackupProvider - Authentication cancelled by user');
          return false;
        }
      }

      await _initializeDriveApi(account);
      await _storage.saveGoogleDriveEmail(account.email);

      _log('GoogleDriveBackupProvider - Authenticated as ${account.email} with Drive scopes');
      return true;
    } on PlatformException catch (e) {
      // Erreurs spécifiques à la plateforme (OAuth, configuration, etc.)
      _log('GoogleDriveBackupProvider - Platform error: ${e.code} - ${e.message}');

      if (e.code == 'sign_in_canceled') {
        // Cas spécial : erreur "canceled" peut signifier plusieurs choses
        throw Exception(
          'Connexion impossible. Causes possibles :\n'
          '\n'
          '1. Google Play Services manquant ou obsolète\n'
          '   → Mettez à jour depuis le Play Store\n'
          '\n'
          '2. Aucun compte Google configuré sur cet appareil\n'
          '   → Paramètres > Comptes > Ajouter un compte Google\n'
          '\n'
          '3. Appareil incompatible (ROM custom, Huawei sans GMS)\n'
          '   → Fonctionnalité non disponible sur cet appareil\n'
          '\n'
          '4. Problème de configuration OAuth (rare)\n'
          '   → Contactez le support si le problème persiste\n'
          '\n'
          'Code erreur : ${e.code}'
        );
      } else if (e.code == 'sign_in_failed' || e.code == 'network_error') {
        throw Exception(
          'Échec de la connexion.\n'
          '\n'
          'Vérifiez votre connexion Internet et réessayez.\n'
          '\n'
          'Code erreur : ${e.code}'
        );
      } else {
        throw Exception(
          'Erreur d\'authentification.\n'
          '\n'
          'Message : ${e.message ?? 'Erreur inconnue'}\n'
          'Code : ${e.code}\n'
          '\n'
          'Veuillez réessayer ou contacter le support.'
        );
      }
    } catch (e) {
      _log('GoogleDriveBackupProvider - Authentication error: $e');
      _log('  → Vérifiez que google-services.json contient les OAuth clients');
      _log('  → Vérifiez que les empreintes SHA sont ajoutées dans Firebase Console');
      rethrow; // Relancer pour que l'UI puisse afficher un message détaillé
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Note: Ne pas appeler GoogleSignInService.signOut() ici
      // car cela déconnecterait aussi Firebase Auth
      // On se contente de nettoyer les données Drive locales
      await _storage.deleteGoogleDriveEmail();
      _driveApi = null;
      _appFolderId = null;
      _log('GoogleDriveBackupProvider - Drive data cleared (Google account still signed in)');
    } catch (e) {
      _log('GoogleDriveBackupProvider - Sign out error: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadBackup(BackupPayload payload, {String? fileName}) async {
    if (_driveApi == null) {
      throw Exception('API Drive non initialisée. Veuillez vous authentifier.');
    }

    try {
      // Générer nom de fichier si non fourni
      final backupFileName = fileName ??
          'passkeyra_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      _log(
        'DRIVE_UP_START file=$backupFileName iterations=${payload.iterations} entryCount=${payload.entryCount}',
      );

      // Convertir BackupPayload en JSON string
      final jsonContent = payload.toJsonString();
      final bytes = utf8.encode(jsonContent);
      _log(
        'DRIVE_UP_JSON bytes=${bytes.length} jsonChars=${jsonContent.length}',
      );

      // Obtenir ou créer le dossier PassKeyra_Backups
      final folderId = await _getOrCreateAppFolder();

      // Métadonnées du fichier Drive
      final fileMetadata = drive.File()
        ..name = backupFileName
        ..parents = [folderId] // Placer dans le dossier PassKeyra_Backups
        ..mimeType = _jsonMimeType
        ..description = 'PassKeyra encrypted backup - ${payload.exportedAt.toIso8601String()}'
        ..appProperties = {
          'entryCount': payload.entryCount.toString(),
          'iterations': payload.iterations.toString(),
        };

      // Upload via Drive API
      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
        contentType: _jsonMimeType,
      );

      final uploadedFile = await _driveApi!.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      if (uploadedFile.id == null) {
        throw Exception('Échec upload: ID fichier manquant');
      }

      _log(
        'DRIVE_UP_OK id=${uploadedFile.id} name=${uploadedFile.name} iterations=${payload.iterations}',
      );
      _log('GoogleDriveBackupProvider - Uploaded: ${uploadedFile.name} (${uploadedFile.id})');
      return uploadedFile.id!;
    } catch (e) {
      _log('DRIVE_UP_ERR $e');
      _log('GoogleDriveBackupProvider - Upload error: $e');
      rethrow;
    }
  }

  @override
  Future<List<CloudBackupMetadata>> listBackups() async {
    _log('GoogleDriveBackupProvider - listBackups() called');
    _log('  → _driveApi is null: ${_driveApi == null}');

    if (_driveApi == null) {
      _log('  → ERROR: API Drive non initialisée');
      throw Exception('API Drive non initialisée. Veuillez vous authentifier.');
    }

    try {
      // Obtenir le dossier PassKeyra_Backups (ne pas créer si n'existe pas)
      _log('  → Searching for app folder...');
      final folderId = await _findAppFolder();
      _log('  → App folder ID: $folderId');

      if (folderId == null) {
        // Aucun dossier = aucun backup
        return [];
      }

      // Lister tous les fichiers JSON dans le dossier
      final query = "'$folderId' in parents and mimeType='$_jsonMimeType' and trashed=false";

      final fileList = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        orderBy: 'modifiedTime desc', // Plus récent en premier
        $fields: 'files(id, name, size, modifiedTime, createdTime, appProperties)', // CORRECTION: Spécifier les champs requis
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return [];
      }

      // Convertir en CloudBackupMetadata sans télécharger les fichiers.
      // Le nombre d'entrées est lu depuis appProperties quand disponible.
      final metadataList = fileList.files!.map((file) {
        final appProps = file.appProperties;
        final entryCountRaw = appProps?['entryCount'];
        final entryCount = entryCountRaw == null ? null : int.tryParse(entryCountRaw);

        // Google Drive retourne les dates en UTC, il faut les convertir en heure locale
        final driveDate = file.modifiedTime ?? file.createdTime ?? DateTime.now().toUtc();

        final localDate = DateTime.utc(
          driveDate.year,
          driveDate.month,
          driveDate.day,
          driveDate.hour,
          driveDate.minute,
          driveDate.second,
        ).toLocal();

        return CloudBackupMetadata(
          id: file.id!,
          name: file.name ?? 'backup.json',
          uploadedAt: localDate,
          sizeBytes: int.tryParse(file.size ?? '0') ?? 0,
          providerName: providerName,
          entryCount: entryCount,
        );
      }).toList();

      return metadataList;
    } catch (e) {
      _log('GoogleDriveBackupProvider - List error: $e');
      rethrow;
    }
  }

  @override
  Future<BackupPayload> downloadBackup(String fileId) async {
    if (_driveApi == null) {
      throw Exception('API Drive non initialisée. Veuillez vous authentifier.');
    }

    try {
      _log('DRIVE_DL_START fileId=$fileId');
      // Télécharger le contenu du fichier
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Lire le stream en bytes
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      _log('DRIVE_DL_BYTES fileId=$fileId bytes=${bytes.length}');

      // Convertir bytes en string JSON
      final jsonContent = utf8.decode(bytes);
      _log('DRIVE_DL_JSON fileId=$fileId chars=${jsonContent.length}');

      // Parser en BackupPayload
      final payload = BackupPayload.fromJsonString(jsonContent);
      _log(
        'DRIVE_DL_OK fileId=$fileId iterations=${payload.iterations} saltChars=${payload.salt.length} entryCount=${payload.entryCount}',
      );

      _log('GoogleDriveBackupProvider - Downloaded backup: $fileId');
      return payload;
    } catch (e) {
      _log('DRIVE_DL_ERR fileId=$fileId err=$e');
      _log('GoogleDriveBackupProvider - Download error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteBackup(String fileId) async {
    if (_driveApi == null) {
      throw Exception('API Drive non initialisée. Veuillez vous authentifier.');
    }

    try {
      await _driveApi!.files.delete(fileId);
      _log('GoogleDriveBackupProvider - Deleted backup: $fileId');
    } catch (e) {
      _log('GoogleDriveBackupProvider - Delete error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // Tester la connectivité en faisant un ping simple à Google
      final response = await http.head(Uri.parse('https://www.google.com')).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      _log('GoogleDriveBackupProvider - Availability check failed: $e');
      return false;
    }
  }

  @override
  Future<CloudQuota> getQuota() async {
    // Vérifier authentification
    if (!await isAuthenticated()) {
      throw Exception('Non authentifié. Veuillez vous connecter à Google Drive.');
    }

    if (_driveApi == null) {
      throw Exception('API Drive non initialisée');
    }

    try {
      // Obtenir les informations sur le quota Drive
      final about = await _driveApi!.about.get();

      if (about.storageQuota == null) {
        throw Exception('Impossible de récupérer les informations de quota');
      }

      final quota = about.storageQuota!;
      final total = int.tryParse(quota.limit ?? '0') ?? 0;
      final used = int.tryParse(quota.usage ?? '0') ?? 0;

      return CloudQuota(
        totalBytes: total,
        usedBytes: used,
      );
    } catch (e) {
      _log('GoogleDriveBackupProvider - Quota error: $e');
      rethrow;
    }
  }

  // ========== Méthodes privées ==========

  /// Initialise l'API Drive avec le compte Google authentifié
  /// Les scopes Drive sont déjà accordés via GoogleSignInService
  Future<void> _initializeDriveApi(GoogleSignInAccount account) async {
    // Effacer le cache du folder ID pour forcer une nouvelle recherche
    // Fix: Évite d'utiliser un ID de dossier obsolète après reconnexion
    _appFolderId = null;

    final authClient = account.authorizationClient;

    // Récupère l'autorisation existante (silencieux) ; si absente — typique d'une session
    // Firebase restaurée sans scope Drive, ou d'un token Drive révoqué — déclenche la UI
    // de consent Drive native pour re-grant.
    var authorization = await authClient.authorizationForScopes(_scopes);
    if (authorization == null) {
      _log('GoogleDriveBackupProvider - Scopes Drive non accordés, demande interactive...');
      authorization = await authClient.authorizeScopes(_scopes);
    }

    final authHeaders = {
      'Authorization': 'Bearer ${authorization.accessToken}',
    };

    final authenticateClient = _GoogleAuthClient(authHeaders);
    _driveApi = drive.DriveApi(authenticateClient);
  }

  /// Initialise l'API Drive avec un access_token brut (desktop Windows).
  /// Sur desktop, on n'a pas de `GoogleSignInAccount` mais un token OAuth
  /// obtenu via `GoogleSignInWindows` (`googleapis_auth`).
  void _initializeDriveApiFromAccessToken(String accessToken) {
    _appFolderId = null;
    final authHeaders = {'Authorization': 'Bearer $accessToken'};
    _driveApi = drive.DriveApi(_GoogleAuthClient(authHeaders));
  }

  /// Trouve le dossier PassKeyra_Backups (retourne null si n'existe pas)
  Future<String?> _findAppFolder() async {
    if (_appFolderId != null) {
      return _appFolderId; // Utiliser cache
    }

    try {
      final query = "name='$_appFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";

      final fileList = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        _appFolderId = fileList.files!.first.id;
        return _appFolderId;
      }

      return null;
    } catch (e) {
      _log('GoogleDriveBackupProvider - Find folder error: $e');
      return null;
    }
  }

  /// Obtient ou crée le dossier PassKeyra_Backups
  Future<String> _getOrCreateAppFolder() async {
    // Essayer de trouver le dossier existant
    final existingFolderId = await _findAppFolder();
    if (existingFolderId != null) {
      return existingFolderId;
    }

    // Créer le dossier
    try {
      final folderMetadata = drive.File()
        ..name = _appFolderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..description = 'PassKeyra encrypted backups folder';

      final createdFolder = await _driveApi!.files.create(folderMetadata);

      if (createdFolder.id == null) {
        throw Exception('Échec création dossier: ID manquant');
      }

      _appFolderId = createdFolder.id;
      _log('GoogleDriveBackupProvider - Created folder: $_appFolderName ($_appFolderId)');
      return _appFolderId!;
    } catch (e) {
      _log('GoogleDriveBackupProvider - Create folder error: $e');
      rethrow;
    }
  }
}

/// Client HTTP personnalisé pour authentifier les requêtes Google Drive
///
/// Ajoute automatiquement les headers OAuth à toutes les requêtes.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Ajouter les headers d'authentification OAuth
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}

