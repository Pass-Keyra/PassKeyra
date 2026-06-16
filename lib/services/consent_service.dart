import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../platform/platform_capabilities.dart';

/// Service de gestion du consentement RGPD pour AdMob
/// Implémente Google User Messaging Platform (UMP) pour la conformité RGPD/TCF
class ConsentService {
  static const String _consentStatusKey = 'consent_status';
  static const String _lastConsentCheckKey = 'last_consent_check';

  static ConsentService? _instance;
  ConsentStatus _consentStatus = ConsentStatus.unknown;

  ConsentService._();

  static ConsentService get instance {
    _instance ??= ConsentService._();
    return _instance!;
  }

  /// Initialise et demande le consentement si nécessaire
  /// DOIT être appelé AVANT l'initialisation d'AdMob
  Future<void> requestConsentIfNeeded() async {
    if (!supportsAds) return; // Pas de pub desktop → pas de UMP
    debugPrint('ConsentService - Vérification du consentement RGPD...');

    // Charger le statut de consentement sauvegardé
    await _loadConsentStatus();

    // Configuration de la demande de consentement
    final params = ConsentRequestParameters(
      // Pour le développement, vous pouvez ajouter un device de test
      // consentDebugSettings: ConsentDebugSettings(
      //   debugGeography: DebugGeography.debugGeographyEea,
      //   testIdentifiers: ['YOUR_TEST_DEVICE_ID'],
      // ),
    );

    try {
      // Demande les informations de consentement
      ConsentInformation.instance.requestConsentInfoUpdate(params, () {
        debugPrint('ConsentService - Informations de consentement récupérées');
      }, (error) {
        debugPrint('ConsentService - Erreur requestConsentInfoUpdate: ${error.message}');
      });

      // Vérifie si un formulaire de consentement doit être affiché
      if (await ConsentInformation.instance.isConsentFormAvailable()) {
        _consentStatus = await ConsentInformation.instance.getConsentStatus();
        debugPrint('ConsentService - Statut actuel: $_consentStatus');

        // Si le consentement est requis, charger et afficher le formulaire
        if (_consentStatus == ConsentStatus.required) {
          await _loadAndShowConsentForm();
        }
      }

      // Sauvegarder le statut
      await _saveConsentStatus();
      _consentStatus = await ConsentInformation.instance.getConsentStatus();
      debugPrint('ConsentService - Statut final: $_consentStatus');

    } catch (e) {
      debugPrint('ConsentService - Erreur lors de la demande de consentement: $e');
      // En cas d'erreur, on continue sans bloquer l'app
      _consentStatus = ConsentStatus.unknown;
    }
  }

  /// Charge et affiche le formulaire de consentement
  Future<void> _loadAndShowConsentForm() async {
    debugPrint('ConsentService - Chargement du formulaire de consentement...');

    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        debugPrint('ConsentService - Erreur formulaire: ${error?.message}');
      });
      debugPrint('ConsentService - Formulaire affiché avec succès');
    } catch (e) {
      debugPrint('ConsentService - Erreur lors de l\'affichage du formulaire: $e');
    }
  }

  /// Affiche le formulaire de consentement pour permettre à l'utilisateur
  /// de modifier ses préférences (à appeler depuis les paramètres)
  Future<void> showConsentForm() async {
    debugPrint('ConsentService - Affichage du formulaire de confidentialité...');

    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        debugPrint('ConsentService - Erreur formulaire: ${error?.message}');
      });
      _consentStatus = await ConsentInformation.instance.getConsentStatus();
      await _saveConsentStatus();
      debugPrint('ConsentService - Préférences mises à jour: $_consentStatus');
    } catch (e) {
      debugPrint('ConsentService - Erreur lors de l\'affichage du formulaire: $e');
    }
  }

  /// Réinitialise le consentement (pour les tests uniquement)
  Future<void> resetConsent() async {
    await ConsentInformation.instance.reset();
    _consentStatus = ConsentStatus.unknown;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consentStatusKey);
    await prefs.remove(_lastConsentCheckKey);
    debugPrint('ConsentService - Consentement réinitialisé');
  }

  /// Sauvegarde le statut de consentement
  Future<void> _saveConsentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_consentStatusKey, _consentStatus.index);
    await prefs.setInt(_lastConsentCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Charge le statut de consentement sauvegardé
  Future<void> _loadConsentStatus() async {
    try {
      _consentStatus = await ConsentInformation.instance.getConsentStatus();
    } catch (e) {
      debugPrint('ConsentService - Erreur lors du chargement du statut: $e');
      _consentStatus = ConsentStatus.unknown;
    }
  }

  /// Vérifie si l'utilisateur peut voir des publicités personnalisées
  Future<bool> canShowAds() async {
    if (!supportsAds) return false; // Desktop : jamais de pub
    _consentStatus = await ConsentInformation.instance.getConsentStatus();

    // On peut afficher des pubs si:
    // - Le consentement est obtenu (publicités personnalisées)
    // - Le consentement n'est pas requis (hors EEE)
    // - Le consentement est inconnu (on laisse AdMob gérer)
    return _consentStatus == ConsentStatus.obtained ||
           _consentStatus == ConsentStatus.notRequired ||
           _consentStatus == ConsentStatus.unknown;
  }

  /// Vérifie si l'utilisateur peut voir des publicités personnalisées
  Future<bool> canShowPersonalizedAds() async {
    _consentStatus = await ConsentInformation.instance.getConsentStatus();
    return _consentStatus == ConsentStatus.obtained;
  }

  /// Retourne le statut actuel du consentement
  ConsentStatus get consentStatus => _consentStatus;

  /// Vérifie si l'utilisateur est dans une région nécessitant le consentement (EEE, UK, CH)
  Future<bool> isConsentRequired() async {
    try {
      _consentStatus = await ConsentInformation.instance.getConsentStatus();
      return _consentStatus == ConsentStatus.required;
    } catch (e) {
      debugPrint('ConsentService - Erreur vérification consentement requis: $e');
      return false;
    }
  }
}
