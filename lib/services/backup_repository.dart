import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/backup_payload.dart';

/// Taille maximale acceptée pour un fichier de backup importé (100 MB).
/// Au-delà, refus immédiat pour éviter OOM côté Hive/Crypto.
const int kMaxBackupFileBytes = 100 * 1024 * 1024;

/// Lit le contenu texte d'un fichier de backup avec validation de taille.
/// Lève une [Exception] si la taille dépasse [kMaxBackupFileBytes].
Future<String> readBackupFileSafe(File file) async {
  final size = await file.length();
  if (size > kMaxBackupFileBytes) {
    throw Exception(
      'Fichier de sauvegarde trop volumineux '
      '(${(size / 1024 / 1024).toStringAsFixed(1)} MB, max 100 MB).',
    );
  }
  return file.readAsString();
}

/// Gère les sauvegardes locales stockées dans l'app.
///
/// Deux familles de fichiers, distinguées par leur préfixe :
/// - `passkeyra_local_*.json` : backups normaux (manuels ou auto Premium).
///   Rotation à 1 fichier max (`maxLocalBackups`).
/// - `passkeyra_pre_change_*.json` : **snapshots pré-changement de master
///   password** créés automatiquement avant chaque rotation de mot de passe
///   maître. Hors rotation, conservés [snapshotRetentionDays] jours, puis
///   supprimés au prochain démarrage par `cleanExpiredSnapshots`.
///   Permet à l'utilisateur de revenir à l'état précédent en cas de problème
///   (restauration avec son ancien mot de passe maître).
class BackupRepository {
  static const int maxLocalBackups = 1;
  static const String _folderName = 'backups';
  static const String _normalPrefix = 'passkeyra_local_';
  static const String _snapshotPrefix = 'passkeyra_pre_change_';

  /// Durée de rétention par défaut des snapshots pré-changement (en jours).
  static const int snapshotRetentionDays = 30;

  Future<Directory> _ensureBackupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Liste les backups **normaux** (exclut les snapshots pré-changement).
  Future<List<LocalBackup>> listLocalBackups() async {
    return _listByPrefix(_normalPrefix);
  }

  /// Liste les snapshots pré-changement (sauvegardes de sécurité).
  Future<List<LocalBackup>> listSnapshotBackups() async {
    return _listByPrefix(_snapshotPrefix);
  }

  Future<List<LocalBackup>> _listByPrefix(String prefix) async {
    final dir = await _ensureBackupDir();
    final files = await dir
        .list()
        .where((entity) {
          if (entity is! File) return false;
          final name = p.basename(entity.path);
          return name.startsWith(prefix) && name.endsWith('.json');
        })
        .cast<File>()
        .toList();

    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    final backups = <LocalBackup>[];
    for (final file in files) {
      try {
        final content = await readBackupFileSafe(file);
        final payload = BackupPayload.fromJsonString(content);
        backups.add(LocalBackup(filePath: file.path, payload: payload));
      } catch (_) {
        await file.delete();
      }
    }
    return backups;
  }

  Future<LocalBackup> saveLocalBackup(BackupPayload payload) async {
    final dir = await _ensureBackupDir();
    final fileName =
        '$_normalPrefix${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(payload.toJsonString());

    final backups = await listLocalBackups();
    if (backups.length > maxLocalBackups) {
      final oldest = backups.last;
      final oldestFile = File(oldest.filePath);
      // Mitigation M4 : pas de check exists() avant delete() pour eviter TOCTOU.
      try {
        await oldestFile.delete();
      } on FileSystemException {
        // Fichier deja absent ou inaccessible : ignore.
      }
    }

    return LocalBackup(filePath: file.path, payload: payload);
  }

  /// Sauvegarde un snapshot pré-changement de master password.
  /// Hors rotation des backups normaux. Conservé jusqu'à expiration
  /// (cf. `cleanExpiredSnapshots`).
  Future<LocalBackup> saveSnapshotBackup(BackupPayload payload) async {
    final dir = await _ensureBackupDir();
    final fileName =
        '$_snapshotPrefix${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsString(payload.toJsonString());
    return LocalBackup(filePath: file.path, payload: payload);
  }

  /// Supprime les snapshots dont l'`exportedAt` est plus ancien que
  /// [maxAgeDays] jours. À appeler au démarrage de l'app.
  Future<int> cleanExpiredSnapshots({int maxAgeDays = snapshotRetentionDays}) async {
    final snapshots = await listSnapshotBackups();
    final cutoff = DateTime.now().subtract(Duration(days: maxAgeDays));
    int deleted = 0;
    for (final snapshot in snapshots) {
      if (snapshot.payload.exportedAt.isBefore(cutoff)) {
        try {
          await File(snapshot.filePath).delete();
          deleted++;
        } on FileSystemException {
          // Ignoré.
        }
      }
    }
    return deleted;
  }

  Future<BackupPayload> readBackup(LocalBackup backup) async {
    final file = File(backup.filePath);
    final content = await readBackupFileSafe(file);
    return BackupPayload.fromJsonString(content);
  }

  Future<void> deleteBackup(LocalBackup backup) async {
    final file = File(backup.filePath);
    // Mitigation M4 : try/catch direct au lieu de exists() puis delete() (TOCTOU).
    try {
      await file.delete();
    } on FileSystemException {
      // Fichier deja absent ou inaccessible : ignore.
    }
  }

  Future<void> clearAll() async {
    final dir = await _ensureBackupDir();
    final files = await dir.list().toList();
    for (final entity in files) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }
}

/// Indique si un [LocalBackup] est un snapshot pré-changement de master pwd.
/// Utilisé par l'UI (page Import/Export) pour afficher un badge distinct.
bool isSnapshotBackup(LocalBackup backup) {
  return p.basename(backup.filePath).startsWith('passkeyra_pre_change_');
}
