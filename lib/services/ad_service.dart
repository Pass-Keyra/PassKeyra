import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../platform/platform_capabilities.dart';
import 'consent_service.dart';
import 'premium_service.dart';

/// Service de gestion des publicités AdMob
/// Affiche des bannières uniquement si l'utilisateur n'est pas premium
/// Respecte le consentement RGPD/TCF pour les utilisateurs européens
class AdService {
  static AdService? _instance;

  AdService._();

  static AdService get instance {
    _instance ??= AdService._();
    return _instance!;
  }

  /// Initialise AdMob
  Future<void> init() async {
    if (!supportsAds) return;
    debugPrint('Initialisation AdMob...');
    try {
      final initResult = await MobileAds.instance.initialize();
      debugPrint('AdMob initialisé: $initResult');
      debugPrint('Statut Premium: ${PremiumService().isPremium}');
    } catch (e) {
      debugPrint('Erreur initialisation AdMob: $e');
    }
  }

  /// Vérifie si l'utilisateur est premium (utilise PremiumService)
  bool get isPremium => PremiumService().isPremium;
  
  /// Crée une bannière publicitaire (à afficher en bas de HomePage)
  /// Retourne null si l'utilisateur est premium ou si le consentement n'est pas donné
  Future<BannerAd?> createBannerAd() async {
    if (!supportsAds) return null;
    if (isPremium) {
      debugPrint('Utilisateur Premium - Pas de publicité');
      return null;
    }

    // Vérifier le consentement RGPD avant d'afficher des pubs
    final canShowAds = await ConsentService.instance.canShowAds();
    if (!canShowAds) {
      debugPrint('Consentement non donné - Pas de publicité');
      return null;
    }

    final adUnitId = _getBannerAdUnitId();
    debugPrint('Création bannière pub avec ID: $adUnitId');

    return BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('BannerAd chargée avec succès!'),
        onAdFailedToLoad: (ad, error) {
          debugPrint('Échec chargement BannerAd: $error');
          ad.dispose();
        },
        onAdOpened: (ad) => debugPrint('BannerAd ouverte'),
        onAdClosed: (ad) => debugPrint('BannerAd fermée'),
      ),
    );
  }
  
  /// Retourne l'ID de l'annonce banner (Production)
  String _getBannerAdUnitId() {
    if (Platform.isAndroid) {
      // ID de production Android
      return 'ca-app-pub-9620704693689273/7535799145';
    } else if (Platform.isIOS) {
      // ID de test iOS (à remplacer si vous publiez sur iOS)
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }
}


