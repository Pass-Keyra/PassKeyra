/// Métadonnées d'une sauvegarde stockée dans le cloud
///
/// Cette classe représente les informations d'un fichier backup
/// sans contenir les données elles-mêmes (qui sont chiffrées).
class CloudBackupMetadata {
  /// ID unique du fichier dans le cloud provider
  ///
  /// Cet ID est spécifique au provider (Google Drive file ID,
  /// Dropbox path, OneDrive item ID, etc.)
  final String id;

  /// Nom du fichier backup
  ///
  /// Format recommandé: passkeyra_backup_TIMESTAMP.json
  final String name;

  /// Date et heure de l'upload
  final DateTime uploadedAt;

  /// Taille du fichier en bytes
  final int sizeBytes;

  /// Nom du provider cloud (ex: "Google Drive", "Dropbox")
  final String providerName;

  /// Hash SHA-256 du fichier (optionnel)
  ///
  /// Utilisé pour vérifier l'intégrité après download
  final String? sha256Hash;

  /// Nombre d'entrées contenues dans la sauvegarde (optionnel)
  ///
  /// Cette valeur n'est disponible que si le backup a été téléchargé et parsé.
  /// Si null, cela signifie que le nombre d'entrées n'a pas encore été extrait.
  final int? entryCount;

  CloudBackupMetadata({
    required this.id,
    required this.name,
    required this.uploadedAt,
    required this.sizeBytes,
    required this.providerName,
    this.sha256Hash,
    this.entryCount,
  });

  /// Formate la taille en unité lisible (KB, MB, GB)
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Formate la date de manière lisible
  ///
  /// Exemples: "Aujourd'hui à 14:30", "Hier à 09:15", "05/12/2025 à 18:00"
  String getFormattedDate(String locale) {
    final now = DateTime.now();

    // Comparer les DATES calendaires, pas les durées !
    final todayDate = DateTime(now.year, now.month, now.day);
    final uploadDate = DateTime(uploadedAt.year, uploadedAt.month, uploadedAt.day);
    final daysDifference = todayDate.difference(uploadDate).inDays;

    final timeStr = '${uploadedAt.hour.toString().padLeft(2, '0')}:'
                    '${uploadedAt.minute.toString().padLeft(2, '0')}';

    if (daysDifference == 0) {
      // Aujourd'hui (même jour calendaire)
      return locale == 'fr'
          ? 'Aujourd\'hui à $timeStr'
          : locale == 'es'
              ? 'Hoy a las $timeStr'
              : 'Today at $timeStr';
    } else if (daysDifference == 1) {
      // Hier (jour précédent)
      return locale == 'fr'
          ? 'Hier à $timeStr'
          : locale == 'es'
              ? 'Ayer a las $timeStr'
              : 'Yesterday at $timeStr';
    } else if (daysDifference < 7) {
      // Il y a X jours
      return locale == 'fr'
          ? 'Il y a $daysDifference jours'
          : locale == 'es'
              ? 'Hace $daysDifference días'
              : '$daysDifference days ago';
    } else {
      // Date complète
      final day = uploadedAt.day.toString().padLeft(2, '0');
      final month = uploadedAt.month.toString().padLeft(2, '0');
      final year = uploadedAt.year;

      return locale == 'fr' || locale == 'es'
          ? '$day/$month/$year à $timeStr'
          : '$month/$day/$year at $timeStr';
    }
  }

  /// Crée une copie avec modifications
  CloudBackupMetadata copyWith({
    String? id,
    String? name,
    DateTime? uploadedAt,
    int? sizeBytes,
    String? providerName,
    String? sha256Hash,
    int? entryCount,
  }) {
    return CloudBackupMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      providerName: providerName ?? this.providerName,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      entryCount: entryCount ?? this.entryCount,
    );
  }

  /// Sérialisation JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'uploadedAt': uploadedAt.toIso8601String(),
      'sizeBytes': sizeBytes,
      'providerName': providerName,
      if (sha256Hash != null) 'sha256Hash': sha256Hash,
      if (entryCount != null) 'entryCount': entryCount,
    };
  }

  /// Désérialisation JSON
  factory CloudBackupMetadata.fromJson(Map<String, dynamic> json) {
    return CloudBackupMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      sizeBytes: json['sizeBytes'] as int,
      providerName: json['providerName'] as String,
      sha256Hash: json['sha256Hash'] as String?,
      entryCount: json['entryCount'] as int?,
    );
  }

  @override
  String toString() {
    return 'CloudBackupMetadata('
           'name: $name, '
           'provider: $providerName, '
           'size: $formattedSize, '
           'uploaded: ${uploadedAt.toIso8601String()}'
           ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CloudBackupMetadata &&
        other.id == id &&
        other.providerName == providerName;
  }

  @override
  int get hashCode => id.hashCode ^ providerName.hashCode;
}
