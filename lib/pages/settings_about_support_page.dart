import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/review_service.dart';

class SettingsAboutSupportPage extends StatelessWidget {
  const SettingsAboutSupportPage({super.key, required this.isPremium});

  final bool isPremium;

  void _showAbout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showAboutDialog(
      context: context,
      applicationName: 'PassKeyra',
      applicationVersion: '1.1.11',
      applicationLegalese: l10n.appTitle,
      children: [
        const SizedBox(height: 8),
        Text(isPremium ? l10n.aboutPremium : l10n.aboutFree),
      ],
    );
  }

  Future<void> _askForReview(BuildContext context) async {
    await ReviewService().requestReviewManually();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merci pour votre retour.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A propos et support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('A propos de PassKeyra'),
            subtitle: const Text('Version de l\'application et informations'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showAbout(context),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Donner un avis'),
            subtitle: const Text('Aidez-nous a ameliorer l\'application'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _askForReview(context),
          ),
        ],
      ),
    );
  }
}
