import 'package:hive_flutter/hive_flutter.dart';

import '../models/password_entry.dart';
import 'auth_service.dart';
import 'crypto_isolate.dart';
import 'crypto_service.dart';

/// Dépôt chiffré pour stocker les entrées dans Hive.
/// On chiffre le contenu global comme un blob JSON, évitant de stocker en clair.
class VaultRepository {
  VaultRepository(this._auth, {CryptoService? crypto})
      : _crypto = crypto ?? CryptoService();

  final AuthService _auth;
  final CryptoService _crypto;
  
  // Exposer auth pour ImportExportPage
  AuthService get auth => _auth;

  static const String _boxName = 'vault_blob';
  static const String _blobKey = 'blob';

  Future<void> _ensureBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  Future<List<PasswordEntry>> readAll() async {
    await _ensureBox();
    final box = Hive.box<String>(_boxName);
    final payload = box.get(_blobKey);
    if (payload == null) return <PasswordEntry>[];
    final key = _auth.currentKey;
    if (key == null) {
      throw StateError('Coffre verrouillé - aucune clé disponible');
    }
    try {
      // Décryptage en isolate pour ne pas bloquer le thread UI sur les
      // coffres volumineux (AES-GCM + parsing JSON peut prendre 100-500 ms).
      final obj = await decryptVaultInIsolate(payload: payload, key: key);
      final list = (obj['entries'] as List<dynamic>? ?? const [])
          .map((e) => PasswordEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      // Si le déchiffrement échoue, c'est que le mot de passe est incorrect
      throw Exception('Mot de passe incorrect - Impossible de déchiffrer le coffre');
    }
  }

  Future<void> saveAll(List<PasswordEntry> entries) async {
    await _ensureBox();
    final box = Hive.box<String>(_boxName);
    final key = _auth.currentKey;
    if (key == null) throw StateError('Verrouillé');
    final payload = _crypto.encryptJson(
      {
        'entries': entries.map((e) => e.toJson()).toList(),
      },
      key,
    );
    await box.put(_blobKey, payload);
  }
  
  /// Rechiffre le coffre avec une nouvelle clé après changement de mot de passe
  Future<void> reEncryptVault(List<int> oldKey) async {
    await _ensureBox();
    final box = Hive.box<String>(_boxName);
    final payload = box.get(_blobKey);
    
    if (payload == null) return; // Rien à rechiffrer
    
    // Déchiffrer avec l'ancienne clé
    final obj = _crypto.decryptToJson(payload, oldKey);
    final entries = (obj['entries'] as List<dynamic>? ?? const [])
        .map((e) => PasswordEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    
    // Rechiffrer avec la nouvelle clé (qui est déjà dans _auth.currentKey)
    final newKey = _auth.currentKey;
    if (newKey == null) throw StateError('Nouvelle clé non disponible');
    
    final newPayload = _crypto.encryptJson(
      {
        'entries': entries.map((e) => e.toJson()).toList(),
      },
      newKey,
    );
    
    await box.put(_blobKey, newPayload);
  }
}
