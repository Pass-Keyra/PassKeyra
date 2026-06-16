import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../platform/platform_capabilities.dart';

/// Service pour gérer les demandes d'avis sur l'App Store / Play Store
///
/// Utilise une stratégie multi-critères pour demander un avis au bon moment :
/// - 5+ mots de passe sauvegardés
/// - 15+ déverrouillages réussis
/// - 7+ jours d'utilisation
/// - 10+ lancements de l'application
class ReviewService {
  // Singleton pattern
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  // Clés SharedPreferences pour le tracking
  static const String _passwordCountKey = 'review_password_count';
  static const String _launchCountKey = 'review_launch_count';
  static const String _unlockCountKey = 'review_unlock_count';
  static const String _firstInstallKey = 'review_first_install_date';
  static const String _reviewRequestedKey = 'review_requested';
  static const String _lastRequestDateKey = 'review_last_request_date';

  // Seuils pour déclencher la demande d'avis
  static const int _minPasswordCount = 5;
  static const int _minUnlockCount = 15;
  static const int _minLaunchCount = 10;
  static const int _minDaysSinceInstall = 7;

  /// Initialise le service (appeler au premier lancement)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Enregistrer la date de première installation si pas encore fait
    if (!prefs.containsKey(_firstInstallKey)) {
      await prefs.setString(
        _firstInstallKey,
        DateTime.now().toIso8601String(),
      );
    }
  }

  /// Incrémente le compteur de mots de passe sauvegardés
  Future<void> incrementPasswordCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_passwordCountKey) ?? 0;
    await prefs.setInt(_passwordCountKey, currentCount + 1);
  }

  /// Incrémente le compteur de lancements de l'application
  Future<void> incrementLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_launchCountKey) ?? 0;
    await prefs.setInt(_launchCountKey, currentCount + 1);
  }

  /// Incrémente le compteur de déverrouillages réussis
  Future<void> incrementUnlockCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_unlockCountKey) ?? 0;
    await prefs.setInt(_unlockCountKey, currentCount + 1);
  }

  /// Vérifie si les conditions sont remplies et demande un avis si approprié
  ///
  /// Retourne true si l'avis a été demandé, false sinon
  Future<bool> checkAndRequestReview() async {
    final prefs = await SharedPreferences.getInstance();

    // Ne pas redemander si déjà fait
    final reviewRequested = prefs.getBool(_reviewRequestedKey) ?? false;
    if (reviewRequested) {
      return false;
    }

    // Vérifier si au moins un critère est rempli
    final shouldRequest = await _shouldRequestReview();

    if (shouldRequest) {
      await _requestReviewInternal(prefs);
      return true;
    }

    return false;
  }

  /// Demande manuellement un avis (depuis les paramètres)
  Future<void> requestReviewManually() async {
    final prefs = await SharedPreferences.getInstance();
    await _requestReviewInternal(prefs);
  }

  /// Logique interne pour demander un avis
  Future<void> _requestReviewInternal(SharedPreferences prefs) async {
    if (!supportsInAppReview) return;
    try {
      // Vérifier si la demande d'avis est disponible
      if (await _inAppReview.isAvailable()) {
        // Demander l'avis
        await _inAppReview.requestReview();

        // Marquer comme demandé
        await prefs.setBool(_reviewRequestedKey, true);
        await prefs.setString(
          _lastRequestDateKey,
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      // En cas d'erreur, ne rien faire (ne pas bloquer l'utilisateur)
      debugPrint('Erreur lors de la demande d\'avis: $e');
    }
  }

  /// Vérifie si au moins un critère est rempli pour demander un avis
  Future<bool> _shouldRequestReview() async {
    final prefs = await SharedPreferences.getInstance();

    // Récupérer les compteurs
    final passwordCount = prefs.getInt(_passwordCountKey) ?? 0;
    final unlockCount = prefs.getInt(_unlockCountKey) ?? 0;
    final launchCount = prefs.getInt(_launchCountKey) ?? 0;

    // Calculer les jours depuis l'installation
    final firstInstallStr = prefs.getString(_firstInstallKey);
    int daysSinceInstall = 0;
    if (firstInstallStr != null) {
      final firstInstall = DateTime.parse(firstInstallStr);
      daysSinceInstall = DateTime.now().difference(firstInstall).inDays;
    }

    // Vérifier si au moins un critère est rempli
    return passwordCount >= _minPasswordCount ||
           unlockCount >= _minUnlockCount ||
           launchCount >= _minLaunchCount ||
           daysSinceInstall >= _minDaysSinceInstall;
  }

  /// Obtient les statistiques actuelles (pour debug/affichage)
  Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();

    final firstInstallStr = prefs.getString(_firstInstallKey);
    int daysSinceInstall = 0;
    if (firstInstallStr != null) {
      final firstInstall = DateTime.parse(firstInstallStr);
      daysSinceInstall = DateTime.now().difference(firstInstall).inDays;
    }

    return {
      'passwordCount': prefs.getInt(_passwordCountKey) ?? 0,
      'unlockCount': prefs.getInt(_unlockCountKey) ?? 0,
      'launchCount': prefs.getInt(_launchCountKey) ?? 0,
      'daysSinceInstall': daysSinceInstall,
      'reviewRequested': prefs.getBool(_reviewRequestedKey) ?? false,
      'shouldRequest': await _shouldRequestReview(),
    };
  }

  /// Réinitialise tous les compteurs (pour debug uniquement)
  Future<void> resetForDebug() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordCountKey);
    await prefs.remove(_launchCountKey);
    await prefs.remove(_unlockCountKey);
    await prefs.remove(_reviewRequestedKey);
    await prefs.remove(_lastRequestDateKey);
    // On garde _firstInstallKey pour ne pas perdre la date d'origine
  }
}
