/// Représente un utilisateur Firebase connecté
class CloudUser {
  CloudUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.createdAt,
  });

  /// ID unique Firebase de l'utilisateur
  final String uid;

  /// Email de l'utilisateur
  final String email;

  /// Nom d'affichage optionnel
  final String? displayName;

  /// Date de création du compte cloud
  final DateTime? createdAt;

  CloudUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
  }) {
    return CloudUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'createdAt': createdAt?.toIso8601String(),
      };

  static CloudUser fromJson(Map<String, dynamic> json) {
    return CloudUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
