import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../platform/platform_capabilities.dart';

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  static const String monthlySubscriptionId = 'passkeyra_premium_monthly';
  static const String yearlySubscriptionId = 'passkeyra_premium_yearly';
  static const String lifetimeId = 'passkeyra_premium_lifetime';
  
  static const String _premiumKey = 'is_premium_user';
  
  // État du premium
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  /// Stream broadcastant tout changement du statut Premium (true/false).
  /// Permet aux services background (sync, auto-backup) de réagir au revoke
  /// sans avoir à poll régulièrement `isPremium`.
  final _premiumStatusController = StreamController<bool>.broadcast();
  Stream<bool> get premiumStatusChanges => _premiumStatusController.stream;

  // Produits disponibles
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;
  
  /// Initialiser le service Premium
  Future<void> initialize() async {
    // Charger l'état premium depuis les préférences (toutes plateformes).
    // Sur desktop V1, c'est la seule source ; Firestore prendra le relais en Phase 5.
    await _loadPremiumStatus();

    // IAP indisponible sur desktop : pas de stream, pas de chargement produits.
    if (!supportsIAP) {
      if (kDebugMode) debugPrint('IAP non supporté sur cette plateforme — Premium lu depuis SharedPreferences uniquement');
      return;
    }

    // Vérifier la disponibilité des achats
    final bool available = await _iap.isAvailable();
    if (!available) {
      if (kDebugMode) debugPrint('IAP non disponible');
      return;
    }

    // Écouter les mises à jour d'achat
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) { if (kDebugMode) debugPrint('Erreur IAP: $error'); },
    );

    // Charger les produits disponibles
    await _loadProducts();

    // Restaurer les achats précédents
    await restorePurchases();
  }
  
  /// Charger les produits depuis Google Play
  Future<void> _loadProducts() async {
    const Set<String> productIds = {
      monthlySubscriptionId,
      yearlySubscriptionId,
      lifetimeId,
    };
    
    final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
    
    if (response.notFoundIDs.isNotEmpty && kDebugMode) {
      debugPrint('Produits non trouvés: ${response.notFoundIDs}');
    }
    
    _products = response.productDetails;
  }
  
  /// Charger le statut premium depuis les préférences
  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumKey) ?? false;
  }
  
  /// Sauvegarder le statut premium et notifier les abonnés du stream.
  Future<void> _savePremiumStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = _isPremium;
    await prefs.setBool(_premiumKey, status);
    _isPremium = status;
    // Ne marquer le tutoriel à montrer QUE sur transition non-premium → premium.
    // Sinon les replays "restored" du purchaseStream relanceraient le tutoriel
    // à chaque démarrage d'app.
    if (status && !previous) {
      await prefs.setBool('pending_premium_tutorial', true);
    }
    // Notifier seulement sur changement réel pour éviter les actions redondantes.
    if (previous != status) {
      _premiumStatusController.add(status);
    }
  }
  
  /// Gérer les mises à jour d'achat
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
          await _savePremiumStatus(true);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        case PurchaseStatus.restored:
          await _savePremiumStatus(true);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        case PurchaseStatus.pending:
          // Achat en attente de validation (ex: paiement différé)
          break;
        case PurchaseStatus.canceled:
          break;
        case PurchaseStatus.error:
          if (kDebugMode) debugPrint('Erreur achat: ${purchase.error}');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
      }
    }
  }
  
  /// Acheter un produit
  Future<bool> purchaseProduct(ProductDetails product) async {
    if (!supportsIAP) return false;
    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors de l\'achat: $e');
      return false;
    }
  }

  /// Restaurer les achats précédents
  Future<void> restorePurchases() async {
    if (!supportsIAP) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur restauration: $e');
    }
  }
  
  /// **EASTER EGG DEBUG** : bascule le statut Premium localement.
  ///
  /// ⚠️ **À DÉSACTIVER AVANT TOUT BUILD AAB PLAY STORE** (revenue leak) :
  /// l'easter egg de bascule fait partie de la checklist obligatoire pré-release.
  ///
  /// Déclenché par 7 clics rapides sur l'icône info de la page "À propos
  /// et support" (`SettingsAboutSupportPage`). Pratique pour le dev/QA :
  /// permet de basculer freemium ↔ premium sans passer par Play Billing.
  Future<bool> togglePremiumDebug() async {
    await _savePremiumStatus(!_isPremium);
    return _isPremium;
  }

  /// Vérifier si une fonctionnalité est premium
  bool isFeaturePremium(String featureId) {
    // Liste des fonctionnalités premium
    const premiumFeatures = {
      'cloud_backup',
      'custom_themes',
      'priority_support',
      'advanced_security',
    };
    
    return premiumFeatures.contains(featureId) && !_isPremium;
  }
  
  /// Obtenir le produit par ID
  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }
  
  /// Nettoyer les ressources
  void dispose() {
    _subscription?.cancel();
    _premiumStatusController.close();
  }
}





