import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'crypto_service.dart';
import 'crypto_isolate.dart';
import 'secure_storage_service.dart';

/// Gère le déverrouillage via code secret ou biométrie.
/// Le code secret dérive une clé (PBKDF2) qui sert à déchiffrer le coffre Hive.
class AuthService {
  AuthService(this._secureStorage, {CryptoService? crypto})
      : _crypto = crypto ?? CryptoService();

  final SecureStorageService _secureStorage;
  final CryptoService _crypto;

  List<int>? _currentKey; // clé de session (non persistée)
  String? _currentSalt; // salt actuel pour cohérence biométrie
  int? _currentKeyIterations; // itérations PBKDF2 de la clé active

  /// True quand la biométrie était activée mais la clé wrapped en SecureStorage
  /// ne peut pas être déchiffrée (changement de plugin, perte de la clé Keystore,
  /// ou clé compromise détectée).
  /// Lu par l'UI pour afficher l'explication "ressaisissez votre mot de passe".
  bool _requiresBiometricMigration = false;
  bool get requiresBiometricMigration => _requiresBiometricMigration;
  void clearBiometricMigrationFlag() => _requiresBiometricMigration = false;

  List<int>? get currentKey => _currentKey;
  int? get currentKeyIterations => _currentKeyIterations;
  SecureStorageService get secureStorage => _secureStorage;

  /// Construit un token de validation v2 (mitigation L1).
  /// Remplace la valeur littérale `'VALIDATION_TOKEN'` par un vrai timestamp
  /// + nonce aléatoire. Pas d'expiration : un mot de passe correct ne doit
  /// jamais être rejeté pour cause d'âge du token.
  Map<String, dynamic> _buildValidationToken() {
    final rnd = Random.secure();
    final nonce = List<int>.generate(16, (_) => rnd.nextInt(256));
    return {
      'v': 2,
      'valid': true,
      'created': DateTime.now().millisecondsSinceEpoch,
      'nonce': base64Encode(nonce),
    };
  }

  /// Wipe explicite des octets de la clé en mémoire avant nullification.
  /// Mitigation M1 : sur device rooté, empêche la clé de subsister en RAM
  /// jusqu'au prochain GC.
  void _zeroizeAndClearKey() {
    final key = _currentKey;
    if (key != null) {
      for (var i = 0; i < key.length; i++) {
        key[i] = 0;
      }
    }
    _currentKey = null;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<bool> unlockWithMasterPassword(String password) async {
    _log('AuthService - unlockWithMasterPassword() appelé');

    // Lectures séquentielles : `flutter_secure_storage` sur Android utilise
    // un canal de plateforme unique, et des lectures concurrentes via
    // `Future.wait` peuvent renvoyer null à cause de conditions de course
    // avec le Keystore — ce qui déclenchait à tort la boucle de fallback
    // multi-itérations PBKDF2 (= temps de déverrouillage doublé).
    var saltB64 = await _secureStorage.readSalt();
    final preReadValidationToken = await _secureStorage.readValidationToken();
    final preReadStoredIterations = await _secureStorage.readKeyIterations();
    final bool isFirstTime = saltB64 == null;

    if (isFirstTime) {
      // Première connexion : créer un nouveau sel
      _log('AuthService - Première connexion: création du sel et du token de validation');
      saltB64 = _crypto.generateSaltBase64();
      await _secureStorage.saveSalt(saltB64);
      final salt = base64Decode(saltB64);

      // CORRECTION ANR: Dériver la clé dans un isolate séparé pour éviter de bloquer l'UI
      _currentKey = await deriveKeyInIsolate(
        password: password,
        salt: salt,
        iterations: CryptoService.defaultIterations,
      );
      _currentSalt = saltB64;
      _currentKeyIterations = CryptoService.defaultIterations;
      await _secureStorage.saveKeyIterations(_currentKeyIterations!);
      _log('AUTH_KEY_SRC master_password iterations=$_currentKeyIterations');

      // Créer un token de validation v2 chiffré avec la clé.
      // Ce token permet de valider le mot de passe même si le coffre est vide.
      final validationEncrypted = _crypto.encryptJson(_buildValidationToken(), _currentKey!);
      await _secureStorage.saveValidationToken(validationEncrypted);
      _log('AuthService - Token de validation v2 créé et sauvegardé');

      return true;
    } else {
      // Connexion existante : dériver la clé et VALIDER le mot de passe
      _log('AuthService - Connexion existante: validation du mot de passe');
      final salt = base64Decode(saltB64);
      
      // Vérifier que le mot de passe est correct en essayant de déchiffrer le token
      final validationToken = preReadValidationToken;
      if (validationToken == null) {
        _log('AuthService - Aucun token de validation trouvé (ancien compte), vérification coffre...');
        // Cas des anciens comptes créés avant cette fonctionnalité:
        // dériver la clé avec les itérations connues et créer le token.
        final iterations = preReadStoredIterations ?? CryptoService.defaultIterations;
        _currentKey = await deriveKeyInIsolate(
          password: password,
          salt: salt,
          iterations: iterations,
        );
        _currentSalt = saltB64;
        _currentKeyIterations = iterations;

        // Sécurité: si un coffre existe déjà, vérifier que la clé dérivée
        // le déchiffre avant de recréer un token de validation.
        final canValidateVault = await _canCreateValidationTokenForExistingVault(
          _currentKey!,
        );
        if (!canValidateVault) {
          _log('AuthService - Échec validation coffre existant: token non recréé');
          _zeroizeAndClearKey();
          _currentSalt = null;
          _currentKeyIterations = null;
          return false;
        }

        final validationEncrypted = _crypto.encryptJson(_buildValidationToken(), _currentKey!);
        await _secureStorage.saveValidationToken(validationEncrypted);
        await _secureStorage.saveKeyIterations(_currentKeyIterations!);
        _log('AUTH_KEY_SRC master_password iterations=$_currentKeyIterations');
        _log('AuthService - Token de validation v2 créé pour compte existant');
        return true;
      }
      
      final candidateIterations = <int>[];
      if (preReadStoredIterations != null) {
        candidateIterations.add(preReadStoredIterations);
      }
      if (!candidateIterations.contains(CryptoService.defaultIterations)) {
        candidateIterations.add(CryptoService.defaultIterations);
      }
      if (!candidateIterations.contains(150000)) {
        candidateIterations.add(150000);
      }
      _log('AUTH_ITER_CANDIDATES master_password ${candidateIterations.join(",")}');

      Object? lastError;
      for (final candidate in candidateIterations) {
        try {
          // CORRECTION ANR: Dériver la clé dans un isolate séparé pour éviter de bloquer l'UI
          final key = await deriveKeyInIsolate(
            password: password,
            salt: salt,
            iterations: candidate,
          );
          _crypto.decryptToJson(validationToken, key);

          _currentKey = key;
          _currentSalt = saltB64;
          _currentKeyIterations = candidate;
          await _secureStorage.saveKeyIterations(_currentKeyIterations!);
          _log('AUTH_KEY_SRC master_password iterations=$_currentKeyIterations');
          _log('AuthService - Token déchiffré avec succès: mot de passe correct');
          return true;
        } catch (e) {
          lastError = e;
          _log('AuthService - Validation token échouée pour iterations=$candidate');
        }
      }

      _log('AuthService - Échec déchiffrement du token: mot de passe INCORRECT');
      _log('AuthService - Erreur finale: $lastError');
      _zeroizeAndClearKey();
      _currentSalt = null;
      _currentKeyIterations = null;
      return false;
    }
  }

  Future<bool> unlockWithBiometrics({
    String promptTitle = 'PassKeyra',
    String promptSubtitle = '',
    String promptCancel = 'Annuler',
  }) async {
    _log('AuthService - unlockWithBiometrics() appelé');
    _requiresBiometricMigration = false;

    // Detecter le mode du blob stocke pour router vers le bon chemin.
    final mode = await _secureStorage.getWrappedKeyMode();

    // --- Chemin strong (Class 3) : le plugin gere le BiometricPrompt ---
    if (mode == 'strong') {
      try {
        final key = await _secureStorage.readHardwareWrappedSessionKeyStrong(
          promptTitle: promptTitle,
          promptSubtitle: promptSubtitle,
          promptCancel: promptCancel,
        );
        if (key != null) {
          _currentKey = key;
          _currentKeyIterations = await _secureStorage.readKeyIterations() ?? 150000;
          await _secureStorage.saveKeyIterations(_currentKeyIterations!);
          _log('AUTH_KEY_SRC biometrics strong_wrap iterations=$_currentKeyIterations');
          return true;
        }
      } on PlatformException catch (e) {
        if (e.code == 'KEY_INVALIDATED') {
          _log('AuthService - Cle strong invalidee (empreinte changee)');
          _requiresBiometricMigration = true;
          return false;
        }
        if (e.code == 'BIOMETRIC_ERROR') {
          _log('AuthService - BiometricPrompt annule/erreur: ${e.message}');
          return false;
        }
        _log('AuthService - Echec unwrap strong (${e.code}): ${e.message}');
        rethrow;
      }
    }

    // --- Chemin faible (Class 1/2) : local_auth a deja ete appele par l'UI ---
    try {
      final hardwareWrappedKey =
          await _secureStorage.readHardwareWrappedSessionKey();
      if (hardwareWrappedKey != null) {
        _currentKey = hardwareWrappedKey;
        _currentKeyIterations = await _secureStorage.readKeyIterations() ?? 150000;
        await _secureStorage.saveKeyIterations(_currentKeyIterations!);
        _log('AUTH_KEY_SRC biometrics hardware_wrap iterations=$_currentKeyIterations');
        return true;
      }
    } on PlatformException catch (e) {
      _log('AuthService - Echec unwrap hardware (${e.code}): ${e.message}');
    } catch (e) {
      _log('AuthService - Echec unwrap hardware, fallback legacy: $e');
    }

    // 2) Fallback REFUSE : la biométrie ne doit JAMAIS décoder une clé en clair.
    // L'ancien fallback (déchiffrement base64 direct sans BiometricPrompt) était
    // une faille de sécurité qui permettait l'unlock biométrique sans aucune
    // confirmation. On force désormais la migration via mot de passe maître.
    final wrapped = await _secureStorage.readWrappedKey();
    if (wrapped == null) {
      _log('AuthService - Aucune clé wrapped trouvée, échec biométrie');
      return false;
    }

    if (wrapped.startsWith('hw1:')) {
      // Clé hardware (hw1:) présente mais le plugin natif n'a pas pu la déchiffrer.
      // Causes possibles : changement de plugin Keystore (rare), perte de la clé
      // Keystore après wipe données, ou clé v2-C3 incompatible avec plugin v1.
      // → Migration via mot de passe maître requise.
      _log('AuthService - Clé hw1: présente mais unwrap échoué : migration biométrique requise');
      _requiresBiometricMigration = await _secureStorage.isBiometryEnabled();
      return false;
    }

    // Cas B : clé legacy plain (créée par l'ancien fallback silencieux Bug A
    // de storeWrappedKeyForBiometrics). C'est une faille héritée :
    // la clé est stockée en clair dans EncryptedSharedPreferences sans
    // protection biométrique. On REFUSE de l'utiliser et on la supprime.
    _log('AuthService - SECURITY : clé legacy plain détectée → suppression + migration');
    await _secureStorage.deleteWrappedKey();
    _requiresBiometricMigration = await _secureStorage.isBiometryEnabled();
    return false;
  }

  Future<void> storeWrappedKeyForBiometrics({
    String promptTitle = 'PassKeyra',
    String promptSubtitle = '',
    String promptCancel = 'Annuler',
  }) async {
    if (_currentKey == null) {
      throw Exception('Aucune clé de session disponible. Veuillez vous reconnecter.');
    }

    if (_currentSalt != null) {
      await _secureStorage.saveSalt(_currentSalt!);
    }

    final iterationsToStore = _currentKeyIterations ?? CryptoService.defaultIterations;
    await _secureStorage.saveKeyIterations(iterationsToStore);

    final canStrong = await _secureStorage.canUseStrongBiometric();

    if (canStrong) {
      // Class 3 : wrapping avec BiometricPrompt + CryptoObject cote plugin.
      await _secureStorage.saveHardwareWrappedSessionKeyStrong(
        _currentKey!,
        promptTitle: promptTitle,
        promptSubtitle: promptSubtitle,
        promptCancel: promptCancel,
      );
      await _secureStorage.setBiometricMode('strong');
      _log('AuthService - Cle biometrique stockee avec wrapping strong (Class 3)');
    } else {
      // Class 1/2 : wrapping sans auth Keystore (local_auth cote UI).
      await _secureStorage.saveHardwareWrappedSessionKey(_currentKey!);
      await _secureStorage.setBiometricMode('weak');
      _log('AuthService - Cle biometrique stockee avec wrapping weak (Class 1/2)');
    }

    await _secureStorage.setBiometryEnabled(true);
  }
  
  /// Cleanup de sécurité au démarrage : détecte les clés legacy plain laissées
  /// par l'ancien fallback silencieux de `storeWrappedKeyForBiometrics()` et
  /// les supprime. Ces clés étaient stockées en clair dans EncryptedSharedPreferences
  /// sans protection biométrique, permettant un unlock biométrique sans aucune
  /// confirmation. Cette méthode force le user à ressaisir son master password
  /// pour re-wrap proprement via le plugin natif.
  Future<void> cleanupCompromisedLegacyWrap() async {
    final isBiometryEnabled = await _secureStorage.isBiometryEnabled();
    if (!isBiometryEnabled) return;

    final wrapped = await _secureStorage.readWrappedKey();
    if (wrapped == null) return;
    if (wrapped.startsWith('hw1:') || wrapped.startsWith('hw2:')) return;

    // Clé legacy plain détectée alors que biométrie est marquée enabled
    // → état hérité du Bug A (catch silencieux). Suppression + désactivation.
    _log('AuthService - SECURITY CLEANUP : clé legacy plain supprimée, biométrie désactivée');
    await _secureStorage.deleteWrappedKey();
    await _secureStorage.setBiometryEnabled(false);
  }

  /// Migration opportuniste v1/weak -> v2-strong.
  /// Appelee apres un login MDP maitre reussi si l'appareil est Class 3
  /// et que le blob actuel n'est pas encore en mode strong.
  /// Non-fatale : si le wrap echoue, l'ancien blob reste valide.
  Future<bool> opportunisticStrongMigration({
    required String promptTitle,
    required String promptSubtitle,
    required String promptCancel,
  }) async {
    if (_currentKey == null) return false;

    final canStrong = await _secureStorage.canUseStrongBiometric();
    if (!canStrong) return false;

    final currentMode = await _secureStorage.getWrappedKeyMode();
    if (currentMode == 'strong') return false;

    final biometryEnabled = await _secureStorage.isBiometryEnabled();
    if (!biometryEnabled) return false;

    try {
      await _secureStorage.saveHardwareWrappedSessionKeyStrong(
        _currentKey!,
        promptTitle: promptTitle,
        promptSubtitle: promptSubtitle,
        promptCancel: promptCancel,
      );
      await _secureStorage.setBiometricMode('strong');
      _log('AuthService - Migration opportuniste vers strong reussie');
      return true;
    } catch (e) {
      _log('AuthService - Migration opportuniste echouee (non-fatal): $e');
      return false;
    }
  }

  /// Force la création d'un nouveau token de validation avec la clé actuelle
  /// Utilisé lors de la restauration/import pour forcer la mise à jour du token
  Future<void> forceCreateValidationToken() async {
    if (_currentKey == null) {
      throw Exception('Aucune clé de session disponible pour créer le token de validation');
    }
    
    _log('AuthService - Force la création d\'un nouveau token de validation v2');
    final validationEncrypted = _crypto.encryptJson(_buildValidationToken(), _currentKey!);
    await _secureStorage.saveValidationToken(validationEncrypted);
    _log('AuthService - Token de validation v2 créé avec succès');
  }
  
  /// Définit manuellement la clé de session (pour restauration/import)
  /// Permet de forcer l'utilisation d'une clé spécifique sans validation
  void setManualKey(List<int> key, String saltBase64, {int? iterations}) {
    _log('AuthService - Définition manuelle de la clé de session (restauration)');
    _currentKey = key;
    _currentSalt = saltBase64;
    _currentKeyIterations = iterations ?? _currentKeyIterations ?? CryptoService.defaultIterations;
  }
  
  /// Change le code secret et retourne la nouvelle clé dérivée
  /// Pour rechiffrer le coffre avec cette nouvelle clé
  Future<List<int>> changeMasterPassword(String oldPassword, String newPassword) async {
    // 1. Vérifier que l'ancien mot de passe est correct
    final saltB64 = await _secureStorage.readSalt();
    if (saltB64 == null) {
      throw Exception('Aucun code secret configuré');
    }

    final salt = base64Decode(saltB64);

    // CORRECTION ANR: Dériver la clé dans un isolate séparé
    final oldIterations = _currentKeyIterations ?? CryptoService.defaultIterations;
    final oldKey = await deriveKeyInIsolate(
      password: oldPassword,
      salt: salt,
      iterations: oldIterations,
    );

    // Vérifier que la clé actuelle correspond (si elle existe).
    // Comparaison timing-safe pour éviter les attaques par mesure de temps.
    if (_currentKey != null && !constantTimeEquals(oldKey, _currentKey!)) {
      throw Exception('Le mot de passe actuel est incorrect');
    }

    // 2. Générer un nouveau sel et dériver une nouvelle clé
    final newSaltB64 = _crypto.generateSaltBase64();
    final newSalt = base64Decode(newSaltB64);

    // CORRECTION ANR: Dériver la clé dans un isolate séparé
    final newKey = await deriveKeyInIsolate(
      password: newPassword,
      salt: newSalt,
      iterations: CryptoService.defaultIterations,
    );
    
    // 3. Sauvegarder le nouveau sel
    await _secureStorage.saveSalt(newSaltB64);
    
    // 4. Mettre à jour la clé courante
    _currentKey = newKey;
    _currentKeyIterations = CryptoService.defaultIterations;
    await _secureStorage.saveKeyIterations(_currentKeyIterations!);
    
    // 5. Mettre à jour le token de validation v2 avec la nouvelle clé
    final validationEncrypted = _crypto.encryptJson(_buildValidationToken(), newKey);
    await _secureStorage.saveValidationToken(validationEncrypted);
    _log('AuthService - Token de validation v2 mis à jour avec la nouvelle clé');
    
    // 6. Mettre a jour la cle biometrique si elle existe.
    // On re-wrap en mode faible (pas de BiometricPrompt surprise pendant un
    // changement de MDP). Le re-upgrade strong se fera automatiquement au
    // prochain login MDP sur un appareil Class 3.
    final biometryEnabled = await _secureStorage.isBiometryEnabled();
    if (biometryEnabled) {
      try {
        await _secureStorage.saveHardwareWrappedSessionKey(newKey);
        await _secureStorage.setBiometricMode('weak');
      } catch (e) {
        _log('AuthService - Echec re-wrap biometrique apres changement MDP: $e');
        await _secureStorage.setBiometryEnabled(false);
      }
    }
    
    // 7. Retourner l'ancienne clé pour permettre le rechiffrement
    return oldKey;
  }

  Future<bool> _canCreateValidationTokenForExistingVault(List<int> key) async {
    try {
      if (!Hive.isBoxOpen('vault_blob')) {
        await Hive.openBox<String>('vault_blob');
      }
      final box = Hive.box<String>('vault_blob');
      final payload = box.get('blob');
      if (payload == null) {
        return true;
      }
      _crypto.decryptToJson(payload, key);
      return true;
    } catch (e) {
      _log('AuthService - Validation coffre existant échouée: $e');
      return false;
    }
  }
}
