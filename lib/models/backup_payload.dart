import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Seuil minimum d'itérations PBKDF2 accepté à l'import.
/// Empêche un backup malicieusement modifié (`iterations: 1`) de rendre
/// le brute-force trivial sur le mot de passe maître.
const int kMinAcceptedIterations = 100000;

/// Représente une sauvegarde chiffrée de PassKeyra
/// avec toutes les informations nécessaires pour une restauration complète.
class BackupPayload {
  BackupPayload({
    required this.salt,
    required this.iv,
    required this.ciphertext,
    required this.tag,
    required this.exportedAt,
    this.entryCount = 0,
    this.iterations = 600000,
    this.schemaVersion = 2,
  });

  final String salt;
  final String iv;
  final String ciphertext;
  final String tag;
  final DateTime exportedAt;
  final int entryCount;
  final int iterations;
  // Schema v1 : pas de sous-categories (parentId absent dans CustomCategory).
  // Schema v2 : CustomCategory peut avoir un parentId (nullable).
  // La lecture est retrocompatible : un payload v1 est lu comme v2 avec
  // parentId=null sur toutes les categories.
  final int schemaVersion;

  Map<String, dynamic> toJson() => {
        'salt': salt,
        'iv': iv,
        'ciphertext': ciphertext,
        'tag': tag,
        'exportedAt': exportedAt.toIso8601String(),
        'entryCount': entryCount,
        'iterations': iterations,
        'schema': schemaVersion,
      };

  String toJsonString() => jsonEncode(toJson());

  /// Map utilisé par CryptoService pour déchiffrer.
  Map<String, dynamic> encryptedMap() => {
        'iv': iv,
        'ciphertext': ciphertext,
        'tag': tag,
      };

  static BackupPayload fromJson(Map<String, dynamic> json) {
    T requireField<T>(String key) {
      if (!json.containsKey(key)) {
        throw FormatException('Champ "$key" manquant');
      }
      final value = json[key];
      if (value is! T) {
        throw FormatException('Champ "$key" invalide');
      }
      return value;
    }

    final salt = requireField<String>('salt');
    final iv = requireField<String>('iv');
    final ciphertext = requireField<String>('ciphertext');
    final tag = requireField<String>('tag');

    DateTime exportedAt;
    final raw = json['exportedAt'];
    if (raw is String) {
      exportedAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      exportedAt = DateTime.now();
    }

    // Récupérer le nombre d'entrées (optionnel pour compatibilité anciennes sauvegardes)
    int entryCount = 0;
    final entryCountRaw = json['entryCount'];
    if (entryCountRaw is int) {
      entryCount = entryCountRaw;
    }

    // Récupérer iterations (rétrocompatibilité : 150k si absent)
    int iterations = 150000; // Anciennes versions utilisaient 150k
    final iterationsRaw = json['iterations'];
    if (iterationsRaw is int) {
      iterations = iterationsRaw;
    }

    // Refus des backups manipulés avec un nombre d'itérations dangereusement bas.
    if (iterations < kMinAcceptedIterations) {
      throw FormatException(
        'Backup refusé : iterations=$iterations < $kMinAcceptedIterations '
        '(risque de brute-force).',
      );
    }

    final jsonKeys = json.keys.toList()..sort();
    debugPrint(
      'PAYLOAD_PARSE keys=${jsonKeys.join(",")} iterations=$iterations saltChars=${salt.length} ivChars=${iv.length} ctChars=${ciphertext.length} tagChars=${tag.length} entryCount=$entryCount',
    );

    // Schema version (v1 si absent = avant sous-categories, v2 = avec parentId)
    final schemaVersion = (json['schema'] as int?) ?? 1;

    return BackupPayload(
      salt: salt,
      iv: iv,
      ciphertext: ciphertext,
      tag: tag,
      exportedAt: exportedAt,
      entryCount: entryCount,
      iterations: iterations,
      schemaVersion: schemaVersion,
    );
  }

  static BackupPayload fromJsonString(String content) {
    final map = jsonDecode(content) as Map<String, dynamic>;
    return BackupPayload.fromJson(map);
  }
}

class LocalBackup {
  LocalBackup({required this.filePath, required this.payload});

  final String filePath;
  final BackupPayload payload;

  String get fileName => filePath.split(RegExp(r'[\\/]')).last;
}


