import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
// `cryptography_flutter` s'active automatiquement quand le plugin est dans pubspec :
// pas besoin d'import ni d'appel manuel pour bénéficier du PBKDF2 natif Android/iOS.

import 'app/app.dart' show PassKeyraAppShell;
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/backup_repository.dart';
import 'services/lock_service.dart';
import 'services/ad_service.dart';
import 'services/auto_close_service.dart';
import 'services/category_service.dart';
import 'services/screen_blur_service.dart';
import 'services/review_service.dart';
import 'services/language_service.dart';
import 'services/secure_storage_service.dart';
import 'services/theme_service.dart';
import 'services/consent_service.dart';
import 'services/premium_service.dart';

void _log(Object message) {
  if (kDebugMode) {
    debugPrint(message.toString());
  }
}

/// Validation grossière qu'une position de fenêtre est utilisable.
/// Garde-fou minimal pour éviter qu'un écran secondaire débranché ne laisse
/// la fenêtre invisible : refuse les coordonnées clairement hors d'une plage
/// raisonnable (un peu plus large que l'écran principal usuel).
///
/// Pas d'API multi-écran fiable dans `window_manager` 0.4 — pour une
/// vérification stricte (multi-display dynamique) il faudrait ajouter
/// `screen_retriever` en dépendance.
bool _isPositionReasonable(Offset position) {
  // Plage permissive : -3840 → +7680 horizontalement (gère configurations
  // dual-monitor 4K à gauche/droite), -2160 → +4320 verticalement.
  // En dehors : c'est un ancien écran probablement déconnecté.
  const minX = -3840.0;
  const maxX = 7680.0;
  const minY = -2160.0;
  const maxY = 4320.0;
  return position.dx >= minX &&
      position.dx <= maxX &&
      position.dy >= minY &&
      position.dy <= maxY;
}

/// Journalise toutes les exceptions Flutter dans un fichier sur disque, pour
/// qu'on puisse les inspecter même en release (où debugPrint est strippé).
/// Spécifique au portage Desktop V1 — à retirer en V1.1 quand on aura du télémétrie.
void _logErrorToFile(Object error, [StackTrace? stack]) {
  try {
    final baseDir = Platform.isWindows
        ? Platform.environment['LOCALAPPDATA']
        : null;
    if (baseDir == null) return;
    final logFile = File('$baseDir\\com.passkeyra\\flutter_errors.log');
    logFile.parent.createSync(recursive: true);
    final now = DateTime.now().toIso8601String();
    logFile.writeAsStringSync(
      '[$now] $error\n${stack ?? ""}\n\n',
      mode: FileMode.append,
    );
  } catch (_) {
    // Ne jamais faire planter l'app à cause du logger.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture toutes les exceptions Flutter dans un fichier (utile en release Windows
  // où la console et debugPrint ne sont pas visibles).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _logErrorToFile(details.exceptionAsString(), details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _logErrorToFile(error, stack);
    return false;
  };

  // Desktop : configure la fenêtre (taille, min, position persistée).
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    // Taille par défaut conservative pour rester confortable même sur des
    // résolutions modestes (sessions RDP, écran 1366×768, etc.).
    final width = prefs.getDouble('window_width') ?? 1024.0;
    final height = prefs.getDouble('window_height') ?? 720.0;
    final savedX = prefs.getDouble('window_x');
    final savedY = prefs.getDouble('window_y');
    final isMaximized = prefs.getBool('window_maximized') ?? false;
    final windowOptions = WindowOptions(
      size: Size(width, height),
      minimumSize: const Size(800, 600),
      center: savedX == null,
      title: 'PassKeyra',
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (savedX != null && savedY != null) {
        // Garde-fou : si la position est clairement hors d'une plage normale
        // (écran secondaire déconnecté), on recentre au lieu de pousser la
        // fenêtre dans le vide.
        if (_isPositionReasonable(Offset(savedX, savedY))) {
          await windowManager.setPosition(Offset(savedX, savedY));
        } else {
          _log('Position sauvegardée hors plage ($savedX, $savedY) — recentrage.');
          await prefs.remove('window_x');
          await prefs.remove('window_y');
          // Pas besoin d'appeler center() : WindowOptions.center = true quand
          // savedX est null à l'init, et le setPosition n'a pas été appelé.
        }
      }
      if (isMaximized) {
        await windowManager.maximize();
      }
      await windowManager.show();
      await windowManager.focus();
    });
  }

  _log('PassKeyra - Démarrage de l\'application...');

  await Hive.initFlutter();
  _log('Hive initialisé');

  try {
    final vaultBox = await Hive.openBox<String>('vault_blob');
    _log('Hive - Box "vault_blob" ouverte (${vaultBox.length} entrées)');
  } catch (e, stack) {
    _log('Hive - Impossible d\'ouvrir la box "vault_blob" : $e');
    _log(stack);
  }

  // Nettoyage des sauvegardes de sécurité expirées (snapshots pré-changement
  // de mot de passe maître > 30 jours). Best effort, ne bloque jamais le boot.
  BackupRepository().cleanExpiredSnapshots().then((deleted) {
    if (deleted > 0) _log('Sauvegardes de sécurité expirées supprimées : $deleted');
  }).catchError((e) {
    _log('cleanExpiredSnapshots erreur : $e');
  });

  try {
    await LockService.instance.init();
    _log('LockService initialisé');
  } on PlatformException catch (e, stack) {
    _log('LockService - Erreur critique au démarrage : ${e.message ?? e}');
    _log(stack);
    // Ne jamais purger automatiquement les données utilisateur au démarrage.
    // Continuer avec l'app permet un diagnostic/rétablissement sans destruction.
    runApp(const PassKeyraRoot());
    return;
  } catch (e, stack) {
    _log('LockService - Exception inattendue : $e');
    _log(stack);
    // Ne jamais purger automatiquement les données utilisateur au démarrage.
    runApp(const PassKeyraRoot());
    return;
  }

  try {
    await AutoCloseService.instance.init();
    _log('AutoCloseService initialisé');
  } catch (e, stack) {
    _log('AutoCloseService - Erreur initialisation : $e');
    _log(stack);
  }

  // SECURITY CLEANUP : détecte et supprime les clés legacy plain laissées par
  // l'ancien fallback silencieux (Bug A). Force la re-saisie du mot de passe
  // maître pour les utilisateurs dans l'état compromis.
  try {
    final auth = AuthService(SecureStorageService());
    await auth.cleanupCompromisedLegacyWrap();
    _log('AuthService - cleanupCompromisedLegacyWrap exécuté');
  } catch (e, stack) {
    _log('AuthService - cleanupCompromisedLegacyWrap erreur (non critique) : $e');
    _log(stack);
  }

  runApp(const PassKeyraRoot());

  // Initialiser Firebase en arrière-plan (requis pour Cloud Sync Premium uniquement).
  // Firebase n'est pas nécessaire avant que l'utilisateur ouvre une fonction cloud,
  // donc on n'attend pas avant runApp pour ne pas bloquer la 1ʳᵉ frame.
  // Sur Android/iOS, le plugin Gradle/Pods charge `google-services.json` et la
  // signature sans-options fonctionne. Sur Windows/Linux/macOS, on doit fournir
  // explicitement les options (cf. `firebase_options.dart`).
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((_) {
    _log('Firebase initialisé avec succès (en arrière-plan)');
  }).catchError((e) {
    _log('Firebase - Initialisation échouée: $e');
    _log('  → La synchronisation cloud ne sera pas disponible');
    _log('  → Voir FIREBASE_SETUP.md pour configurer Firebase');
  });

  // IMPORTANT: Demander le consentement RGPD AVANT d'initialiser AdMob
  ConsentService.instance.requestConsentIfNeeded().then((_) async {
    _log('Consentement RGPD vérifié');

    // Initialiser AdMob uniquement si l'utilisateur peut voir des pubs
    final canShowAds = await ConsentService.instance.canShowAds();
    if (canShowAds) {
      await AdService.instance.init();
      _log('AdMob initialisé en arrière-plan');
    } else {
      _log('AdMob non initialisé - Consentement refusé ou requis');
    }
  }).catchError((e) {
    _log('Erreur initialisation Consentement/AdMob: $e');
  });

  CategoryService().initialize().then((_) {
    _log('CategoryService initialisé');
  }).catchError((e) {
    _log('Erreur initialisation CategoryService: $e');
  });

  // ScreenBlurService initialisé en arrière-plan (lecture SharedPreferences ~10-30 ms).
  // L'await précédent bloquait inutilement la chaîne des .then() suivants.
  ScreenBlurService.instance.init().then((_) {
    _log('ScreenBlurService initialisé (en arrière-plan)');
  }).catchError((e) {
    _log('Erreur initialisation ScreenBlurService: $e');
  });

  ReviewService().initialize().then((_) {
    _log('ReviewService initialisé');
  }).catchError((e) {
    _log('Erreur initialisation ReviewService: $e');
  });

  ReviewService().incrementLaunchCount().then((_) {
    _log('ReviewService - Compteur de lancements incrémenté');
  }).catchError((e) {
    _log('Erreur incrémentation compteur lancements: $e');
  });

  LanguageService().initialize().then((_) {
    _log('LanguageService initialisé');
  }).catchError((e) {
    _log('Erreur initialisation LanguageService: $e');
  });

  // Initialiser ThemeService pour gérer les thèmes
  ThemeService().init().then((_) {
    _log('ThemeService initialisé');
  }).catchError((e) {
    _log('Erreur initialisation ThemeService: $e');
  });

  // Initialiser PremiumService pour gérer les achats in-app
  PremiumService().initialize().then((_) {
    _log('PremiumService initialisé');
  }).catchError((e) {
    _log('Erreur initialisation PremiumService: $e');
  });
}

/// Application principale avec gestion du cycle de vie
class PassKeyraRoot extends StatefulWidget {
  const PassKeyraRoot({super.key});

  @override
  State<PassKeyraRoot> createState() => _PassKeyraRootState();
}

class _PassKeyraRootState extends State<PassKeyraRoot>
    with WidgetsBindingObserver, WindowListener {
  final _lockService = LockService.instance;
  final _autoCloseService = AutoCloseService.instance;
  final bool _isDesktop =
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  void initState() {
    super.initState();
    _log('PassKeyraRoot - Initialisation du widget');
    WidgetsBinding.instance.addObserver(this);
    if (_isDesktop) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    _log('PassKeyraRoot - Fermeture du widget');
    WidgetsBinding.instance.removeObserver(this);
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    _autoCloseService.dispose();
    super.dispose();
  }

  /// Persiste taille + position fenêtre. Appelé sur resize/move (avec debounce
  /// naturel : on écrit à chaque event, mais SharedPreferences est asynchrone
  /// et ne bloque pas le thread UI).
  Future<void> _persistWindowState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isMaximized = await windowManager.isMaximized();
      await prefs.setBool('window_maximized', isMaximized);
      if (!isMaximized) {
        final size = await windowManager.getSize();
        final pos = await windowManager.getPosition();
        await prefs.setDouble('window_width', size.width);
        await prefs.setDouble('window_height', size.height);
        await prefs.setDouble('window_x', pos.dx);
        await prefs.setDouble('window_y', pos.dy);
      }
    } catch (e) {
      _log('Persist window state - erreur: $e');
    }
  }

  @override
  void onWindowResized() => _persistWindowState();

  @override
  void onWindowMoved() => _persistWindowState();

  @override
  void onWindowMaximize() => _persistWindowState();

  @override
  void onWindowUnmaximize() => _persistWindowState();

  // ─── Délai de verrouillage desktop ───
  // Sur mobile, `AppLifecycleState.paused` est déclenché quand l'app passe en
  // arrière-plan → LockService démarre son timer. Sur Windows, ce lifecycle
  // n'existe pas pour une fenêtre. On reroute les events `window_manager`
  // vers les mêmes hooks LockService :
  // - onWindowBlur / onWindowMinimize  → onAppPaused (démarre le timer)
  // - onWindowFocus / onWindowRestore  → onAppResumed (check timeout)

  @override
  void onWindowBlur() {
    if (_isDesktop) _lockService.onAppPaused();
  }

  @override
  void onWindowFocus() {
    if (_isDesktop) _lockService.onAppResumed();
  }

  @override
  void onWindowMinimize() {
    if (_isDesktop) _lockService.onAppPaused();
  }

  @override
  void onWindowRestore() {
    if (_isDesktop) _lockService.onAppResumed();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log('Lifecycle - Changement d\'état : $state');

    if (state == AppLifecycleState.paused) {
      _lockService.onAppPaused();
      _autoCloseService.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _lockService.onAppResumed();
      _autoCloseService.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser StreamBuilder pour reconstruire l'UI quand l'état de verrouillage change
    // CORRECTION: Utiliser Listener au lieu de GestureDetector pour capturer TOUS les événements
    // y compris ceux dans les WebView OAuth, TextField, dialogues, etc.
    return Listener(
      onPointerDown: (_) => _autoCloseService.onUserActivity(),
      behavior: HitTestBehavior.translucent, // Capturer TOUS les événements tactiles
      child: StreamBuilder<bool>(
        stream: _lockService.lockStream,
        initialData: _lockService.isLocked,
        builder: (context, snapshot) {
          final isLocked = snapshot.data ?? true;
          _log('StreamBuilder - Reconstruction avec isLocked=$isLocked');

          return PassKeyraAppShell(isLocked: isLocked);
        },
      ),
    );
  }
}

