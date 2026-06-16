import 'package:flutter/material.dart';

class CustomCategory {
  final String id;
  final String name;
  final int colorValue; // Color.value (int)
  final int iconCodePoint; // IconData.codePoint
  final int order;
  final bool isDefault; // true pour les catégories par défaut
  final bool isDeletable; // false pour "Autre"
  final String? emoji; // Emoji personnalisé (Premium) - XOR avec iconCodePoint
  final bool isRoundShape; // true = rond, false = carré (Premium, seulement pour emoji)

  CustomCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.order,
    this.isDefault = false,
    this.isDeletable = true,
    this.emoji,
    this.isRoundShape = false,
  });

  // Getter pour obtenir l'objet Color
  Color get color => Color(colorValue);

  // Getter pour obtenir l'objet IconData
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons', matchTextDirection: false);

  // Vérifier si la catégorie utilise un emoji (Premium)
  bool get isEmoji => emoji != null && emoji!.isNotEmpty;

  // Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
      'order': order,
      'isDefault': isDefault,
      'isDeletable': isDeletable,
      'emoji': emoji,
      'isRoundShape': isRoundShape,
    };
  }

  // Création depuis JSON
  factory CustomCategory.fromJson(Map<String, dynamic> json) {
    return CustomCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
      iconCodePoint: json['iconCodePoint'] as int,
      order: json['order'] as int,
      isDefault: json['isDefault'] as bool? ?? false,
      isDeletable: json['isDeletable'] as bool? ?? true,
      emoji: json['emoji'] as String?,
      isRoundShape: json['isRoundShape'] as bool? ?? false,
    );
  }

  // Copie avec modifications
  CustomCategory copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? iconCodePoint,
    int? order,
    bool? isDefault,
    bool? isDeletable,
    String? emoji,
    bool? isRoundShape,
  }) {
    return CustomCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      order: order ?? this.order,
      isDefault: isDefault ?? this.isDefault,
      isDeletable: isDeletable ?? this.isDeletable,
      emoji: emoji ?? this.emoji,
      isRoundShape: isRoundShape ?? this.isRoundShape,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
