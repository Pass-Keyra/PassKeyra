import 'package:uuid/uuid.dart';

class PasswordEntry {
  PasswordEntry({
    String? id,
    required this.name,
    required this.username,
    required this.password,
    this.url,
    this.notes,
    this.tags = const <String>[],
    this.category,
    this.additionalPasswords = const <Map<String, String>>[],
    this.emoji,
    this.iconColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final String username;
  final String password;
  final String? url;
  final String? notes;
  final List<String> tags;
  final String? category;
  /// Liste de mots de passe additionnels (Premium)
  /// Format : [{'label': 'Email secondaire', 'username': 'user@...', 'password': '...'}]
  final List<Map<String, String>> additionalPasswords;
  /// Emoji personnalisé pour l'entrée (Premium)
  final String? emoji;
  /// Couleur de fond de l'icône au format hex (Premium)
  final String? iconColor;
  final DateTime createdAt;
  final DateTime updatedAt;

  PasswordEntry copyWith({
    String? name,
    String? username,
    String? password,
    String? url,
    String? notes,
    List<String>? tags,
    String? category,
    List<Map<String, String>>? additionalPasswords,
    String? emoji,
    String? iconColor,
  }) {
    return PasswordEntry(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      additionalPasswords: additionalPasswords ?? this.additionalPasswords,
      emoji: emoji ?? this.emoji,
      iconColor: iconColor ?? this.iconColor,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'password': password,
        'url': url,
        'notes': notes,
        'tags': tags,
        'category': category,
        'additionalPasswords': additionalPasswords,
        'emoji': emoji,
        'iconColor': iconColor,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static PasswordEntry fromJson(Map<String, dynamic> json) => PasswordEntry(
        id: json['id'] as String?,
        name: json['name'] as String,
        username: json['username'] as String,
        password: json['password'] as String,
        url: json['url'] as String?,
        notes: json['notes'] as String?,
        tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
        category: json['category'] as String?,
        additionalPasswords: (json['additionalPasswords'] as List<dynamic>? ?? const [])
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
        emoji: json['emoji'] as String?,
        iconColor: json['iconColor'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}



