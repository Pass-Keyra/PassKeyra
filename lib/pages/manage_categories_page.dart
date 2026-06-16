import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_category.dart';
import '../services/category_service.dart';
import '../services/auto_close_service.dart';
import '../widgets/category_dialog.dart';
import '../app/app.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});
  static const String route = '/manage-categories';

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final _categoryService = CategoryService();
  List<CustomCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _categoryService.addListener(_loadCategories);
    _loadCategories();
  }

  @override
  void dispose() {
    _categoryService.removeListener(_loadCategories);
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categories = _categoryService.getAllCategories();
    });
  }

  Future<void> _addCategory() async {
    // Version gratuite avec catégories illimitées
    // Afficher le dialogue de création
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CategoryDialog(),
    );

    if (result == null || !mounted) return;

    try {
      await _categoryService.addCategory(
        name: result['name'] as String,
        color: result['color'] as Color,
        icon: result['icon'] as IconData,
        emoji: result['emoji'] as String?,
        isRoundShape: result['isRoundShape'] as bool? ?? false,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.categorySaved),
          backgroundColor: PassKeyraColors.success,
        ),
      );

      _loadCategories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: PassKeyraColors.error,
        ),
      );
    }
  }

  Future<void> _editCategory(CustomCategory category) async {
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deleteEntryMessage),
          backgroundColor: PassKeyraColors.warning,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CategoryDialog(category: category),
    );

    if (result == null || !mounted) return;

    try {
      await _categoryService.updateCategory(
        id: category.id,
        name: result['name'] as String,
        color: result['color'] as Color,
        icon: result['icon'] as IconData,
        emoji: result['emoji'] as String?,
        isRoundShape: result['isRoundShape'] as bool? ?? false,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.categorySaved),
          backgroundColor: PassKeyraColors.success,
        ),
      );

      _loadCategories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: PassKeyraColors.error,
        ),
      );
    }
  }

  Future<void> _deleteCategory(CustomCategory category) async {
    if (!category.isDeletable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deleteCategoryConfirm),
          backgroundColor: PassKeyraColors.warning,
        ),
      );
      return;
    }

    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteCategory),
        content: Text(AppLocalizations.of(context)!.deleteCategoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: PassKeyraColors.error),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _categoryService.deleteCategory(category.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.categoryDeleted),
          backgroundColor: PassKeyraColors.error,
        ),
      );

      _loadCategories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: PassKeyraColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageCategoriesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addCategory,
            tooltip: AppLocalizations.of(context)!.addCategory,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => AutoCloseService.instance.onUserActivity(),
        onPanStart: (_) => AutoCloseService.instance.onUserActivity(),
        behavior: HitTestBehavior.translucent,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            AutoCloseService.instance.onUserActivity();
            return false;
          },
          child: _categories.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              onReorder: (oldIndex, newIndex) async {
                await _categoryService.reorderCategories(oldIndex, newIndex);
                _loadCategories();
              },
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Card(
                  key: ValueKey(category.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: category.isEmoji
                        ? Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: category.color,
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              category.emoji!,
                              style: const TextStyle(fontSize: 24),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: category.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              category.icon,
                              color: category.color,
                            ),
                          ),
                    title: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      category.isDefault
                          ? AppLocalizations.of(context)!.category
                          : AppLocalizations.of(context)!.customCategories,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!category.isDefault)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editCategory(category),
                            tooltip: AppLocalizations.of(context)!.edit,
                          ),
                        if (category.isDeletable)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: PassKeyraColors.error),
                            onPressed: () => _deleteCategory(category),
                            tooltip: AppLocalizations.of(context)!.delete,
                          ),
                        const Icon(Icons.drag_handle),
                      ],
                    ),
                  ),
                );
              },
            ),
        ),
      ),
    );
  }
}
