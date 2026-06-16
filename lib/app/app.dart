import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import '../platform/platform_capabilities.dart';
import '../services/lock_service.dart';
import 'page_actions.dart';

import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/settings_page.dart';
import '../pages/import_export_page.dart';
import '../pages/premium_page.dart';
import '../pages/manage_categories_page.dart';
import '../pages/security_report_page.dart';
import '../pages/cloud_backup_page.dart';
import '../pages/cloud_sync_settings_page.dart';
import '../pages/discovery_tutorials_page.dart';
import '../pages/keyboard_shortcuts_page.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/vault_repository.dart';
import 'app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

// NavigatorKey global pour gérer la navigation programmatique
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Sur desktop, on supprime les animations slide entre pages : une nav doit
// être instantanée (UX logiciel PC). Les builders mobile (Android/iOS)
// gardent leurs transitions natives par défaut.
class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

const PageTransitionsTheme _kDesktopPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
    TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
    TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
  },
);

// Scrollbar toujours visible : convention Windows pour faciliter l'usage à la
// souris (pas besoin d'attendre le fade-in en survolant).
final ScrollbarThemeData _kDesktopScrollbar = ScrollbarThemeData(
  thumbVisibility: WidgetStateProperty.all(true),
  thickness: WidgetStateProperty.all(8.0),
);

/// ScrollBehavior custom qui place la scrollbar **à gauche** sur desktop
/// (préférence PassKeyra Desktop, anticipe la sidebar de catégories à droite
/// dans la refonte master-detail). Sur mobile : comportement par défaut (droite).
class _DesktopLeftScrollBehavior extends MaterialScrollBehavior {
  const _DesktopLeftScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (!isDesktop) {
      return super.buildScrollbar(context, child, details);
    }
    // Inverse la direction du Scrollbar pour le placer à gauche, puis
    // re-impose ltr sur le child pour ne pas inverser le contenu lui-même.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RawScrollbar(
        controller: details.controller,
        thumbVisibility: true,
        thickness: 8.0,
        radius: const Radius.circular(4),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: child,
        ),
      ),
    );
  }
}

// RouteObserver global pour détecter les changements de route (ex: relance du didacticiel)
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
void _log(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

// Palette de couleurs PassKeyra - Dégradé bleu → gris-bleuté
class PassKeyraColors {
  // Couleur principale du logo (pour icônes et éléments de marque)
  static const Color primary = Color(0xFF2196F3);

  // Couleur du reflet bleu (utilisée pour le fond des cartes)
  static const Color glowBlue = Color(0xFF198CF0);       // Bleu du reflet du logo

  // Dégradé de textes : bleu → gris-bleuté
  static const Color textPrimary = Color(0xFF546E7A);    // Bleu-gris moyen
  static const Color textSecondary = Color(0xFF78909C);  // Bleu-gris clair
  static const Color textTertiary = Color(0xFF90A4AE);   // Bleu-gris très clair
  static const Color textSubtle = Color(0xFFB0BEC5);     // Bleu-gris ultra clair

  // Bordures et séparateurs - gris légèrement bleuté
  static const Color border = Color(0xFFCFD8DC);         // Gris avec touche bleue
  static const Color divider = Color(0xFFECEFF1);        // Gris très clair bleuté

  // Couleurs sémantiques
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2196F3);
  static const Color inProgress = Color(0xFF9C27B0);  // Violet pour état "en cours"

  // Effets de glow
  static BoxDecoration primaryGlow({double opacity = 0.3, double blurRadius = 40.0}) {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: opacity),
          blurRadius: blurRadius,
          spreadRadius: blurRadius / 4,
        ),
      ],
    );
  }

  static BoxDecoration successGlow({double opacity = 0.3, double blurRadius = 40.0}) {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: success.withValues(alpha: opacity),
          blurRadius: blurRadius,
          spreadRadius: blurRadius / 4,
        ),
      ],
    );
  }

  static BoxDecoration warningGlow({double opacity = 0.3, double blurRadius = 40.0}) {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: warning.withValues(alpha: opacity),
          blurRadius: blurRadius,
          spreadRadius: blurRadius / 4,
        ),
      ],
    );
  }
}

class PassKeyraAppShell extends StatefulWidget {
  const PassKeyraAppShell({super.key, required this.isLocked});
  
  final bool isLocked;

  @override
  State<PassKeyraAppShell> createState() => _PassKeyraAppShellState();
}

class _PassKeyraAppShellState extends State<PassKeyraAppShell> with WidgetsBindingObserver {
  bool _previousLockState = true;
  final _languageService = LanguageService();
  final _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    // Écouter les changements de langue
    _languageService.addListener(_onLanguageChanged);
    // Écouter les changements de thème
    _themeService.addListener(_onThemeChanged);
    // Écouter le cycle de vie de l'app pour gérer le capteur de luminosité
    WidgetsBinding.instance.addObserver(this);
    // Démarrer le capteur si en mode automatique
    _themeService.startLightSensor();
  }

  @override
  void dispose() {
    _languageService.removeListener(_onLanguageChanged);
    _themeService.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    _themeService.stopLightSensor();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Gérer le capteur de luminosité selon l'état de l'app
    switch (state) {
      case AppLifecycleState.resumed:
        // App au premier plan - démarrer le capteur
        _themeService.startLightSensor();
        break;
      case AppLifecycleState.paused:
        // App en arrière-plan - arrêter le capteur (économie de batterie)
        _themeService.stopLightSensor();
        break;
      default:
        break;
    }
  }

  void _onLanguageChanged() {
    // Reconstruire l'UI quand la langue change
    setState(() {});
  }

  void _onThemeChanged() {
    // Reconstruire l'UI quand le thème change
    setState(() {});
  }

  @override
  void didUpdateWidget(PassKeyraAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    _log('PassKeyraAppShell - didUpdateWidget: oldLocked=${oldWidget.isLocked}, newLocked=${widget.isLocked}, previous=$_previousLockState');
    
    // Détecter quand l'app passe de déverrouillée à verrouillée (verrouillage automatique)
    // UNIQUEMENT si on passe de false à true
    if (!_previousLockState && widget.isLocked) {
      // L'app vient de se verrouiller automatiquement
      _log('PassKeyraAppShell - VERROUILLAGE AUTOMATIQUE détecté, retour à LoginPage');
      
      // Forcer le retour à LoginPage en supprimant toutes les routes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _log('PassKeyraAppShell - Exécution de la navigation vers LoginPage...');
        
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          LoginPage.route,
          (route) => false,
        );
        
        _log('PassKeyraAppShell - Navigation vers LoginPage terminée');
      });
    }
    // Si on passe de verrouillé à déverrouillé, NE RIEN FAIRE
    // La navigation est gérée par LoginPage lui-même
    else if (_previousLockState && !widget.isLocked) {
      _log('PassKeyraAppShell - Déverrouillage détecté, AUCUNE navigation (LoginPage gère la navigation)');
    }
    
    _previousLockState = widget.isLocked;
  }

  // Obtenir la palette de couleurs actuelle
  AppColorPalette _getCurrentPalette() {
    return getPaletteFromEnum(_themeService.colorPalette);
  }

  // Obtenir le TextTheme selon la police sélectionnée
  TextTheme _getTextTheme() {
    switch (_themeService.fontFamily) {
      case FontFamily.roboto:
        return GoogleFonts.robotoTextTheme();
      case FontFamily.lato:
        return GoogleFonts.latoTextTheme();
      case FontFamily.montserrat:
        return GoogleFonts.montserratTextTheme();
      case FontFamily.openSans:
        return GoogleFonts.openSansTextTheme();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyL, control: true): () {
          if (!LockService.instance.isLocked) {
            LockService.instance.lock();
          }
        },
        const SingleActivator(LogicalKeyboardKey.comma, control: true): () {
          if (LockService.instance.isLocked) return;
          final nav = navigatorKey.currentState;
          if (nav == null) return;
          if (ModalRoute.of(nav.context)?.settings.name != SettingsPage.route) {
            nav.pushNamed(SettingsPage.route);
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          final nav = navigatorKey.currentState;
          if (nav != null && nav.canPop()) {
            nav.pop();
          }
        },
        // Page-spécifique : invoque le callback enregistré par la page courante
        // via HomePageActions. No-op si aucune page n'est enregistrée.
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          HomePageActions.instance.newEntry.value?.call();
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          HomePageActions.instance.focusSearch.value?.call();
        },
      },
      child: Focus(
        autofocus: true,
        child: MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      scrollBehavior: const _DesktopLeftScrollBehavior(),
      title: 'PassKeyra',
      // Configuration de l'internationalisation
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'), // Français
        Locale('en'), // English
        Locale('es'), // Español
      ],
      locale: _languageService.currentLocale,
      theme: _buildLightTheme(),
      darkTheme: _getCurrentDarkTheme(),
      themeMode: _themeService.effectiveThemeMode,
      home: const LoginPage(),
      routes: {
        LoginPage.route: (_) => const LoginPage(),
        SettingsPage.route: (_) => const SettingsPage(),
        ImportExportPage.route: (_) => const ImportExportPage(),
        PremiumPage.route: (_) => const PremiumPage(),
        ManageCategoriesPage.route: (_) => const ManageCategoriesPage(),
        SecurityReportPage.route: (_) => const SecurityReportPage(),
        CloudBackupPage.route: (_) => const CloudBackupPage(),
        DiscoveryTutorialsPage.route: (_) => const DiscoveryTutorialsPage(),
        KeyboardShortcutsPage.route: (_) => const KeyboardShortcutsPage(),
      },
      onGenerateRoute: (settings) {
        // HomePage : transition instantanée (Duration.zero) après unlock —
        // l'utilisateur vient d'attendre PBKDF2, on ne lui inflige pas
        // 300 ms supplémentaires d'animation slide.
        if (settings.name == HomePage.route) {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (_, __, ___) => const HomePage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          );
        }
        // Route /cloud-sync-settings avec arguments
        if (settings.name == '/cloud-sync-settings') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CloudSyncSettingsPage(
              authService: args['authService'] as AuthService,
              vaultRepository: args['vaultRepository'] as VaultRepository,
              startTutorial: args['startTutorial'] == true,
            ),
          );
        }
        return null;
      },
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final palette = _getCurrentPalette();
    final baseTextTheme = _getTextTheme();

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: _kDesktopPageTransitions,
      scrollbarTheme: _kDesktopScrollbar,
      colorScheme: ColorScheme.light(
        primary: palette.primary,
        onPrimary: Colors.white,
        primaryContainer: palette.primaryContainer,
        onPrimaryContainer: palette.onPrimaryContainer,
        secondary: palette.secondary,
        onSecondary: Colors.white,
        secondaryContainer: palette.secondaryContainer,
        onSecondaryContainer: palette.onSecondaryContainer,
        tertiary: palette.tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: palette.tertiaryContainer,
        onTertiaryContainer: palette.onTertiaryContainer,
        error: AppColorPalette.error,
        onError: Colors.white,
        errorContainer: const Color(0xFFFFCDD2),
        onErrorContainer: const Color(0xFFB71C1C),
        surface: const Color(0xFFFAFAFA),
        onSurface: palette.textPrimary,
        surfaceContainerHighest: const Color(0xFFECEFF1),
        onSurfaceVariant: palette.textSecondary,
        outline: palette.border,
        outlineVariant: const Color(0xFFE0E0E0),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: const Color(0xFF303030),
        onInverseSurface: const Color(0xFFFFFFFF),
        inversePrimary: palette.primaryContainer,
        brightness: Brightness.light,
      ),
      // Thème des icônes - couleur principale de la palette
      iconTheme: IconThemeData(
        color: palette.primary,
        size: 24,
      ),
      // Thème des textes - police personnalisée + couleurs de la palette
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: palette.textPrimary, fontWeight: FontWeight.bold),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: palette.textPrimary, fontWeight: FontWeight.bold),
        displaySmall: baseTextTheme.displaySmall?.copyWith(color: palette.textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: palette.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: palette.textPrimary),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: palette.textSecondary, fontWeight: FontWeight.w500),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: palette.textSecondary),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: palette.textSecondary),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: palette.textTertiary),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: palette.textSecondary, fontWeight: FontWeight.w500),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: palette.textTertiary),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: palette.textSubtle),
      ),
      // Thème de l'AppBar - icônes et textes selon la palette
      appBarTheme: AppBarTheme(
        iconTheme: IconThemeData(color: palette.primary),
        actionsIconTheme: IconThemeData(color: palette.primary),
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Thème des ListTile - icônes et textes selon la palette
      listTileTheme: ListTileThemeData(
        iconColor: palette.primary,
        textColor: palette.textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Coins carrés
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
      ),
    );
  }

  // Retourne le thème dark approprié selon la variante sélectionnée
  ThemeData _getCurrentDarkTheme() {
    switch (_themeService.darkVariant) {
      case DarkThemeVariant.amoledBlack:
        return _buildAmoledBlackTheme();
      case DarkThemeVariant.darkGrey:
        return _buildDarkGreyTheme();
      case DarkThemeVariant.standard:
        return _buildDarkTheme();
    }
  }

  // Mode sombre standard (gratuit)
  ThemeData _buildDarkTheme() {
    final palette = _getCurrentPalette();
    final baseTextTheme = _getTextTheme();

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: _kDesktopPageTransitions,
      scrollbarTheme: _kDesktopScrollbar,
      colorScheme: ColorScheme.dark(
        primary: palette.darkPrimary,
        onPrimary: palette.darkOnPrimary,
        primaryContainer: palette.darkPrimaryContainer,
        onPrimaryContainer: palette.darkOnPrimaryContainer,
        secondary: palette.darkSecondary,
        onSecondary: Colors.white,
        secondaryContainer: palette.darkSecondaryContainer,
        onSecondaryContainer: palette.darkOnSecondaryContainer,
        tertiary: palette.darkTertiary,
        onTertiary: Colors.white,
        tertiaryContainer: palette.darkTertiaryContainer,
        onTertiaryContainer: palette.darkOnTertiaryContainer,
        error: const Color(0xFFEF5350),
        onError: const Color(0xFFFFFFFF),
        errorContainer: const Color(0xFFD32F2F),
        onErrorContainer: const Color(0xFFFFCDD2),
        surface: const Color(0xFF121212),
        onSurface: const Color(0xFFE0E0E0),
        surfaceContainerHighest: const Color(0xFF2C2C2C),
        onSurfaceVariant: const Color(0xFFBDBDBD),
        outline: const Color(0xFF757575),
        outlineVariant: const Color(0xFF424242),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: const Color(0xFFE0E0E0),
        onInverseSurface: const Color(0xFF121212),
        inversePrimary: palette.primary,
        brightness: Brightness.dark,
      ),
      // Thème des icônes en mode sombre - couleur primary de la palette
      iconTheme: IconThemeData(
        color: palette.darkPrimary,
        size: 24,
      ),
      // Thème des textes en mode sombre - police personnalisée + gris clairs
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        displaySmall: baseTextTheme.displaySmall?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.w600),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: const Color(0xFFB0BEC5)),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.w600),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: const Color(0xFF90A4AE), fontWeight: FontWeight.w500),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: const Color(0xFF90A4AE)),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: const Color(0xFF90A4AE)),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: const Color(0xFF90A4AE)),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: const Color(0xFF78909C)),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: const Color(0xFF90A4AE), fontWeight: FontWeight.w500),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: const Color(0xFF78909C)),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: const Color(0xFF607D8B)),
      ),
      // Thème de l'AppBar en mode sombre
      appBarTheme: AppBarTheme(
        iconTheme: IconThemeData(color: palette.darkPrimary),
        actionsIconTheme: IconThemeData(color: palette.darkPrimary),
        titleTextStyle: const TextStyle(
          color: Color(0xFFB0BEC5),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Thème des ListTile en mode sombre
      listTileTheme: ListTileThemeData(
        iconColor: palette.darkPrimary,
        textColor: const Color(0xFF90A4AE),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.darkPrimary, width: 2),
        ),
      ),
    );
  }

  // Mode sombre AMOLED Black (Premium) - Noir pur pour écrans OLED
  ThemeData _buildAmoledBlackTheme() {
    final palette = _getCurrentPalette();
    final baseTextTheme = _getTextTheme();

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: _kDesktopPageTransitions,
      scrollbarTheme: _kDesktopScrollbar,
      colorScheme: ColorScheme.dark(
        primary: palette.darkPrimary,
        onPrimary: palette.darkOnPrimary,
        primaryContainer: palette.darkPrimaryContainer,
        onPrimaryContainer: palette.darkOnPrimaryContainer,
        secondary: palette.darkSecondary,
        onSecondary: Colors.white,
        secondaryContainer: palette.darkSecondaryContainer,
        onSecondaryContainer: palette.darkOnSecondaryContainer,
        tertiary: palette.darkTertiary,
        onTertiary: Colors.white,
        tertiaryContainer: palette.darkTertiaryContainer,
        onTertiaryContainer: palette.darkOnTertiaryContainer,
        error: const Color(0xFFEF5350),
        onError: const Color(0xFFFFFFFF),
        errorContainer: const Color(0xFFD32F2F),
        onErrorContainer: const Color(0xFFFFCDD2),
        surface: const Color(0xFF000000), // Noir pur AMOLED
        onSurface: const Color(0xFFE0E0E0),
        surfaceContainerHighest: const Color(0xFF0A0A0A), // Noir légèrement grisé
        onSurfaceVariant: const Color(0xFFBDBDBD),
        outline: const Color(0xFF424242),
        outlineVariant: const Color(0xFF1A1A1A),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: const Color(0xFFE0E0E0),
        onInverseSurface: const Color(0xFF000000),
        inversePrimary: palette.primary,
        brightness: Brightness.dark,
      ),
      iconTheme: IconThemeData(
        color: palette.darkPrimary,
        size: 24,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        displaySmall: baseTextTheme.displaySmall?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.w600),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: const Color(0xFFB0BEC5)),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.w600),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: const Color(0xFF90A4AE), fontWeight: FontWeight.w500),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: const Color(0xFF90A4AE)),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: const Color(0xFF90A4AE)),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: const Color(0xFF90A4AE)),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: const Color(0xFF78909C)),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: const Color(0xFF90A4AE), fontWeight: FontWeight.w500),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: const Color(0xFF78909C)),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: const Color(0xFF607D8B)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF000000), // AppBar noir pur
        iconTheme: IconThemeData(color: palette.darkPrimary),
        actionsIconTheme: IconThemeData(color: palette.darkPrimary),
        titleTextStyle: const TextStyle(
          color: Color(0xFFB0BEC5),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.darkPrimary,
        textColor: const Color(0xFF90A4AE),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0A0A0A), // Cards légèrement grisées sur fond noir
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.darkPrimary, width: 2),
        ),
      ),
    );
  }

  // Mode sombre Dark Grey (Premium) - Gris foncé personnalisé
  ThemeData _buildDarkGreyTheme() {
    final palette = _getCurrentPalette();
    final baseTextTheme = _getTextTheme();

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: _kDesktopPageTransitions,
      scrollbarTheme: _kDesktopScrollbar,
      colorScheme: ColorScheme.dark(
        primary: palette.darkPrimary,
        onPrimary: palette.darkOnPrimary,
        primaryContainer: palette.darkPrimaryContainer,
        onPrimaryContainer: palette.darkOnPrimaryContainer,
        secondary: palette.darkSecondary,
        onSecondary: Colors.white,
        secondaryContainer: palette.darkSecondaryContainer,
        onSecondaryContainer: palette.darkOnSecondaryContainer,
        tertiary: palette.darkTertiary,
        onTertiary: Colors.white,
        tertiaryContainer: palette.darkTertiaryContainer,
        onTertiaryContainer: palette.darkOnTertiaryContainer,
        error: const Color(0xFFEF5350),
        onError: const Color(0xFFFFFFFF),
        errorContainer: const Color(0xFFD32F2F),
        onErrorContainer: const Color(0xFFFFCDD2),
        surface: const Color(0xFF1A1A1A), // Gris très foncé
        onSurface: const Color(0xFFE0E0E0),
        surfaceContainerHighest: const Color(0xFF2A2A2A), // Gris foncé plus clair
        onSurfaceVariant: const Color(0xFFBDBDBD),
        outline: const Color(0xFF606060),
        outlineVariant: const Color(0xFF383838),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: const Color(0xFFE0E0E0),
        onInverseSurface: const Color(0xFF1A1A1A),
        inversePrimary: palette.primary,
        brightness: Brightness.dark,
      ),
      iconTheme: IconThemeData(
        color: palette.darkPrimary,
        size: 24,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        displaySmall: baseTextTheme.displaySmall?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.bold),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.w600),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: const Color(0xFFB0BEC5)),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: const Color(0xFFB0BEC5), fontWeight: FontWeight.w600),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: const Color(0xFF90A4AE), fontWeight: FontWeight.w500),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: const Color(0xFF90A4AE)),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: const Color(0xFF90A4AE)),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: const Color(0xFF90A4AE)),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: const Color(0xFF78909C)),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: const Color(0xFF90A4AE), fontWeight: FontWeight.w500),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: const Color(0xFF78909C)),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: const Color(0xFF607D8B)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: IconThemeData(color: palette.darkPrimary),
        actionsIconTheme: IconThemeData(color: palette.darkPrimary),
        titleTextStyle: const TextStyle(
          color: Color(0xFFB0BEC5),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.darkPrimary,
        textColor: const Color(0xFF90A4AE),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2A2A2A), // Cards gris foncé
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF606060)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.darkPrimary, width: 2),
        ),
      ),
    );
  }
}



