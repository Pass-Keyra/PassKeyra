import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage sécurisé pour la clé dérivée et préférences sensibles.
class SecureStorageService {
  static const MethodChannel _biometricKeywrapChannel = MethodChannel(
    'biometric_keywrap',
  );
  static const String _hardwareWrapPrefix = 'hw1:';

  // Options Android.
  // - encryptedSharedPreferences = true : EncryptedSharedPreferences (AES-GCM)
  // - resetOnError = false : (mitigation M3) ne PAS nuker silencieusement tout le
  //   store en cas d'erreur globale. La gestion par-clé est faite par _safeRead()
  //   qui supprime uniquement la clé corrompue (BAD_DECRYPT/BadPaddingException).
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: false,
    ),
  );

  static const String _kMasterKeySalt = 'master_key_salt';
  static const String _kWrappedMasterKey = 'wrapped_master_key';
  static const String _kMasterKeyIterations = 'master_key_iterations';
  static const String _kBiometryEnabled = 'biometry_enabled';
  static const String _kValidationToken = 'validation_token'; // Token pour valider le mot de passe

  // Clés pour Cloud Backup
  static const String _kGoogleDriveEmail = 'google_drive_email'; // Email du compte Google authentifié
  static const String _kDropboxToken = 'dropbox_access_token'; // Token OAuth Dropbox
  static const String _kOneDriveToken = 'onedrive_access_token'; // Token OAuth OneDrive
  static const String _kOneDriveEmail = 'onedrive_email'; // Email du compte OneDrive authentifié

  // Clés pour Firebase Sync
  static const String _kFirebaseSyncEnabled = 'firebase_sync_enabled'; // État de la synchronisation Firebase (plus persistant que SharedPreferences)

  Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e) {
      final message = e.message ?? '';
      final isBadDecrypt =
          message.contains('BAD_DECRYPT') || message.contains('BadPaddingException');

      if (isBadDecrypt) {
        debugPrint('SecureStorage - Donnée corrompue pour "$key". Suppression...');
        await _storage.delete(key: key);
        return null;
      }

      debugPrint('SecureStorage - Erreur inattendue sur "$key" : ${e.message}');
      rethrow;
    }
  }

  Future<void> saveSalt(String saltBase64) async {
    await _storage.write(key: _kMasterKeySalt, value: saltBase64);
  }

  Future<String?> readSalt() => _safeRead(_kMasterKeySalt);

  Future<void> saveWrappedKey(String wrappedBase64) async {
    await _storage.write(key: _kWrappedMasterKey, value: wrappedBase64);
  }

  Future<String?> readWrappedKey() => _safeRead(_kWrappedMasterKey);
  
  Future<void> deleteWrappedKey() async {
    await _storage.delete(key: _kWrappedMasterKey);
    await _clearHardwareWrappingKey();
  }

  /// Stocke la clé de session enveloppée via le Keystore matériel.
  /// L'authentification biométrique est faite côté UI via local_auth AVANT
  /// d'appeler cette méthode (le wrap lui-même ne déclenche pas de prompt).
  Future<void> saveHardwareWrappedSessionKey(List<int> sessionKey) async {
    final plaintextBase64 = base64Encode(sessionKey);
    final wrappedBase64 = await _biometricKeywrapChannel.invokeMethod<String>(
      'wrapKeyMaterial',
      {'plaintextBase64': plaintextBase64},
    );

    if (wrappedBase64 == null || wrappedBase64.isEmpty) {
      throw PlatformException(
        code: 'HW_WRAP_EMPTY',
        message: 'Le wrapping matériel a retourné une valeur vide.',
      );
    }

    await _storage.write(
      key: _kWrappedMasterKey,
      value: '$_hardwareWrapPrefix$wrappedBase64',
    );
  }

  /// Lit puis déchiffre la clé de session depuis le Keystore matériel.
  /// Retourne null si aucune donnée hardware n'est présente.
  /// L'authentification biométrique est faite côté UI via local_auth AVANT
  /// d'appeler cette méthode.
  Future<List<int>?> readHardwareWrappedSessionKey() async {
    final raw = await _safeRead(_kWrappedMasterKey);
    if (raw == null || !raw.startsWith(_hardwareWrapPrefix)) {
      return null;
    }

    final wrappedBase64 = raw.substring(_hardwareWrapPrefix.length);
    if (wrappedBase64.isEmpty) {
      return null;
    }

    final plaintextBase64 = await _biometricKeywrapChannel.invokeMethod<String>(
      'unwrapKeyMaterial',
      {'wrappedBase64': wrappedBase64},
    );
    if (plaintextBase64 == null || plaintextBase64.isEmpty) {
      return null;
    }
    return base64Decode(plaintextBase64);
  }

  Future<void> _clearHardwareWrappingKey() async {
    try {
      await _biometricKeywrapChannel.invokeMethod<void>('clearWrappingKey');
    } on MissingPluginException {
      // Plateforme sans implémentation native : ignorer.
    } on PlatformException {
      // Nettoyage best-effort.
    }
  }

  Future<void> saveKeyIterations(int iterations) async {
    await _storage.write(key: _kMasterKeyIterations, value: iterations.toString());
  }

  Future<int?> readKeyIterations() async {
    final raw = await _safeRead(_kMasterKeyIterations);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<void> deleteKeyIterations() async {
    await _storage.delete(key: _kMasterKeyIterations);
  }

  Future<void> setBiometryEnabled(bool enabled) async {
    await _storage.write(key: _kBiometryEnabled, value: enabled ? '1' : '0');
  }

  Future<bool> isBiometryEnabled() async {
    final v = await _safeRead(_kBiometryEnabled);
    return v == '1';
  }
  
  Future<void> saveValidationToken(String tokenBase64) async {
    await _storage.write(key: _kValidationToken, value: tokenBase64);
  }
  
  Future<String?> readValidationToken() => _safeRead(_kValidationToken);

  // Méthodes pour Cloud Backup - Google Drive
  Future<void> saveGoogleDriveEmail(String email) async {
    await _storage.write(key: _kGoogleDriveEmail, value: email);
  }

  Future<String?> readGoogleDriveEmail() => _safeRead(_kGoogleDriveEmail);

  Future<void> deleteGoogleDriveEmail() async {
    await _storage.delete(key: _kGoogleDriveEmail);
  }

  // Méthodes pour Cloud Backup - Dropbox
  Future<void> saveDropboxToken(String token) async {
    await _storage.write(key: _kDropboxToken, value: token);
  }

  Future<String?> readDropboxToken() => _safeRead(_kDropboxToken);

  Future<void> deleteDropboxToken() async {
    await _storage.delete(key: _kDropboxToken);
  }

  // Méthodes pour Cloud Backup - OneDrive
  Future<void> saveOneDriveToken(String token) async {
    await _storage.write(key: _kOneDriveToken, value: token);
  }

  Future<String?> readOneDriveToken() => _safeRead(_kOneDriveToken);

  Future<void> deleteOneDriveToken() async {
    await _storage.delete(key: _kOneDriveToken);
  }

  Future<void> saveOneDriveEmail(String email) async {
    await _storage.write(key: _kOneDriveEmail, value: email);
  }

  Future<String?> readOneDriveEmail() => _safeRead(_kOneDriveEmail);

  Future<void> deleteOneDriveEmail() async {
    await _storage.delete(key: _kOneDriveEmail);
  }

  /// Supprime tous les tokens OAuth cloud
  Future<void> deleteAllCloudTokens() async {
    await deleteGoogleDriveEmail();
    await deleteDropboxToken();
    await deleteOneDriveToken();
    await deleteOneDriveEmail();
  }

  // Méthodes pour Firebase Sync - État de synchronisation
  // Stockage dans SecureStorage au lieu de SharedPreferences pour garantir la persistance
  // sur tous les appareils Android (notamment Pixel avec Battery Optimization)
  Future<void> setFirebaseSyncEnabled(bool enabled) async {
    await _storage.write(key: _kFirebaseSyncEnabled, value: enabled ? '1' : '0');
  }

  Future<bool> isFirebaseSyncEnabled() async {
    final value = await _safeRead(_kFirebaseSyncEnabled);
    return value == '1';
  }

  Future<void> deleteFirebaseSyncEnabled() async {
    await _storage.delete(key: _kFirebaseSyncEnabled);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  // ---------------------------------------------------------------------------
  // Mitigation M2 : helpers int pour le rate limiting brute-force
  // (anciennement en SharedPreferences clair, modifiable par toute app malveillante).
  // ---------------------------------------------------------------------------

  Future<void> writeInt(String key, int value) async {
    await _storage.write(key: key, value: value.toString());
  }

  Future<int?> readInt(String key) async {
    final raw = await _safeRead(key);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<void> deleteKey(String key) async {
    await _storage.delete(key: key);
  }
}

