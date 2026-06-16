import 'package:flutter/material.dart';

import '../app/keyboard_shortcuts.dart';

/// Widget réutilisable qui affiche les "key caps" d'un raccourci clavier
/// (ex: `[Ctrl] + [N]`). Utilisé dans :
/// - La page Raccourcis Clavier (Settings)
/// - Les coach marks / didacticiels via `CoachMarkSystem.showCoachStep(..., shortcut: ...)`
class KeyboardShortcutHint extends StatelessWidget {
  const KeyboardShortcutHint({super.key, required this.shortcut});
  final AppShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < shortcut.keys.length; i++) ...[
          _KeyCap(label: shortcut.keys[i]),
          if (i < shortcut.keys.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text('+', style: theme.textTheme.bodyMedium),
            ),
        ],
      ],
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
