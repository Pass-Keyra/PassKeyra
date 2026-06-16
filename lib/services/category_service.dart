import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/custom_category.dart';

class CategoryService extends ChangeNotifier {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  static const String _categoriesKey = 'custom_categories';
  final _uuid = const Uuid();

  List<CustomCategory> _categories = [];
  bool _isInitialized = false;

  // Catégories par défaut - Palette claire autour du bleu PassKeyra #2196F3
  static final List<CustomCategory> _defaultCategories = [
    CustomCategory(
      id: 'default_social',
      name: 'Réseaux sociaux',
      colorValue: const Color(0xFF2196F3).value, // Bleu PassKeyra principal
      iconCodePoint: Icons.people.codePoint,
      order: 0,
      isDefault: true,
      isDeletable: true,
    ),
    CustomCategory(
      id: 'default_email',
      name: 'Email',
      colorValue: const Color(0xFF42A5F5).value, // Bleu clair
      iconCodePoint: Icons.email.codePoint,
      order: 1,
      isDefault: true,
      isDeletable: true,
    ),
    CustomCategory(
      id: 'default_bank',
      name: 'Banque',
      colorValue: const Color(0xFF26C6DA).value, // Cyan clair
      iconCodePoint: Icons.account_balance.codePoint,
      order: 2,
      isDefault: true,
      isDeletable: true,
    ),
    CustomCategory(
      id: 'default_shopping',
      name: 'Shopping',
      colorValue: const Color(0xFFAB47BC).value, // Violet clair
      iconCodePoint: Icons.shopping_cart.codePoint,
      order: 3,
      isDefault: true,
      isDeletable: true,
    ),
    CustomCategory(
      id: 'default_work',
      name: 'Travail',
      colorValue: const Color(0xFF5C6BC0).value, // Indigo clair
      iconCodePoint: Icons.work.codePoint,
      order: 4,
      isDefault: true,
      isDeletable: true,
    ),
    CustomCategory(
      id: 'default_personal',
      name: 'Personnel',
      colorValue: const Color(0xFF29B6F6).value, // Bleu ciel clair
      iconCodePoint: Icons.person.codePoint,
      order: 5,
      isDefault: true,
      isDeletable: true,
    ),
    CustomCategory(
      id: 'default_other',
      name: 'Autre',
      colorValue: const Color(0xFF78909C).value, // Gris bleuté clair
      iconCodePoint: Icons.category.codePoint,
      order: 6,
      isDefault: true,
      isDeletable: false, // "Autre" n'est jamais supprimable
    ),
  ];

  // Initialiser le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final String? categoriesJson = prefs.getString(_categoriesKey);

    if (categoriesJson == null) {
      // Première utilisation : charger les catégories par défaut
      _categories = List.from(_defaultCategories);
      await _saveCategories();
    } else {
      // Charger les catégories sauvegardées
      try {
        final List<dynamic> decoded = jsonDecode(categoriesJson);
        _categories = decoded
            .map((json) => CustomCategory.fromJson(json as Map<String, dynamic>))
            .toList();

        // Trier par ordre
        _categories.sort((a, b) => a.order.compareTo(b.order));
      } catch (e) {
        debugPrint('Erreur lors du chargement des catégories : $e');
        // En cas d'erreur, utiliser les catégories par défaut
        _categories = List.from(_defaultCategories);
        await _saveCategories();
      }
    }

    _isInitialized = true;
  }

  // Sauvegarder les catégories
  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
        _categories.map((cat) => cat.toJson()).toList();
    await prefs.setString(_categoriesKey, jsonEncode(jsonList));
  }

  // Obtenir toutes les catégories
  List<CustomCategory> getAllCategories() {
    return List.unmodifiable(_categories);
  }

  // Obtenir une catégorie par nom
  CustomCategory? getCategoryByName(String name) {
    try {
      return _categories.firstWhere((cat) => cat.name == name);
    } catch (e) {
      return null;
    }
  }

  // Obtenir une catégorie par ID
  CustomCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  // Ajouter une catégorie
  Future<CustomCategory> addCategory({
    required String name,
    required Color color,
    required IconData icon,
    String? emoji,
    bool isRoundShape = false,
  }) async {
    // Vérifier si le nom existe déjà
    if (_categories.any((cat) => cat.name.toLowerCase() == name.toLowerCase())) {
      throw Exception('Une catégorie avec ce nom existe déjà');
    }

    // Créer la nouvelle catégorie avec l'ordre le plus élevé
    final int maxOrder = _categories.isEmpty
        ? 0
        : _categories.map((c) => c.order).reduce((a, b) => a > b ? a : b);

    final newCategory = CustomCategory(
      id: _uuid.v4(),
      name: name,
      colorValue: color.value,
      iconCodePoint: icon.codePoint,
      order: maxOrder + 1,
      isDefault: false,
      isDeletable: true,
      emoji: emoji,
      isRoundShape: isRoundShape,
    );

    _categories.add(newCategory);
    await _saveCategories();
    notifyListeners();
    return newCategory;
  }

  // Modifier une catégorie (seulement les catégories personnalisées)
  Future<void> updateCategory({
    required String id,
    String? name,
    Color? color,
    IconData? icon,
    String? emoji,
    bool? isRoundShape,
  }) async {
    final index = _categories.indexWhere((cat) => cat.id == id);
    if (index == -1) {
      throw Exception('Catégorie introuvable');
    }

    final category = _categories[index];

    // Ne pas autoriser la modification des catégories par défaut (sauf leur ordre)
    if (category.isDefault) {
      throw Exception('Les catégories par défaut ne peuvent pas être modifiées');
    }

    // Vérifier si le nouveau nom existe déjà (sauf pour la catégorie actuelle)
    if (name != null && name != category.name) {
      if (_categories.any((cat) =>
          cat.id != id && cat.name.toLowerCase() == name.toLowerCase())) {
        throw Exception('Une catégorie avec ce nom existe déjà');
      }
    }

    _categories[index] = category.copyWith(
      name: name,
      colorValue: color?.value,
      iconCodePoint: icon?.codePoint,
      emoji: emoji,
      isRoundShape: isRoundShape,
    );

    await _saveCategories();
    notifyListeners();
  }

  // Supprimer une catégorie
  Future<void> deleteCategory(String id) async {
    final category = _categories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => throw Exception('Catégorie introuvable'),
    );

    if (!category.isDeletable) {
      throw Exception('Cette catégorie ne peut pas être supprimée');
    }

    _categories.removeWhere((cat) => cat.id == id);

    // Réorganiser les ordres
    for (int i = 0; i < _categories.length; i++) {
      _categories[i] = _categories[i].copyWith(order: i);
    }

    await _saveCategories();
    notifyListeners();
  }

  // Réorganiser les catégories
  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final category = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, category);

    // Mettre à jour les ordres
    for (int i = 0; i < _categories.length; i++) {
      _categories[i] = _categories[i].copyWith(order: i);
    }

    await _saveCategories();
    notifyListeners();
  }

  // Obtenir la catégorie "Autre" (fallback)
  CustomCategory getOtherCategory() {
    return _categories.firstWhere(
      (cat) => cat.name == 'Autre',
      orElse: () => _defaultCategories.last, // Dernier élément = "Autre"
    );
  }

  // Réinitialiser aux catégories par défaut
  Future<void> resetToDefaults() async {
    _categories = List.from(_defaultCategories);
    await _saveCategories();
    notifyListeners();
  }

  /// Applique des catégories reçues depuis le cloud (Firebase Sync).
  /// Met à jour l'état mémoire ET SharedPreferences, puis notifie les listeners.
  Future<void> applyFromCloud(List<CustomCategory> categories) async {
    _categories = List.from(categories);
    _categories.sort((a, b) => a.order.compareTo(b.order));
    await _saveCategories();
    notifyListeners();
  }

  // Obtenir le nombre de catégories personnalisées (non par défaut)
  int getCustomCategoryCount() {
    return _categories.where((cat) => !cat.isDefault).length;
  }

  // Vérifier si l'utilisateur peut ajouter des catégories
  bool canAddCategory(bool isPremium) {
    // Version gratuite : catégories illimitées
    return true;
  }
}
