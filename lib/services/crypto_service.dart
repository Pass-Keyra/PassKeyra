import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' as pc;

/// Comparaison à temps constant de deux séquences d'octets.
/// Empêche les timing attacks lors de la comparaison de clés ou de MACs.
/// Note : la longueur reste un side-channel acceptable (publique).
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a[i] ^ b[i];
  }
  return result == 0;
}

/// Service cryptographique : PBKDF2 pour dériver une clé et AES-256-GCM.
///
/// SÉCURITÉ (Session 22 - Renforcement protection brute force) :
/// - Itérations PBKDF2 augmentées de 150k → 600k (4x plus lent)
/// - Protection contre attaque brute force offline sur backups cloud
/// - Standard industrie 2025 (Bitwarden, LastPass utilisent 600k+)
/// - Temps dérivation : ~500ms sur mobile moderne (acceptable)
///
/// RÉTROCOMPATIBILITÉ (Session 38 - Fix DECRYPTION_FAILED) :
/// - deriveKey() accepte maintenant iterations en paramètre
/// - Permet de déchiffrer les backups créés avec anciennes versions (150k)
/// - Nouveaux backups utilisent 600k (défaut)
class CryptoService {
  static const int _saltBytes = 16; // 128-bit salt
  static const int defaultIterations = 600000; // coût PBKDF2 par défaut (600k = standard 2025)
  static const int _keyBytes = 32; // 256-bit key
  static const int _ivBytes = 12; // 96-bit nonce pour GCM

  /// Version du format JSON chiffré produit par [encryptJson].
  /// Mitigation L4 : permet de migrer vers un nouvel algorithme/format dans
  /// le futur sans casser les anciens blobs (qui sont en v1 implicite).
  static const int currentEncryptionVersion = 1;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  String generateSaltBase64() {
    final rnd = Random.secure();
    final salt = List<int>.generate(_saltBytes, (_) => rnd.nextInt(256));
    return base64Encode(salt);
  }

  /// Fingerprint déterministe d'une clé de session, utilisable comme empreinte
  /// publique pour détecter qu'une autre instance a changé sa clé (ex: changement
  /// de mot de passe maître sur un autre appareil).
  ///
  /// Calculé via HMAC-SHA256(key, constant) tronqué à 16 octets puis base64.
  /// Propriétés :
  /// - **Déterministe** : même clé → même fingerprint, donc on peut comparer
  ///   les fingerprints de 2 devices pour savoir s'ils dérivent la même clé.
  /// - **One-way** : ne révèle rien sur la clé (HMAC est résistant à l'inversion).
  /// - **Stable au temps** : sans IV/nonce, le fingerprint reste identique entre
  ///   appels (contrairement à un chiffrement AES-GCM qui randomise chaque fois).
  /// - **Court** : 16 octets = 24 caractères base64, OK pour Firestore.
  String keyFingerprint(List<int> key) {
    final hmac = pc.HMac(pc.SHA256Digest(), 64)
      ..init(pc.KeyParameter(Uint8List.fromList(key)));
    final input = Uint8List.fromList(utf8.encode('PASSKEYRA_KEY_FINGERPRINT_V1'));
    final mac = hmac.process(input);
    // Tronqué à 16 octets : la collision-resistance reste largement suffisante
    // (un fingerprint = équivalent d'un fingerprint TLS), inutile de stocker 32.
    return base64Encode(mac.sublist(0, 16));
  }

  List<int> deriveKey(String password, List<int> salt, {int? iterations}) {
    final iterationsToUse = iterations ?? defaultIterations;
    // Mitigation L3 : masquer la valeur exacte (deja kDebugMode-protege).
    _log('CRYPTO_DERIVE iterations=***');
    final derivator = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(pc.Pbkdf2Parameters(Uint8List.fromList(salt), iterationsToUse, _keyBytes));
    final out = derivator.process(Uint8List.fromList(utf8.encode(password)));
    _log('CRYPTO_DERIVE_OK');
    return out;
  }

  String encryptJson(Map<String, dynamic> json, List<int> key) {
    final plain = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    final iv = _randomBytes(_ivBytes);

    final cipher = pc.GCMBlockCipher(pc.AESEngine())
      ..init(
        true,
        pc.AEADParameters(
          pc.KeyParameter(Uint8List.fromList(key)),
          128, // tag length in bits
          iv,
          Uint8List(0), // AAD vide
        ),
      );

    final out = cipher.process(plain);
    final ciphertext = out.sublist(0, out.length - 16);
    final tag = out.sublist(out.length - 16);

    return jsonEncode({
      'v': currentEncryptionVersion,
      'iv': base64Encode(iv),
      'ciphertext': base64Encode(ciphertext),
      'tag': base64Encode(tag),
    });
  }

  Map<String, dynamic> decryptToJson(String payload, List<int> key) {
    try {
      final obj = jsonDecode(payload) as Map<String, dynamic>;
      // Mitigation L4 : valider la version du format si presente.
      // Les blobs anciens sans champ 'v' sont traites comme v1 (retro-compat).
      final version = obj['v'] is int ? obj['v'] as int : 1;
      if (version > currentEncryptionVersion) {
        throw FormatException(
          'Format de chiffrement v$version non supporte (max v$currentEncryptionVersion). '
          'Mettez a jour PassKeyra.',
        );
      }
      final iv = base64Decode(obj['iv'] as String);
      final ciphertext = base64Decode(obj['ciphertext'] as String);
      final tag = base64Decode(obj['tag'] as String);
      _log('CRYPTO_DEC_START');

      final cipher = pc.GCMBlockCipher(pc.AESEngine())
        ..init(
          false,
          pc.AEADParameters(
            pc.KeyParameter(Uint8List.fromList(key)),
            128,
            Uint8List.fromList(iv),
            Uint8List(0),
          ),
        );

      final combined = Uint8List(ciphertext.length + tag.length)
        ..setAll(0, ciphertext)
        ..setAll(ciphertext.length, tag);

      final out = cipher.process(combined);
      final decoded = utf8.decode(out);
      _log('CRYPTO_DEC_OK');
      return jsonDecode(decoded) as Map<String, dynamic>;
    } on pc.InvalidCipherTextException {
      // Mot de passe incorrect ou données corrompues
      _log('CRYPTO_DEC_FAIL InvalidCipherTextException');
      throw Exception('DECRYPTION_FAILED');
    } catch (e) {
      // Autres erreurs (JSON invalide, format incorrect, etc.)
      _log('CRYPTO_DEC_ERR $e');
      rethrow;
    }
  }

  Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    final bytes = List<int>.generate(length, (_) => rnd.nextInt(256));
    return Uint8List.fromList(bytes);
  }
}
