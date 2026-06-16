import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../platform/platform_capabilities.dart';
import '../services/auth_service.dart';
import '../services/auto_close_service.dart';
import '../services/premium_service.dart';
import '../services/vault_repository.dart';
import '../widgets/coach_mark_system.dart';
import 'premium_page.dart';
import 'security_report_page.dart';
import 'settings_about_support_page.dart';
import 'settings_appearance_page.dart';
import 'settings_backup_sync_page.dart';
import 'settings_security_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  static const String route = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  AuthService? _auth;
  VaultRepository? _vaultRepository;
  final _autoCloseService = AutoCloseService.instance;
  bool _isPremium = false;
  bool _startTutorial = false;
  bool _startPremiumTutorial = false;
  bool _isTutorialRunning = false;
  String? _activeTargetKey;
  late final AnimationController _coachPulseController;
  final GlobalKey _backupCardKey = GlobalKey();
  final GlobalKey _appearanceCardKey = GlobalKey();
  final GlobalKey _securityCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _coachPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _coachPulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_auth != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AuthService) {
      _auth = args;
    } else if (args is Map) {
      _auth = args['auth'] as AuthService?;
      _startTutorial = args['startTutorial'] as bool? ?? false;
      _startPremiumTutorial = args['startPremiumTutorial'] as bool? ?? false;
    }

    if (_auth != null) {
      _vaultRepository = VaultRepository(_auth!);
      _isPremium = PremiumService().isPremium;
      setState(() {});
      if (_startTutorial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _runSettingsTutorial();
        });
      } else if (_startPremiumTutorial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _runPremiumSettingsTutorial();
        });
      }
    }
  }

  Future<void> _runSettingsTutorial() async {
    setState(() { _isTutorialRunning = true; _activeTargetKey = 'security'; });
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    // Étape 1 : Sécurité
    final step1 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _securityCardKey,
      pulseController: _coachPulseController,
      title: l10n.onboardingSettingsSecurityTitle,
      message: l10n.onboardingSettingsSecurityBody,
      primaryLabel: l10n.onboardingContinue,
      secondaryLabel: l10n.onboardingSkipTutorial,
      clearFocusInset: 20.0,
      fullWidth: true,
      stepIndicator: '1 / 3',
    );

    setState(() => _activeTargetKey = null);

    if (step1 == CoachStepResult.primary && mounted && _auth != null) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SettingsSecurityPage(auth: _auth!, startTutorial: true),
      ));
    }

    if (!mounted) return;

    // Étape 2 : Apparence
    setState(() => _activeTargetKey = 'appearance');
    final step2 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _appearanceCardKey,
      pulseController: _coachPulseController,
      title: l10n.onboardingSettingsAppearanceTitle,
      message: l10n.onboardingSettingsAppearanceBody,
      primaryLabel: l10n.onboardingContinue,
      secondaryLabel: l10n.onboardingSkipTutorial,
      clearFocusInset: 20.0,
      fullWidth: true,
      stepIndicator: '2 / 3',
    );

    setState(() => _activeTargetKey = null);

    if (step2 == CoachStepResult.primary && mounted) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const SettingsAppearancePage(startTutorial: true),
      ));
    }

    if (!mounted) return;

    // Étape 3 : Sauvegarde & Synchronisation (sous-étape locale uniquement)
    setState(() => _activeTargetKey = 'backup');
    final step3 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _backupCardKey,
      pulseController: _coachPulseController,
      title: l10n.onboardingSettingsBackupTitle,
      message: l10n.onboardingSettingsBackupBody,
      primaryLabel: l10n.onboardingContinue,
      secondaryLabel: l10n.onboardingSkipTutorial,
      clearFocusInset: 20.0,
      fullWidth: true,
      stepIndicator: '3 / 3',
    );

    setState(() => _activeTargetKey = null);

    // L'étape 3 push SettingsBackupSyncPage qui gère lui-même son tutoriel
    // interne (Sauvegarde locale + Sauvegarde cloud). La phase 2 du didacticiel
    // cloud (DiscoveryTutorial.firstCloudBackup) se déclenche ensuite sur
    // CloudBackupPage quand SettingsBackupSyncPage la pousse.
    if (step3 == CoachStepResult.primary && mounted &&
        _auth != null && _vaultRepository != null) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SettingsBackupSyncPage(
          auth: _auth!,
          vaultRepository: _vaultRepository!,
          startTutorial: true,
        ),
      ));
    }

    setState(() { _isTutorialRunning = false; _activeTargetKey = null; });

    if (mounted) Navigator.pop(context);
  }

  Future<void> _runPremiumSettingsTutorial() async {
    setState(() { _isTutorialRunning = true; _activeTargetKey = 'security'; });
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    // Analyse de sécurité
    final step1 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _securityCardKey,
      pulseController: _coachPulseController,
      title: l10n.premiumTutorialSecurityTitle,
      message: l10n.premiumTutorialSecurityMessage,
      primaryLabel: l10n.onboardingContinue,
      secondaryLabel: l10n.onboardingSkipTutorial,
      clearFocusInset: 20.0,
      fullWidth: true,
      stepIndicator: '1 / 1',
    );
    setState(() => _activeTargetKey = null);
    if (step1 == CoachStepResult.primary && mounted) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const SecurityReportPage(fromTutorial: true),
        settings: RouteSettings(arguments: _auth),
      ));
    }

    setState(() { _isTutorialRunning = false; _activeTargetKey = null; });
    if (mounted) Navigator.pop(context);
  }

  void _showNeedLoginMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reconnectez-vous pour ouvrir ce menu.'),
      ),
    );
  }

  void _openSecurity() {
    if (_auth == null) {
      _showNeedLoginMessage();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsSecurityPage(auth: _auth!),
      ),
    );
  }

  void _openAppearance() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsAppearancePage(),
      ),
    );
  }

  void _openBackupSync() {
    if (_auth == null || _vaultRepository == null) {
      _showNeedLoginMessage();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsBackupSyncPage(
          auth: _auth!,
          vaultRepository: _vaultRepository!,
        ),
      ),
    );
  }

  void _openPremium() {
    Navigator.pushNamed(context, PremiumPage.route);
  }

  void _openAboutSupport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsAboutSupportPage(isPremium: _isPremium),
      ),
    );
  }
  void _openDiscoveryMode() {
    Navigator.pushNamed(
      context,
      '/discovery-tutorials',
      arguments: {
        'auth': _auth,
        if (_vaultRepository != null) 'vaultRepository': _vaultRepository,
      },
    );
  }

  void _openKeyboardShortcuts() {
    Navigator.pushNamed(context, '/keyboard-shortcuts');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _autoCloseService.onUserActivity();
          return false;
        },
        child: GestureDetector(
          onTap: () => _autoCloseService.onUserActivity(),
          onPanStart: (_) => _autoCloseService.onUserActivity(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                'Paramètres',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choisissez une rubrique pour gérer votre application simplement.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              CoachMarkSystem.buildHalo(
                key: _securityCardKey,
                pulseController: _coachPulseController,
                isActive: _isTutorialRunning && _activeTargetKey == 'security',
                borderRadius: BorderRadius.circular(12),
                child: _SectionCard(
                  title: 'Sécurité',
                  onTap: _openSecurity,
                ),
              ),
              CoachMarkSystem.buildHalo(
                key: _appearanceCardKey,
                pulseController: _coachPulseController,
                isActive: _isTutorialRunning && _activeTargetKey == 'appearance',
                borderRadius: BorderRadius.circular(12),
                child: _SectionCard(
                  title: 'Apparence',
                  onTap: _openAppearance,
                ),
              ),
              CoachMarkSystem.buildHalo(
                key: _backupCardKey,
                pulseController: _coachPulseController,
                isActive: _isTutorialRunning && _activeTargetKey == 'backup',
                borderRadius: BorderRadius.circular(12),
                child: _SectionCard(
                  title: 'Sauvegarde & Synchronisation',
                  onTap: _openBackupSync,
                ),
              ),
              _SectionCard(
                title: 'Premium',
                onTap: _openPremium,
              ),
              _SectionCard(
                title: l10n.discoveryModeTitle,
                onTap: _openDiscoveryMode,
              ),
              if (isDesktop)
                _SectionCard(
                  title: 'Raccourcis clavier',
                  onTap: _openKeyboardShortcuts,
                ),
              _SectionCard(
                title: 'À propos et support',
                onTap: _openAboutSupport,
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
