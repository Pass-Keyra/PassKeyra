import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/custom_category.dart';
import '../../models/password_entry.dart';
import '../../models/sync_state.dart';
import '../auth_service.dart';
import '../crypto_service.dart';
import '../premium_service.dart';
import '../secure_storage_service.dart';
import 'firebase_auth_service.dart';

/// Service de synchronisation Firebase pour PassKeyra
///
/// Implémente la synchronisation bidirectionnelle des entrées de mots de passe
/// entre le stockage local (Hive) et Cloud Firestore.
///
/// Architecture zero-knowledge :
/// - Les données sont chiffrées AVANT upload vers Firebase
/// - Firebase ne peut pas lire le contenu des mots de passe
/// - Clé de chiffrement dérivée du code secret utilisateur (PBKDF2)
///
/// Stratégie de résolution de conflits :
/// - Last-Write-Wins (LWW) basé sur updatedAt timestamp
/// - L'entrée la plus récente écrase la plus ancienne
class FirebaseSyncService {
  FirebaseSyncService({
    required AuthService authService,
    required FirebaseAuthService firebaseAuthService,
    FirebaseFirestore? firestore,
    CryptoService? cryptoService,
  })  : _authService = authService,
        _firebaseAuthService = firebaseAuthService,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _cryptoService = cryptoService ?? CryptoService();

  final AuthService _authService;
  final FirebaseAuthService _firebaseAuthService;
  final FirebaseFirestore _firestore;
  final CryptoService _cryptoService;
  final SecureStorageService _secureStorage = SecureStorageService();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  // Clés SharedPreferences (conservé uniquement pour _lastSyncKey et migration)
  static const String _syncEnabledKey = 'firebase_sync_enabled'; // LEGACY - migré vers SecureStorage
  static const String _lastSyncKey = 'firebase_last_sync';
  static const String _syncEnabledFileBackup = '.firebase_sync_enabled_backup'; // Fichier de sauvegarde local

  // StreamController pour broadcaster les changements de status
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _currentStatus = SyncStatus.initial;

  // Callback pour notifier le VaultRepository des changements cloud
  Function(List<PasswordEntry>)? onCloudEntriesChanged;

  // Callback pour notifier le VaultRepository des suppressions cloud
  Function(List<String>)? onCloudEntriesDeleted;

  // Callback pour notifier des changements de catégories cloud
  Function(List<CustomCategory>)? onCloudCategoriesChanged;

  // Listener Firestore pour le document catégories
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _categoriesListener;

  // Debounce pour les syncs de catégories
  Timer? _categoriesSyncDebounceTimer;

  // Indique qu'un upload de catégories vient d'être envoyé (évite la boucle listener)
  bool _categoriesUploadPending = false;

  // Debounce pour éviter les syncs trop fréquentes
  Timer? _syncDebounceTimer;
  static const _syncDebounceDuration = Duration(seconds: 3);

  // Queue pour les entrées en attente de sync
  final List<String> _pendingSyncEntryIds = [];

  /// Stream des changements de statut de synchronisation
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Statut actuel de la synchronisation
  SyncStatus get currentStatus => _currentStatus;

  /// Listener Firestore pour sync temps réel
  StreamSubscription<QuerySnapshot>? _firestoreListener;

  /// Collection Firestore des entrées pour l'utilisateur connecté
  CollectionReference<Map<String, dynamic>>? get _entriesCollection {
    final user = _firebaseAuthService.currentFirebaseUser;
    if (user == null) return null;

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('vault')
        .doc('data')
        .collection('entries');
  }

  /// Document Firestore des catégories pour l'utilisateur connecté
  DocumentReference<Map<String, dynamic>>? get _categoriesDocument {
    final user = _firebaseAuthService.currentFirebaseUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('vault')
        .doc('categories');
  }

  /// Document Firestore qui stocke l'empreinte (fingerprint) de la clé de
  /// session courante. Utilisé pour détecter qu'un autre appareil a changé
  /// le mot de passe maître : si le fingerprint cloud ≠ fingerprint local,
  /// l'utilisateur doit réimporter la dernière sauvegarde de l'appareil source.
  ///
  /// Le fingerprint est une valeur publique (HMAC tronqué) qui ne révèle rien
  /// sur la clé elle-même — zero-knowledge maintenu.
  DocumentReference<Map<String, dynamic>>? get _keyFingerprintDocument {
    final user = _firebaseAuthService.currentFirebaseUser;
    if (user == null) return null;
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('vault')
        .doc('key_fingerprint');
  }

  /// Retourne true si la synchronisation est activée
  ///
  /// STOCKAGE REDONDANT MULTI-COUCHES:
  /// Lit dans cet ordre de priorité pour garantir la persistance sur TOUS les appareils:
  /// 1. SecureStorage (EncryptedSharedPreferences) - Préféré
  /// 2. SharedPreferences normal - Fallback #1
  /// 3. Fichier local dans app directory - Fallback #2 (dernier recours)
  ///
  /// Si une valeur est trouvée dans un fallback, elle est restaurée dans toutes les couches
  Future<bool> isSyncEnabled() async {
    bool? value;
    String? source;

    // Couche 1: SecureStorage (préféré)
    try {
      value = await _secureStorage.isFirebaseSyncEnabled();
      if (value) {
        source = 'SecureStorage';
      }
    } catch (e) {
      _log('FirebaseSyncService - Erreur lecture SecureStorage: $e');
    }

    // Couche 2: SharedPreferences (fallback)
    if (value == null || !value) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final prefValue = prefs.getBool(_syncEnabledKey);
        if (prefValue != null && prefValue) {
          value = true;
          source = 'SharedPreferences';
        }
      } catch (e) {
        _log('FirebaseSyncService - Erreur lecture SharedPreferences: $e');
      }
    }

    // Couche 3: Fichier local (dernier recours)
    if (value == null || !value) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$_syncEnabledFileBackup');
        if (await file.exists()) {
          final content = await file.readAsString();
          if (content.trim() == '1') {
            value = true;
            source = 'FileBackup';
          }
        }
      } catch (e) {
        _log('FirebaseSyncService - Erreur lecture fichier backup: $e');
      }
    }

    final finalValue = value ?? false;

    // Si trouvé dans un fallback, restaurer dans toutes les couches
    if (finalValue && source != 'SecureStorage') {
      _log('FirebaseSyncService - RESTAURATION détectée depuis $source - reconstruction redondance');
      await _setSyncEnabledRedundant(true);
    }

    _log('FirebaseSyncService - isSyncEnabled() = $finalValue (source: ${source ?? 'default'})');
    return finalValue;
  }

  /// Écrit l'état de synchronisation dans TOUTES les couches de stockage (redondance)
  ///
  /// Garantit la persistance sur tous les appareils Android (notamment Pixel avec Battery Optimization)
  /// en écrivant dans 3 emplacements indépendants
  Future<void> _setSyncEnabledRedundant(bool enabled) async {
    final value = enabled ? '1' : '0';
    int successCount = 0;

    // Couche 1: SecureStorage
    try {
      await _secureStorage.setFirebaseSyncEnabled(enabled);
      successCount++;
      _log('FirebaseSyncService - SecureStorage écrit');
    } catch (e) {
      _log('FirebaseSyncService - Erreur écriture SecureStorage: $e');
    }

    // Couche 2: SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_syncEnabledKey, enabled);
      successCount++;
      _log('FirebaseSyncService - SharedPreferences écrit');
    } catch (e) {
      _log('FirebaseSyncService - Erreur écriture SharedPreferences: $e');
    }

    // Couche 3: Fichier local (dernier recours)
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_syncEnabledFileBackup');
      await file.writeAsString(value);
      successCount++;
      _log('FirebaseSyncService - FileBackup écrit');
    } catch (e) {
      _log('FirebaseSyncService - Erreur écriture fichier backup: $e');
    }

    _log('FirebaseSyncService - Stockage redondant: $successCount/3 couches écrites avec succès');

    if (successCount == 0) {
      throw Exception('ÉCHEC: Impossible d\'écrire dans AUCUNE couche de stockage');
    }
  }

  /// Active ou désactive la synchronisation
  ///
  /// STOCKAGE REDONDANT: Sauvegarde l'état dans 3 couches indépendantes
  /// pour garantir la persistance même si Android efface une ou deux couches
  Future<void> setSyncEnabled(bool enabled) async {
    // Sauvegarder dans TOUTES les couches (redondance triple)
    await _setSyncEnabledRedundant(enabled);

    if (enabled) {
      // Démarrer l'écoute des changements Firestore
      await _startRealtimeListener();
    } else {
      // Arrêter l'écoute
      await _stopRealtimeListener();
    }

    // Émettre un statut mis à jour avec le nouveau état d'activation
    await _updateStatus(_currentStatus.copyWith(
      state: enabled ? SyncState.idle : SyncState.idle,
    ));

    _log('FirebaseSyncService - Sync ${enabled ? "activée" : "désactivée"}');
  }

  /// Retourne la date de la dernière synchronisation réussie
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Sauvegarde la date de dernière synchronisation
  Future<void> _saveLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Met à jour le statut de synchronisation et notifie les listeners
  Future<void> _updateStatus(SyncStatus status) async {
    final enabled = await isSyncEnabled();
    final statusWithEnabled = status.copyWith(isEnabled: enabled);
    _currentStatus = statusWithEnabled;
    _syncStatusController.add(statusWithEnabled);
  }

  /// Initialise le statut de synchronisation avec les valeurs actuelles
  ///
  /// Cette méthode doit être appelée au démarrage pour que le statut initial
  /// reflète correctement l'état de la synchronisation (activée/désactivée).
  ///
  /// MIGRATION AUTOMATIQUE: Migre les données vers le système de stockage redondant triple couche
  /// pour garantir la persistance sur tous les appareils Android (notamment Pixel)
  Future<void> initializeStatus() async {
    _log('=========================================================');
    _log('FirebaseSyncService - DÉBUT initializeStatus()');
    _log('=========================================================');

    // MIGRATION: Vérifier si une valeur existe dans l'ancien système (SharedPreferences uniquement)
    // et la migrer vers le nouveau système redondant (3 couches)
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyValue = prefs.getBool(_syncEnabledKey);
      _log('FirebaseSyncService - Valeur legacy SharedPreferences: $legacyValue');

      // Vérifier si SecureStorage a déjà la valeur
      bool hasSecureValue = false;
      try {
        hasSecureValue = await _secureStorage.isFirebaseSyncEnabled();
        _log('FirebaseSyncService - Valeur dans SecureStorage: $hasSecureValue');
      } catch (e) {
        _log('FirebaseSyncService - Pas de valeur dans SecureStorage: $e');
      }

      if (legacyValue != null && !hasSecureValue) {
        // Migration détectée - transférer vers système redondant
        _log('FirebaseSyncService - MIGRATION détectée: SharedPreferences seul → Stockage redondant triple couche');
        await _setSyncEnabledRedundant(legacyValue);
        _log('FirebaseSyncService - Migration terminée (valeur: $legacyValue)');
      }
    } catch (e) {
      _log('FirebaseSyncService - Erreur migration (non critique): $e');
    }

    // Charger l'état depuis le système redondant (auto-restauration si une couche manque)
    _log('FirebaseSyncService - Appel isSyncEnabled()...');
    final enabled = await isSyncEnabled();
    _log('FirebaseSyncService - Résultat isSyncEnabled() = $enabled');

    // Vérifier l'état de l'authentification Firebase
    final isSignedIn = _firebaseAuthService.isSignedIn;
    final currentUser = _firebaseAuthService.currentFirebaseUser;
    _log('FirebaseSyncService - État Firebase Auth:');
    _log('  - isSignedIn: $isSignedIn');
    _log('  - currentUser: ${currentUser?.email ?? "null"}');
    _log('  - currentUser.uid: ${currentUser?.uid ?? "null"}');

    _currentStatus = SyncStatus.initial.copyWith(isEnabled: enabled);
    _syncStatusController.add(_currentStatus);

    _log('FirebaseSyncService - Statut émis (isEnabled: $enabled)');

    // Si la sync est activée, démarrer le listener
    if (enabled) {
      // FIX FAILLE PREMIUM : exiger isPremium en plus de isSignedIn pour
      // éviter que le listener reste actif après revoke du Premium.
      final isPremium = PremiumService().isPremium;
      if (isSignedIn && isPremium) {
        _log('FirebaseSyncService - Conditions réunies: démarrage du listener Firestore');
        await _startRealtimeListener();
        _log('FirebaseSyncService - Listener Firestore démarré avec succès');
      } else if (!isPremium) {
        _log('FirebaseSyncService - Sync activée localement mais user NON-Premium → listener bloqué');
      } else {
        _log('FirebaseSyncService - PROBLÈME: Sync activée mais utilisateur NON connecté !');
        _log('FirebaseSyncService - Listener Firestore NON démarré');
      }
    } else {
      _log('FirebaseSyncService - Sync désactivée, listener non démarré');
    }

    _log('=========================================================');
    _log('FirebaseSyncService - FIN initializeStatus()');
    _log('=========================================================');
  }

  /// Upload une entrée chiffrée vers Firestore
  ///
  /// Les données sont chiffrées avec la clé de session de l'utilisateur
  /// avant d'être envoyées à Firebase (zero-knowledge)
  Future<void> uploadEntry(PasswordEntry entry) async {
    try {
      final collection = _entriesCollection;
      if (collection == null) {
        throw Exception('Aucun utilisateur Firebase connecté');
      }

      final encryptionKey = _authService.currentKey;
      if (encryptionKey == null) {
        throw Exception('Aucune clé de chiffrement disponible');
      }

      // Marquer cet ID comme en cours de sync (éviter les boucles)
      _pendingSyncEntryIds.add(entry.id);

      // Chiffrer l'entrée complète
      final entryJson = entry.toJson();
      final encryptedData = _cryptoService.encryptJson(entryJson, encryptionKey);

      // Préparer le document Firestore
      final docData = {
        'encryptedData': encryptedData,
        'lastModified': FieldValue.serverTimestamp(),
        'version': 1,
        'deleted': false,
      };

      // Upload vers Firestore (upsert)
      await collection.doc(entry.id).set(docData, SetOptions(merge: true));

      _log('FirebaseSyncService - Entrée uploadée: ${entry.id}');
    } catch (e) {
      // Retirer de la queue en cas d'erreur
      _pendingSyncEntryIds.remove(entry.id);
      _log('FirebaseSyncService - Erreur upload: $e');
      rethrow;
    }
  }

  /// Upload plusieurs entrées vers Firestore en batch
  ///
  /// Plus performant que uploadEntry() en boucle pour sync initiale
  Future<void> uploadEntries(List<PasswordEntry> entries) async {
    try {
      _updateStatus(_currentStatus.copyWith(state: SyncState.syncing));

      final collection = _entriesCollection;
      if (collection == null) {
        throw Exception('Aucun utilisateur Firebase connecté');
      }

      final encryptionKey = _authService.currentKey;
      if (encryptionKey == null) {
        throw Exception('Aucune clé de chiffrement disponible');
      }

      // Upload par batch de 500 (limite Firestore)
      final batch = _firestore.batch();
      int count = 0;

      // Collecter les IDs pour les marquer comme pending après le batch
      final uploadedIds = <String>[];

      for (final entry in entries) {
        uploadedIds.add(entry.id);

        // Chiffrer l'entrée
        final entryJson = entry.toJson();
        final encryptedData = _cryptoService.encryptJson(entryJson, encryptionKey);

        final docData = {
          'encryptedData': encryptedData,
          'lastModified': FieldValue.serverTimestamp(),
          'version': 1,
          'deleted': false,
        };

        batch.set(
          collection.doc(entry.id),
          docData,
          SetOptions(merge: true),
        );

        count++;

        // Firestore limite à 500 opérations par batch
        if (count >= 500) {
          await batch.commit();
          count = 0;
          _log('FirebaseSyncService - Batch de 500 entrées uploadé');
        }
      }

      // Commit le dernier batch
      if (count > 0) {
        await batch.commit();
        _log('FirebaseSyncService - Batch final de $count entrées uploadé');
      }

      // Marquer les IDs comme pending APRÈS le commit réussi
      // pour éviter que le listener ne réapplique nos propres changements
      _pendingSyncEntryIds.addAll(uploadedIds);
      _log('FirebaseSyncService - ${uploadedIds.length} IDs marqués comme pending');

      // Nettoyer automatiquement après 10 secondes (au cas où le listener ne les traite pas)
      Future.delayed(const Duration(seconds: 10), () {
        for (final id in uploadedIds) {
          _pendingSyncEntryIds.remove(id);
        }
        _log('FirebaseSyncService - Nettoyage automatique: ${uploadedIds.length} IDs retirés de pending');
      });

      await _saveLastSyncTime();
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.success,
        lastSync: DateTime.now(),
      ));

      _log('FirebaseSyncService - Upload complet: ${entries.length} entrées');
    } catch (e) {
      _log('FirebaseSyncService - Erreur upload batch: $e');
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }

  /// Re-upload forcé de TOUTES les entrées avec la clé de chiffrement courante.
  ///
  /// Utilisé après un changement de mot de passe maître pour mettre à jour
  /// les données Firestore (qui restent chiffrées avec l'ancienne clé jusqu'à
  /// ré-upload explicite). Appelle [onProgress] après chaque chunk pour
  /// permettre à l'UI d'afficher une barre de progression.
  ///
  /// No-op silencieuse si l'utilisateur n'est pas authentifié Firebase ou si
  /// la sync n'est pas activée — dans ces cas, il n'y a rien à mettre à jour
  /// côté cloud.
  Future<void> forceReuploadAll(
    List<PasswordEntry> entries, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (entries.isEmpty) {
      onProgress?.call(0, 0);
      return;
    }
    final collection = _entriesCollection;
    if (collection == null) {
      _log('FirebaseSyncService.forceReuploadAll - utilisateur non connecté, skip');
      onProgress?.call(entries.length, entries.length);
      return;
    }
    final encryptionKey = _authService.currentKey;
    if (encryptionKey == null) {
      _log('FirebaseSyncService.forceReuploadAll - clé absente, skip');
      onProgress?.call(entries.length, entries.length);
      return;
    }

    _updateStatus(_currentStatus.copyWith(state: SyncState.syncing));

    const chunkSize = 50;
    final total = entries.length;
    int done = 0;
    final uploadedIds = <String>[];

    onProgress?.call(0, total);

    try {
      for (var i = 0; i < total; i += chunkSize) {
        final end = (i + chunkSize < total) ? i + chunkSize : total;
        final chunk = entries.sublist(i, end);
        final batch = _firestore.batch();
        for (final entry in chunk) {
          uploadedIds.add(entry.id);
          final encryptedData = _cryptoService.encryptJson(entry.toJson(), encryptionKey);
          batch.set(
            collection.doc(entry.id),
            {
              'encryptedData': encryptedData,
              'lastModified': FieldValue.serverTimestamp(),
              'version': 1,
              'deleted': false,
            },
            SetOptions(merge: true),
          );
        }
        await batch.commit();
        done = end;
        onProgress?.call(done, total);
        _log('FirebaseSyncService.forceReuploadAll - chunk $done/$total OK');
      }

      // Marquer les IDs comme pending (évite que le listener réapplique
      // nos propres changements). Nettoyage auto après 10s.
      _pendingSyncEntryIds.addAll(uploadedIds);
      Future.delayed(const Duration(seconds: 10), () {
        for (final id in uploadedIds) {
          _pendingSyncEntryIds.remove(id);
        }
      });

      await _saveLastSyncTime();
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.success,
        lastSync: DateTime.now(),
      ));
      _log('FirebaseSyncService.forceReuploadAll - $total entrées re-chiffrées et envoyées');
    } catch (e) {
      _log('FirebaseSyncService.forceReuploadAll - erreur: $e');
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }

  /// Pousse le fingerprint de la clé de session courante dans Firestore.
  ///
  /// À appeler après chaque changement de mot de passe maître (ou à la 1re
  /// activation de la sync sur un device) pour que les autres appareils
  /// puissent détecter le changement. Le fingerprint est calculé via
  /// [CryptoService.keyFingerprint] — déterministe, one-way, ne révèle rien
  /// sur la clé (zero-knowledge maintenu).
  ///
  /// No-op silencieuse si pas d'utilisateur Firestore connecté ou pas de clé.
  Future<void> uploadKeyFingerprint() async {
    final doc = _keyFingerprintDocument;
    if (doc == null) return;
    final key = _authService.currentKey;
    if (key == null) return;
    try {
      final fingerprint = _cryptoService.keyFingerprint(key);
      await doc.set({
        'fingerprint': fingerprint,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _log('FirebaseSyncService - keyFingerprint uploadé');
    } catch (e) {
      _log('FirebaseSyncService - erreur uploadKeyFingerprint: $e');
    }
  }

  /// Lit le fingerprint de la clé stocké côté Firestore. Retourne null si
  /// pas de document, pas d'utilisateur connecté, ou erreur réseau.
  Future<String?> getCloudKeyFingerprint() async {
    final doc = _keyFingerprintDocument;
    if (doc == null) return null;
    try {
      final snapshot = await doc.get();
      if (!snapshot.exists) return null;
      return snapshot.data()?['fingerprint'] as String?;
    } catch (e) {
      _log('FirebaseSyncService - erreur getCloudKeyFingerprint: $e');
      return null;
    }
  }

  /// Calcule le fingerprint de la clé de session courante (local).
  /// Retourne null si pas de clé active.
  String? computeLocalKeyFingerprint() {
    final key = _authService.currentKey;
    if (key == null) return null;
    return _cryptoService.keyFingerprint(key);
  }

  /// Télécharge une entrée depuis Firestore
  ///
  /// Déchiffre les données avec la clé de session de l'utilisateur
  Future<PasswordEntry?> downloadEntry(String entryId) async {
    try {
      final collection = _entriesCollection;
      if (collection == null) {
        throw Exception('Aucun utilisateur Firebase connecté');
      }

      final encryptionKey = _authService.currentKey;
      if (encryptionKey == null) {
        throw Exception('Aucune clé de chiffrement disponible');
      }

      final doc = await collection.doc(entryId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // Vérifier si l'entrée est marquée comme supprimée
      if (data['deleted'] == true) return null;

      // Déchiffrer les données
      final encryptedData = data['encryptedData'] as String;
      final decryptedJson = _cryptoService.decryptToJson(
        encryptedData,
        encryptionKey,
      );

      return PasswordEntry.fromJson(decryptedJson);
    } catch (e) {
      _log('FirebaseSyncService - Erreur download: $e');
      rethrow;
    }
  }

  /// Télécharge toutes les entrées depuis Firestore
  ///
  /// Utilisé pour la synchronisation initiale ou refresh complet
  Future<List<PasswordEntry>> downloadAllEntries() async {
    try {
      _updateStatus(_currentStatus.copyWith(state: SyncState.syncing));

      final collection = _entriesCollection;
      if (collection == null) {
        throw Exception('Aucun utilisateur Firebase connecté');
      }

      final encryptionKey = _authService.currentKey;
      if (encryptionKey == null) {
        throw Exception('Aucune clé de chiffrement disponible');
      }

      final querySnapshot = await collection
          .where('deleted', isEqualTo: false)
          .get();

      final entries = <PasswordEntry>[];

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final encryptedData = data['encryptedData'] as String;
          final decryptedJson = _cryptoService.decryptToJson(
            encryptedData,
            encryptionKey,
          );

          entries.add(PasswordEntry.fromJson(decryptedJson));
        } catch (e) {
          _log('FirebaseSyncService - Erreur déchiffrement entrée ${doc.id}: $e');
          // Continue avec les autres entrées
        }
      }

      await _saveLastSyncTime();
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.success,
        lastSync: DateTime.now(),
      ));

      _log('FirebaseSyncService - Download complet: ${entries.length} entrées');
      return entries;
    } catch (e) {
      _log('FirebaseSyncService - Erreur download all: $e');
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }

  /// Force une synchronisation immédiate depuis le cloud
  ///
  /// Récupère toutes les entrées (actives et supprimées) depuis Firestore
  /// et déclenche les callbacks pour merger avec le local
  Future<void> forceSyncFromCloud() async {
    try {
      _log('FirebaseSyncService - Force sync depuis le cloud...');
      _updateStatus(_currentStatus.copyWith(state: SyncState.syncing));

      final collection = _entriesCollection;
      if (collection == null) {
        throw Exception('Aucun utilisateur Firebase connecté');
      }

      final encryptionKey = _authService.currentKey;
      if (encryptionKey == null) {
        throw Exception('Aucune clé de chiffrement disponible');
      }

      // Récupérer TOUS les documents (incluant deleted: true)
      final querySnapshot = await collection.get();

      final activeEntries = <PasswordEntry>[];
      final deletedEntryIds = <String>[];

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final isDeleted = data['deleted'] == true;

          if (isDeleted) {
            // Entrée supprimée
            deletedEntryIds.add(doc.id);
          } else {
            // Entrée active - déchiffrer
            final encryptedData = data['encryptedData'] as String;
            final decryptedJson = _cryptoService.decryptToJson(
              encryptedData,
              encryptionKey,
            );
            activeEntries.add(PasswordEntry.fromJson(decryptedJson));
          }
        } catch (e) {
          _log('FirebaseSyncService - Erreur traitement entrée ${doc.id}: $e');
          // Continue avec les autres entrées
        }
      }

      // Notifier les suppressions d'abord
      if (deletedEntryIds.isNotEmpty && onCloudEntriesDeleted != null) {
        onCloudEntriesDeleted!(deletedEntryIds);
        _log('FirebaseSyncService - Force sync: ${deletedEntryIds.length} suppressions détectées');
      }

      // Puis notifier les entrées actives
      if (activeEntries.isNotEmpty && onCloudEntriesChanged != null) {
        onCloudEntriesChanged!(activeEntries);
        _log('FirebaseSyncService - Force sync: ${activeEntries.length} entrées actives détectées');
      }

      // Télécharger et notifier les catégories
      final cloudCategories = await downloadCategories();
      if (cloudCategories.isNotEmpty) {
        onCloudCategoriesChanged?.call(cloudCategories);
        _log('FirebaseSyncService - Force sync: ${cloudCategories.length} catégories cloud notifiées');
      }

      await _saveLastSyncTime();
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.success,
        lastSync: DateTime.now(),
      ));

      _log('FirebaseSyncService - Force sync terminée avec succès');
    } catch (e) {
      _log('FirebaseSyncService - Erreur force sync: $e');
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }

  /// Supprime une entrée sur Firestore (soft delete)
  ///
  /// Marque l'entrée comme supprimée sans la supprimer physiquement
  /// Permet d'éviter la recréation par sync bidirectionnelle
  Future<void> deleteEntry(String entryId) async {
    try {
      final collection = _entriesCollection;
      if (collection == null) {
        throw Exception('Aucun utilisateur Firebase connecté');
      }

      await collection.doc(entryId).update({
        'deleted': true,
        'lastModified': FieldValue.serverTimestamp(),
      });

      _log('FirebaseSyncService - Entrée supprimée: $entryId');
    } catch (e) {
      _log('FirebaseSyncService - Erreur suppression: $e');
      rethrow;
    }
  }

  /// Démarre une synchronisation avec debounce
  ///
  /// Attend 3 secondes avant de lancer la sync pour éviter les syncs trop fréquentes
  void syncWithDebounce(List<PasswordEntry> entries) {
    // Annuler le timer précédent si existant
    _syncDebounceTimer?.cancel();

    // Créer un nouveau timer
    _syncDebounceTimer = Timer(_syncDebounceDuration, () async {
      try {
        await uploadEntries(entries);
      } catch (e) {
        _log('FirebaseSyncService - Erreur sync automatique: $e');
      }
    });

    _log('FirebaseSyncService - Sync planifiée dans ${_syncDebounceDuration.inSeconds} secondes');
  }

  /// Démarre l'écoute temps réel des changements Firestore
  ///
  /// Permet de recevoir automatiquement les modifications faites
  /// depuis un autre appareil et les merge avec le vault local
  Future<void> _startRealtimeListener() async {
    try {
      final collection = _entriesCollection;
      if (collection == null) return;

      // Arrêter le listener précédent si existant
      await _stopRealtimeListener();

      _firestoreListener = collection
          .snapshots()
          .listen(
        (snapshot) async {
          // FIX FAILLE PREMIUM (defense-in-depth) : si une race fait que le
          // listener reste attaché après revoke Premium, on ignore les snapshots.
          if (!PremiumService().isPremium) {
            _log('FirebaseSyncService - Snapshot reçu mais user NON-Premium → ignoré');
            return;
          }

          _log('FirebaseSyncService - Changement détecté: ${snapshot.docChanges.length} modifications');

          // Liste des entrées cloud modifiées/ajoutées
          final cloudChanges = <PasswordEntry>[];
          // Liste des IDs des entrées supprimées
          final cloudDeletions = <String>[];

          for (final change in snapshot.docChanges) {
            try {
              // Ignorer les changements que nous avons nous-mêmes créés
              if (_pendingSyncEntryIds.contains(change.doc.id)) {
                _log('  - Ignoré (sync locale): ${change.doc.id}');
                _pendingSyncEntryIds.remove(change.doc.id);
                continue;
              }

              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                // Déchiffrer l'entrée cloud
                final data = change.doc.data();
                if (data == null) continue;

                // Vérifier si l'entrée est marquée comme supprimée
                final isDeleted = data['deleted'] == true;
                if (isDeleted) {
                  // C'est une suppression (document marqué deleted: true)
                  cloudDeletions.add(change.doc.id);
                  _log('  - Suppression détectée: ${change.doc.id}');
                  continue;
                }

                final encryptedData = data['encryptedData'] as String;
                final encryptionKey = _authService.currentKey;
                if (encryptionKey == null) continue;

                final decryptedJson = _cryptoService.decryptToJson(
                  encryptedData,
                  encryptionKey,
                );

                final cloudEntry = PasswordEntry.fromJson(decryptedJson);
                cloudChanges.add(cloudEntry);

                _log('  - ${change.type.name}: ${cloudEntry.name} (${cloudEntry.id})');
              } else if (change.type == DocumentChangeType.removed) {
                // Hard delete (document complètement supprimé de Firestore)
                cloudDeletions.add(change.doc.id);
                _log('  - Hard delete détecté: ${change.doc.id}');
              }
            } catch (e) {
              _log('  - Erreur traitement changement ${change.doc.id}: $e');
            }
          }

          // Notifier les suppressions
          if (cloudDeletions.isNotEmpty && onCloudEntriesDeleted != null) {
            onCloudEntriesDeleted!(cloudDeletions);
            _log('FirebaseSyncService - ${cloudDeletions.length} suppressions cloud notifiées');
          }

          // Notifier les changements
          if (cloudChanges.isNotEmpty && onCloudEntriesChanged != null) {
            onCloudEntriesChanged!(cloudChanges);
            _log('FirebaseSyncService - ${cloudChanges.length} entrées cloud notifiées');
          }
        },
        onError: (error) {
          _log('FirebaseSyncService - Erreur listener: $error');
          _updateStatus(_currentStatus.copyWith(
            state: SyncState.error,
            errorMessage: error.toString(),
          ));
        },
      );

      _log('FirebaseSyncService - Listener entrées démarré');

      // Listener sur le document catégories
      final categoriesDoc = _categoriesDocument;
      if (categoriesDoc != null) {
        _categoriesListener = categoriesDoc.snapshots().listen(
          (snapshot) async {
            // FIX FAILLE PREMIUM (defense-in-depth) : ignorer les snapshots
            // catégories si le user n'est plus Premium.
            if (!PremiumService().isPremium) {
              _log('FirebaseSyncService - Snapshot catégories reçu mais user NON-Premium → ignoré');
              return;
            }

            if (!snapshot.exists) return;

            // Ignorer si c'est notre propre upload
            if (_categoriesUploadPending) {
              _categoriesUploadPending = false;
              _log('FirebaseSyncService - Changement catégories ignoré (sync locale)');
              return;
            }

            try {
              final data = snapshot.data();
              if (data == null || !data.containsKey('encryptedData')) return;
              final encryptionKey = _authService.currentKey;
              if (encryptionKey == null) return;

              final encryptedData = data['encryptedData'] as String;
              final decrypted = _cryptoService.decryptToJson(encryptedData, encryptionKey);
              final list = decrypted['categories'] as List<dynamic>?;
              if (list == null) return;

              final categories = list
                  .map((c) => CustomCategory.fromJson(c as Map<String, dynamic>))
                  .toList();

              onCloudCategoriesChanged?.call(categories);
              _log('FirebaseSyncService - ${categories.length} catégories cloud reçues');
            } catch (e) {
              _log('FirebaseSyncService - Erreur traitement catégories cloud: $e');
            }
          },
          onError: (error) {
            _log('FirebaseSyncService - Erreur listener catégories: $error');
          },
        );
        _log('FirebaseSyncService - Listener catégories démarré');
      }
    } catch (e) {
      _log('FirebaseSyncService - Erreur démarrage listener: $e');
    }
  }

  /// Arrête l'écoute temps réel (entrées et catégories)
  Future<void> _stopRealtimeListener() async {
    await _firestoreListener?.cancel();
    _firestoreListener = null;
    await _categoriesListener?.cancel();
    _categoriesListener = null;
    _log('FirebaseSyncService - Listener temps réel arrêté');
  }

  /// Upload la liste complète des catégories chiffrées vers Firestore
  Future<void> uploadCategories(List<CustomCategory> categories) async {
    try {
      final doc = _categoriesDocument;
      if (doc == null) throw Exception('Aucun utilisateur Firebase connecté');
      final encryptionKey = _authService.currentKey;
      if (encryptionKey == null) throw Exception('Aucune clé de chiffrement disponible');

      final payload = {'categories': categories.map((c) => c.toJson()).toList()};
      final encryptedData = _cryptoService.encryptJson(payload, encryptionKey);

      _categoriesUploadPending = true;
      await doc.set({
        'encryptedData': encryptedData,
        'lastModified': FieldValue.serverTimestamp(),
        'version': 1,
      });

      // Libérer le flag après un délai (au cas où le listener ne se déclenche pas)
      Future.delayed(const Duration(seconds: 10), () {
        _categoriesUploadPending = false;
      });

      _log('FirebaseSyncService - ${categories.length} catégories uploadées');
    } catch (e) {
      _categoriesUploadPending = false;
      _log('FirebaseSyncService - Erreur upload catégories: $e');
      rethrow;
    }
  }

  /// Télécharge et déchiffre les catégories depuis Firestore
  Future<List<CustomCategory>> downloadCategories() async {
    try {
      final doc = _categoriesDocument;
      if (doc == null) return [];
      final encryptionKey = _authService.currentKey;
      if (encryptionKey == null) return [];

      final snapshot = await doc.get();
      if (!snapshot.exists) return [];
      final data = snapshot.data();
      if (data == null || !data.containsKey('encryptedData')) return [];

      final encryptedData = data['encryptedData'] as String;
      final decrypted = _cryptoService.decryptToJson(encryptedData, encryptionKey);
      final list = decrypted['categories'] as List<dynamic>?;
      if (list == null) return [];

      return list
          .map((c) => CustomCategory.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log('FirebaseSyncService - Erreur download catégories: $e');
      return [];
    }
  }

  /// Planifie un upload des catégories avec debounce (3 secondes)
  void syncCategoriesWithDebounce(List<CustomCategory> categories) {
    _categoriesSyncDebounceTimer?.cancel();
    _categoriesSyncDebounceTimer = Timer(_syncDebounceDuration, () async {
      try {
        await uploadCategories(categories);
      } catch (e) {
        _log('FirebaseSyncService - Erreur sync catégories automatique: $e');
      }
    });
    _log('FirebaseSyncService - Sync catégories planifiée dans ${_syncDebounceDuration.inSeconds}s');
  }

  /// Nettoie les ressources (à appeler lors de la destruction du service)
  void dispose() {
    _syncDebounceTimer?.cancel();
    _categoriesSyncDebounceTimer?.cancel();
    _stopRealtimeListener();
    _syncStatusController.close();
  }
}

