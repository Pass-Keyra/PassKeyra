import 'package:flutter/material.dart';

import '../app/app.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../services/premium_service.dart';
import '../services/theme_service.dart';
import '../widgets/coach_mark_system.dart';
import '../widgets/premium_badge.dart';
import 'manage_categories_page.dart';
import 'premium_page.dart';

class SettingsAppearancePage extends StatefulWidget {
  const SettingsAppearancePage({super.key, this.startTutorial = false});
  final bool startTutorial;

  @override
  State<SettingsAppearancePage> createState() => _SettingsAppearancePageState();
}

class _SettingsAppearancePageState extends State<SettingsAppearancePage>
    with SingleTickerProviderStateMixin {
  // Tutorial
  late final AnimationController _coachPulseController;
  bool _isTutorialRunning = false;
  String? _activeTargetKey;
  final _languageKey = GlobalKey();
  final _themeKey = GlobalKey();
  final _categoriesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _coachPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    if (widget.startTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runAppearanceTutorial();
      });
    }
  }

  @override
  void dispose() {
    _coachPulseController.dispose();
    super.dispose();
  }

  Future<void> _runAppearanceTutorial() async {
    setState(() => _isTutorialRunning = true);
    final l10n = AppLocalizations.of(context)!;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Étape 1 : Langue
    setState(() => _activeTargetKey = 'language');
    final step1 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _languageKey,
      pulseController: _coachPulseController,
      title: l10n.language,
      message: l10n.languageSubtitle,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      clearFocusInset: 20.0,
      stepIndicator: '1 / 3',
    );

    if (step1 != CoachStepResult.primary || !mounted) {
      setState(() {
        _isTutorialRunning = false;
        _activeTargetKey = null;
      });
      return;
    }

    // Étape 2 : Thème
    setState(() => _activeTargetKey = 'theme');
    final step2 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _themeKey,
      pulseController: _coachPulseController,
      title: l10n.theme,
      message: "Changez le mode d'affichage (clair, sombre ou système) et choisissez votre police de caractères. Plus de polices disponibles avec Premium.",
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '2 / 3',
    );

    if (step2 != CoachStepResult.primary || !mounted) {
      setState(() {
        _isTutorialRunning = false;
        _activeTargetKey = null;
      });
      return;
    }

    // Étape 3 : Catégories
    setState(() => _activeTargetKey = 'categories');
    await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _categoriesKey,
      pulseController: _coachPulseController,
      title: l10n.customCategories,
      message: l10n.customCategoriesSubtitle,
      primaryLabel: l10n.onboardingFinish,
      stepIndicator: '3 / 3',
    );

    setState(() {
      _isTutorialRunning = false;
      _activeTargetKey = null;
    });
    if (mounted) Navigator.pop(context);
  }
  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption('fr', l10n.french, 'FR'),
            _languageOption('en', l10n.english, 'EN'),
            _languageOption('es', l10n.spanish, 'ES'),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String code, String label, String prefix) {
    return RadioListTile<String>(
      title: Text('$prefix - $label'),
      value: code,
      groupValue: LanguageService().currentLocale.languageCode,
      onChanged: (value) async {
        if (value == null) return;
        await LanguageService().setLanguageByCode(value);
        if (!mounted) return;
        Navigator.pop(context);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.languageChanged),
            backgroundColor: PassKeyraColors.success,
          ),
        );
      },
    );
  }

  void _showThemeDialog() {
    final l10n = AppLocalizations.of(context)!;
    final themeService = ThemeService();
    final premiumService = PremiumService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectTheme),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.fontFamily, style: const TextStyle(fontWeight: FontWeight.bold)),
              _fontOption(themeService, premiumService, FontFamily.roboto, l10n.fontRoboto),
              _fontOption(themeService, premiumService, FontFamily.lato, l10n.fontLato),
              _fontOption(themeService, premiumService, FontFamily.montserrat, l10n.fontMontserrat),
              _fontOption(themeService, premiumService, FontFamily.openSans, l10n.fontOpenSans),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(l10n.themeMode, style: const TextStyle(fontWeight: FontWeight.bold)),
              RadioListTile<ThemeMode>(
                title: Text(l10n.lightMode),
                value: ThemeMode.light,
                groupValue: themeService.themeMode,
                onChanged: (value) async {
                  if (value == null) return;
                  await themeService.setThemeMode(value);
                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.darkMode),
                value: ThemeMode.dark,
                groupValue: themeService.themeMode,
                onChanged: (value) async {
                  if (value == null) return;
                  await themeService.setThemeMode(value);
                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.systemMode),
                value: ThemeMode.system,
                groupValue: themeService.themeMode,
                onChanged: (value) async {
                  if (value == null) return;
                  await themeService.setThemeMode(value);
                  if (!mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _fontOption(
    ThemeService themeService,
    PremiumService premiumService,
    FontFamily value,
    String label,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isPremiumChoice = value != FontFamily.roboto;
    return RadioListTile<FontFamily>(
      title: Row(
        children: [
          Expanded(child: Text(label)),
          if (isPremiumChoice && !premiumService.isPremium) const PremiumBadge(),
        ],
      ),
      value: value,
      groupValue: themeService.fontFamily,
      onChanged: (selected) async {
        if (selected == null) return;
        if (isPremiumChoice && !premiumService.isPremium) {
          Navigator.pop(context);
          _showPremiumDialog(l10n.fontFamilyPremiumFeature);
          return;
        }
        await themeService.setFontFamily(selected);
        if (!mounted) return;
        Navigator.pop(context);
        setState(() {});
      },
    );
  }

  void _showPremiumDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    showPremiumLockedDialog(
      context,
      featureName: l10n.premium,
      customMessage: message,
    );
  }

  String _themeSummary(AppLocalizations l10n) {
    final mode = ThemeService().themeMode;
    if (mode == ThemeMode.light) return l10n.lightMode;
    if (mode == ThemeMode.dark) return l10n.darkMode;
    return l10n.systemMode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Apparence')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CoachMarkSystem.buildHalo(
            key: _languageKey,
            pulseController: _coachPulseController,
            isActive: _isTutorialRunning && _activeTargetKey == 'language',
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.language),
              subtitle: Text(l10n.languageSubtitle),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showLanguageDialog,
            ),
          ),
          CoachMarkSystem.buildHalo(
            key: _themeKey,
            pulseController: _coachPulseController,
            isActive: _isTutorialRunning && _activeTargetKey == 'theme',
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text(l10n.theme),
              subtitle: Text(_themeSummary(l10n)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showThemeDialog,
            ),
          ),
          CoachMarkSystem.buildHalo(
            key: _categoriesKey,
            pulseController: _coachPulseController,
            isActive: _isTutorialRunning && _activeTargetKey == 'categories',
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: Text(l10n.customCategories),
              subtitle: Text(l10n.customCategoriesSubtitle),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.pushNamed(context, ManageCategoriesPage.route),
            ),
          ),
        ],
      ),
    );
  }
}
