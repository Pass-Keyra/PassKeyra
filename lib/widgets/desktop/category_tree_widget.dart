import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../models/custom_category.dart';
import '../../services/category_service.dart';

/// Widget arborescent pour afficher les categories avec sous-categories
/// sur desktop. Chaque categorie parente affiche une fleche `expand_more`
/// a droite de son cadre, **uniquement si elle a au moins un enfant**.
/// Cliquer sur la fleche expand/collapse les enfants. Cliquer sur le
/// corps de la categorie la selectionne (filtre les entries).
///
/// Profondeur max 3 (cf. [CategoryService.maxDepth]).
/// Indentation par niveau : 16px par profondeur.
class CategoryTreeWidget extends StatefulWidget {
  const CategoryTreeWidget({
    super.key,
    required this.categories,
    required this.selectedCategoryName,
    required this.onCategorySelected,
    this.showAllOption = true,
  });

  final List<CustomCategory> categories;
  final String? selectedCategoryName;
  final ValueChanged<String?> onCategorySelected;
  final bool showAllOption;

  @override
  State<CategoryTreeWidget> createState() => _CategoryTreeWidgetState();
}

class _CategoryTreeWidgetState extends State<CategoryTreeWidget> {
  final _categoryService = CategoryService();
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final roots = _categoryService.getRootCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showAllOption)
          _buildCategoryTile(
            label: 'Toutes',
            icon: Icons.apps,
            color: PassKeyraColors.primary,
            isSelected: widget.selectedCategoryName == null,
            onTap: () => widget.onCategorySelected(null),
            depth: 0,
            hasChildren: false,
            categoryId: null,
          ),
        for (final root in roots) _buildCategoryNode(root, 0),
      ],
    );
  }

  Widget _buildCategoryNode(CustomCategory category, int depth) {
    final children = _categoryService.getChildren(category.id);
    final isExpanded = _expanded.contains(category.id);
    final isSelected = widget.selectedCategoryName == category.name;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCategoryTile(
          label: category.name,
          icon: category.isEmoji ? null : category.icon,
          emoji: category.isEmoji ? category.emoji : null,
          color: category.color,
          isSelected: isSelected,
          onTap: () => widget.onCategorySelected(category.name),
          depth: depth,
          hasChildren: children.isNotEmpty,
          categoryId: category.id,
          isExpanded: isExpanded,
        ),
        if (isExpanded)
          for (final child in children)
            _buildCategoryNode(child, depth + 1),
      ],
    );
  }

  Widget _buildCategoryTile({
    required String label,
    IconData? icon,
    String? emoji,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required int depth,
    required bool hasChildren,
    required String? categoryId,
    bool isExpanded = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (emoji != null)
                  Text(emoji, style: const TextStyle(fontSize: 18))
                else if (icon != null)
                  Icon(icon, size: 20, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasChildren && categoryId != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expanded.remove(categoryId);
                        } else {
                          _expanded.add(categoryId);
                        }
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.0 : -0.25,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
