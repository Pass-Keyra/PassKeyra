import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_category.dart';
import '../platform/platform_capabilities.dart';
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
  // Desktop : ids des categories deroulees dans l'arbre.
  final Set<String> _expanded = {};

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

  Future<void> _addCategory({String? parentId}) async {
    // Version gratuite avec catégories illimitées
    // Afficher le dialogue de création
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CategoryDialog(),
    );

    if (result == null || !mounted) return;

    try {
      if (parentId != null) {
        await _categoryService.addSubCategory(
          parentId: parentId,
          name: result['name'] as String,
          color: result['color'] as Color,
          icon: result['icon'] as IconData,
          emoji: result['emoji'] as String?,
          isRoundShape: result['isRoundShape'] as bool? ?? false,
        );
        // Derouler automatiquement le parent pour voir la nouvelle sous-cat.
        _expanded.add(parentId);
      } else {
        await _categoryService.addCategory(
          name: result['name'] as String,
          color: result['color'] as Color,
          icon: result['icon'] as IconData,
          emoji: result['emoji'] as String?,
          isRoundShape: result['isRoundShape'] as bool? ?? false,
        );
      }

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

  // ===========================================================================
  // Vue arborescente Desktop (sous-categories)
  // ===========================================================================

  Widget _buildDesktopTree() {
    final roots = _categoryService.getRootCategories();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final root in roots) ..._buildCategoryRows(root, 0),
      ],
    );
  }

  /// Freres d'une categorie (meme parent), tries par ordre.
  List<CustomCategory> _siblingsOf(CustomCategory category) {
    return category.isRoot
        ? _categoryService.getRootCategories()
        : _categoryService.getChildren(category.parentId!);
  }

  /// Construit recursivement les lignes d'une categorie et de ses enfants
  /// (si deroulee). Retourne une liste plate de widgets indentes.
  List<Widget> _buildCategoryRows(CustomCategory category, int depth) {
    final children = _categoryService.getChildren(category.id);
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expanded.contains(category.id);
    final canAddSub = _categoryService.getDepth(category.id) + 1 < CategoryService.maxDepth;
    final siblings = _siblingsOf(category);
    final siblingIndex = siblings.indexWhere((c) => c.id == category.id);
    final isFirstSibling = siblingIndex <= 0;
    final isLastSibling = siblingIndex == siblings.length - 1;

    final rows = <Widget>[
      Padding(
        padding: EdgeInsets.only(left: depth * 24.0, bottom: 8),
        child: Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: category.isEmoji
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(category.emoji!, style: const TextStyle(fontSize: 22)),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(category.icon, color: category.color),
                  ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: depth > 0
                ? Text(
                    'Sous-categorie',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reordonner parmi les freres (meme parent).
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  tooltip: 'Monter',
                  visualDensity: VisualDensity.compact,
                  onPressed: isFirstSibling
                      ? null
                      : () => _categoryService.moveCategoryUp(category.id),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  tooltip: 'Descendre',
                  visualDensity: VisualDensity.compact,
                  onPressed: isLastSibling
                      ? null
                      : () => _categoryService.moveCategoryDown(category.id),
                ),
                // Ajouter une sous-categorie (si profondeur le permet).
                if (canAddSub)
                  IconButton(
                    icon: const Icon(Icons.create_new_folder_outlined),
                    tooltip: 'Ajouter une sous-categorie',
                    onPressed: () => _addCategory(parentId: category.id),
                  ),
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
                // Fleche d'expansion UNIQUEMENT si la categorie a des enfants.
                if (hasChildren)
                  IconButton(
                    icon: AnimatedRotation(
                      turns: isExpanded ? 0.0 : -0.25,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more),
                    ),
                    tooltip: isExpanded ? 'Reduire' : 'Derouler',
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expanded.remove(category.id);
                        } else {
                          _expanded.add(category.id);
                        }
                      });
                    },
                  )
                else
                  // Espaceur pour aligner les cartes sans enfants.
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    ];

    if (isExpanded) {
      for (final child in children) {
        rows.addAll(_buildCategoryRows(child, depth + 1));
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageCategoriesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addCategory(),
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
              : isDesktop
                  ? _buildDesktopTree()
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
