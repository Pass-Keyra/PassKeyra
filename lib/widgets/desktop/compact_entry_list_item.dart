import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app.dart';
import '../../models/password_entry.dart';

class CompactEntryListItem extends StatelessWidget {
  const CompactEntryListItem({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
    required this.onSecondaryTapDown,
    this.categoryColor,
    this.categoryIcon,
    this.categoryEmoji,
  });

  final PasswordEntry entry;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final void Function(TapDownDetails) onSecondaryTapDown;
  final Color? categoryColor;
  final IconData? categoryIcon;
  final String? categoryEmoji;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onDoubleTap: onDoubleTap,
      onSecondaryTapDown: onSecondaryTapDown,
      child: Material(
        color: isSelected
            ? primary.withValues(alpha: 0.08)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: const Color(0xFFF5F7FA),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                // Barre de selection gauche
                Container(
                  width: 3,
                  color: isSelected ? primary : Colors.transparent,
                ),
                const SizedBox(width: 12),
                // Icone
                _buildIcon(),
                const SizedBox(width: 10),
                // Nom
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected
                          ? primary
                          : const Color(0xFF37474F),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Identifiant
                SizedBox(
                  width: 200,
                  child: Text(
                    entry.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PassKeyraColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Date
                SizedBox(
                  width: 80,
                  child: Text(
                    _formatDate(entry.updatedAt ?? entry.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: PassKeyraColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (entry.emoji != null) {
      final bgColor = entry.iconColor != null
          ? Color(int.parse(entry.iconColor!.replaceFirst('#', '0xFF')))
          : PassKeyraColors.primary;
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(entry.emoji!, style: const TextStyle(fontSize: 14)),
      );
    }

    if (categoryEmoji != null) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: (categoryColor ?? PassKeyraColors.primary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(categoryEmoji!, style: const TextStyle(fontSize: 14)),
      );
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: (categoryColor ?? PassKeyraColors.primary).withValues(alpha: 0.1),
      child: Icon(
        categoryIcon ?? Icons.lock_outline,
        color: categoryColor ?? PassKeyraColors.primary,
        size: 14,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }
}
