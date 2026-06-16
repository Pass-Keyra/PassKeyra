import 'package:flutter/material.dart';
import '../../models/backup_payload.dart';
import 'models/cloud_backup_metadata.dart';

/// Interface abstraite pour tous les providers de backup cloud
///
/// Cette interface définit le contrat que chaque provider cloud
/// (Google Drive, Dropbox, OneDrive, iCloud) doit implémenter.
///
/// Pattern utilisé: Strategy Pattern
abstract class CloudBackupProvider {
  /// Nom du provider (ex: "Google Drive", "Dropbox", "OneDrive")
  String get providerName;

  /// Icône du provider pour affichage dans l'UI
  IconData get providerIcon;

  /// Couleur associée au provider (pour UI)
  Color get providerColor;

  /// Vérifie si l'utilisateur est actuellement authentifié
  ///
  /// Returns: true si authentifié et token valide, false sinon
  Future<bool> isAuthenticated();

  /// Lance le flux d'authentification OAuth pour le provider
  ///
  /// Cette méthode ouvre le navigateur ou l'app native pour
  /// que l'utilisateur autorise l'accès à son compte cloud.
  ///
  /// Returns: true si authentification réussie, false sinon
  /// Throws: Exception si erreur réseau ou serveur
  Future<bool> authenticate();

  /// Déconnecte l'utilisateur et supprime les tokens OAuth
  ///
  /// Cette méthode révoque les tokens OAuth et nettoie
  /// les données sensibles stockées localement.
  Future<void> signOut();

  /// Upload un fichier de sauvegarde chiffré vers le cloud
  ///
  /// Le fichier est déjà chiffré avec AES-256-GCM côté client
  /// avant d'être envoyé au cloud (zero-knowledge encryption).
  ///
  /// [payload] - Backup chiffré à uploader
  /// [fileName] - Nom du fichier (optionnel, généré si null)
  ///
  /// Returns: ID unique du fichier dans le cloud
  /// Throws: Exception si quota dépassé, offline, ou erreur serveur
  Future<String> uploadBackup(BackupPayload payload, {String? fileName});

  /// Liste toutes les sauvegardes disponibles dans le cloud
  ///
  /// Returns: Liste des métadonnées des backups (triée par date desc)
  /// Throws: Exception si erreur réseau ou non authentifié
  Future<List<CloudBackupMetadata>> listBackups();

  /// Télécharge une sauvegarde spécifique depuis le cloud
  ///
  /// [fileId] - ID unique du fichier à télécharger
  ///
  /// Returns: BackupPayload chiffré (à déchiffrer côté client)
  /// Throws: Exception si fichier introuvable ou erreur réseau
  Future<BackupPayload> downloadBackup(String fileId);

  /// Supprime une sauvegarde du cloud
  ///
  /// [fileId] - ID unique du fichier à supprimer
  ///
  /// Throws: Exception si fichier introuvable ou erreur serveur
  Future<void> deleteBackup(String fileId);

  /// Vérifie la disponibilité du service cloud
  ///
  /// Cette méthode teste la connectivité réseau et la disponibilité
  /// du service cloud (pas de maintenance, pas de firewall, etc.)
  ///
  /// Returns: true si le service est accessible, false sinon
  Future<bool> isAvailable();

  /// Obtient les informations de quota du compte cloud
  ///
  /// Returns: Quota (total, utilisé, restant) en bytes
  /// Throws: Exception si non authentifié ou erreur API
  Future<CloudQuota> getQuota();
}

/// Informations de quota pour un compte cloud
class CloudQuota {
  /// Espace total disponible en bytes
  final int totalBytes;

  /// Espace utilisé en bytes
  final int usedBytes;

  /// Espace restant en bytes
  int get remainingBytes => totalBytes - usedBytes;

  /// Pourcentage d'utilisation (0-100)
  double get usagePercentage => (usedBytes / totalBytes) * 100;

  CloudQuota({
    required this.totalBytes,
    required this.usedBytes,
  });

  /// Vérifie si assez d'espace pour un fichier de taille donnée
  bool hasSpaceFor(int sizeBytes) => remainingBytes >= sizeBytes;

  /// Formate la taille en unité lisible (KB, MB, GB)
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  String toString() {
    return 'CloudQuota(used: ${formatBytes(usedBytes)} / ${formatBytes(totalBytes)}, '
           'remaining: ${formatBytes(remainingBytes)}, '
           '${usagePercentage.toStringAsFixed(1)}% used)';
  }
}
