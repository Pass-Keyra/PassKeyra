import 'package:flutter/material.dart';

class CustomCategory {
  final String id;
  final String name;
  final int colorValue; // Color.value (int)
  final int iconCodePoint; // IconData.codePoint
  final int order;
  final bool isDefault; // true pour les categories par defaut
  final bool isDeletable; // false pour "Autre"
  final String? emoji; // Emoji personnalise (Premium) - XOR avec iconCodePoint
  final bool isRoundShape; // true = rond, false = carre (Premium, seulement pour emoji)
  // Sous-categories : si non-null, cette categorie est un enfant de la
  // categorie identifiee par parentId. Profondeur max 3. Null = racine.
  // Retrocompat schema v1 : les anciennes sauvegardes n'ont pas ce champ,
  // fromJson l'hydrate a null automatiquement.
  final String? parentId;

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
    this.parentId,
  });

  Color get color => Color(colorValue);

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons', matchTextDirection: false);

  bool get isEmoji => emoji != null && emoji!.isNotEmpty;

  bool get isRoot => parentId == null;

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
      if (parentId != null) 'parentId': parentId,
    };
  }

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
      parentId: json['parentId'] as String?,
    );
  }

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
    String? Function()? parentId,
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
      // Trick pour distinguer "pas passe" (null) de "explicitement null".
      // copyWith(parentId: () => null) met parentId a null.
      // copyWith(parentId: () => 'abc') met parentId a 'abc'.
      // copyWith() sans parentId garde la valeur existante.
      parentId: parentId != null ? parentId() : this.parentId,
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
