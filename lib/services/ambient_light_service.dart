import 'dart:async';
import 'package:light/light.dart';
import 'package:flutter/foundation.dart';
import '../platform/platform_capabilities.dart';

/// Service de détection de luminosité ambiante pour le mode automatique
///
/// Ce service utilise le capteur de luminosité du téléphone pour déterminer
/// si le mode sombre doit être activé automatiquement.
///
/// Seuil : 3 lux (< 3 = nuit très noire uniquement, >= 3 = clair)
class AmbientLightService {
  static final AmbientLightService _instance = AmbientLightService._internal();
  factory AmbientLightService() => _instance;
  AmbientLightService._internal();

  // Seuil de luminosité en lux (3 = nuit très noire uniquement)
  static const double _luxThreshold = 3.0;

  // Délai de debounce pour éviter les changements trop fréquents
  static const Duration _debounceDuration = Duration(seconds: 2);

  Light? _light;
  StreamSubscription? _subscription;
  Timer? _debounceTimer;
  bool _isDark = false;
  bool _isListening = false;
  bool _sensorAvailable = true;

  // Callbacks pour notifier les changements
  final List<Function(bool)> _listeners = [];

  /// Indique si le capteur est disponible
  bool get isSensorAvailable => _sensorAvailable;

  /// Indique si le service écoute actuellement le capteur
  bool get isListening => _isListening;

  /// État actuel : true = mode sombre, false = mode clair
  bool get isDark => _isDark;

  /// Ajouter un listener pour être notifié des changements
  void addListener(Function(bool isDark) listener) {
    _listeners.add(listener);
  }

  /// Retirer un listener
  void removeListener(Function(bool isDark) listener) {
    _listeners.remove(listener);
  }

  /// Notifier tous les listeners
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener(_isDark);
    }
  }

  /// Démarrer l'écoute du capteur de luminosité
  Future<void> startListening() async {
    if (_isListening) return;

    // Plateformes sans capteur de luminosité (desktop) : on n'instancie pas
    // le plugin pour éviter MissingPluginException et on signale indisponible.
    if (!supportsAmbientLight) {
      _sensorAvailable = false;
      return;
    }

    try {
      _light = Light();

      // Tester si le capteur est disponible ET initialiser la valeur
      try {
        final luxValue = await _light!.lightSensorStream.first.timeout(
          const Duration(seconds: 2),
        );
        // Initialiser l'état avec la valeur actuelle du capteur
        _isDark = luxValue < _luxThreshold;
        debugPrint('AmbientLightService: Capteur disponible, luminosité initiale: ${luxValue.toStringAsFixed(1)} lux → ${_isDark ? "SOMBRE" : "CLAIR"}');
        _sensorAvailable = true;
        // Notifier immédiatement les listeners de la valeur initiale
        _notifyListeners();
      } catch (e) {
        debugPrint('AmbientLightService: Capteur non disponible - $e');
        _sensorAvailable = false;
        return;
      }

      // Écouter le flux de luminosité
      _subscription = _light!.lightSensorStream.listen(
        _onLightChanged,
        onError: (error) {
          debugPrint('AmbientLightService: Erreur capteur - $error');
          _sensorAvailable = false;
          stopListening();
        },
        cancelOnError: true,
      );

      _isListening = true;
      debugPrint('AmbientLightService: Écoute démarrée (seuil: $_luxThreshold lux)');
    } catch (e) {
      debugPrint('AmbientLightService: Impossible de démarrer - $e');
      _sensorAvailable = false;
      _isListening = false;
    }
  }

  /// Arrêter l'écoute du capteur (économie de batterie)
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _isListening = false;
    debugPrint('AmbientLightService: Écoute arrêtée');
  }

  /// Callback appelé quand la luminosité change
  void _onLightChanged(int luxValue) {
    // Annuler le timer précédent
    _debounceTimer?.cancel();

    // Créer un nouveau timer de debounce
    _debounceTimer = Timer(_debounceDuration, () {
      final shouldBeDark = luxValue < _luxThreshold;

      if (shouldBeDark != _isDark) {
        _isDark = shouldBeDark;
        debugPrint(
          'AmbientLightService: Changement détecté - '
          '$luxValue lux → ${_isDark ? "SOMBRE" : "CLAIR"}'
        );
        _notifyListeners();
      }
    });
  }

  /// Libérer les ressources
  void dispose() {
    stopListening();
    _listeners.clear();
  }
}
