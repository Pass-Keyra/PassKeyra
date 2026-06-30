import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_backup_provider.dart';
import 'cloud_backup_factory.dart';
import 'models/cloud_backup_metadata.dart';
import '../../models/backup_payload.dart';
import '../premium_service.dart';

/// Service de gestion centralisé pour les backups cloud
///
/// Ce service:
/// - Gère la sélection du provider cloud (Google Drive, Dropbox, etc.)
/// - Persiste le choix de l'utilisateur
/// - Fournit une API unifiée pour upload/download/list/delete
/// - Gère les erreurs et rate limiting
///
/// Pattern: Facade + Singleton
class CloudBackupService {
  // Singleton
  static final CloudBackupService _instance = CloudBackupService._internal();
  factory CloudBackupService() => _instance;
  CloudBackupService._internal();

  // Clés SharedPreferences
  static const String _kSelectedProviderKey = 'selected_cloud_provider';
  static const String _kLastUploadTimeKey = 'last_cloud_upload_time';
  static const String _kAutoBackupEnabledKey = 'auto_drive_backup_enabled';

  // Provider actuellement sélectionné (un seul à la fois)
  CloudBackupProvider? _currentProvider;
  CloudProvider? _selectedProviderType;

  // Rate limiting: dernier upload timestamp
  DateTime? _lastUploadTime;

  // Délai minimum entre 2 uploads (éviter spam)
  static const Duration _minUploadInterval = Duration(minutes: 5);

  /// Charge le provider sauvegardé par l'utilisateur
  ///
  /// À appeler au démarrage de l'app ou lors de l'accès à la page Cloud Backup
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Migration : si une ancienne liste de providers actifs existe (multi-provider
    // déprécié), on la nettoie. Le single _kSelectedProviderKey reste source de
    // vérité.
    await prefs.remove('active_cloud_providers');

    // Charger le provider sélectionné
    final savedProviderName = prefs.getString(_kSelectedProviderKey);
    if (savedProviderName != null) {
      try {
        final providerType = CloudProvider.values.firstWhere(
          (p) => p.name == savedProviderName,
          orElse: () => CloudBackupFactory.getDefaultProvider(),
        );
        await selectProvider(providerType);
      } catch (e) {
        debugPrint('CloudBackupService - Failed to load saved provider: $e');
        // Fallback sur le provider par défaut
        await selectProvider(CloudBackupFactory.getDefaultProvider());
      }
    }

    // Charger le dernier timestamp d'upload
    final lastUploadMillis = prefs.getInt(_kLastUploadTimeKey);
    if (lastUploadMillis != null) {
      _lastUploadTime = DateTime.fromMillisecondsSinceEpoch(lastUploadMillis);
    }

    // Desktop : tenter de restaurer silencieusement la session OAuth
    // (Drive/OneDrive) au demarrage pour que isAuthenticated() retourne true
    // sans que l'utilisateur doive re-cliquer. Sur mobile, la session Google
    // est geree par le plugin natif et se restaure automatiquement.
    if (_currentProvider != null) {
      try {
        final isAuth = await _currentProvider!.isAuthenticated();
        debugPrint('CloudBackupService - Session provider restauree: $isAuth');
      } catch (e) {
        debugPrint('CloudBackupService - Erreur restauration session provider: $e');
      }
    }
  }

  /// Sélectionne et configure un provider cloud
  ///
  /// [provider] - Type de provider à utiliser
  ///
  /// Throws: UnsupportedError si le provider n'est pas disponible
  Future<void> selectProvider(CloudProvider provider) async {
    _currentProvider = CloudBackupFactory.createProvider(provider);
    _selectedProviderType = provider;

    // Sauvegarder le choix
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedProviderKey, provider.name);

    debugPrint('CloudBackupService - Selected provider: ${provider.displayName}');
  }

  /// Retourne le provider actuellement sélectionné
  CloudBackupProvider? get currentProvider => _currentProvider;

  /// Retourne le type de provider sélectionné
  CloudProvider? get selectedProviderType => _selectedProviderType;

  /// Vérifie si un provider est configuré
  bool get hasProvider => _currentProvider != null;

  /// Vérifie si l'utilisateur est authentifié au provider actuel
  Future<bool> isAuthenticated() async {
    if (_currentProvider == null) {
      return false;
    }
    return await _currentProvider!.isAuthenticated();
  }

  /// Lance l'authentification au provider actuel
  Future<bool> authenticate() async {
    if (_currentProvider == null) {
      throw Exception('Aucun provider cloud configuré');
    }
    return await _currentProvider!.authenticate();
  }

  /// Déconnecte du provider actuel
  Future<void> signOut() async {
    if (_currentProvider == null) {
      return;
    }
    await _currentProvider!.signOut();
  }

  /// Déconnexion complète du service de sauvegarde cloud.
  /// - Revoke les tokens OAuth de tous les providers actifs
  /// - Désactive l'auto-backup
  /// - Efface la sélection de provider
  /// - Reset l'état interne du service
  ///
  /// Après cet appel, `hasProvider` retourne false et l'utilisateur doit
  /// re-sélectionner + re-authentifier un provider pour utiliser le cloud backup.
  Future<void> disconnectCompletely() async {
    debugPrint('CloudBackupService - disconnectCompletely() appelé');

    // 1. Sign out du provider actuel
    if (_currentProvider != null) {
      try {
        await _currentProvider!.signOut();
        debugPrint('CloudBackupService - SignOut ${_selectedProviderType?.displayName ?? "provider"} OK');
      } catch (e) {
        debugPrint('CloudBackupService - Erreur signOut: $e');
      }
    }

    // 2. Désactiver l'auto-backup + nettoyer toute trace d'ancienne config multi-provider
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoBackupEnabledKey, false);
    await prefs.remove(_kSelectedProviderKey);
    await prefs.remove('active_cloud_providers'); // legacy multi-provider

    // 3. Reset état interne
    _currentProvider = null;
    _selectedProviderType = null;

    debugPrint('CloudBackupService - Déconnexion complète terminée');
  }

  /// Upload un backup vers le cloud
  ///
  /// [payload] - Backup chiffré à uploader
  ///
  /// Vérifie:
  /// - Provider configuré
  /// - Authentification
  /// - Rate limiting (max 1 upload toutes les 5 minutes)
  /// - Connectivité
  ///
  /// Returns: ID du fichier uploadé
  /// Throws: Exception si erreur ou rate limit dépassé
  Future<String> uploadBackup(BackupPayload payload) async {
    if (_currentProvider == null) {
      throw Exception('Aucun provider cloud configuré');
    }

    // Vérifier rate limiting
    if (_lastUploadTime != null) {
      final elapsed = DateTime.now().difference(_lastUploadTime!);
      if (elapsed < _minUploadInterval) {
        final remainingMinutes = _minUploadInterval.inMinutes - elapsed.inMinutes;
        throw Exception(
          'Veuillez attendre $remainingMinutes minute(s) avant le prochain backup',
        );
      }
    }

    // Vérifier connectivité
    if (!await _currentProvider!.isAvailable()) {
      throw Exception('Service cloud non disponible. Vérifiez votre connexion internet.');
    }

    // Vérifier authentification
    if (!await _currentProvider!.isAuthenticated()) {
      final authenticated = await _currentProvider!.authenticate();
      if (!authenticated) {
        throw Exception('Authentification échouée');
      }
    }

    // Upload
    try {
      final fileName = 'passkeyra_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final fileId = await _currentProvider!.uploadBackup(payload, fileName: fileName);

      // Sauvegarder le timestamp
      _lastUploadTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastUploadTimeKey, _lastUploadTime!.millisecondsSinceEpoch);

      debugPrint('CloudBackupService - Upload successful: $fileId');
      return fileId;
    } catch (e) {
      debugPrint('CloudBackupService - Upload failed: $e');
      rethrow;
    }
  }

  /// Liste tous les backups disponibles dans le cloud
  ///
  /// Returns: Liste triée par date (plus récent en premier)
  /// Throws: Exception si erreur ou non authentifié
  Future<List<CloudBackupMetadata>> listBackups() async {
    if (_currentProvider == null) {
      throw Exception('Aucun provider cloud configuré');
    }

    // Note: Pas de vérification isAuthenticated() ici pour éviter race condition
    // La vérification est faite avant l'appel de cette méthode
    // Le provider vérifie _driveApi != null de toute façon

    try {
      final backups = await _currentProvider!.listBackups();
      debugPrint('CloudBackupService - Found ${backups.length} backup(s)');
      return backups;
    } catch (e) {
      debugPrint('CloudBackupService - List failed: $e');
      rethrow;
    }
  }

  /// Télécharge un backup depuis le cloud
  ///
  /// [fileId] - ID du fichier à télécharger
  ///
  /// Returns: BackupPayload chiffré (à déchiffrer avec master password)
  /// Throws: Exception si erreur ou fichier introuvable
  Future<BackupPayload> downloadBackup(String fileId) async {
    if (_currentProvider == null) {
      throw Exception('Aucun provider cloud configuré');
    }

    // Note: Pas de vérification isAuthenticated() ici pour éviter race condition
    // La vérification est faite avant l'appel de cette méthode
    // Le provider vérifie _driveApi != null de toute façon

    try {
      final payload = await _currentProvider!.downloadBackup(fileId);
      debugPrint('CloudBackupService - Download successful: $fileId');
      return payload;
    } catch (e) {
      debugPrint('CloudBackupService - Download failed: $e');
      rethrow;
    }
  }

  /// Supprime un backup du cloud
  ///
  /// [fileId] - ID du fichier à supprimer
  ///
  /// Throws: Exception si erreur ou fichier introuvable
  Future<void> deleteBackup(String fileId) async {
    if (_currentProvider == null) {
      throw Exception('Aucun provider cloud configuré');
    }

    // Note: Pas de vérification isAuthenticated() ici pour éviter race condition
    // La vérification est faite avant l'appel de cette méthode
    // Le provider vérifie _driveApi != null de toute façon

    try {
      await _currentProvider!.deleteBackup(fileId);
      debugPrint('CloudBackupService - Delete successful: $fileId');
    } catch (e) {
      debugPrint('CloudBackupService - Delete failed: $e');
      rethrow;
    }
  }

  /// Obtient les informations de quota du cloud
  ///
  /// Returns: Quota (total, utilisé, restant)
  /// Throws: Exception si erreur ou non authentifié
  Future<CloudQuota> getQuota() async {
    if (_currentProvider == null) {
      throw Exception('Aucun provider cloud configuré');
    }

    // Note: Pas de vérification isAuthenticated() ici pour éviter race condition
    // La vérification est faite avant l'appel de cette méthode
    // Le provider vérifie _driveApi != null de toute façon

    try {
      return await _currentProvider!.getQuota();
    } catch (e) {
      debugPrint('CloudBackupService - Quota failed: $e');
      rethrow;
    }
  }

  /// Retourne le temps restant avant de pouvoir uploader à nouveau
  ///
  /// Returns: Duration restante, ou null si pas de restriction
  Duration? getTimeUntilNextUpload() {
    if (_lastUploadTime == null) {
      return null;
    }

    final elapsed = DateTime.now().difference(_lastUploadTime!);
    if (elapsed >= _minUploadInterval) {
      return null;
    }

    return _minUploadInterval - elapsed;
  }

  /// Réinitialise le rate limiting (pour tests)
  @visibleForTesting
  Future<void> resetRateLimit() async {
    _lastUploadTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastUploadTimeKey);
  }

  /// Active ou désactive les sauvegardes automatiques Drive
  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoBackupEnabledKey, enabled);
    debugPrint('CloudBackupService - Auto backup ${enabled ? "enabled" : "disabled"}');
  }

  /// Vérifie si les sauvegardes automatiques sont activées
  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoBackupEnabledKey) ?? false; // Désactivé par défaut
  }

  /// Nettoie les anciennes sauvegardes (garde la 1 plus récente uniquement)
  ///
  /// Appelé automatiquement après chaque upload (manuel ou automatique)
  Future<void> cleanOldBackups() async {
    if (_currentProvider == null) {
      return;
    }

    try {
      // Lister tous les backups (déjà triés par date décroissante)
      final allBackups = await listBackups();

      // Si on a plus de 1 backup, supprimer les anciens
      if (allBackups.length > 1) {
        final backupsToDelete = allBackups.sublist(1); // Tout après le 1er (le plus récent)

        debugPrint('CloudBackupService - Cleaning ${backupsToDelete.length} old backups');

        for (final backup in backupsToDelete) {
          try {
            await _currentProvider!.deleteBackup(backup.id);
            debugPrint('  - Deleted: ${backup.name}');
          } catch (e) {
            debugPrint('  - Failed to delete ${backup.name}: $e');
            // Continue malgré l'erreur
          }
        }
      }
    } catch (e) {
      debugPrint('CloudBackupService - Clean old backups failed: $e');
      // Ne pas rethrow, c'est une opération de maintenance
    }
  }

  /// Upload automatique d'un backup (déclenché par sync Firebase)
  ///
  /// Différences avec uploadBackup() manuel :
  /// - Pas de rate limiting (suit le rythme de Firebase sync)
  /// - Format de nom standardisé : passkeyra_backup_YYYY-MM-DD_HH-mm-ss.json
  /// - Rotation automatique des anciennes sauvegardes
  ///
  /// Returns: ID du fichier uploadé
  /// Throws: Exception si erreur
  Future<String> uploadAutoBackup(BackupPayload payload) async {
    if (_currentProvider == null) {
      throw Exception('Aucun provider cloud configuré');
    }

    // Vérifier que l'auto backup est activé
    if (!await isAutoBackupEnabled()) {
      throw Exception('Auto backup désactivé');
    }

    // Vérifier connectivité
    if (!await _currentProvider!.isAvailable()) {
      throw Exception('Service cloud non disponible');
    }

    // Vérifier authentification
    if (!await _currentProvider!.isAuthenticated()) {
      final providerName = _selectedProviderType?.displayName ?? 'cloud provider';
      throw Exception('Non authentifié à $providerName');
    }

    // Vérifier que l'utilisateur est Premium
    final isPremium = PremiumService().isPremium;
    if (!isPremium) {
      throw Exception('Sauvegardes automatiques réservées aux utilisateurs Premium');
    }

    try {
      // Format standardisé : passkeyra_backup_YYYY-MM-DD_HH-mm-ss.json
      final now = DateTime.now();
      final fileName = 'passkeyra_backup_'
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}'
          '.json';

      // Upload
      final fileId = await _currentProvider!.uploadBackup(payload, fileName: fileName);
      debugPrint('CloudBackupService - Auto backup uploaded: $fileId ($fileName)');

      // Rotation : supprimer les backups au-delà de 5
      await cleanOldBackups();

      return fileId;
    } catch (e) {
      debugPrint('CloudBackupService - Auto backup failed: $e');
      rethrow;
    }
  }

  /// Authentifie silencieusement l'utilisateur si l'auto backup est activé
  ///
  /// Cette méthode est appelée au démarrage de l'app pour s'assurer
  /// que Google Drive est prêt si la sauvegarde automatique est activée.
  ///
  /// Returns true si l'authentification a réussi ou si déjà authentifié,
  /// false si l'auto backup est désactivé ou si l'authentification échoue.
  Future<bool> authenticateIfAutoBackupEnabled() async {
    try {
      // Vérifier si auto backup activé
      final isEnabled = await isAutoBackupEnabled();
      if (!isEnabled) {
        debugPrint('CloudBackupService - Auto backup désactivé, pas d\'auth nécessaire');
        return false;
      }

      // S'assurer qu'un provider est sélectionné (provider par défaut)
      if (_currentProvider == null) {
        await selectProvider(CloudBackupFactory.getDefaultProvider());
      }

      // Vérifier si déjà authentifié
      final isAuth = await isAuthenticated();
      if (isAuth) {
        debugPrint('CloudBackupService - Déjà authentifié à ${_selectedProviderType?.displayName}');
        return true;
      }

      // Ne PAS forcer l'authentification (popup) au démarrage de l'app
      // L'utilisateur devra cliquer explicitement sur "Sauvegarder vers Drive"
      debugPrint('CloudBackupService - Non authentifié, attendre action utilisateur explicite');
      return false;
    } catch (e) {
      debugPrint('CloudBackupService - Erreur auth automatique: $e');
      return false;
    }
  }
}
