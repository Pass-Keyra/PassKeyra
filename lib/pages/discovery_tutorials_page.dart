import 'package:flutter/material.dart';

import '../app/app.dart';
import '../l10n/app_localizations.dart';
import 'home_page.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../services/ad_service.dart';
import '../services/vault_repository.dart';
import 'cloud_backup_page.dart';
import 'edit_entry_page.dart';
import 'import_export_page.dart';

class DiscoveryTutorialsPage extends StatefulWidget {
  const DiscoveryTutorialsPage({super.key});

  static const route = '/discovery-tutorials';

  @override
  State<DiscoveryTutorialsPage> createState() => _DiscoveryTutorialsPageState();
}

class _DiscoveryTutorialsPageState extends State<DiscoveryTutorialsPage> {
  final _onboardingService = OnboardingService.instance;
  final Map<DiscoveryTutorial, bool> _completedStatus = {};
  AuthService? _auth;
  VaultRepository? _vaultRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_auth != null) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args?['auth'] is AuthService) _auth = args!['auth'] as AuthService;
    if (args?['vaultRepository'] is VaultRepository) {
      _vaultRepository = args!['vaultRepository'] as VaultRepository;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCompletedStatus();
  }

  Future<void> _loadCompletedStatus() async {
    for (final tutorial in DiscoveryTutorial.values) {
      final completed = await _onboardingService.isDiscoveryCompleted(tutorial);
      if (mounted) {
        setState(() => _completedStatus[tutorial] = completed);
      }
    }
  }

  Future<void> _startTutorial(DiscoveryTutorial tutorial) async {
    switch (tutorial) {
      case DiscoveryTutorial.premium:
        await _runPremiumTutorial();
        break;
      case DiscoveryTutorial.firstEntry:
        await _runFirstEntryTutorial();
        break;
      case DiscoveryTutorial.firstCloudBackup:
        await _runFirstCloudBackupTutorial();
        break;
      case DiscoveryTutorial.firstCloudBackupPhase1:
        // Étape interne du didacticiel cloud, pas rejouable individuellement
        // depuis cette page. Géré comme la phase complète si jamais sollicitée.
        await _runFirstCloudBackupTutorial();
        break;
    }

    await _onboardingService.markDiscoveryCompleted(tutorial);
    await _loadCompletedStatus();
  }

  Future<void> _runFirstCloudBackupTutorial() async {
    // Réinitialiser le flag pour que le tutoriel se redéclenche dans CloudBackupPage
    await _onboardingService.resetDiscoveryTutorial(DiscoveryTutorial.firstCloudBackup);
    if (!mounted || _auth == null) return;
    await Navigator.of(context).pushNamed(
      CloudBackupPage.route,
      arguments: {'authService': _auth!, 'startTutorial': true},
    );
  }

  Future<void> _runFirstEntryTutorial() async {
    // Réinitialiser le flag pour que le tutoriel se déclenche dans EditEntryPage
    await _onboardingService.resetDiscoveryTutorial(DiscoveryTutorial.firstEntry);
    if (!mounted) return;

    // Naviguer vers EditEntryPage (le tutoriel Phase 1 se déclenche automatiquement)
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditEntryPage()),
    );

    // Consommer le flag Phase 2 pour éviter un déclenchement intempestif sur HomePage
    await _onboardingService.consumeShouldShowFirstEntryPhase2();
  }

  Future<void> _runPremiumTutorial() async {
    final l10n = AppLocalizations.of(context)!;

    // Intro (non numérotée)
    final start = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.workspace_premium, size: 48, color: PassKeyraColors.primary),
        title: Text(l10n.premiumTutorialIntroTitle),
        content: Text(l10n.premiumTutorialIntroMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.onboardingSkipTutorial),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.onboardingContinue),
          ),
        ],
      ),
    );

    if (start != true || !mounted) return;

    // Fonctionnalité 1 / 7 : Sans publicités
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.block, size: 48, color: PassKeyraColors.primary),
        title: Text(l10n.premiumTutorialNoAdsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.premiumTutorialNoAdsMessage),
            const SizedBox(height: 10),
            Text(
              'Fonctionnalité 1 / 7',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PassKeyraColors.primary),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.onboardingNext),
          ),
        ],
      ),
    );

    if (!mounted) return;

    // Fonctionnalités 2 et 3 / 7 : Icônes & Mots de passe multiples (transition)
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.edit_note, size: 48, color: PassKeyraColors.primary),
        title: Text(l10n.premiumTutorialIconsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.premiumTutorialIconsMessage),
            const SizedBox(height: 10),
            Text(
              'Fonctionnalités 2 et 3 / 7',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PassKeyraColors.primary),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.onboardingNext),
          ),
        ],
      ),
    );

    if (!mounted) return;

    // Fonctionnalités 2 & 3 : Icônes & Mots de passe multiples (coach marks dans EditEntryPage)
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EditEntryPage(startTutorial: true),
      ),
    );

    if (!mounted) return;

    // Fonctionnalité 4 / 7 : Analyse de sécurité avancée
    await Navigator.pushNamed(
      context,
      '/settings',
      arguments: {
        'startPremiumTutorial': true,
        if (_auth != null) 'auth': _auth,
      },
    );

    if (!mounted) return;

    // Fonctionnalité 5 / 7 : Synchronisation temps réel
    await Navigator.pushNamed(
      context,
      '/cloud-sync-settings',
      arguments: {
        if (_auth != null) 'authService': _auth,
        if (_vaultRepository != null) 'vaultRepository': _vaultRepository,
        'startTutorial': true,
      },
    );

    if (!mounted) return;

    // Fonctionnalité 6 / 7 : Sauvegarde Drive automatique
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CloudBackupPage(startTutorial: true),
      ),
    );

    if (!mounted) return;

    // Fonctionnalité 7 / 7 : Sauvegarde locale automatique (transition)
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.phone_android_outlined, size: 48, color: PassKeyraColors.primary),
        title: Text(l10n.premiumTutorialLocalBackupTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.premiumTutorialLocalBackupMessage),
            const SizedBox(height: 10),
            Text(
              'Fonctionnalité 7 / 7',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PassKeyraColors.primary),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.onboardingNext),
          ),
        ],
      ),
    );

    if (!mounted) return;

    // Fonctionnalité 7 : Coach mark sauvegarde locale automatique
    await Navigator.pushNamed(
      context,
      ImportExportPage.route,
      arguments: {
        if (_auth != null) 'authService': _auth,
        'startTutorialAutoBackup': true,
      },
    );
    if (!mounted) return;

    // Confirmation finale (non numérotée)
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, size: 48, color: Colors.green),
        title: Text(l10n.onboardingFinish),
        content: Text(l10n.premiumTutorialCompleteMessage),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getTutorialTitle(DiscoveryTutorial tutorial) {
    final l10n = AppLocalizations.of(context)!;
    switch (tutorial) {
      case DiscoveryTutorial.premium:
        return l10n.discoveryPremiumTitle;
      case DiscoveryTutorial.firstEntry:
        return l10n.discoveryFirstEntryTitle;
      case DiscoveryTutorial.firstCloudBackup:
        return 'Sauvegarde cloud';
      case DiscoveryTutorial.firstCloudBackupPhase1:
        return 'Sauvegarde cloud';
    }
  }

  String _getTutorialDescription(DiscoveryTutorial tutorial) {
    final l10n = AppLocalizations.of(context)!;
    switch (tutorial) {
      case DiscoveryTutorial.premium:
        return l10n.discoveryPremiumDescription;
      case DiscoveryTutorial.firstEntry:
        return l10n.discoveryFirstEntryDescription;
      case DiscoveryTutorial.firstCloudBackup:
        return 'Découvrir la page de sauvegarde cloud';
      case DiscoveryTutorial.firstCloudBackupPhase1:
        return 'Découvrir la page de sauvegarde cloud';
    }
  }

  String _getTutorialSteps(DiscoveryTutorial tutorial) {
    final l10n = AppLocalizations.of(context)!;
    switch (tutorial) {
      case DiscoveryTutorial.premium:
        return '7';
      case DiscoveryTutorial.firstEntry:
        return l10n.discoveryFirstEntrySteps;
      case DiscoveryTutorial.firstCloudBackup:
        return '4';
      case DiscoveryTutorial.firstCloudBackupPhase1:
        return '1';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.discoveryModeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.discoveryModeSubtitle,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          _buildRelaunchTutorialCard(),
          const SizedBox(height: 12),
          _buildTutorialCard(DiscoveryTutorial.firstEntry),
          const SizedBox(height: 12),
          if (AdService.instance.isPremium)
            _buildTutorialCard(DiscoveryTutorial.premium),
        ],
      ),
    );
  }

  Widget _buildRelaunchTutorialCard() {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      color: PassKeyraColors.primary.withOpacity(0.05),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PassKeyraColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.replay,
            color: PassKeyraColors.primary,
            size: 32,
          ),
        ),
        title: Text(
          l10n.onboardingRestart,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(l10n.onboardingRestartDescription),
        ),
        trailing: FilledButton(
          onPressed: () async {
            await OnboardingService.instance.requestPostVaultReplay();
            if (!mounted) return;
            Navigator.of(context).popUntil(
              ModalRoute.withName(HomePage.route),
            );
          },
          child: Text(l10n.discoveryReplay),
        ),
      ),
    );
  }

  Widget _buildTutorialCard(DiscoveryTutorial tutorial) {
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = _completedStatus[tutorial] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCompleted
                ? PassKeyraColors.success.withOpacity(0.1)
                : PassKeyraColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.school,
            color: isCompleted ? PassKeyraColors.success : PassKeyraColors.primary,
            size: 32,
          ),
        ),
        title: Text(
          _getTutorialTitle(tutorial),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_getTutorialDescription(tutorial)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_getTutorialSteps(tutorial)} ${l10n.discoverySteps}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PassKeyraColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.discoveryCompleted,
                      style: TextStyle(
                        fontSize: 12,
                        color: PassKeyraColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: FilledButton(
          onPressed: () => _startTutorial(tutorial),
          child: Text(isCompleted ? l10n.discoveryReplay : l10n.discoveryStart),
        ),
      ),
    );
  }
}
