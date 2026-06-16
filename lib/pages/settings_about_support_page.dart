import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/premium_service.dart';
import '../services/review_service.dart';

class SettingsAboutSupportPage extends StatefulWidget {
  const SettingsAboutSupportPage({super.key, required this.isPremium});

  final bool isPremium;

  @override
  State<SettingsAboutSupportPage> createState() => _SettingsAboutSupportPageState();
}

class _SettingsAboutSupportPageState extends State<SettingsAboutSupportPage> {
  // Easter egg debug : 7 clics rapides sur l'icône info "À propos" → toggle Premium.
  // ⚠️ DOIT être `false` pour tout build AAB Play Store (revenue leak : Premium
  // débloqué gratuitement). Repasser à `true` pour le développement local après publication.
  static const bool _premiumEasterEggEnabled = true;
  static const int _easterEggTapThreshold = 7;
  static const Duration _easterEggResetDelay = Duration(seconds: 3);
  int _aboutTapCount = 0;
  DateTime? _lastAboutTapAt;
  late bool _isPremium = widget.isPremium;

  void _showAbout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showAboutDialog(
      context: context,
      applicationName: 'PassKeyra',
      applicationVersion: '1.1.0',
      applicationLegalese: l10n.appTitle,
      children: [
        const SizedBox(height: 8),
        Text(_isPremium ? l10n.aboutPremium : l10n.aboutFree),
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

  /// Compte les taps rapides sur l'icône info. Au seuil → toggle Premium debug.
  /// Reset le compteur si > 3 s entre 2 taps.
  Future<void> _handleAboutIconTap() async {
    final now = DateTime.now();
    if (_lastAboutTapAt != null &&
        now.difference(_lastAboutTapAt!) > _easterEggResetDelay) {
      _aboutTapCount = 0;
    }
    _aboutTapCount++;
    _lastAboutTapAt = now;

    if (_aboutTapCount >= _easterEggTapThreshold) {
      _aboutTapCount = 0;
      _lastAboutTapAt = null;
      final newPremium = await PremiumService().togglePremiumDebug();
      if (!mounted) return;
      setState(() => _isPremium = newPremium);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newPremium
                ? '✨ Mode Premium activé (debug)'
                : 'Mode gratuit activé (debug)',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos et support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            // L'icône leading est cliquable INDÉPENDAMMENT du onTap du ListTile :
            // 7 clics rapides dessus = bascule Premium debug.
            leading: GestureDetector(
              onTap: _premiumEasterEggEnabled ? _handleAboutIconTap : null,
              behavior: HitTestBehavior.opaque,
              child: const Icon(Icons.info_outline),
            ),
            title: const Text('À propos de PassKeyra'),
            subtitle: const Text('Version de l’application et informations'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showAbout(context),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Donner un avis'),
            subtitle: const Text('Aidez-nous à améliorer l’application'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _askForReview(context),
          ),
        ],
      ),
    );
  }
}
