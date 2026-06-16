import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer la langue de l'application
///
/// Permet de changer et persister la langue choisie par l'utilisateur
class LanguageService extends ChangeNotifier {
  // Singleton pattern
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const String _languageKey = 'app_language';

  // Langue actuelle (par défaut français)
  Locale _currentLocale = const Locale('fr');

  Locale get currentLocale => _currentLocale;

  /// Initialise le service et charge la langue sauvegardée
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);

    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
      notifyListeners();
    }
  }

  /// Change la langue de l'application
  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;

    _currentLocale = locale;

    // Sauvegarder la préférence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);

    // Notifier les listeners pour reconstruire l'UI
    notifyListeners();
  }

  /// Change la langue par code (pratique pour les dropdowns)
  Future<void> setLanguageByCode(String languageCode) async {
    await setLocale(Locale(languageCode));
  }

  /// Retourne true si la langue est le français
  bool get isFrench => _currentLocale.languageCode == 'fr';

  /// Retourne true si la langue est l'anglais
  bool get isEnglish => _currentLocale.languageCode == 'en';

  /// Retourne true si la langue est l'espagnol
  bool get isSpanish => _currentLocale.languageCode == 'es';
}
