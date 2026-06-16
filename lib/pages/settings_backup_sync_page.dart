import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/cloud_backup/cloud_backup_factory.dart';
import '../services/cloud_backup/cloud_backup_service.dart';
import '../services/premium_service.dart';
import '../services/vault_repository.dart';
import '../widgets/coach_mark_system.dart';
import '../widgets/premium_badge.dart';
import 'cloud_backup_page.dart';
import 'import_export_page.dart';
import 'premium_page.dart';

class SettingsBackupSyncPage extends StatefulWidget {
  const SettingsBackupSyncPage({
    super.key,
    required this.auth,
    required this.vaultRepository,
    this.startTutorial = false,
  });

  final AuthService auth;
  final VaultRepository vaultRepository;
  final bool startTutorial;

  @override
  State<SettingsBackupSyncPage> createState() => _SettingsBackupSyncPageState();
}

class _SettingsBackupSyncPageState extends State<SettingsBackupSyncPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _coachPulseController;
  bool _isTutorialRunning = false;
  String? _activeTargetKey;
  final GlobalKey _localBackupKey = GlobalKey();
  final GlobalKey _cloudBackupKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _coachPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    if (widget.startTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runBackupSyncTutorial();
      });
    }
  }

  @override
  void dispose() {
    _coachPulseController.dispose();
    super.dispose();
  }

  Future<void> _runBackupSyncTutorial() async {
    setState(() { _isTutorialRunning = true; _activeTargetKey = 'local'; });
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    // Étape 1 / 2 : Sauvegarde locale
    final step1 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _localBackupKey,
      pulseController: _coachPulseController,
      title: l10n.onboardingBackupLocalTitle,
      message: l10n.onboardingBackupLocalBody,
      primaryLabel: l10n.onboardingContinue,
      secondaryLabel: l10n.onboardingSkipTutorial,
      clearFocusInset: 20.0,
      fullWidth: true,
      stepIndicator: '1 / 2',
    );

    setState(() { _isTutorialRunning = false; _activeTargetKey = null; });

    if (step1 != CoachStepResult.primary) {
      if (mounted) Navigator.pop(context);
      return;
    }

    if (mounted) {
      await Navigator.pushNamed(
        context,
        ImportExportPage.route,
        arguments: {
          'authService': widget.auth,
          'startTutorial': true,
        },
      );
    }

    if (!mounted) return;

    // Étape 2 / 2 : Sauvegarde cloud (introduction du tile + push CloudBackupPage)
    setState(() { _isTutorialRunning = true; _activeTargetKey = 'cloud'; });
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final step2 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _cloudBackupKey,
      pulseController: _coachPulseController,
      title: 'Sauvegarde cloud',
      message:
          'Sauvegardez votre coffre dans le cloud (Google Drive, OneDrive ou Dropbox) pour le retrouver sur tous vos appareils. Découvrons-la ensemble.',
      primaryLabel: l10n.onboardingContinue,
      secondaryLabel: l10n.onboardingSkipTutorial,
      clearFocusInset: 20.0,
      fullWidth: true,
      stepIndicator: '2 / 2',
    );

    setState(() { _isTutorialRunning = false; _activeTargetKey = null; });

    if (step2 == CoachStepResult.primary && mounted) {
      // Push CloudBackupPage en mode tutoriel : la page gère elle-même son
      // didacticiel (phase 1 si aucun provider, phase 2 si authentifié) et
      // affiche inline la liste de choix de provider quand nécessaire.
      await Navigator.pushNamed(
        context,
        CloudBackupPage.route,
        arguments: {'authService': widget.auth, 'startTutorial': true},
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<String> _getCloudProviderSubtitle(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedProvider = prefs.getString('selected_cloud_provider');

      // Aucun provider configuré → service complètement désactivé.
      // L'utilisateur peut tap pour configurer un nouveau provider.
      if (savedProvider == null) return 'Service désactivé';

      final provider = CloudProvider.values.firstWhere(
        (p) => p.name == savedProvider,
        orElse: () => CloudProvider.googleDrive,
      );
      final isAutoBackupEnabled = await CloudBackupService().isAutoBackupEnabled();
      return isAutoBackupEnabled
          ? '${provider.displayName} - Sauvegarde automatique activée'
          : '${provider.displayName} - Sauvegarde automatique désactivée';
    } catch (_) {
      return 'Service désactivé';
    }
  }

  Future<void> _openSyncSettings() async {
    final isPremium = PremiumService().isPremium;
    if (!isPremium) {
      await showPremiumLockedDialog(
        context,
        featureName: 'Synchronisation cloud',
        customMessage:
            'La synchronisation en temps réel entre vos appareils est réservée aux utilisateurs Premium.',
      );
      return;
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/cloud-sync-settings',
      arguments: {
        'authService': widget.auth,
        'vaultRepository': widget.vaultRepository,
      },
    );
  }

  void _openLocalBackupPage() {
    Navigator.pushNamed(
      context,
      ImportExportPage.route,
      arguments: {
        'authService': widget.auth,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Sauvegarde & Synchronisation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Sauvegarde',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          CoachMarkSystem.buildHalo(
            key: _localBackupKey,
            pulseController: _coachPulseController,
            isActive: _isTutorialRunning && _activeTargetKey == 'local',
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: const Icon(Icons.save_outlined),
              title: const Text('Sauvegarde locale'),
              subtitle: const Text('Créer et restaurer une sauvegarde sur cet appareil'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _openLocalBackupPage,
            ),
          ),
          CoachMarkSystem.buildHalo(
            key: _cloudBackupKey,
            pulseController: _coachPulseController,
            isActive: _isTutorialRunning && _activeTargetKey == 'cloud',
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('Sauvegarde cloud'),
              subtitle: FutureBuilder<String>(
                future: _getCloudProviderSubtitle(context),
                builder: (context, snapshot) {
                  if (snapshot.hasData) return Text(snapshot.data!);
                  return Text(l10n.cloudBackupSubtitle);
                },
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.pushNamed(
                context,
                CloudBackupPage.route,
                arguments: widget.auth,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Synchronisation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Row(
              children: [
                const Expanded(child: Text('Synchronisation cloud')),
                if (!PremiumService().isPremium) const PremiumBadge(),
              ],
            ),
            subtitle: const Text('Mise à jour automatique entre vos appareils'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _openSyncSettings,
          ),
        ],
      ),
    );
  }
}
