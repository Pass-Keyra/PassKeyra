import 'package:flutter/material.dart';

import '../app/keyboard_shortcuts.dart';
import '../widgets/keyboard_shortcut_hint.dart';

class KeyboardShortcutsPage extends StatelessWidget {
  const KeyboardShortcutsPage({super.key});
  static const String route = '/keyboard-shortcuts';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raccourcis clavier'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Text(
            'Liste des raccourcis disponibles dans PassKeyra Desktop.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ...AppShortcut.values.map((s) => _ShortcutRow(shortcut: s)),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.shortcut});
  final AppShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: KeyboardShortcutHint(shortcut: shortcut),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shortcut.label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  shortcut.description,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
