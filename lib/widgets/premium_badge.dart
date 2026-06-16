import 'package:flutter/material.dart';

import '../app/app.dart';
import '../pages/premium_page.dart';

/// Badge "Premium" affiché à côté des titres de features Premium quand
/// l'utilisateur n'est pas Premium. Style canonique défini une seule fois.
///
/// Usage typique :
/// ```dart
/// Row(
///   children: [
///     const Text('Ma feature'),
///     const Spacer(),
///     if (!premiumService.isPremium) const PremiumBadge(),
///   ],
/// )
/// ```
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.label = 'Premium'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: PassKeyraColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium, size: 14, color: PassKeyraColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: PassKeyraColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Affiche le dialog standard "Fonctionnalité Premium requise".
/// Centralise l'UX de tous les dialogs Premium ad-hoc dispersés dans l'app.
///
/// [featureName] : nom de la feature (ex: "Sauvegarde locale automatique")
/// [customMessage] : message custom optionnel ; sinon message par défaut générique
Future<void> showPremiumLockedDialog(
  BuildContext context, {
  required String featureName,
  String? customMessage,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.workspace_premium, color: PassKeyraColors.primary, size: 48),
      title: Text('$featureName — Premium'),
      content: Text(
        customMessage ?? '$featureName est réservée aux utilisateurs Premium.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.pushNamed(context, PremiumPage.route);
          },
          child: const Text('Voir Premium'),
        ),
      ],
    ),
  );
}
