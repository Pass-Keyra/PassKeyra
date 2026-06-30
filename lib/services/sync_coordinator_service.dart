import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase/rest/cloud_debug_log.dart';
import '../models/custom_category.dart';
import '../models/password_entry.dart';
import '../models/backup_payload.dart';
import '../services/auth_service.dart';
import '../services/backup_repository.dart';
import '../services/vault_repository.dart';
import '../services/firebase/firebase_auth_service.dart';
import '../services/firebase/firebase_sync_service.dart';
import '../services/premium_service.dart';
import '../services/cloud_backup/cloud_backup_service.dart';
import '../services/crypto_service.dart';
import '../services/category_service.dart';

/// États possibles pour le backup cloud automatique
enum CloudBackupState {
  disabled,       // Backup auto désactivé ou pas Premium
  idle,           // Activé et prêt
  inProgress,     // Backup en cours
  success,        // Dernier backup réussi
  failed,         // Dernier backup échoué
}

/// États possibles pour la sauvegarde locale automatique
enum LocalBackupState {
  disabled,    // Toggle désactivé ou pas Premium
  idle,        // Toggle activé, aucune opération en cours
  inProgress,  // Sauvegarde en cours
  success,     // Dernière sauvegarde réussie
  failed,      // Dernière sauvegarde échouée
}

/// Service coordinateur entre VaultRepository et FirebaseSyncService
///
/// Gère la synchronisation automatique bidirectionnelle :
/// - Local → Cloud : Lors de saveAll()
/// - Cloud → Local : Lors de changements Firestore détectés
///
/// Stratégie Last-Write-Wins pour la résolution des conflits
class SyncCoordinatorService {
  SyncCoordinatorService({
    required AuthService authService,
    required VaultRepository vaultRepository,
  })  : _authService = authService,
        _vaultRepository = vaultRepository {
    _firebaseAuthService = FirebaseAuthService();
    _firebaseSyncService = FirebaseSyncService(
      authService: authService,
      firebaseAuthService: _firebaseAuthService,
    );

    // Configurer les callbacks pour les changements cloud
    _firebaseSyncService.onCloudEntriesChanged = _handleCloudChanges;
    _firebaseSyncService.onCloudEntriesDeleted = _handleCloudDeletions;
    _firebaseSyncService.onCloudCategoriesChanged = _handleCloudCategoriesChanged;
  }

  final AuthService _authService;
  final VaultRepository _vaultRepository;
  final _categoryService = CategoryService();
  bool _isSyncingCategories = false;
  late final FirebaseAuthService _firebaseAuthService;
  late final FirebaseSyncService _firebaseSyncService;
  final CloudBackupService _driveBackupService = CloudBackupService();
  final CryptoService _cryptoService = CryptoService();

  /// État actuel du backup cloud automatique avec notification
  final _backupStateNotifier = ValueNotifier<CloudBackupState>(CloudBackupState.disabled);

  CloudBackupState get backupState => _backupStateNotifier.value;
  ValueNotifier<CloudBackupState> get backupStateNotifier => _backupStateNotifier;

  /// État actuel de la sauvegarde locale automatique avec notification (statique pour accès cross-pages)
  static final localBackupStateNotifier = ValueNotifier<LocalBackupState>(LocalBackupState.disabled);

  /// Subscription au stream authStateChanges de Firebase
  StreamSubscription<dynamic>? _authStateSubscription;

  /// Subscription au stream premiumStatusChanges (réagit au revoke Premium).
  StreamSubscription<bool>? _premiumStatusSubscription;

  /// Met à jour l'état du backup et notifie les listeners
  void _updateBackupState(CloudBackupState newState) {
    _backupStateNotifier.value = newState;
  }

  /// Service Firebase Sync (exposé pour configuration UI)
  FirebaseSyncService get firebaseSyncService => _firebaseSyncService;

  /// Service Firebase Auth (exposé pour configuration UI)
  FirebaseAuthService get firebaseAuthService => _firebaseAuthService;

  /// Force une synchronisation immédiate depuis le cloud
  ///
  /// Utilisé pour le pull-to-refresh dans la HomePage
  Future<void> forceSyncFromCloud() async {
    await _firebaseSyncService.forceSyncFromCloud();
  }

  /// Initialise le statut de synchronisation
  ///
  /// Cette méthode doit être appelée après la création du service pour que
  /// le statut initial reflète correctement l'état de la synchronisation
  /// (activée/désactivée) stocké dans SharedPreferences.
  ///
  /// CRITIQUE: Tente de restaurer automatiquement la session Firebase/Google
  /// et écoute les changements d'état pour réactiver la sync si nécessaire
  Future<void> initialize() async {
    debugPrint('DEBUG - SyncCoordinatorService.initialize() DÉMARRÉ');

    // Restaurer la session Google uniquement pour les utilisateurs Premium
    // Les utilisateurs gratuits n'utilisent pas Firebase/Google → pas de popup inutile au démarrage
    final isPremium = PremiumService().isPremium;
    cloudLog('SyncCoordinator.initialize : isPremium=$isPremium');
    if (isPremium) {
      debugPrint('SyncCoordinatorService - Tentative de restauration session Google (Premium)...');
      final restoredUser = await _firebaseAuthService.restoreSession();
      if (restoredUser != null) {
        debugPrint('SyncCoordinatorService - Session Google restaurée: ${restoredUser.email}');
        cloudLog('SyncCoordinator : session restauree email=${restoredUser.email}');
      } else {
        debugPrint('SyncCoordinatorService - Aucune session à restaurer ou restauration échouée');
        cloudLog('SyncCoordinator : restoreSession retourne null');
      }
    } else {
      debugPrint('SyncCoordinatorService - Utilisateur gratuit, restauration session ignorée');
      cloudLog('SyncCoordinator : NON-Premium, restauration ignoree');
    }

    // Initialiser Firebase Sync (maintenant l'utilisateur devrait être connecté si session restaurée)
    debugPrint('SyncCoordinatorService - Initialisation Firebase Sync...');
    await _firebaseSyncService.initializeStatus();
    debugPrint('SyncCoordinatorService - Firebase Sync initialisé');

    // CRITIQUE: Initialiser CloudBackupService pour charger le provider sauvegardé
    debugPrint('SyncCoordinatorService - Initialisation CloudBackupService...');
    await _driveBackupService.initialize();
    debugPrint('SyncCoordinatorService - CloudBackupService initialisé');

    // Initialiser l'état du backup cloud
    debugPrint('SyncCoordinatorService - Initialisation backup state...');
    await _initializeBackupState();
    debugPrint('SyncCoordinatorService - Backup state initialisé');

    // Initialiser l'état du backup local
    await _initializeLocalBackupState();

    // CRITIQUE: Écouter les changements d'état d'authentification Firebase
    // pour détecter automatiquement les reconnexions et réactiver la sync
    _listenToAuthStateChanges();

    // CRITIQUE: Écouter les changements de statut Premium pour stopper
    // immédiatement les services Premium quand le user perd son abonnement
    // (annulation IAP, expiration, ou easter egg toggle OFF en debug).
    _premiumStatusSubscription = PremiumService().premiumStatusChanges.listen((isPremium) async {
      if (!isPremium) {
        debugPrint('SyncCoordinator - Premium revoked → arrêt features Premium');
        await _onPremiumRevoked();
      }
    });

    // Écouter les changements locaux de catégories pour les uploader vers Firebase
    await _categoryService.initialize();
    _categoryService.addListener(_onLocalCategoriesChanged);

    debugPrint('DEBUG - SyncCoordinatorService.initialize() TERMINÉ');
  }

  /// Désactive toutes les features Premium quand l'utilisateur perd son abonnement.
  /// Stoppe les listeners background, désactive les flags persistents.
  /// Ne supprime PAS les données locales (le user a payé pour les avoir).
  Future<void> _onPremiumRevoked() async {
    // 1. Stopper Firebase sync + désactiver le flag persistent (3 couches)
    try {
      await _firebaseSyncService.setSyncEnabled(false);
    } catch (e) {
      debugPrint('SyncCoordinator - Erreur arrêt Firebase sync: $e');
    }

    // 2. Stopper auto-backup cloud + désactiver le flag persistent
    try {
      await _driveBackupService.setAutoBackupEnabled(false);
    } catch (e) {
      debugPrint('SyncCoordinator - Erreur arrêt auto-backup cloud: $e');
    }

    // 3. Désactiver flag local auto-backup
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('local_auto_backup_enabled', false);
      localBackupStateNotifier.value = LocalBackupState.disabled;
    } catch (e) {
      debugPrint('SyncCoordinator - Erreur désactivation auto-backup local: $e');
    }

    // 4. Invalider le token Firebase pour qu'un futur re-init ne réactive pas
    //    silencieusement la sync. Le user qui re-paye refera Google sign-in
    //    consciemment.
    try {
      await _firebaseAuthService.signOut();
    } catch (e) {
      debugPrint('SyncCoordinator - Erreur signOut Firebase: $e');
    }

    debugPrint('SyncCoordinator - Toutes les features Premium désactivées');
  }

  /// Écoute les changements d'état d'authentification Firebase
  ///
  /// Si l'utilisateur se reconnecte (après perte de session due au Battery Optimization),
  /// cette méthode réactive automatiquement la synchronisation Firestore
  void _listenToAuthStateChanges() {
    debugPrint('SyncCoordinatorService - Démarrage écoute authStateChanges...');

    _authStateSubscription = _firebaseAuthService.authStateChanges.listen((cloudUser) async {
      debugPrint('SyncCoordinatorService - authStateChanges détecté:');
      debugPrint('  - Utilisateur: ${cloudUser?.email ?? "null"}');
      debugPrint('  - UID: ${cloudUser?.uid ?? "null"}');

      // Vérifier si la sync est censée être activée
      final syncEnabled = await _firebaseSyncService.isSyncEnabled();
      final isPremium = PremiumService().isPremium;

      debugPrint('  - Sync activée (stockage): $syncEnabled');
      debugPrint('  - Premium: $isPremium');

      if (cloudUser != null && syncEnabled && isPremium) {
        // Utilisateur connecté ET sync activée → Réinitialiser la sync
        debugPrint('SyncCoordinatorService - RECONNEXION DÉTECTÉE - Réactivation de la sync...');

        // Forcer la réinitialisation du statut pour redémarrer le listener
        await _firebaseSyncService.initializeStatus();

        debugPrint('SyncCoordinatorService - Synchronisation réactivée avec succès');
      } else if (cloudUser == null && syncEnabled) {
        // Utilisateur déconnecté mais sync activée → Avertir
        debugPrint('SyncCoordinatorService - DÉCONNEXION DÉTECTÉE - Sync activée mais utilisateur déconnecté');
        debugPrint('SyncCoordinatorService - La sync sera réactivée automatiquement à la prochaine connexion');
      }
    });

    debugPrint('SyncCoordinatorService - Écoute authStateChanges active');
  }

  /// Initialise l'état du backup cloud au démarrage
  Future<void> _initializeBackupState() async {
    // Vérifier si Premium
    final isPremium = PremiumService().isPremium;
    if (!isPremium) {
      _updateBackupState(CloudBackupState.disabled);
      return;
    }

    // Vérifier si auto backup activé
    try {
      final autoBackupEnabled = await _driveBackupService.isAutoBackupEnabled();
      if (!autoBackupEnabled) {
        _updateBackupState(CloudBackupState.disabled);
        return;
      }

      // Auto backup activé - passer à idle (bleu) - prêt pour backup
      _updateBackupState(CloudBackupState.idle);
    } catch (e) {
      debugPrint('SyncCoordinatorService - Erreur initialisation backup state: $e');
      _updateBackupState(CloudBackupState.disabled);
    }
  }

  /// Initialise l'état de la sauvegarde locale au démarrage
  Future<void> _initializeLocalBackupState() async {
    final isPremium = PremiumService().isPremium;
    if (!isPremium) {
      SyncCoordinatorService.localBackupStateNotifier.value = LocalBackupState.disabled;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('local_auto_backup_enabled') ?? false;
      SyncCoordinatorService.localBackupStateNotifier.value =
          enabled ? LocalBackupState.idle : LocalBackupState.disabled;
    } catch (e) {
      SyncCoordinatorService.localBackupStateNotifier.value = LocalBackupState.disabled;
    }
  }

  /// Sauvegarde les entrées localement ET lance une sync vers le cloud (si activée)
  ///
  /// C'est la méthode à utiliser à la place de VaultRepository.saveAll()
  Future<void> saveAll(List<PasswordEntry> entries) async {
    debugPrint('DEBUG - SyncCoordinatorService.saveAll() appelé avec ${entries.length} entrées');

    // Sauvegarder localement d'abord (source de vérité)
    await _vaultRepository.saveAll(entries);
    debugPrint('  Sauvegarde locale effectuée');

    // Sauvegarde locale automatique (Premium) — indépendant du cloud
    _triggerLocalAutoBackupIfEnabled(entries);

    // Si sync activée et Premium, uploader vers cloud
    final syncEnabled = await _firebaseSyncService.isSyncEnabled();
    final isPremium = PremiumService().isPremium;
    final isSignedIn = _firebaseAuthService.isSignedIn;

    debugPrint('SyncCoordinatorService - État de synchronisation:');
    debugPrint('  - Sync activée: $syncEnabled');
    debugPrint('  - Premium: $isPremium');
    debugPrint('  - Connecté Firebase: $isSignedIn');

    if (syncEnabled && isPremium && isSignedIn) {
      // Utiliser le debounce pour optimiser les syncs
      debugPrint('SyncCoordinatorService - Sync automatique planifiée');
      cloudLog('saveAll : upload planifie (${entries.length} entries)');
      _firebaseSyncService.syncWithDebounce(entries);
    } else {
      debugPrint('SyncCoordinatorService - Sync ignorée (conditions non remplies)');
      cloudLog('saveAll : upload IGNORE (syncEnabled=$syncEnabled isPremium=$isPremium isSignedIn=$isSignedIn)');
    }

    // Déclencher le backup automatique cloud (Google Drive/OneDrive)
    // INDÉPENDANT de Firebase Sync - un utilisateur peut utiliser Drive/OneDrive sans Firebase
    _triggerAutoBackupIfEnabled(entries);
  }

  /// Lit toutes les entrées locales
  Future<List<PasswordEntry>> readAll() async {
    return await _vaultRepository.readAll();
  }

  /// Supprime une entrée localement ET dans le cloud (si sync activée)
  ///
  /// Cette méthode garantit que la suppression est propagée correctement
  /// à Firestore en marquant l'entrée comme deleted=true
  Future<void> delete(String entryId) async {
    debugPrint('DEBUG - SyncCoordinatorService.delete() appelé pour: $entryId');

    // Supprimer localement
    final entries = await _vaultRepository.readAll();
    entries.removeWhere((e) => e.id == entryId);
    await _vaultRepository.saveAll(entries);
    debugPrint('  Suppression locale effectuée');

    // Supprimer sur le cloud si sync activée
    final syncEnabled = await _firebaseSyncService.isSyncEnabled();
    final isPremium = PremiumService().isPremium;
    final isSignedIn = _firebaseAuthService.isSignedIn;

    debugPrint('SyncCoordinatorService - État de synchronisation (suppression):');
    debugPrint('  - Sync activée: $syncEnabled');
    debugPrint('  - Premium: $isPremium');
    debugPrint('  - Connecté Firebase: $isSignedIn');

    if (syncEnabled && isPremium && isSignedIn) {
      debugPrint('  - Suppression cloud immédiate (marquer deleted=true dans Firestore)');
      await _firebaseSyncService.deleteEntry(entryId);
    } else {
      debugPrint('  - Suppression locale uniquement (sync non activée)');
    }
  }

  /// Gère les changements cloud détectés par le listener Firestore
  ///
  /// Merge les entrées cloud avec le vault local selon Last-Write-Wins
  Future<void> _handleCloudChanges(List<PasswordEntry> cloudEntries) async {
    try {
      debugPrint('SyncCoordinatorService - Traitement ${cloudEntries.length} changements cloud');

      // Lire les entrées locales
      final localEntries = await _vaultRepository.readAll();

      // Map pour accès rapide par ID
      final localMap = {for (var e in localEntries) e.id: e};
      final mergedEntries = <PasswordEntry>[];

      // Merge chaque entrée cloud avec locale
      for (final cloudEntry in cloudEntries) {
        final localEntry = localMap[cloudEntry.id];

        if (localEntry == null) {
          // Nouvelle entrée cloud → ajouter au local
          mergedEntries.add(cloudEntry);
          debugPrint('  - Nouvelle entrée: ${cloudEntry.name}');
        } else {
          // Conflit → résolution Last-Write-Wins
          if (cloudEntry.updatedAt.isAfter(localEntry.updatedAt)) {
            mergedEntries.add(cloudEntry); // Cloud gagne
            debugPrint('  - Conflit résolu (cloud gagne): ${cloudEntry.name}');
          } else {
            mergedEntries.add(localEntry); // Local gagne
            debugPrint('  - Conflit résolu (local gagne): ${localEntry.name}');
          }

          // Retirer de la map pour éviter les doublons
          localMap.remove(cloudEntry.id);
        }
      }

      // Ajouter les entrées locales restantes (non modifiées)
      mergedEntries.addAll(localMap.values);

      // Sauvegarder le résultat mergé localement
      // Note: On appelle directement VaultRepository pour éviter de re-déclencher une sync
      await _vaultRepository.saveAll(mergedEntries);

      debugPrint('SyncCoordinatorService - Merge terminé (${mergedEntries.length} entrées totales)');
    } catch (e) {
      debugPrint('SyncCoordinatorService - Erreur merge cloud: $e');
    }
  }

  /// Gère les suppressions cloud détectées par le listener Firestore
  ///
  /// Supprime localement les entrées qui ont été supprimées sur le cloud
  Future<void> _handleCloudDeletions(List<String> deletedEntryIds) async {
    try {
      debugPrint('SyncCoordinatorService - Traitement ${deletedEntryIds.length} suppressions cloud');

      // Lire les entrées locales
      final localEntries = await _vaultRepository.readAll();

      // Supprimer les entrées dont l'ID est dans la liste de suppressions
      final remainingEntries = localEntries.where((entry) {
        final isDeleted = deletedEntryIds.contains(entry.id);
        if (isDeleted) {
          debugPrint('  - Suppression locale de: ${entry.name} (${entry.id})');
        }
        return !isDeleted;
      }).toList();

      // Sauvegarder le résultat sans les entrées supprimées
      // Note: On appelle directement VaultRepository pour éviter de re-déclencher une sync
      await _vaultRepository.saveAll(remainingEntries);

      debugPrint('SyncCoordinatorService - Suppressions appliquées (${remainingEntries.length} entrées restantes)');
    } catch (e) {
      debugPrint('SyncCoordinatorService - Erreur traitement suppressions cloud: $e');
    }
  }

  /// Déclenche une sauvegarde automatique sur Google Drive (si activée)
  ///
  /// Appelé après une synchronisation Firebase réussie
  Future<void> _triggerAutoBackupIfEnabled(List<PasswordEntry> entries) async {
    debugPrint('AUTO_START entries=${entries.length}');
    // Vérifier que l'utilisateur est Premium
    final isPremium = PremiumService().isPremium;
    if (!isPremium) {
      debugPrint('SyncCoordinatorService - Auto backup cloud: utilisateur non Premium');
      _updateBackupState(CloudBackupState.disabled);
      return;
    }

    // Vérifier si l'auto backup est activé
    try {
      final autoBackupEnabled = await _driveBackupService.isAutoBackupEnabled();
      if (!autoBackupEnabled) {
        debugPrint('SyncCoordinatorService - Auto backup cloud désactivé');
        _updateBackupState(CloudBackupState.disabled);
        return;
      }
    } catch (e) {
      debugPrint('SyncCoordinatorService - Erreur vérification auto backup: $e');
      _updateBackupState(CloudBackupState.disabled);
      return;
    }

    // Vérifier l'authentification du provider actuel (1 seul provider supporté)
    try {
      final isAuthenticated = await _driveBackupService.isAuthenticated();
      if (!isAuthenticated) {
        final providerName = _driveBackupService.currentProvider?.providerName ?? 'service cloud';
        debugPrint('SyncCoordinatorService - Non authentifié à $providerName, auto backup ignoré');
        debugPrint('SyncCoordinatorService - L\'utilisateur doit reconnecter manuellement depuis la page Cloud Backup');
        _updateBackupState(CloudBackupState.idle);
        return;
      }
    } catch (e) {
      debugPrint('SyncCoordinatorService - Erreur vérification authentification: $e');
      _updateBackupState(CloudBackupState.idle);
      return;
    }

    final providerName = _driveBackupService.currentProvider?.providerName ?? 'cloud';
    debugPrint('SyncCoordinatorService - Déclenchement auto backup $providerName...');

    _updateBackupState(CloudBackupState.inProgress);

    // Créer le backup payload chiffré
    final encryptionKey = _authService.currentKey;
    if (encryptionKey == null) {
      debugPrint('SyncCoordinatorService - Pas de clé de chiffrement, auto backup annulé');
      return;
    }

    // Récupérer le salt de session (CRITIQUE: doit correspondre à la clé de chiffrement)
    final saltBase64 = await _authService.secureStorage.readSalt();
    if (saltBase64 == null) {
      debugPrint('SyncCoordinatorService - Pas de salt de session, auto backup annulé');
      return;
    }

    // Charger les catégories personnalisées
    final categoryService = CategoryService();
    await categoryService.initialize();
    final categories = categoryService.getAllCategories();

    // Préparer les données (entrées ET catégories)
    final exportData = {
      'entries': entries.map((e) => e.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    // Chiffrer les données avec la clé de session
    final encryptedJson = _cryptoService.encryptJson(exportData, encryptionKey);
    final encryptedMap = jsonDecode(encryptedJson) as Map<String, dynamic>;

    // Créer le backup payload
    final keyIterations =
        _authService.currentKeyIterations ?? CryptoService.defaultIterations;
    debugPrint(
      'AUTO_KEY keyBytes=${encryptionKey.length} keyIterations=$keyIterations saltChars=${saltBase64.length}',
    );
    final payload = BackupPayload(
      salt: saltBase64,
      iv: encryptedMap['iv'] as String,
      ciphertext: encryptedMap['ciphertext'] as String,
      tag: encryptedMap['tag'] as String,
      exportedAt: DateTime.now(),
      entryCount: entries.length,
      iterations: keyIterations, // CRITIQUE: Itérations réelles de la clé de session
    );
    debugPrint(
      'AUTO_PAYLOAD iterations=${payload.iterations} ivChars=${payload.iv.length} ctChars=${payload.ciphertext.length} tagChars=${payload.tag.length} entryCount=${payload.entryCount}',
    );

    // Upload automatique avec mécanisme de retry (single provider)
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        await _driveBackupService.uploadAutoBackup(payload);
        debugPrint('AUTO_SINGLE_OK provider=$providerName');
        debugPrint('SyncCoordinatorService - Auto backup $providerName réussi${retryCount > 0 ? ' (tentative ${retryCount + 1}/$maxRetries)' : ''}');
        _updateBackupState(CloudBackupState.success);

        // Repasser à idle après 5 secondes pour indiquer que le système est prêt
        Future.delayed(const Duration(seconds: 5), () {
          _updateBackupState(CloudBackupState.idle);
        });

        return; // Succès, on sort de la fonction
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          // Échec après toutes les tentatives
          debugPrint('SyncCoordinatorService - Auto backup $providerName échoué après $maxRetries tentatives: $e');
          _updateBackupState(CloudBackupState.failed);
        } else {
          // Attendre avant la prochaine tentative (backoff exponentiel)
          final delaySeconds = 2 * retryCount; // 2s, 4s, 6s...
          debugPrint('SyncCoordinatorService - Auto backup Drive échoué (tentative $retryCount/$maxRetries), nouvelle tentative dans ${delaySeconds}s: $e');
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }
    }
  }

  /// Déclenche une sauvegarde locale automatique si activée (Premium)
  Future<void> _triggerLocalAutoBackupIfEnabled(List<PasswordEntry> entries) async {
    final isPremium = PremiumService().isPremium;
    if (!isPremium) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('local_auto_backup_enabled') ?? false;
      if (!enabled) return;
    } catch (e) {
      return;
    }

    SyncCoordinatorService.localBackupStateNotifier.value = LocalBackupState.inProgress;

    final encryptionKey = _authService.currentKey;
    if (encryptionKey == null) {
      SyncCoordinatorService.localBackupStateNotifier.value = LocalBackupState.failed;
      return;
    }

    final saltBase64 = await _authService.secureStorage.readSalt();
    if (saltBase64 == null) {
      SyncCoordinatorService.localBackupStateNotifier.value = LocalBackupState.failed;
      return;
    }

    try {
      final categoryService = CategoryService();
      await categoryService.initialize();
      final categories = categoryService.getAllCategories();

      final exportData = {
        'entries': entries.map((e) => e.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };

      final encryptedJson = _cryptoService.encryptJson(exportData, encryptionKey);
      final encryptedMap = jsonDecode(encryptedJson) as Map<String, dynamic>;
      final keyIterations = _authService.currentKeyIterations ?? CryptoService.defaultIterations;

      final payload = BackupPayload(
        salt: saltBase64,
        iv: encryptedMap['iv'] as String,
        ciphertext: encryptedMap['ciphertext'] as String,
        tag: encryptedMap['tag'] as String,
        exportedAt: DateTime.now(),
        entryCount: entries.length,
        iterations: keyIterations,
      );

      await BackupRepository().saveLocalBackup(payload);
      SyncCoordinatorService.localBackupStateNotifier.value = LocalBackupState.success;
      Future.delayed(const Duration(seconds: 5), () {
        if (SyncCoordinatorService.localBackupStateNotifier.value == LocalBackupState.success) {
          SyncCoordinatorService.localBackupStateNotifier.value = LocalBackupState.idle;
        }
      });
      debugPrint('SyncCoordinatorService - Sauvegarde locale automatique effectuée');
    } catch (e) {
      SyncCoordinatorService.localBackupStateNotifier.value = LocalBackupState.failed;
      Future.delayed(const Duration(seconds: 5), () {
        if (SyncCoordinatorService.localBackupStateNotifier.value == LocalBackupState.failed) {
          SyncCoordinatorService.localBackupStateNotifier.value = LocalBackupState.idle;
        }
      });
      debugPrint('SyncCoordinatorService - Sauvegarde locale automatique échouée: $e');
    }
  }

  /// Applique les catégories reçues depuis le cloud Firebase
  Future<void> _handleCloudCategoriesChanged(List<CustomCategory> cloudCategories) async {
    _isSyncingCategories = true;
    try {
      debugPrint('SyncCoordinatorService - Application ${cloudCategories.length} catégories cloud');
      await _categoryService.applyFromCloud(cloudCategories);
      debugPrint('SyncCoordinatorService - Catégories cloud appliquées localement');
    } catch (e) {
      debugPrint('SyncCoordinatorService - Erreur application catégories cloud: $e');
    } finally {
      _isSyncingCategories = false;
    }
  }

  /// Déclenche l'upload des catégories locales vers Firebase lorsqu'elles changent
  Future<void> _onLocalCategoriesChanged() async {
    if (_isSyncingCategories) return;

    final syncEnabled = await _firebaseSyncService.isSyncEnabled();
    final isPremium = PremiumService().isPremium;
    final isSignedIn = _firebaseAuthService.isSignedIn;

    if (syncEnabled && isPremium && isSignedIn) {
      final categories = _categoryService.getAllCategories();
      _firebaseSyncService.syncCategoriesWithDebounce(List.from(categories));
      debugPrint('SyncCoordinatorService - Sync catégories planifiée (${categories.length} catégories)');
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _categoryService.removeListener(_onLocalCategoriesChanged);
    _authStateSubscription?.cancel();
    _premiumStatusSubscription?.cancel();
    _firebaseSyncService.dispose();
    _backupStateNotifier.dispose();
  }
}
