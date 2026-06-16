import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';

import 'crypto_service.dart';

/// Dérive une clé PBKDF2-HMAC-SHA256 via le package `cryptography`,
/// qui utilise les bindings natifs (Android javax.crypto / iOS CryptoKit)
/// — gain ~10× par rapport à pointycastle pure-Dart.
///
/// PBKDF2-HMAC-SHA256 étant déterministe (RFC 8018), les bytes générés sont
/// identiques à ceux de pointycastle pour les mêmes paramètres → aucun
/// risque pour les coffres existants.
///
/// [password] Le mot de passe maître
/// [salt] Le sel cryptographique
/// [iterations] Nombre d'itérations PBKDF2 (par défaut 600000, standard 2025)
/// [keyBytes] Longueur de la clé en octets (par défaut 32 pour AES-256)
Future<List<int>> deriveKeyInIsolate({
  required String password,
  required List<int> salt,
  int iterations = 600000,
  int keyBytes = 32,
}) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: keyBytes * 8,
  );

  final secretKey = await pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );
  return secretKey.extractBytes();
}

/// Paramètres pour le décryptage du blob du coffre
class VaultDecryptParams {
  final String payload;
  final List<int> key;

  VaultDecryptParams({required this.payload, required this.key});
}

/// Fonction isolée pour décrypter le blob AES-GCM du coffre
Map<String, dynamic> _decryptVaultIsolate(VaultDecryptParams params) {
  return CryptoService().decryptToJson(params.payload, params.key);
}

/// Décrypte le blob du coffre dans un isolate séparé.
///
/// Évite de bloquer le thread UI pour les coffres volumineux (>50 entrées),
/// où le décryptage AES-GCM + parsing JSON peut prendre plusieurs centaines
/// de millisecondes.
Future<Map<String, dynamic>> decryptVaultInIsolate({
  required String payload,
  required List<int> key,
}) {
  return compute(
    _decryptVaultIsolate,
    VaultDecryptParams(payload: payload, key: key),
  );
}
