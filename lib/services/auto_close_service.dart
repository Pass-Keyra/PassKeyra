import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform/platform_capabilities.dart';

/// Service de gestion de la fermeture automatique de l'application
/// Ferme l'app après une période d'inactivité configurable
class AutoCloseService {
  static AutoCloseService? _instance;
  static AutoCloseService get instance {
    _instance ??= AutoCloseService._();
    return _instance!;
  }

  AutoCloseService._();

  Timer? _inactivityTimer;
  Duration _autoCloseTimeout = const Duration(minutes: 1);
  bool _isEnabled = false;

  Duration get autoCloseTimeout => _autoCloseTimeout;
  bool get isEnabled => _isEnabled;

  /// Initialise le service avec les paramètres sauvegardés.
  /// Sur desktop : no-op (la fermeture surprise de fenêtre est destructive
  /// et peu pertinente PC ; la feature est retirée de Settings côté UI).
  Future<void> init() async {
    if (isDesktop) {
      _isEnabled = false;
      debugPrint('AutoCloseService - Désactivé sur desktop (no-op)');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final timeoutSeconds = prefs.getInt('auto_close_timeout_seconds');
    final enabled = prefs.getBool('auto_close_enabled') ?? false;

    if (timeoutSeconds != null) {
      _autoCloseTimeout = Duration(seconds: timeoutSeconds);
    }
    _isEnabled = enabled;

    debugPrint('AutoCloseService - Initialisé: ${enabled ? "activé" : "désactivé"}, timeout: ${_autoCloseTimeout.inSeconds}s');
  }

  /// Configure le délai de fermeture automatique
  Future<void> setAutoCloseTimeout(Duration timeout) async {
    _autoCloseTimeout = timeout;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_close_timeout_seconds', timeout.inSeconds);
    debugPrint('AutoCloseService - Délai configuré: ${timeout.inSeconds}s');
  }

  /// Active ou désactive la fermeture automatique.
  /// No-op sur desktop (fonctionnalité retirée).
  Future<void> setEnabled(bool enabled) async {
    if (isDesktop) return;
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_close_enabled', enabled);
    
    if (enabled) {
      _startInactivityTimer();
      debugPrint('AutoCloseService - Fermeture automatique activée');
    } else {
      _stopInactivityTimer();
      debugPrint('AutoCloseService - Fermeture automatique désactivée');
    }
  }

  /// Appelé lors d'une interaction utilisateur (tap, scroll, etc.)
  void onUserActivity() {
    if (_isEnabled) {
      _resetInactivityTimer();
    }
  }

  /// Appelé quand l'app passe en arrière-plan (arrête le timer)
  void onAppPaused() {
    _stopInactivityTimer();
    debugPrint('AutoCloseService - App en arrière-plan, timer arrêté');
  }

  /// Appelé quand l'app revient au premier plan (relance le timer si activé)
  void onAppResumed() {
    if (_isEnabled) {
      _startInactivityTimer();
      debugPrint('AutoCloseService - App au premier plan, timer relancé');
    }
  }

  /// Démarre le timer d'inactivité
  void _startInactivityTimer() {
    _stopInactivityTimer();
    _inactivityTimer = Timer(_autoCloseTimeout, () {
      _closeApp();
    });
    debugPrint('AutoCloseService - Timer démarré: ${_autoCloseTimeout.inSeconds}s');
  }

  /// Remet à zéro le timer d'inactivité
  void _resetInactivityTimer() {
    if (_isEnabled) {
      _startInactivityTimer();
    }
  }

  /// Arrête le timer d'inactivité
  void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Ferme l'application
  void _closeApp() {
    debugPrint('AutoCloseService - Fermeture automatique de l\'app après ${_autoCloseTimeout.inSeconds}s d\'inactivité');
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  /// Libère les ressources
  void dispose() {
    _stopInactivityTimer();
  }
}
