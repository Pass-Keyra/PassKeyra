import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ambient_light_service.dart';

enum DarkThemeVariant {
  standard,     // Gratuit - mode sombre standard
  amoledBlack,  // Premium - noir pur #000000
  darkGrey,     // Premium - gris foncé personnalisé
}

enum ColorPalette {
  blue,      // Gratuit - palette bleue actuelle
  green,     // Premium - palette verte
  redPink,   // Premium - palette rouge/rose
  purple,    // Premium - palette violette
  orange,    // Premium - palette orange
}

enum FontFamily {
  roboto,      // Gratuit - police par défaut
  lato,        // Premium - police Lato
  montserrat,  // Premium - police Montserrat
  openSans,    // Premium - police Open Sans
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeModeKey = 'theme_mode';
  static const String _darkVariantKey = 'dark_theme_variant';
  static const String _colorPaletteKey = 'color_palette';
  static const String _fontFamilyKey = 'font_family';

  ThemeMode _themeMode = ThemeMode.system;
  DarkThemeVariant _darkVariant = DarkThemeVariant.standard;
  ColorPalette _colorPalette = ColorPalette.blue;
  FontFamily _fontFamily = FontFamily.roboto;
  bool _isInitialized = false;

  final _ambientLightService = AmbientLightService();
  Brightness? _currentBrightness; // Brightness actuel selon le capteur de luminosité

  ThemeMode get themeMode => _themeMode;
  DarkThemeVariant get darkVariant => _darkVariant;
  ColorPalette get colorPalette => _colorPalette;
  FontFamily get fontFamily => _fontFamily;
  bool get isInitialized => _isInitialized;

  /// Retourne le ThemeMode effectif à utiliser par MaterialApp
  /// En mode automatique, retourne light/dark selon le capteur
  ThemeMode get effectiveThemeMode {
    // Mode manuel : retourner le mode configuré
    if (_themeMode != ThemeMode.system) {
      return _themeMode;
    }

    // Mode automatique : utiliser le capteur si disponible
    if (_currentBrightness != null) {
      return _currentBrightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light;
    }

    // Fallback : utiliser la préférence système
    return ThemeMode.system;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();

    // Charger le ThemeMode
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeModeIndex];

    // Charger la variante de mode sombre
    final darkVariantIndex = prefs.getInt(_darkVariantKey) ?? DarkThemeVariant.standard.index;
    _darkVariant = DarkThemeVariant.values[darkVariantIndex];

    // Charger la palette de couleurs
    final colorPaletteIndex = prefs.getInt(_colorPaletteKey) ?? ColorPalette.blue.index;
    _colorPalette = ColorPalette.values[colorPaletteIndex];

    // Charger la police
    final fontFamilyIndex = prefs.getInt(_fontFamilyKey) ?? FontFamily.roboto.index;
    _fontFamily = FontFamily.values[fontFamilyIndex];

    // Initialiser le capteur de luminosité si mode automatique
    _initLightSensor();

    _isInitialized = true;
    notifyListeners();
  }

  /// Initialise le capteur de luminosité pour le mode automatique
  void _initLightSensor() {
    if (_themeMode == ThemeMode.system) {
      // Écouter les changements de luminosité
      _ambientLightService.addListener(_onLightChanged);
      // Démarrer le capteur immédiatement
      _ambientLightService.startListening();
    }
  }

  /// Callback appelé quand la luminosité change
  void _onLightChanged(bool isDark) {
    _currentBrightness = isDark ? Brightness.dark : Brightness.light;
    notifyListeners();
  }

  /// Démarrer l'écoute du capteur (appelé quand l'app passe au premier plan)
  void startLightSensor() {
    if (_themeMode == ThemeMode.system) {
      _ambientLightService.startListening();
    }
  }

  /// Arrêter l'écoute du capteur (appelé quand l'app passe en arrière-plan)
  void stopLightSensor() {
    _ambientLightService.stopListening();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    final oldMode = _themeMode;
    _themeMode = mode;

    // Gérer le capteur de luminosité selon le nouveau mode
    if (mode == ThemeMode.system && oldMode != ThemeMode.system) {
      // Activer le capteur
      _ambientLightService.addListener(_onLightChanged);
      startLightSensor();
    } else if (mode != ThemeMode.system && oldMode == ThemeMode.system) {
      // Désactiver le capteur
      stopLightSensor();
      _ambientLightService.removeListener(_onLightChanged);
      _currentBrightness = null;
    }

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setDarkVariant(DarkThemeVariant variant) async {
    if (_darkVariant == variant) return;

    _darkVariant = variant;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_darkVariantKey, variant.index);
  }

  Future<void> setColorPalette(ColorPalette palette) async {
    if (_colorPalette == palette) return;

    _colorPalette = palette;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorPaletteKey, palette.index);
  }

  Future<void> setFontFamily(FontFamily font) async {
    if (_fontFamily == font) return;

    _fontFamily = font;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontFamilyKey, font.index);
  }

  @override
  void dispose() {
    _ambientLightService.removeListener(_onLightChanged);
    _ambientLightService.stopListening();
    super.dispose();
  }

  // Helper pour savoir si on utilise le mode sombre actuellement
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;

    // ThemeMode.system - utiliser le capteur de luminosité si disponible
    if (_currentBrightness != null) {
      return _currentBrightness == Brightness.dark;
    }

    // Fallback sur la préférence système si capteur non disponible
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }
}
