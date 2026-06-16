import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../platform/platform_capabilities.dart';
import '../app/keyboard_shortcuts.dart';
import '../widgets/keyboard_shortcut_hint.dart';
import '../models/password_entry.dart';
import '../models/custom_category.dart';
import '../models/sync_state.dart';
import '../services/auth_service.dart';
import '../services/vault_repository.dart';
import '../services/sync_coordinator_service.dart';
import '../services/secure_clipboard_service.dart';
import '../services/ad_service.dart';
import '../services/auto_close_service.dart';
import '../services/category_service.dart';
import '../services/onboarding_service.dart';
import '../services/review_service.dart';
import '../services/premium_service.dart';
import 'cloud_backup_page.dart';
import 'edit_entry_page.dart';
import 'view_entry_page.dart';
import 'settings_page.dart';
import 'import_export_page.dart';
import 'login_page.dart';
import 'premium_page.dart';
import '../app/app.dart';
import '../app/page_actions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static const String route = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _OverlayExcludeClipper extends CustomClipper<Path> {
  final Rect excludedRect;
  final double borderRadius;

  const _OverlayExcludeClipper({
    required this.excludedRect,
    required this.borderRadius,
  });

  @override
  Path getClip(Size size) {
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          excludedRect,
          Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, full, hole);
  }

  @override
  bool shouldReclip(covariant _OverlayExcludeClipper oldClipper) {
    return oldClipper.excludedRect != excludedRect ||
        oldClipper.borderRadius != borderRadius;
  }
}

enum _CoachStepResult { primary, skip, finish }
enum _CoachTarget { search, sort, categories, add, copyAll, settings, copyPassword, firstEntryCard }

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, RouteAware {
  late final VaultRepository _repo;
  // Nullable : sur Windows V1, Firebase n'est pas configuré et l'instantiation
  // de SyncCoordinatorService crashe. La sync cloud arrive en Phase 5.
  SyncCoordinatorService? _syncCoordinator;
  late final AuthService _authService;
  final _categoryService = CategoryService();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<PasswordEntry> _all = <PasswordEntry>[];
  List<PasswordEntry> _filtered = <PasswordEntry>[];
  String _sort = 'date_desc';
  String? _selectedCategory; // null = toutes les catégories
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  List<CustomCategory> _categories = [];
  final GlobalKey _searchBarKey = GlobalKey();
  final GlobalKey _sortButtonKey = GlobalKey();
  final GlobalKey _categoryChipsKey = GlobalKey();
  final GlobalKey _settingsButtonKey = GlobalKey();
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey _copyAllButtonKey      = GlobalKey();
  final GlobalKey _copyPasswordButtonKey = GlobalKey();
  final GlobalKey _firstEntryCardKey     = GlobalKey();
  bool _isTutorialRunning = false;
  bool _depsInitialized = false;
  bool _authReady = false;
  late final AnimationController _coachPulseController;
  _CoachTarget? _activeCoachTarget;
  // Obtenir la couleur d'une catégorie par son nom
  Color getCategoryColor(String? categoryName) {
    if (categoryName == null) return const Color(0xFF607D8B);

    final category = _categories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => _categoryService.getOtherCategory(),
    );

    return category.color;
  }

  // Obtenir l'icône d'une catégorie par son nom
  IconData getCategoryIcon(String? categoryName) {
    if (categoryName == null) return Icons.category;

    final category = _categories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => _categoryService.getOtherCategory(),
    );

    return category.icon;
  }

  // Vérifier si une catégorie utilise un emoji
  bool categoryHasEmoji(String? categoryName) {
    if (categoryName == null) return false;

    final category = _categories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => _categoryService.getOtherCategory(),
    );

    return category.isEmoji;
  }

  // Obtenir l'emoji d'une catégorie par son nom
  String? getCategoryEmoji(String? categoryName) {
    if (categoryName == null) return null;

    final category = _categories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => _categoryService.getOtherCategory(),
    );

    return category.emoji;
  }

  // Vérifier si une catégorie a une forme ronde
  bool categoryIsRound(String? categoryName) {
    // Toujours rond pour les cartes HomePage
    return true;
  }

  @override
  void initState() {
    super.initState();
    _coachPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _searchController.addListener(_applyFilters);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);

    // ModalRoute.of(context) n'est pas autorisé dans initState (assert Flutter
    // strict sur desktop). L'init dépendante du contexte vit ici, derrière un
    // guard pour ne s'exécuter qu'une fois.
    if (_depsInitialized) return;
    _depsInitialized = true;

    final auth = route?.settings.arguments as AuthService?;
    if (auth == null) {
      // Différé après le frame courant pour éviter un push pendant le build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(LoginPage.route);
        }
      });
      return;
    }
    _authService = auth;
    _repo = VaultRepository(auth);
    // Sync cloud : Mobile uniquement en V1. Phase 5 du plan desktop activera
    // FlutterFire Windows et instanciera ce service côté desktop aussi.
    if (supportsCloudSync) {
      _syncCoordinator = SyncCoordinatorService(
        authService: auth,
        vaultRepository: _repo,
      );
    }
    _authReady = true;

    // Enregistrer les actions HomePage pour les raccourcis clavier globaux
    // (Ctrl+N, Ctrl+F dans PassKeyraAppShell). Désenregistré dans dispose().
    HomePageActions.instance.newEntry.value = _checkLimitAndAdd;
    HomePageActions.instance.focusSearch.value = _searchFocusNode.requestFocus;

    _categoryService.addListener(_loadCategories);
    _loadCategories();
    _loadSortPreference();
    _load();

    // Charger la bannière avec un petit délai pour s'assurer qu'AdMob est initialisé
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _loadBannerAd();
    });

    // Tâches non critiques différées après le 1ᵉʳ paint pour ne pas freiner
    // l'affichage initial de la home page (Firebase Auth restore + lecture
    // multi-couches du statut sync peuvent consommer du CPU).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCoordinator?.initialize();
      _checkAndStartOnboardingTutorial();
      _checkAndStartPremiumTutorial();
      // Re-keying multi-device (Option C) : vérifier si un autre appareil
      // a changé le mdp maître. Différé pour ne pas bloquer le 1ᵉʳ paint.
      Future.delayed(const Duration(seconds: 2), _checkCrossDeviceKeyChange);
    });
  }

  /// Vérifie si la clé de session locale correspond au fingerprint stocké
  /// côté Firestore. Si mismatch → un autre appareil a changé le mot de
  /// passe maître depuis ce coffre. Affiche un dialog d'alerte avec
  /// invitation à réimporter la dernière sauvegarde.
  ///
  /// Si pas de fingerprint cloud → on push le local (1ʳᵉ activation sync).
  ///
  /// No-op si Firestore pas activé / pas Premium / pas signed in.
  Future<void> _checkCrossDeviceKeyChange() async {
    if (!mounted) return;
    final sync = _syncCoordinator;
    if (sync == null) return;
    try {
      final firebaseAuth = sync.firebaseAuthService;
      if (!firebaseAuth.isSignedIn) return;
      final enabled = await sync.firebaseSyncService.isSyncEnabled();
      if (!enabled) return;

      final cloudFingerprint = await sync.firebaseSyncService.getCloudKeyFingerprint();
      final localFingerprint = sync.firebaseSyncService.computeLocalKeyFingerprint();
      if (localFingerprint == null) return;

      if (cloudFingerprint == null) {
        // 1ʳᵉ activation : on publie notre fingerprint pour les autres devices.
        await sync.firebaseSyncService.uploadKeyFingerprint();
        return;
      }

      if (cloudFingerprint != localFingerprint && mounted) {
        await _showCrossDeviceKeyChangedDialog();
      }
    } catch (_) {
      // Best effort, ne jamais faire crasher l'app sur cette vérification.
    }
  }

  Future<void> _showCrossDeviceKeyChangedDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            size: 48, color: PassKeyraColors.warning),
        title: Text(l10n.crossDeviceKeyChangedTitle),
        content: Text(l10n.crossDeviceKeyChangedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.crossDeviceKeyChangedLater),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ImportExportPage.route,
                  arguments: _authService);
            },
            child: Text(l10n.masterPasswordChangeSeeBackups),
          ),
        ],
      ),
    );
  }

  @override
  void didPopNext() {
    // Appelé quand une page empilée au-dessus est dépilée (retour sur HomePage).
    // Garde : si la chaîne du tutoriel est encore en cours (await sur la page
    // dépilée), ne pas relancer — sinon on déclenche une boucle infinie.
    if (_isTutorialRunning) return;
    _checkAndStartOnboardingTutorial();
    _checkAndStartPremiumTutorial();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categories = _categoryService.getAllCategories();
    });
  }
  
  Future<void> _loadSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSort = prefs.getString('sort_preference') ?? 'date_desc';
    setState(() => _sort = savedSort);
  }
  
  Future<void> _saveSortPreference(String sort) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sort_preference', sort);
  }

  /// Gère le pull-to-refresh pour forcer la synchronisation
  Future<void> _handlePullToRefresh() async {
    try {
      // Forcer la synchronisation depuis le cloud
      await _syncCoordinator?.forceSyncFromCloud();

      // Recharger les entrées locales
      await _load();
    } catch (e) {
      debugPrint('HomePage - Erreur pull-to-refresh: $e');
    }
  }

  void _loadBannerAd() async {
    debugPrint('Tentative de chargement bannière pub...');
    debugPrint('isPremium: ${AdService.instance.isPremium}');

    _bannerAd = await AdService.instance.createBannerAd();
    if (_bannerAd != null) {
      debugPrint('Bannière créée, chargement en cours...');
      _bannerAd!.load().then((_) {
        debugPrint('Bannière publicitaire chargée avec succès!');
        if (mounted) {
          setState(() => _isBannerAdLoaded = true);
          debugPrint('État mis à jour: _isBannerAdLoaded = true');
        }
      }).catchError((error) {
        debugPrint('Erreur chargement pub: $error');
        debugPrint('Type d\'erreur: ${error.runtimeType}');
      });
    } else {
      debugPrint('Mode Premium ou Consentement refusé - Pas de pub');
    }
  }

  Future<void> _checkAndStartOnboardingTutorial({bool force = false}) async {
    if (!mounted || _isTutorialRunning) return;

    if (force) {
      await OnboardingService.instance.requestPostVaultReplay();
    }

    final shouldStart =
        await OnboardingService.instance.consumeShouldShowPostVaultTutorial();
    if (!shouldStart || !mounted) return;

    _isTutorialRunning = true;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      _isTutorialRunning = false;
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    // Étape 1 : Recherche
    final step1 = await _showCoachStep(
      targetKey: _searchBarKey,
      title: l10n.onboardingStepSearchTitle,
      message: l10n.onboardingStepSearchBody,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '1 / 5',
      shortcut: AppShortcut.search,
    );
    if (step1 != _CoachStepResult.primary || !mounted) {
      // Quitter = sortir de TOUS les tutoriels (y compris premium, firstEntry,
      // etc. qui pourraient se déclencher automatiquement plus tard).
      await OnboardingService.instance.quitAllTutorials();
      _isTutorialRunning = false;
      return;
    }

    // Étape 2 : Tri
    final step2 = await _showCoachStep(
      targetKey: _sortButtonKey,
      title: l10n.onboardingStepSortTitle,
      message: l10n.onboardingStepSortBody,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '2 / 5',
    );
    if (step2 != _CoachStepResult.primary || !mounted) {
      // Quitter = sortir de TOUS les tutoriels (y compris premium, firstEntry,
      // etc. qui pourraient se déclencher automatiquement plus tard).
      await OnboardingService.instance.quitAllTutorials();
      _isTutorialRunning = false;
      return;
    }

    // Étape 3 : Catégories
    final step3 = await _showCoachStep(
      targetKey: _categoryChipsKey,
      title: l10n.onboardingStepCategoriesTitle,
      message: l10n.onboardingStepCategoriesBody,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '3 / 5',
    );
    if (step3 != _CoachStepResult.primary || !mounted) {
      // Quitter = sortir de TOUS les tutoriels (y compris premium, firstEntry,
      // etc. qui pourraient se déclencher automatiquement plus tard).
      await OnboardingService.instance.quitAllTutorials();
      _isTutorialRunning = false;
      return;
    }

    // Étape 4 : Ajouter une entrée
    final step4 = await _showCoachStep(
      targetKey: _addButtonKey,
      title: l10n.onboardingStepAddTitle,
      message: l10n.onboardingStepAddBody,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '4 / 5',
      shortcut: AppShortcut.newEntry,
    );
    if (step4 != _CoachStepResult.primary || !mounted) {
      // Quitter = sortir de TOUS les tutoriels (y compris premium, firstEntry,
      // etc. qui pourraient se déclencher automatiquement plus tard).
      await OnboardingService.instance.quitAllTutorials();
      _isTutorialRunning = false;
      return;
    }

    // Étape 5 : Paramètres
    final step6 = await _showCoachStep(
      targetKey: _settingsButtonKey,
      title: l10n.onboardingStepSettingsTitle,
      message: l10n.onboardingStepSettingsBody,
      primaryLabel: l10n.onboardingContinue,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '5 / 5',
    );

    if (step6 != _CoachStepResult.primary || !mounted) {
      _isTutorialRunning = false;
      await OnboardingService.instance.quitAllTutorials();
      return;
    }

    // Marquer terminé AVANT la navigation : évite que didPopNext relance
    // le tutoriel quand SettingsPage est dépilée plus tard dans la chaîne.
    await OnboardingService.instance.markTutorialCompleted();

    // Paramètres enchaîne Sauvegarde & Sync → Apparence → Sécurité.
    // _isTutorialRunning reste à true pour bloquer didPopNext pendant
    // toute la chaîne async settings → cloud → retour.
    await Navigator.pushNamed(
      context,
      SettingsPage.route,
      arguments: {'auth': _authService, 'startTutorial': true},
    );

    if (!mounted) {
      _isTutorialRunning = false;
      return;
    }

    // Dialogue de fin : 2 variantes selon que l'user a quitté ou complété.
    final hasQuit = OnboardingService.instance.userQuitInCurrentSession;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          hasQuit ? Icons.info_outline : Icons.check_circle,
          size: 48,
          color: hasQuit ? PassKeyraColors.info : Colors.green,
        ),
        title: Text(hasQuit ? l10n.onboardingQuitTitle : l10n.onboardingFinish),
        content: Text(
          hasQuit ? l10n.onboardingQuitMessage : l10n.onboardingCompleteMessage,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    _isTutorialRunning = false;
  }

  Future<void> _checkAndStartPremiumTutorial() async {
    if (!mounted || _isTutorialRunning) return;
    final shouldStart =
        await OnboardingService.instance.consumeShouldShowPremiumTutorial();
    if (!shouldStart || !mounted) return;
    // Defense-in-depth : si l'utilisateur a déjà complété ce tutoriel
    // (Discovery flag), on ne le relance jamais — même si un bug réarmait
    // le pending flag. Rejouable manuellement depuis le Mode Découverte.
    final alreadyDone = await OnboardingService.instance
        .isDiscoveryCompleted(DiscoveryTutorial.premium);
    if (alreadyDone || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _runPremiumTutorialFlow();
  }

  Future<void> _runPremiumTutorialFlow() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    // Intro
    final start = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.workspace_premium, size: 48),
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

    if (start != true || !mounted) {
      await OnboardingService.instance.markDiscoveryCompleted(DiscoveryTutorial.premium);
      return;
    }

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

    // Fonctionnalités 2 & 3 : coach marks dans EditEntryPage
    final entry = _all.isNotEmpty ? _all.first : null;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditEntryPage(entry: entry, startTutorial: true),
      ),
    );

    if (!mounted) return;

    // Fonctionnalité 4 / 7 : Analyse de sécurité avancée
    await Navigator.pushNamed(
      context,
      '/settings',
      arguments: {
        'startPremiumTutorial': true,
        'auth': _authService,
      },
    );

    if (!mounted) return;

    // Fonctionnalité 5 / 7 : Synchronisation temps réel
    await Navigator.pushNamed(
      context,
      '/cloud-sync-settings',
      arguments: {
        'authService': _authService,
        'vaultRepository': _repo,
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

    // Fonctionnalité 7 : coach mark sauvegarde locale automatique
    await Navigator.pushNamed(
      context,
      ImportExportPage.route,
      arguments: {
        'authService': _authService,
        'startTutorialAutoBackup': true,
      },
    );

    if (!mounted) return;

    // Confirmation finale
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

    if (mounted) {
      await OnboardingService.instance.markDiscoveryCompleted(DiscoveryTutorial.premium);
    }
  }

  Future<_CoachStepResult> _showCoachStep({
    required GlobalKey targetKey,
    required String title,
    required String message,
    required String primaryLabel,
    String? secondaryLabel,
    String? stepIndicator,
    AppShortcut? shortcut,
  }) async {
    // Court-circuit global : si l'user a cliqué Quitter sur un coach mark
    // précédent, on retourne skip immédiatement sans afficher de dialog.
    if (OnboardingService.instance.userQuitInCurrentSession) {
      return _CoachStepResult.skip;
    }
    final targetContext = targetKey.currentContext;
    final l10n = AppLocalizations.of(context)!;
    final coachTarget = _coachTargetForKey(targetKey);
    Rect? targetRect;
    Rect? clearFocusRect;
    double clearFocusRadius = 18;

    if (coachTarget != null && mounted) {
      setState(() => _activeCoachTarget = coachTarget);
    }
    if (targetContext == null) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (secondaryLabel != null)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(secondaryLabel),
              ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(primaryLabel),
            ),
          ],
        ),
      );
      if (mounted) {
        setState(() => _activeCoachTarget = null);
      }
      return result == true ? _CoachStepResult.primary : _CoachStepResult.skip;
    }

    final renderBox = targetContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      if (mounted) {
        setState(() => _activeCoachTarget = null);
      }
      return _CoachStepResult.skip;
    }

    final overlayRenderBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlayRenderBox != null) {
      final targetTopLeft =
          renderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
      final rawRect = Rect.fromLTWH(
        targetTopLeft.dx,
        targetTopLeft.dy,
        renderBox.size.width,
        renderBox.size.height,
      );
      targetRect = rawRect;
      // Fenêtre claire dynamique (avec limites), pour suivre la cible
      // sans effet grossier ni zone trop courte.
      final baseInset = coachTarget == _CoachTarget.search
          ? (rawRect.height * 0.22).clamp(8.0, 14.0).toDouble()
          : (rawRect.longestSide * 0.30).clamp(10.0, 16.0).toDouble();
      clearFocusRect = rawRect.inflate(baseInset);
      clearFocusRadius = coachTarget == _CoachTarget.search ? 14 : 34;
    }

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'coach',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final screenSize = MediaQuery.of(dialogContext).size;
        final anchorRect = targetRect == null
            ? null
            : Rect.fromLTWH(
                targetRect.left.clamp(0.0, screenSize.width).toDouble(),
                targetRect.top.clamp(0.0, screenSize.height).toDouble(),
                targetRect.width.clamp(0.0, screenSize.width).toDouble(),
                targetRect.height.clamp(0.0, screenSize.height).toDouble(),
              );
        final focusRect = clearFocusRect == null
            ? null
            : Rect.fromLTWH(
                clearFocusRect.left.clamp(0.0, screenSize.width).toDouble(),
                clearFocusRect.top.clamp(0.0, screenSize.height).toDouble(),
                clearFocusRect.width
                    .clamp(0.0, screenSize.width)
                    .toDouble(),
                clearFocusRect.height
                    .clamp(0.0, screenSize.height)
                    .toDouble(),
              );
        const horizontalMargin = 12.0;
        const verticalMargin = 16.0;
        const targetSpacing = 12.0;
        const estimatedCardHeight = 168.0;
        final cardWidth =
            (screenSize.width * 0.78).clamp(250.0, 330.0).toDouble();
        final placeAboveTarget = anchorRect == null
            ? coachTarget == _CoachTarget.add
            : anchorRect.center.dy > (screenSize.height * 0.52);
        final cardTop = anchorRect == null
            ? (placeAboveTarget
                ? verticalMargin
                : (screenSize.height - estimatedCardHeight - verticalMargin))
            : (placeAboveTarget
                ? anchorRect.top - estimatedCardHeight - targetSpacing
                : anchorRect.bottom + targetSpacing);
        final clampedCardTop = cardTop
            .clamp(
              verticalMargin,
              screenSize.height - estimatedCardHeight - verticalMargin,
            )
            .toDouble();
        final rawCardLeft = anchorRect == null
            ? ((screenSize.width - cardWidth) / 2)
            : (anchorRect.center.dx - (cardWidth / 2));
        final clampedCardLeft = rawCardLeft
            .clamp(
              horizontalMargin,
              screenSize.width - cardWidth - horizontalMargin,
            )
            .toDouble();
        return Stack(
          fit: StackFit.expand,
          children: [
            // Desktop : overlay opaque (BackdropFilter + blur = GPU killer Windows).
            // Mobile : BackdropFilter blur léger (visuel fin, GPU OK).
            if (focusRect != null)
              ClipPath(
                clipper: _OverlayExcludeClipper(
                  excludedRect: focusRect,
                  borderRadius: clearFocusRadius,
                ),
                child: isDesktop
                    ? Container(color: Colors.black.withValues(alpha: 0.35))
                    : BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
              )
            else if (isDesktop)
              Container(color: Colors.black.withValues(alpha: 0.35))
            else
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
            Positioned(
              top: clampedCardTop,
              left: clampedCardLeft,
              width: cardWidth,
              child: AnimatedBuilder(
                animation: _coachPulseController,
                builder: (context, child) {
                  final pulse = _coachPulseController.value;
                  final glowAlpha = 0.18 + (pulse * 0.2);
                  final blurRadius = 14.0 + (pulse * 12.0);
                  final spreadRadius = 0.8 + (pulse * 1.6);
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: PassKeyraColors.primary.withValues(
                            alpha: glowAlpha,
                          ),
                          blurRadius: blurRadius,
                          spreadRadius: spreadRadius,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Material(
                  color: Colors.transparent,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: PassKeyraColors.primary.withValues(alpha: 0.45),
                        width: 1.4,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: Theme.of(dialogContext)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: PassKeyraColors.primary,
                                      ),
                                ),
                              ),
                              if (stepIndicator != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: PassKeyraColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    stepIndicator,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: PassKeyraColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message,
                            style: Theme.of(dialogContext).textTheme.bodySmall,
                          ),
                          if (isDesktop && shortcut != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Raccourci : ',
                                  style: Theme.of(dialogContext).textTheme.bodySmall,
                                ),
                                KeyboardShortcutHint(shortcut: shortcut),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final maxPrimaryWidth =
                                  (constraints.maxWidth * 0.68)
                                      .clamp(160.0, 240.0)
                                      .toDouble();
                              return Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (secondaryLabel != null)
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(false),
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      child: Text(secondaryLabel),
                                    ),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: maxPrimaryWidth,
                                    ),
                                    child: FilledButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(true),
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
                                      child: Text(
                                        primaryLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );
    if (mounted) {
      setState(() => _activeCoachTarget = null);
    }

    if (result == true) {
      return _CoachStepResult.primary;
    }
    if (secondaryLabel == l10n.onboardingFinish) {
      return _CoachStepResult.finish;
    }
    return _CoachStepResult.skip;
  }

  _CoachTarget? _coachTargetForKey(GlobalKey key) {
    if (identical(key, _searchBarKey)) return _CoachTarget.search;
    if (identical(key, _sortButtonKey)) return _CoachTarget.sort;
    if (identical(key, _categoryChipsKey)) return _CoachTarget.categories;
    if (identical(key, _settingsButtonKey)) return _CoachTarget.settings;
    if (identical(key, _addButtonKey)) return _CoachTarget.add;
    if (identical(key, _copyAllButtonKey)) return _CoachTarget.copyAll;
    if (identical(key, _copyPasswordButtonKey)) return _CoachTarget.copyPassword;
    if (identical(key, _firstEntryCardKey)) return _CoachTarget.firstEntryCard;
    return null;
  }

  bool _isCoachTargetActive(_CoachTarget target) =>
      _isTutorialRunning && _activeCoachTarget == target;

  Widget _buildCoachHalo({
    required Widget child,
    required _CoachTarget target,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
    bool includeBorder = false,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    // Desktop : halo statique (mêmes raisons qu'avec CoachMarkSystem.buildHalo,
    // BoxShadow blur animé à 60fps = GPU saturé sur Windows).
    if (isDesktop) {
      final active = _isCoachTargetActive(target);
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
          border: includeBorder && active
              ? Border.all(
                  color: PassKeyraColors.primary.withValues(alpha: 0.65),
                  width: 1.4,
                )
              : null,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: PassKeyraColors.primary.withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : const [],
        ),
        child: child,
      );
    }
    return AnimatedBuilder(
      animation: _coachPulseController,
      child: child,
      builder: (context, childWidget) {
        final active = _isCoachTargetActive(target);
        final pulse = _coachPulseController.value;
        final glowAlpha = active ? (0.25 + (pulse * 0.35)) : 0.0;
        final blurRadius = active ? (12.0 + (pulse * 12.0)) : 0.0;
        final spreadRadius = active ? (1.0 + (pulse * 2.0)) : 0.0;
        final scale = active ? (1.0 + (pulse * 0.015)) : 1.0;
        return AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              shape: shape,
              borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
              border: includeBorder && active
                  ? Border.all(
                      color: PassKeyraColors.primary.withValues(alpha: 0.65),
                      width: 1.4,
                    )
                  : null,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: PassKeyraColors.primary.withValues(alpha: glowAlpha),
                        blurRadius: blurRadius,
                        spreadRadius: spreadRadius,
                      ),
                    ]
                  : const [],
            ),
            child: childWidget,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _categoryService.removeListener(_loadCategories);
    _searchController.dispose();
    _searchFocusNode.dispose();
    // Libérer les actions du bus global (les autres pages n'en ont pas besoin).
    if (HomePageActions.instance.newEntry.value == _checkLimitAndAdd) {
      HomePageActions.instance.newEntry.value = null;
    }
    if (HomePageActions.instance.focusSearch.value == _searchFocusNode.requestFocus) {
      HomePageActions.instance.focusSearch.value = null;
    }
    _bannerAd?.dispose();
    _syncCoordinator?.dispose();
    _coachPulseController.dispose();
    super.dispose();
  }

  // Persist via SyncCoordinator si dispo (mobile), sinon directement via _repo
  // (Windows V1 sans Firebase). La sauvegarde locale est toujours faite.
  Future<void> _persistAll() async {
    final sync = _syncCoordinator;
    if (sync != null) {
      await sync.saveAll(_all);
    } else {
      await _repo.saveAll(_all);
    }
  }

  Future<void> _persistDelete(String id) async {
    final sync = _syncCoordinator;
    if (sync != null) {
      await sync.delete(id);
    } else {
      _all.removeWhere((e) => e.id == id);
      await _repo.saveAll(_all);
    }
  }

  Future<void> _load() async {
    try {
      final items = await _repo.readAll();
      setState(() {
        _all = items;
        _applyFilters();
      });
    } catch (e) {
      // Erreur de déchiffrement = mauvais mot de passe
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.incorrectMasterPassword),
            backgroundColor: PassKeyraColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        // Retourner à la page de connexion
        Navigator.of(context).pushReplacementNamed(LoginPage.route);
      }
    }
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    var list = _all.where((e) {
      // Si la recherche est active, chercher dans TOUTES les catégories
      if (q.isNotEmpty) {
        return e.name.toLowerCase().contains(q) ||
            e.username.toLowerCase().contains(q) ||
            (e.url ?? '').toLowerCase().contains(q) ||
            e.tags.any((t) => t.toLowerCase().contains(q));
      }

      // Si pas de recherche, filtrer par catégorie si une catégorie est sélectionnée
      if (_selectedCategory != null && e.category != _selectedCategory) {
        return false;
      }

      return true;
    }).toList();

    switch (_sort) {
      case 'name_asc':
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'date_asc':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'date_desc':
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    setState(() => _filtered = list);
  }

  Future<void> _checkLimitAndAdd() async {
    // Version gratuite avec mots de passe illimités
    await _addOrEdit();
  }

  Future<void> _viewEntry(PasswordEntry entry) async {
    // Ouvrir la page de visualisation (lecture seule)
    final result = await Navigator.of(context).push<PasswordEntry>(
      MaterialPageRoute(builder: (_) => ViewEntryPage(entry: entry)),
    );
    if (result != null) {
      // upsert si modifié
      final idx = _all.indexWhere((e) => e.id == result.id);
      if (idx >= 0) {
        _all[idx] = result;
      }
      await _persistAll();
      _applyFilters();
    }
  }
  
  Future<void> _addOrEdit([PasswordEntry? entry]) async {
    final result = await Navigator.of(context).push<PasswordEntry>(
      MaterialPageRoute(builder: (_) => EditEntryPage(entry: entry)),
    );
    if (result != null) {
      // upsert
      final idx = _all.indexWhere((e) => e.id == result.id);
      final isNewEntry = idx < 0;
      if (idx >= 0) {
        _all[idx] = result;
      } else {
        _all.add(result);
      }
      await _persistAll();
      _applyFilters();

      // Si c'est une nouvelle entrée, incrémenter le compteur et vérifier si on doit demander un avis
      if (isNewEntry) {
        await ReviewService().incrementPasswordCount();
        // Vérifier et demander un avis si les conditions sont remplies
        final reviewRequested = await ReviewService().checkAndRequestReview();
        if (reviewRequested) {
          debugPrint('HomePage - Demande d\'avis envoyée à l\'utilisateur');
        }

        // Vérifier si la Phase 2 du tutoriel première entrée doit démarrer
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _checkAndStartFirstEntryPhase2();
          });
        }
      }
    }
  }

  Future<void> _checkAndStartFirstEntryPhase2() async {
    if (!mounted || _isTutorialRunning) return;
    final should = await OnboardingService.instance.consumeShouldShowFirstEntryPhase2();
    if (!should || !mounted) return;
    _isTutorialRunning = true;
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) await _runFirstEntryTutorialPhase2();
  }

  Future<void> _runFirstEntryTutorialPhase2() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    // Step 11 — La carte est affichée
    setState(() => _activeCoachTarget = _CoachTarget.firstEntryCard);
    final r11 = await _showCoachStep(
      targetKey: _firstEntryCardKey,
      title: l10n.firstEntryTutorialCardTitle,
      message: l10n.firstEntryTutorialCardMessage,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '1 / 4',
    );
    if (r11 != _CoachStepResult.primary || !mounted) {
      await OnboardingService.instance.quitAllTutorials();
      await _finishFirstEntryTutorial();
      return;
    }

    // Step 12 — Copier uniquement le mot de passe
    setState(() => _activeCoachTarget = _CoachTarget.copyPassword);
    final r12 = await _showCoachStep(
      targetKey: _copyPasswordButtonKey,
      title: l10n.firstEntryTutorialCopyPasswordTitle,
      message: l10n.firstEntryTutorialCopyPasswordMessage,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '2 / 4',
    );
    if (r12 != _CoachStepResult.primary || !mounted) {
      await OnboardingService.instance.quitAllTutorials();
      await _finishFirstEntryTutorial();
      return;
    }

    // Step 13 — Copier toutes les informations
    setState(() => _activeCoachTarget = _CoachTarget.copyAll);
    final r13 = await _showCoachStep(
      targetKey: _copyAllButtonKey,
      title: l10n.firstEntryTutorialCopyAllTitle,
      message: l10n.firstEntryTutorialCopyAllMessage,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '3 / 4',
    );
    if (r13 != _CoachStepResult.primary || !mounted) {
      await OnboardingService.instance.quitAllTutorials();
      await _finishFirstEntryTutorial();
      return;
    }

    // Step 14 — Appuyer sur la carte
    setState(() => _activeCoachTarget = _CoachTarget.firstEntryCard);
    await _showCoachStep(
      targetKey: _firstEntryCardKey,
      title: l10n.firstEntryTutorialTapCardTitle,
      message: l10n.firstEntryTutorialTapCardMessage,
      primaryLabel: l10n.onboardingFinish,
      stepIndicator: '4 / 4',
    );

    await _finishFirstEntryTutorial();
  }

  Future<void> _finishFirstEntryTutorial() async {
    _isTutorialRunning = false;
    if (mounted) setState(() => _activeCoachTarget = null);
    await OnboardingService.instance.markDiscoveryCompleted(DiscoveryTutorial.firstEntry);
  }

  Future<void> _delete(PasswordEntry entry) async {
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteEntryTitle),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.deleteEntryMessage),
                const SizedBox(height: 8),
                Text(
                  '"${entry.name}"',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.deleteEntryConfirm,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Text('${AppLocalizations.of(context)!.deleteEntryConfirm} :'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: confirmController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: AppLocalizations.of(context)!.deleteKeyword.toLowerCase(),
                  ),
                  validator: (v) {
                    if (v == null || v.toLowerCase() != AppLocalizations.of(context)!.deleteKeyword.toLowerCase()) {
                      return AppLocalizations.of(context)!.deleteEntryConfirm;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    
    confirmController.dispose();
    
    if (confirmed == true) {
      await _persistDelete(entry.id);
      _all.removeWhere((e) => e.id == entry.id);
      _applyFilters();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deleteSuccess),
          backgroundColor: PassKeyraColors.error,
        ),
      );
    }
  }

  Future<void> _copyPassword(PasswordEntry entry) async {
    await SecureClipboardService.copyWithAutoClear(entry.password);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.passwordCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _copyEntryInfo(PasswordEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final buffer = StringBuffer()
      ..writeln('${l10n.name} : ${entry.name}')
      ..writeln('${l10n.username} : ${entry.username}')
      ..writeln('${l10n.password} : ${entry.password}');
    if (entry.url != null && entry.url!.isNotEmpty) {
      buffer.writeln('${l10n.url} : ${entry.url}');
    }
    if (entry.notes != null && entry.notes!.isNotEmpty) {
      buffer.writeln('${l10n.notes} : ${entry.notes}');
    }
    if (entry.tags.isNotEmpty) {
      buffer.writeln('${l10n.tags} : ${entry.tags.join(', ')}');
    }
    await SecureClipboardService.copyWithAutoClear(buffer.toString().trimRight());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.allInfoCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showEntryMenu(PasswordEntry entry) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(AppLocalizations.of(context)!.edit),
              onTap: () {
                Navigator.pop(context);
                _addOrEdit(entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(AppLocalizations.of(context)!.copyPassword),
              onTap: () {
                Navigator.pop(context);
                _copyPassword(entry);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _delete(entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Guard : tant que didChangeDependencies n'a pas peuplé _authService /
    // _syncCoordinator, on affiche un loader. Évite LateInitializationError
    // au premier paint sur desktop.
    if (!_authReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return GestureDetector(
      onTap: () => AutoCloseService.instance.onUserActivity(),
      onPanDown: (_) => AutoCloseService.instance.onUserActivity(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icons/PassKeyra_centered.png',
              width: 32,
              height: 32,
              // Pré-rastérise l'asset 1024×1024 à 96px (3× la taille affichée)
              // pour rester net sur DPI 125-200 % de Windows.
              cacheWidth: 96,
              cacheHeight: 96,
              filterQuality: FilterQuality.medium,
            ),
            const SizedBox(width: 8),
            const Text(
              'PassKeyra',
              style: TextStyle(
                color: PassKeyraColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Icône sauvegarde locale automatique (Premium)
          if (PremiumService().isPremium)
            ValueListenableBuilder<LocalBackupState>(
              valueListenable: SyncCoordinatorService.localBackupStateNotifier,
              builder: (context, state, _) {
                IconData icon;
                Color color;
                String tooltip;

                switch (state) {
                  case LocalBackupState.disabled:
                    icon = Icons.save_outlined;
                    color = Colors.grey;
                    tooltip = 'Sauvegarde locale désactivée';
                    break;
                  case LocalBackupState.idle:
                    icon = Icons.save_outlined;
                    color = PassKeyraColors.info;
                    tooltip = 'Sauvegarde locale activée';
                    break;
                  case LocalBackupState.inProgress:
                    icon = Icons.save;
                    color = PassKeyraColors.inProgress;
                    tooltip = 'Sauvegarde locale en cours...';
                    break;
                  case LocalBackupState.success:
                    icon = Icons.save;
                    color = PassKeyraColors.success;
                    tooltip = 'Sauvegarde locale réussie';
                    break;
                  case LocalBackupState.failed:
                    icon = Icons.save;
                    color = PassKeyraColors.error;
                    tooltip = 'Sauvegarde locale échouée';
                    break;
                }

                return IconButton(
                  icon: Icon(icon, color: color),
                  tooltip: tooltip,
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      ImportExportPage.route,
                      arguments: {'authService': _authService},
                    );
                  },
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.save_outlined, color: Colors.grey),
              tooltip: AppLocalizations.of(context)!.premiumOnlyTooltip,
              onPressed: () => Navigator.pushNamed(context, PremiumPage.route),
            ),
          // Logo 1: Backup automatique Google Drive (Premium)
          if (PremiumService().isPremium && _syncCoordinator != null)
            ValueListenableBuilder<CloudBackupState>(
              valueListenable: _syncCoordinator!.backupStateNotifier,
              builder: (context, state, child) {
                // Icône et couleur selon l'état
                IconData icon;
                Color color;
                String tooltip;

                switch (state) {
                  case CloudBackupState.disabled:
                    icon = Icons.cloud_outlined;
                    color = Colors.grey;
                    tooltip = 'Backup Drive désactivé';
                    break;
                  case CloudBackupState.idle:
                    icon = Icons.cloud_outlined;
                    color = PassKeyraColors.info;
                    tooltip = 'Backup Drive prêt';
                    break;
                  case CloudBackupState.inProgress:
                    icon = Icons.cloud_upload;
                    color = PassKeyraColors.inProgress;
                    tooltip = 'Backup Drive en cours...';
                    break;
                  case CloudBackupState.success:
                    icon = Icons.cloud_done;
                    color = PassKeyraColors.success;
                    tooltip = 'Backup Drive réussi';
                    break;
                  case CloudBackupState.failed:
                    icon = Icons.cloud_off;
                    color = PassKeyraColors.error;
                    tooltip = 'Backup Drive échoué';
                    break;
                }

                return IconButton(
                  icon: Icon(icon, color: color),
                  tooltip: tooltip,
                  onPressed: () {
                    // Ouvrir la page Cloud Backup (nuage)
                    Navigator.pushNamed(
                      context,
                      CloudBackupPage.route,
                      arguments: _authService,
                    );
                  },
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_outlined, color: Colors.grey),
              tooltip: AppLocalizations.of(context)!.premiumOnlyTooltip,
              onPressed: () => Navigator.pushNamed(context, PremiumPage.route),
            ),

          // Logo 2: Synchronisation Firebase (Premium)
          if (PremiumService().isPremium && _syncCoordinator != null)
            StreamBuilder<SyncStatus>(
              stream: _syncCoordinator!.firebaseSyncService.syncStatusStream,
              initialData: SyncStatus.initial,
              builder: (context, snapshot) {
                final status = snapshot.data ?? SyncStatus.initial;

                // Icône selon l'état
                IconData icon;
                Color color;
                String tooltip;

                // Si sync désactivée, afficher en gris
                if (!status.isEnabled) {
                  icon = Icons.sync_disabled;
                  color = Colors.grey;
                  tooltip = 'Synchronisation désactivée';
                } else {
                  // Sync activée - afficher selon l'état
                  switch (status.state) {
                    case SyncState.syncing:
                      icon = Icons.sync_alt;
                      color = PassKeyraColors.inProgress;  // Violet au lieu de bleu
                      tooltip = AppLocalizations.of(context)!.syncStatusSyncing;
                      break;
                    case SyncState.success:
                      icon = Icons.sync_alt;
                      color = PassKeyraColors.success;
                      tooltip = AppLocalizations.of(context)!.syncStatusSuccess;
                      break;
                    case SyncState.error:
                      icon = Icons.sync_problem;
                      color = PassKeyraColors.error;
                      tooltip = status.errorMessage ?? AppLocalizations.of(context)!.syncStatusError;
                      break;
                    case SyncState.conflict:
                      icon = Icons.sync_problem;
                      color = PassKeyraColors.warning;
                      tooltip = AppLocalizations.of(context)!.syncConflictResolved;
                      break;
                    case SyncState.idle:
                      // Sync activée mais au repos - bleu
                      icon = Icons.sync_alt;
                      color = PassKeyraColors.info;
                      tooltip = AppLocalizations.of(context)!.syncStatusIdle;
                      break;
                  }
                }

                return IconButton(
                  icon: Icon(icon, color: color),
                  tooltip: tooltip,
                  onPressed: () {
                    // Ouvrir la page de synchronisation Firebase (double flèche)
                    Navigator.pushNamed(
                      context,
                      '/cloud-sync-settings',
                      arguments: {
                        'authService': _authService,
                        'vaultRepository': _repo,
                      },
                    );
                  },
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.sync_disabled, color: Colors.grey),
              tooltip: AppLocalizations.of(context)!.premiumOnlyTooltip,
              onPressed: () => Navigator.pushNamed(context, PremiumPage.route),
            ),
          Container(
            key: _sortButtonKey,
            child: _buildCoachHalo(
              target: _CoachTarget.sort,
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(4),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (v) {
                  setState(() => _sort = v);
                  _saveSortPreference(v);
                  _applyFilters();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'name_asc', child: Text(AppLocalizations.of(context)!.sortByNameAsc)),
                  PopupMenuItem(value: 'name_desc', child: Text(AppLocalizations.of(context)!.sortByNameDesc)),
                  PopupMenuItem(value: 'date_desc', child: Text(AppLocalizations.of(context)!.sortByDateDesc)),
                  PopupMenuItem(value: 'date_asc', child: Text(AppLocalizations.of(context)!.sortByDateAsc)),
                ],
              ),
            ),
          ),
          IconButton(
            key: _settingsButtonKey,
            icon: _buildCoachHalo(
              target: _CoachTarget.settings,
              shape: BoxShape.circle,
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.settings_outlined),
            ),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                SettingsPage.route,
                arguments: _authService,
              );
              if (result == true) {
                await _checkAndStartOnboardingTutorial(force: true);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            key: _searchBarKey,
            padding: const EdgeInsets.all(16),
            child: _buildCoachHalo(
              target: _CoachTarget.search,
              borderRadius: BorderRadius.circular(12),
              includeBorder: true,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onTap: () => AutoCloseService.instance.onUserActivity(),
                onChanged: (_) => AutoCloseService.instance.onUserActivity(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: AppLocalizations.of(context)!.searchPlaceholder,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          
          // Filtres par catégorie (chips horizontaux)
          _buildCoachHalo(
            target: _CoachTarget.categories,
            borderRadius: BorderRadius.circular(8),
            includeBorder: true,
            child: SizedBox(
            key: _categoryChipsKey,
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(AppLocalizations.of(context)!.all),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = null;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                ..._categories.map((category) {
                  final isSelected = _selectedCategory == category.name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: category.isEmoji
                          ? null
                          : Icon(
                              category.icon,
                              color: isSelected ? Colors.white : category.color,
                              size: 18,
                            ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (category.isEmoji)
                            Text(
                              category.emoji!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          if (category.isEmoji) const SizedBox(width: 6),
                          Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : category.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: category.color,
                      backgroundColor: category.color.withValues(alpha: 0.1),
                      checkmarkColor: Colors.white,
                      side: BorderSide(color: category.color, width: 2),
                      onSelected: (_) {
                        setState(() {
                          // Permet de désélectionner en recliquant
                          if (_selectedCategory == category.name) {
                            _selectedCategory = null;
                          } else {
                            _selectedCategory = category.name;
                          }
                          _applyFilters();
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          ),

          // Compteur d'entrées
          if (_filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${_filtered.length} ${_filtered.length > 1 ? AppLocalizations.of(context)!.entries : AppLocalizations.of(context)!.entry}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Liste des entrées
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handlePullToRefresh,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Tracker le scroll comme activité utilisateur
                  AutoCloseService.instance.onUserActivity();
                  return false;
                },
                child: _filtered.isEmpty
                    ? ListView(
                        // RefreshIndicator nécessite un widget scrollable
                        // On enveloppe le Center dans un ListView avec physics toujours actif
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _all.isEmpty ? AppLocalizations.of(context)!.noEntries : AppLocalizations.of(context)!.noResults,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _all.isEmpty
                                        ? AppLocalizations.of(context)!.addFirstPassword
                                        : AppLocalizations.of(context)!.noResults,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final e = _filtered[i];
                      return Card(
                        key: i == 0 ? _firstEntryCardKey : null,
                        color: PassKeyraColors.glowBlue.withValues(alpha: 0.08),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: PassKeyraColors.glowBlue.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: e.emoji != null
                              ? Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: e.iconColor != null
                                        ? Color(int.parse(e.iconColor!.replaceFirst('#', '0xFF')))
                                        : PassKeyraColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    e.emoji!,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                )
                              : categoryHasEmoji(e.category)
                                  ? Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: getCategoryColor(e.category).withValues(alpha: 0.1), // Fond transparent comme les icônes
                                        shape: categoryIsRound(e.category) ? BoxShape.circle : BoxShape.rectangle,
                                        borderRadius: categoryIsRound(e.category) ? null : BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        getCategoryEmoji(e.category)!,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 24, // Diamètre fixe de 48 pixels (comme les emojis)
                                      backgroundColor: getCategoryColor(e.category).withValues(alpha: 0.1),
                                      child: Icon(
                                        getCategoryIcon(e.category),
                                        color: getCategoryColor(e.category),
                                        size: 24, // Taille cohérente
                                      ),
                                    ),
                          title: Text(
                            e.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF37474F), // Gris très foncé pour le titre
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                e.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: PassKeyraColors.textPrimary,
                                ),
                              ),
                              if (e.category != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (categoryHasEmoji(e.category))
                                      Text(
                                        getCategoryEmoji(e.category)!,
                                        style: const TextStyle(fontSize: 14),
                                      )
                                    else
                                      Icon(
                                        getCategoryIcon(e.category),
                                        size: 14,
                                        color: getCategoryColor(e.category),
                                      ),
                                    const SizedBox(width: 4),
                                    Text(
                                      e.category!,
                                      style: TextStyle(
                                        color: getCategoryColor(e.category),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (e.url != null && e.url!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  e.url!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: PassKeyraColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (e.notes != null && e.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.note_outlined,
                                      size: 14,
                                      color: PassKeyraColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        e.notes!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: PassKeyraColors.textSecondary, // Gris moyen-clair
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.yMd().add_Hm().format(e.updatedAt),
                                style: const TextStyle(
                                  color: PassKeyraColors.textTertiary, // Gris clair pour la date
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _viewEntry(e),
                          onLongPress: () => _showEntryMenu(e),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              i == 0
                                  ? _buildCoachHalo(
                                      target: _CoachTarget.copyAll,
                                      shape: BoxShape.circle,
                                      child: IconButton(
                                        key: _copyAllButtonKey,
                                        icon: const Icon(
                                          Icons.copy_outlined,
                                          color: PassKeyraColors.primary,
                                        ),
                                        onPressed: () => _copyEntryInfo(e),
                                        tooltip: AppLocalizations.of(context)!.copyAllInfo,
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.copy_outlined,
                                        color: PassKeyraColors.primary,
                                      ),
                                      onPressed: () => _copyEntryInfo(e),
                                      tooltip: AppLocalizations.of(context)!.copyAllInfo,
                                    ),
                              i == 0
                                  ? _buildCoachHalo(
                                      target: _CoachTarget.copyPassword,
                                      shape: BoxShape.circle,
                                      child: IconButton(
                                        key: _copyPasswordButtonKey,
                                        icon: const Icon(Icons.key, color: PassKeyraColors.primary),
                                        onPressed: () => _copyPassword(e),
                                        tooltip: AppLocalizations.of(context)!.copyPassword,
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.key, color: PassKeyraColors.primary),
                                      onPressed: () => _copyPassword(e),
                                      tooltip: AppLocalizations.of(context)!.copyPassword,
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        child: _buildCoachHalo(
          target: _CoachTarget.add,
          shape: BoxShape.circle,
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: PassKeyraColors.primaryGlow(
                opacity: 0.3, blurRadius: 35.0),
            child: FloatingActionButton.extended(
              key: _addButtonKey,
              onPressed: () => _checkLimitAndAdd(),
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.add),
            ),
          ),
        ),
      ),
        bottomNavigationBar: _isBannerAdLoaded && _bannerAd != null
            ? Container(
                height: _bannerAd!.size.height.toDouble(),
                alignment: Alignment.center,
                child: AdWidget(ad: _bannerAd!),
              )
            : null,
      ),
    );
  }
}


