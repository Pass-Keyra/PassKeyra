/// État de la synchronisation Firebase
enum SyncState {
  /// Synchronisation inactive (pas de compte cloud connecté)
  idle,

  /// Synchronisation en cours
  syncing,

  /// Synchronisation réussie
  success,

  /// Erreur de synchronisation
  error,

  /// Conflit détecté nécessitant une résolution manuelle
  conflict,
}

/// Statut détaillé de la synchronisation
class SyncStatus {
  SyncStatus({
    required this.state,
    this.lastSync,
    this.pendingChanges = 0,
    this.conflictsCount = 0,
    this.errorMessage,
    this.isEnabled = false,
  });

  final SyncState state;
  final DateTime? lastSync;
  final int pendingChanges;
  final int conflictsCount;
  final String? errorMessage;
  final bool isEnabled;

  SyncStatus copyWith({
    SyncState? state,
    DateTime? lastSync,
    int? pendingChanges,
    int? conflictsCount,
    String? errorMessage,
    bool? isEnabled,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      lastSync: lastSync ?? this.lastSync,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      conflictsCount: conflictsCount ?? this.conflictsCount,
      errorMessage: errorMessage ?? this.errorMessage,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Statut par défaut (idle, pas de sync)
  static SyncStatus get initial => SyncStatus(
        state: SyncState.idle,
        lastSync: null,
        pendingChanges: 0,
        conflictsCount: 0,
      );

  /// Retourne true si la sync est en cours
  bool get isSyncing => state == SyncState.syncing;

  /// Retourne true si il y a des changements en attente
  bool get hasPendingChanges => pendingChanges > 0;

  /// Retourne true si il y a des conflits à résoudre
  bool get hasConflicts => conflictsCount > 0;

  /// Retourne true si la dernière sync a échoué
  bool get hasError => state == SyncState.error;

  Map<String, dynamic> toJson() => {
        'state': state.name,
        'lastSync': lastSync?.toIso8601String(),
        'pendingChanges': pendingChanges,
        'conflictsCount': conflictsCount,
        'errorMessage': errorMessage,
        'isEnabled': isEnabled,
      };

  static SyncStatus fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      state: SyncState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => SyncState.idle,
      ),
      lastSync: json['lastSync'] != null
          ? DateTime.tryParse(json['lastSync'] as String)
          : null,
      pendingChanges: json['pendingChanges'] as int? ?? 0,
      conflictsCount: json['conflictsCount'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      isEnabled: json['isEnabled'] as bool? ?? false,
    );
  }
}
