import 'package:flutter/material.dart';
import '../app/app.dart';
import '../l10n/app_localizations.dart';

class CloudSyncHelpPage extends StatelessWidget {
  const CloudSyncHelpPage({super.key, this.onDeleteAccountRequested});

  final VoidCallback? onDeleteAccountRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide - Synchronisation Cloud'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildColorLegendSection(context, theme),
          const SizedBox(height: 24),
          _buildSection(
            theme,
            icon: Icons.sync_alt,
            iconColor: PassKeyraColors.info,
            title: 'Synchronisation Firestore',
            subtitle: 'Temps réel · Multi-appareils',
            description:
                'La synchronisation Firestore maintient vos mots de passe à jour '
                'en temps réel sur tous vos appareils connectés.\n\n'
                '✓ Synchronisation automatique et instantanée\n'
                '✓ Modifications reflétées immédiatement\n'
                '✓ Fonctionne en arrière-plan\n'
                '✓ Résolution automatique des conflits',
          ),
          const SizedBox(height: 24),
          _buildSecuritySection(theme),
          if (onDeleteAccountRequested != null) ...[
            const SizedBox(height: 32),
            Center(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onDeleteAccountRequested!();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.deleteCloudAccount,
                    style: const TextStyle(
                      color: Colors.red,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorLegendSection(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.helpColorLegend,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildColorLegendRow(
              icon: Icons.circle,
              color: PassKeyraColors.info,
              label: l10n.helpColorBlue,
              meaning: l10n.helpColorBlueMeaning,
            ),
            _buildColorLegendRow(
              icon: Icons.circle,
              color: PassKeyraColors.inProgress,
              label: l10n.helpColorPurple,
              meaning: l10n.helpColorPurpleMeaning,
            ),
            _buildColorLegendRow(
              icon: Icons.circle,
              color: PassKeyraColors.success,
              label: l10n.helpColorGreen,
              meaning: l10n.helpColorGreenMeaning,
            ),
            _buildColorLegendRow(
              icon: Icons.circle,
              color: PassKeyraColors.error,
              label: l10n.helpColorRed,
              meaning: l10n.helpColorRedMeaning,
            ),
            _buildColorLegendRow(
              icon: Icons.circle,
              color: Colors.grey,
              label: l10n.helpColorGrey,
              meaning: l10n.helpColorGreyMeaning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorLegendRow({
    required IconData icon,
    required Color color,
    required String label,
    required String meaning,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          const Text('→', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              meaning,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String description,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection(ThemeData theme) {
    return Card(
      color: Colors.green.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.security, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sécurité',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toutes vos données sont chiffrées de bout en bout avant '
                    'd\'être envoyées vers le cloud. Ni Google ni Firebase ne peuvent '
                    'lire vos mots de passe.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
