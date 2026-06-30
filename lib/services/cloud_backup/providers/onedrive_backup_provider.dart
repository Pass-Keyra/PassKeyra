import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:http/http.dart' as http;
import '../cloud_backup_provider.dart';
import '../models/cloud_backup_metadata.dart';
import '../../../models/backup_payload.dart';
import '../../../platform/platform_capabilities.dart';
import '../../secure_storage_service.dart';
import '../../../app/app.dart' show navigatorKey;
import 'onedrive_auth_windows.dart';

/// Implémentation du provider de backup pour OneDrive
///
/// Utilise Azure AD OAuth 2.0 pour l'authentification
/// et Microsoft Graph API pour les opérations de fichiers.
///
/// Sécurité: Les fichiers sont toujours chiffrés côté client
/// AVANT d'être uploadés (zero-knowledge encryption).
class OneDriveBackupProvider implements CloudBackupProvider {
  // Azure AD Configuration
  static const String _clientId = '9de25a1a-23a4-451e-976b-3bba2efa9032';
  static const String _tenantId = 'common'; // 'common' accepte tous types de comptes Microsoft
  static const String _redirectUri = 'msauth://com.passkeyra/callback';

  // Scopes requis pour OneDrive
  static const List<String> _scopes = [
    'https://graph.microsoft.com/Files.ReadWrite',
    'https://graph.microsoft.com/User.Read',
    'offline_access',
  ];

  // Nom du dossier racine pour les backups PassKeyra
  static const String _appFolderName = 'PassKeyra_Backups';

  // Service de stockage sécurisé pour les tokens
  final SecureStorageService _storage = SecureStorageService();

  // OAuth helper (mobile uniquement — WebView indisponible sur desktop).
  AadOAuth? _oauth;

  // Desktop : flow OAuth manuel PKCE.
  final _windowsAuth = OneDriveAuthWindows();

  // HTTP client avec token d'accès
  http.Client? _httpClient;
  String? _accessToken;

  // ID du dossier PassKeyra_Backups (cached)
  String? _appFolderId;

  OneDriveBackupProvider() {
    // `aad_oauth` repose sur un WebView (navigatorKey) → uniquement mobile.
    // Sur desktop, on utilise `OneDriveAuthWindows` (flow OAuth manuel PKCE).
    if (!isDesktop) {
      final config = Config(
        tenant: _tenantId,
        clientId: _clientId,
        scope: _scopes.join(' '),
        redirectUri: _redirectUri,
        navigatorKey: navigatorKey,
        webUseRedirect: false,
      );
      _oauth = AadOAuth(config);
    }
  }

  @override
  String get providerName => 'OneDrive';

  @override
  IconData get providerIcon => Icons.cloud;

  @override
  Color get providerColor => const Color(0xFF0078D4); // Bleu Microsoft

  @override
  Future<bool> isAuthenticated() async {
    try {
      // Desktop : restaurer via le refresh_token persisté (flow PKCE).
      if (isDesktop) {
        if (_httpClient != null && _accessToken != null) return true;
        final token = await _windowsAuth.restoreSession();
        if (token != null && token.isNotEmpty) {
          _initializeHttpClient(token);
          await _storage.saveOneDriveToken(token);
          return true;
        }
        return false;
      }

      // Si le client HTTP est déjà initialisé, on est probablement authentifié
      // Évite les appels API inutiles
      if (_httpClient != null && _accessToken != null) {
        // Vérifier rapidement la validité du token
        try {
          final response = await _httpClient!.get(
            Uri.parse('https://graph.microsoft.com/v1.0/me'),
            headers: {'Authorization': 'Bearer $_accessToken'},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            return true;
          }
          // Si 401, le token a expiré → on va essayer de le rafraîchir ci-dessous
        } catch (e) {
          // Erreur réseau ou timeout → on continue pour essayer de rafraîchir
          debugPrint('OneDriveBackupProvider - Token validation error: $e');
        }
      }

      // Essayer d'obtenir un token (avec refresh automatique si nécessaire)
      // Le package aad_oauth rafraîchit automatiquement le token avec le refresh token
      try {
        final token = await _oauth!.getAccessToken();

        if (token != null && token.isNotEmpty) {
          // Token obtenu (peut être un nouveau token rafraîchi)
          _initializeHttpClient(token);
          await _storage.saveOneDriveToken(token);

          debugPrint('OneDriveBackupProvider - Token refreshed successfully');
          return true;
        } else {
          // Pas de token disponible → besoin de ré-authentification complète
          debugPrint('OneDriveBackupProvider - No valid token available');
          await _storage.deleteOneDriveToken();
          _httpClient?.close();
          _httpClient = null;
          _accessToken = null;
          return false;
        }
      } catch (e) {
        // Erreur lors du refresh du token
        debugPrint('OneDriveBackupProvider - Token refresh failed: $e');
        await _storage.deleteOneDriveToken();
        _httpClient?.close();
        _httpClient = null;
        _accessToken = null;
        return false;
      }
    } catch (e) {
      debugPrint('OneDriveBackupProvider - isAuthenticated error: $e');
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    try {
      debugPrint('OneDriveBackupProvider - Starting authentication...');

      // Lancer l'authentification OAuth
      final String? token;
      if (isDesktop) {
        // Desktop : flow OAuth manuel PKCE (navigateur externe).
        token = await _windowsAuth.signIn();
      } else {
        await _oauth!.login();
        token = await _oauth!.getAccessToken();
      }

      if (token == null || token.isEmpty) {
        debugPrint('OneDriveBackupProvider - No token received');
        return false;
      }

      // Initialiser le client HTTP avec le token
      _initializeHttpClient(token);

      // Sauvegarder le token
      await _storage.saveOneDriveToken(token);

      // Récupérer et sauvegarder l'email de l'utilisateur
      try {
        final response = await _httpClient!.get(
          Uri.parse('https://graph.microsoft.com/v1.0/me'),
          headers: {'Authorization': 'Bearer $_accessToken'},
        );

        if (response.statusCode == 200) {
          final user = jsonDecode(response.body);
          final email = user['userPrincipalName'] ?? user['mail'] ?? 'unknown';
          await _storage.saveOneDriveEmail(email);
          debugPrint('OneDriveBackupProvider - Authenticated as $email');
        }
      } catch (e) {
        debugPrint('OneDriveBackupProvider - Could not fetch user email: $e');
      }

      return true;
    } catch (e) {
      debugPrint('OneDriveBackupProvider - Authentication error: $e');
      throw Exception(
        'Erreur d\'authentification OneDrive.\n'
        '\n'
        'Message : ${e.toString()}\n'
        '\n'
        'Veuillez réessayer ou contacter le support.'
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (isDesktop) {
        await _windowsAuth.signOut();
      } else {
        await _oauth!.logout();
      }
      await _storage.deleteOneDriveToken();
      await _storage.deleteOneDriveEmail();
      _httpClient?.close();
      _httpClient = null;
      _accessToken = null;
      _appFolderId = null;
      debugPrint('OneDriveBackupProvider - Signed out successfully');
    } catch (e) {
      debugPrint('OneDriveBackupProvider - Sign out error: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadBackup(BackupPayload payload, {String? fileName}) async {
    if (_httpClient == null || _accessToken == null) {
      throw Exception('Client HTTP non initialisé. Veuillez vous authentifier.');
    }

    try {
      // Générer nom de fichier si non fourni
      final backupFileName = fileName ??
          'passkeyra_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      // Convertir BackupPayload en JSON string
      final jsonContent = payload.toJsonString();
      final bytes = utf8.encode(jsonContent);

      // Obtenir ou créer le dossier PassKeyra_Backups
      final folderId = await _getOrCreateAppFolder();

      // Upload le fichier dans le dossier
      // Path: /drive/items/{folderId}/children/{fileName}/content
      final uploadPath = '/me/drive/items/$folderId:/$backupFileName:/content';

      final response = await _httpClient!.put(
        Uri.parse('https://graph.microsoft.com/v1.0$uploadPath'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: bytes,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Échec upload: ${response.statusCode} - ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final fileId = responseData['id'] as String;

      debugPrint('OneDriveBackupProvider - Uploaded: $backupFileName ($fileId)');
      return fileId;
    } catch (e) {
      debugPrint('OneDriveBackupProvider - Upload error: $e');
      rethrow;
    }
  }

  @override
  Future<List<CloudBackupMetadata>> listBackups() async {
    debugPrint('OneDriveBackupProvider - listBackups() called');

    if (_httpClient == null || _accessToken == null) {
      debugPrint('  → ERROR: Client HTTP non initialisé');
      throw Exception('Client HTTP non initialisé. Veuillez vous authentifier.');
    }

    try {
      // Obtenir le dossier PassKeyra_Backups (ne pas créer si n'existe pas)
      debugPrint('  → Searching for app folder...');
      final folderId = await _findAppFolder();
      debugPrint('  → App folder ID: $folderId');

      if (folderId == null) {
        // Aucun dossier = aucun backup
        return [];
      }

      // Lister tous les fichiers JSON dans le dossier
      final childrenPath = '/me/drive/items/$folderId/children';
      final response = await _httpClient!.get(
        Uri.parse('https://graph.microsoft.com/v1.0$childrenPath'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode != 200) {
        throw Exception('Échec liste fichiers: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final files = data['value'] as List<dynamic>;

      if (files.isEmpty) {
        return [];
      }

      // Filtrer uniquement les fichiers JSON
      final jsonFiles = files.where((file) {
        final name = file['name'] as String;
        return name.endsWith('.json');
      }).toList();

      // Convertir en CloudBackupMetadata et extraire le nombre d'entrées
      final metadataList = <CloudBackupMetadata>[];

      for (final file in jsonFiles) {
        int? entryCount;

        try {
          // Télécharger et parser le backup pour obtenir le nombre d'entrées
          final payload = await downloadBackup(file['id'] as String);
          entryCount = payload.entryCount;
        } catch (e) {
          debugPrint('OneDriveBackupProvider - Failed to extract entry count for ${file['name']}: $e');
          entryCount = null;
        }

        // Parser la date de modification
        final modifiedTimeStr = file['lastModifiedDateTime'] as String;
        final modifiedTime = DateTime.parse(modifiedTimeStr).toLocal();

        metadataList.add(CloudBackupMetadata(
          id: file['id'] as String,
          name: file['name'] as String,
          uploadedAt: modifiedTime,
          sizeBytes: file['size'] as int,
          providerName: providerName,
          entryCount: entryCount,
        ));
      }

      // Trier par date (plus récent en premier)
      metadataList.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      return metadataList;
    } catch (e) {
      debugPrint('OneDriveBackupProvider - List error: $e');
      rethrow;
    }
  }

  @override
  Future<BackupPayload> downloadBackup(String fileId) async {
    if (_httpClient == null || _accessToken == null) {
      throw Exception('Client HTTP non initialisé. Veuillez vous authentifier.');
    }

    try {
      // Télécharger le contenu du fichier
      final downloadPath = '/me/drive/items/$fileId/content';
      final response = await _httpClient!.get(
        Uri.parse('https://graph.microsoft.com/v1.0$downloadPath'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode != 200) {
        throw Exception('Échec download: ${response.statusCode}');
      }

      // Convertir bytes en string JSON
      final jsonContent = utf8.decode(response.bodyBytes);

      // Parser en BackupPayload
      final payload = BackupPayload.fromJsonString(jsonContent);

      debugPrint('OneDriveBackupProvider - Downloaded backup: $fileId');
      return payload;
    } catch (e) {
      debugPrint('OneDriveBackupProvider - Download error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteBackup(String fileId) async {
    if (_httpClient == null || _accessToken == null) {
      throw Exception('Client HTTP non initialisé. Veuillez vous authentifier.');
    }

    try {
      final deletePath = '/me/drive/items/$fileId';
      final response = await _httpClient!.delete(
        Uri.parse('https://graph.microsoft.com/v1.0$deletePath'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode != 204) {
        throw Exception('Échec suppression: ${response.statusCode}');
      }

      debugPrint('OneDriveBackupProvider - Deleted backup: $fileId');
    } catch (e) {
      debugPrint('OneDriveBackupProvider - Delete error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // Si on a un token, on est connecté → service disponible
      if (_accessToken != null && _httpClient != null) {
        return true;
      }

      // Sinon, tester la connectivité réseau basique
      final client = http.Client();
      final response = await client.head(
        Uri.parse('https://graph.microsoft.com'),
      ).timeout(const Duration(seconds: 5));
      client.close();
      return response.statusCode < 500; // Disponible si pas d'erreur serveur
    } catch (e) {
      debugPrint('OneDriveBackupProvider - Availability check failed: $e');
      return false;
    }
  }

  @override
  Future<CloudQuota> getQuota() async {
    // Vérifier authentification
    if (!await isAuthenticated()) {
      throw Exception('Non authentifié. Veuillez vous connecter à OneDrive.');
    }

    if (_httpClient == null || _accessToken == null) {
      throw Exception('Client HTTP non initialisé');
    }

    try {
      // Obtenir les informations sur le quota OneDrive
      final response = await _httpClient!.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me/drive'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode != 200) {
        throw Exception('Impossible de récupérer les informations de quota');
      }

      final data = jsonDecode(response.body);
      final quota = data['quota'];

      final total = quota['total'] as int;
      final used = quota['used'] as int;

      return CloudQuota(
        totalBytes: total,
        usedBytes: used,
      );
    } catch (e) {
      debugPrint('OneDriveBackupProvider - Quota error: $e');
      rethrow;
    }
  }

  // ========== Méthodes privées ==========

  /// Initialise le client HTTP avec le token d'accès
  void _initializeHttpClient(String accessToken) {
    _accessToken = accessToken;
    _httpClient = http.Client();
  }

  /// Trouve le dossier PassKeyra_Backups (retourne null si n'existe pas)
  Future<String?> _findAppFolder() async {
    if (_appFolderId != null) {
      return _appFolderId; // Utiliser cache
    }

    try {
      // Rechercher le dossier dans la racine OneDrive
      final searchPath = '/me/drive/root/children?\$filter=name eq \'$_appFolderName\'';
      final response = await _httpClient!.get(
        Uri.parse('https://graph.microsoft.com/v1.0$searchPath'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode != 200) {
        debugPrint('OneDriveBackupProvider - Find folder error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);
      final files = data['value'] as List<dynamic>;

      if (files.isNotEmpty) {
        _appFolderId = files.first['id'] as String;
        return _appFolderId;
      }

      return null;
    } catch (e) {
      debugPrint('OneDriveBackupProvider - Find folder error: $e');
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
      final createPath = '/me/drive/root/children';
      final folderData = {
        'name': _appFolderName,
        'folder': {},
        '@microsoft.graph.conflictBehavior': 'fail',
      };

      final response = await _httpClient!.post(
        Uri.parse('https://graph.microsoft.com/v1.0$createPath'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(folderData),
      );

      if (response.statusCode != 201) {
        throw Exception('Échec création dossier: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      _appFolderId = data['id'] as String;

      debugPrint('OneDriveBackupProvider - Created folder: $_appFolderName ($_appFolderId)');
      return _appFolderId!;
    } catch (e) {
      debugPrint('OneDriveBackupProvider - Create folder error: $e');
      rethrow;
    }
  }
}
