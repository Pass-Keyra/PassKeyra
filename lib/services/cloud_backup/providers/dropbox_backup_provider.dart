import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:dropbox_client/dropbox_client.dart'; // Désactivé temporairement (limite 50 users)
import 'package:http/http.dart' as http;
import '../cloud_backup_provider.dart';
import '../models/cloud_backup_metadata.dart';
import '../../../models/backup_payload.dart';
import '../../secure_storage_service.dart';

/// Implémentation du provider de backup pour Dropbox
///
/// Utilise dropbox_client pour l'authentification OAuth 2.0
/// et les opérations de fichiers.
///
/// Configuration: App folder (scoped access) - Les fichiers sont stockés
/// dans /Apps/PassKeyra/ (isolé du reste du Dropbox de l'utilisateur)
///
/// Sécurité: Les fichiers sont toujours chiffrés côté client
/// AVANT d'être uploadés (zero-knowledge encryption).
class DropboxBackupProvider implements CloudBackupProvider {
  // OAuth Configuration - À configurer via Dropbox Developers Console
  // https://www.dropbox.com/developers/apps
  // App Dropbox supprimée côté console (secret compromis car publié en open source).
  // Constantes vidées ; provider Dropbox à retirer entièrement plus tard (cf. plan).
  static const String _appKey = '';
  static const String _appSecret = '';

  // Avec App folder, tous les fichiers sont automatiquement dans /Apps/PassKeyra/
  // Pas besoin de créer un sous-dossier supplémentaire

  // Service de stockage sécurisé pour les tokens
  final SecureStorageService _storage = SecureStorageService();

  // Token d'accès Dropbox (initialisé après authentification)
  String? _accessToken;

  @override
  String get providerName => 'Dropbox';

  @override
  IconData get providerIcon => Icons.cloud_queue;

  @override
  Color get providerColor => const Color(0xFF0061FF); // Bleu Dropbox

  @override
  Future<bool> isAuthenticated() async {
    try {
      // Vérifier si un token est stocké
      _accessToken = await _storage.readDropboxToken();

      if (_accessToken == null || _accessToken!.isEmpty) {
        debugPrint('DropboxBackupProvider - No stored token found');
        return false;
      }

      // Vérifier la validité du token en testant une requête API simple
      try {
        // Tenter d'obtenir les infos du compte avec le token
        final response = await http.post(
          Uri.parse('https://api.dropboxapi.com/2/users/get_current_account'),
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          debugPrint('DropboxBackupProvider - Token valid, user authenticated');
          return true;
        } else if (response.statusCode == 401) {
          // Token invalide ou expiré
          debugPrint('DropboxBackupProvider - Token expired or invalid');
          await _storage.deleteDropboxToken();
          _accessToken = null;
          return false;
        } else {
          debugPrint('DropboxBackupProvider - Unexpected status: ${response.statusCode}');
          return false;
        }
      } catch (e) {
        // Erreur réseau ou temporaire, mais token existe toujours
        debugPrint('DropboxBackupProvider - Network error checking token: $e');
        // On considère l'utilisateur comme authentifié si le token existe
        return true;
      }
    } catch (e) {
      debugPrint('DropboxBackupProvider - isAuthenticated error: $e');
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    try {
      debugPrint('DropboxBackupProvider - Starting authentication...');

      // Initialiser Dropbox avec les credentials
      // Les 3 paramètres sont: clientId (identifiant app), App Key, App Secret
      // Le redirect URI est géré automatiquement via le scheme dans AndroidManifest.xml
      await Dropbox.init('passkeyra', _appKey, _appSecret);

      // Lancer le flux OAuth (ouvre navigateur ou app Dropbox)
      // Note: authorize() retourne void, on vérifie le token après
      await Dropbox.authorize();

      // Récupérer le token d'accès
      final token = await Dropbox.getAccessToken();

      if (token == null || token.isEmpty) {
        debugPrint('DropboxBackupProvider - Failed to get access token');
        return false;
      }

      // Sauvegarder le token de manière sécurisée
      await _storage.saveDropboxToken(token);
      _accessToken = token;

      debugPrint('DropboxBackupProvider - Authentication successful');
      return true;

    } catch (e) {
      debugPrint('DropboxBackupProvider - Authentication error: $e');

      // Messages d'erreur user-friendly
      if (e.toString().contains('INVALID_CLIENT')) {
        throw Exception(
          'Configuration OAuth incorrecte.\n'
          '\n'
          'Les clés Dropbox (App Key/Secret) sont invalides.\n'
          'Veuillez contacter le support.'
        );
      } else if (e.toString().contains('network')) {
        throw Exception(
          'Erreur de connexion.\n'
          '\n'
          'Vérifiez votre connexion Internet et réessayez.'
        );
      } else {
        throw Exception(
          'Erreur d\'authentification Dropbox.\n'
          '\n'
          'Message: ${e.toString()}\n'
          '\n'
          'Veuillez réessayer ou contacter le support.'
        );
      }
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Révoquer le token Dropbox
      await Dropbox.unlink();

      // Supprimer le token stocké localement
      await _storage.deleteDropboxToken();
      _accessToken = null;

      debugPrint('DropboxBackupProvider - Signed out successfully');
    } catch (e) {
      debugPrint('DropboxBackupProvider - Sign out error: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadBackup(BackupPayload payload, {String? fileName}) async {
    if (_accessToken == null) {
      throw Exception('Non authentifié à Dropbox. Veuillez vous connecter.');
    }

    try {
      // Générer nom de fichier si non fourni
      final backupFileName = fileName ??
          'passkeyra_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      // Avec App folder, le chemin commence toujours par /
      final filePath = '/$backupFileName';

      // Convertir BackupPayload en JSON bytes
      final jsonContent = payload.toJsonString();
      final bytes = utf8.encode(jsonContent);

      // Upload via Dropbox API
      final response = await http.post(
        Uri.parse('https://content.dropboxapi.com/2/files/upload'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/octet-stream',
          'Dropbox-API-Arg': jsonEncode({
            'path': filePath,
            'mode': 'add',
            'autorename': true, // Auto-renommer si fichier existe déjà
            'mute': false,
          }),
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final fileId = result['path_display'] as String;

        debugPrint('DropboxBackupProvider - Uploaded: $backupFileName → $fileId');
        return fileId; // Dropbox utilise le path comme ID
      } else {
        throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DropboxBackupProvider - Upload error: $e');
      rethrow;
    }
  }

  @override
  Future<List<CloudBackupMetadata>> listBackups() async {
    if (_accessToken == null) {
      throw Exception('Non authentifié à Dropbox. Veuillez vous connecter.');
    }

    try {
      // Lister tous les fichiers dans le dossier App (root avec App folder)
      final response = await http.post(
        Uri.parse('https://api.dropboxapi.com/2/files/list_folder'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'path': '', // Empty path = root of App folder (/Apps/PassKeyra/)
          'recursive': false,
          'include_deleted': false,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('List failed: ${response.statusCode} - ${response.body}');
      }

      final result = jsonDecode(response.body);
      final entries = result['entries'] as List<dynamic>;

      // Filtrer uniquement les fichiers JSON
      final backups = <CloudBackupMetadata>[];

      for (final entry in entries) {
        final tag = entry['.tag'] as String;
        final name = entry['name'] as String;

        // Ignorer les dossiers et les fichiers non-JSON
        if (tag != 'file' || !name.endsWith('.json')) {
          continue;
        }

        // Extraire les métadonnées
        final pathDisplay = entry['path_display'] as String;
        final sizeBytes = entry['size'] as int;
        final modifiedTime = DateTime.parse(entry['server_modified'] as String);

        // Télécharger le backup pour extraire le nombre d'entrées
        int? entryCount;
        try {
          final payload = await downloadBackup(pathDisplay);
          entryCount = payload.entryCount;
        } catch (e) {
          debugPrint('DropboxBackupProvider - Failed to extract entry count for $name: $e');
          entryCount = null;
        }

        backups.add(CloudBackupMetadata(
          id: pathDisplay, // Dropbox utilise le path comme ID
          name: name,
          uploadedAt: modifiedTime.toLocal(),
          sizeBytes: sizeBytes,
          providerName: providerName,
          entryCount: entryCount,
        ));
      }

      // Trier par date décroissante (plus récent en premier)
      backups.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      debugPrint('DropboxBackupProvider - Found ${backups.length} backups');
      return backups;
    } catch (e) {
      debugPrint('DropboxBackupProvider - List error: $e');
      rethrow;
    }
  }

  @override
  Future<BackupPayload> downloadBackup(String fileId) async {
    if (_accessToken == null) {
      throw Exception('Non authentifié à Dropbox. Veuillez vous connecter.');
    }

    try {
      // Télécharger le fichier (fileId = path dans Dropbox)
      final response = await http.post(
        Uri.parse('https://content.dropboxapi.com/2/files/download'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Dropbox-API-Arg': jsonEncode({
            'path': fileId,
          }),
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode} - ${response.body}');
      }

      // Convertir bytes en string JSON
      final jsonContent = utf8.decode(response.bodyBytes);

      // Parser en BackupPayload
      final payload = BackupPayload.fromJsonString(jsonContent);

      debugPrint('DropboxBackupProvider - Downloaded backup: $fileId');
      return payload;
    } catch (e) {
      debugPrint('DropboxBackupProvider - Download error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteBackup(String fileId) async {
    if (_accessToken == null) {
      throw Exception('Non authentifié à Dropbox. Veuillez vous connecter.');
    }

    try {
      // Supprimer le fichier (fileId = path dans Dropbox)
      final response = await http.post(
        Uri.parse('https://api.dropboxapi.com/2/files/delete_v2'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'path': fileId,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('DropboxBackupProvider - Deleted backup: $fileId');
      } else {
        throw Exception('Delete failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('DropboxBackupProvider - Delete error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // Tester la connectivité à l'API Dropbox
      final response = await http.head(
        Uri.parse('https://www.dropbox.com'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200 || response.statusCode == 301 || response.statusCode == 302;
    } catch (e) {
      debugPrint('DropboxBackupProvider - Availability check failed: $e');
      return false;
    }
  }

  @override
  Future<CloudQuota> getQuota() async {
    if (_accessToken == null) {
      throw Exception('Non authentifié à Dropbox. Veuillez vous connecter.');
    }

    try {
      // Obtenir les informations d'espace de stockage
      final response = await http.post(
        Uri.parse('https://api.dropboxapi.com/2/users/get_space_usage'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Quota check failed: ${response.statusCode} - ${response.body}');
      }

      final result = jsonDecode(response.body);

      // Dropbox retourne "used" et "allocation"
      final used = result['used'] as int;
      final allocation = result['allocation'];

      // Le champ "allocated" contient le quota total
      final total = allocation['allocated'] as int;

      debugPrint('DropboxBackupProvider - Quota: ${CloudQuota.formatBytes(used)} / ${CloudQuota.formatBytes(total)}');

      return CloudQuota(
        totalBytes: total,
        usedBytes: used,
      );
    } catch (e) {
      debugPrint('DropboxBackupProvider - Quota error: $e');
      rethrow;
    }
  }
}
