import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../app/app.dart';
import '../services/auto_close_service.dart';
import '../services/premium_service.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});
  static const String route = '/premium';

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  final _premiumService = PremiumService();
  bool _isLoading = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    setState(() {
      _isPremium = _premiumService.isPremium;
    });
  }

  Future<void> _purchaseProduct(ProductDetails product) async {
    setState(() => _isLoading = true);

    try {
      final success = await _premiumService.purchaseProduct(product);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Achat réussi ! Merci pour votre soutien.'),
              backgroundColor: PassKeyraColors.success,
            ),
          );
          _loadPremiumStatus();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Achat annulé ou échoué'),
              backgroundColor: PassKeyraColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: PassKeyraColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      await _premiumService.restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Achats restaurés'),
            backgroundColor: PassKeyraColors.success,
          ),
        );
        _loadPremiumStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: PassKeyraColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Ouvre la page de redemption Google Play (champ code vide).
  /// L'utilisateur colle son code directement dans Play Store.
  /// Au retour dans l'app, le purchaseStream du PremiumService détecte
  /// automatiquement l'achat via _onPurchaseUpdate.
  Future<void> _openPromoCodeRedemption() async {
    final url = Uri.parse('https://play.google.com/redeem');
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.redeemPromoCodeError),
          backgroundColor: PassKeyraColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.premiumTitle),
        actions: [
          if (_isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: PassKeyraColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => AutoCloseService.instance.onUserActivity(),
        onPanStart: (_) => AutoCloseService.instance.onUserActivity(),
        behavior: HitTestBehavior.translucent,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            AutoCloseService.instance.onUserActivity();
            return false;
          },
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isPremium
                  ? _buildPremiumActiveView()
                  : _buildPurchaseView(),
        ),
      ),
    );
  }

  Widget _buildPremiumActiveView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Premium actif
          Icon(
            Icons.workspace_premium,
            size: 100,
            color: PassKeyraColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Vous êtes Premium !',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PassKeyraColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Merci de soutenir PassKeyra',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: PassKeyraColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Features Premium actives
          Text(
            'Fonctionnalités Premium activées',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PassKeyraColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),

          _buildActiveFeature(
            context,
            icon: Icons.block,
            title: 'Sans publicités',
            description: 'Profitez d\'une expérience sans interruption',
          ),
          const SizedBox(height: 12),

          _buildActiveFeature(
            context,
            icon: Icons.vpn_key_outlined,
            title: 'Mots de passe multiples',
            description: 'Plusieurs mots de passe par entrée',
          ),
          const SizedBox(height: 12),

          _buildActiveFeature(
            context,
            icon: Icons.emoji_emotions_outlined,
            title: 'Icônes personnalisées',
            description: 'Personnalisez vos entrées avec des emojis',
          ),
          const SizedBox(height: 12),

          _buildActiveFeature(
            context,
            icon: Icons.security,
            title: 'Analyse de sécurité avancée',
            description: 'Score de sécurité et détection des mots de passe faibles',
          ),
          const SizedBox(height: 12),

          _buildActiveFeature(
            context,
            icon: Icons.cloud_sync,
            title: 'Synchronisation temps réel',
            description: 'Synchronisation automatique entre vos appareils - fonctionne uniquement avec un compte Google',
          ),
          const SizedBox(height: 12),

          _buildActiveFeature(
            context,
            icon: Icons.backup,
            title: 'Sauvegardes automatiques',
            description: 'Sauvegarde automatique sur votre compte Google Drive ou OneDrive',
          ),
          const SizedBox(height: 12),

          _buildActiveFeature(
            context,
            icon: Icons.phone_android_outlined,
            title: 'Sauvegarde locale automatique',
            description: 'Sauvegarde chiffrée automatique sur votre appareil à chaque modification du coffre',
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseView() {
    // Ordre d'affichage figé (croissant : mensuel → annuel → à vie) — le store
    // peut renvoyer les products dans n'importe quel ordre.
    const displayOrder = [
      PremiumService.monthlySubscriptionId,
      PremiumService.yearlySubscriptionId,
      PremiumService.lifetimeId,
    ];
    final products = [..._premiumService.products]..sort(
        (a, b) => displayOrder.indexOf(a.id).compareTo(displayOrder.indexOf(b.id)),
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Icon(
            Icons.workspace_premium,
            size: 80,
            color: PassKeyraColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'PassKeyra Premium',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PassKeyraColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Soutenez PassKeyra et débloquez toutes les fonctionnalités en illimité !',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: PassKeyraColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Features Premium
          Text(
            'Ce que vous obtenez',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: PassKeyraColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            context,
            icon: Icons.block,
            title: 'Sans publicités',
            description: 'Profitez d\'une expérience fluide sans interruption',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            icon: Icons.vpn_key_outlined,
            title: 'Mots de passe multiples',
            description: 'Stockez plusieurs mots de passe par entrée',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            icon: Icons.emoji_emotions_outlined,
            title: 'Icônes personnalisées',
            description: 'Personnalisez vos entrées avec des emojis colorés',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            icon: Icons.security,
            title: 'Analyse de sécurité avancée',
            description: 'Score de sécurité et détection des mots de passe faibles',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            icon: Icons.cloud_sync,
            title: 'Synchronisation temps réel',
            description: 'Synchronisation automatique entre vos appareils - fonctionne uniquement avec un compte Google',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            icon: Icons.backup,
            title: 'Sauvegardes automatiques',
            description: 'Sauvegarde automatique sur votre compte Google Drive ou OneDrive',
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            icon: Icons.phone_android_outlined,
            title: 'Sauvegarde locale automatique',
            description: 'Sauvegarde chiffrée automatique sur votre appareil à chaque modification du coffre',
          ),

          const SizedBox(height: 32),

          // Offres d'achat
          if (products.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PassKeyraColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PassKeyraColors.info.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: PassKeyraColors.info,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Offres Premium indisponibles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: PassKeyraColors.textPrimary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les offres Premium ne sont pas disponibles pour le moment. Veuillez réessayer ultérieurement.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PassKeyraColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choisissez votre plan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: PassKeyraColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 16),
                for (var product in products) ...[
                  _buildProductCard(context, product),
                  const SizedBox(height: 12),
                ],
              ],
            ),

          const SizedBox(height: 24),

          // Bouton Restaurer + mini-explication contextuelle
          Center(
            child: Text(
              'Déjà abonné sur un autre appareil ou après une réinstallation ?',
              style: TextStyle(
                fontSize: 12,
                color: PassKeyraColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _isLoading ? null : _restorePurchases,
            child: Text(
              'Restaurer mes achats',
              style: TextStyle(
                color: PassKeyraColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _isLoading ? null : _openPromoCodeRedemption,
            icon: Icon(Icons.card_giftcard, size: 18, color: PassKeyraColors.primary),
            label: Text(
              AppLocalizations.of(context)!.havePromoCode,
              style: TextStyle(
                color: PassKeyraColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductDetails product) {
    bool isRecommended = product.id == PremiumService.lifetimeId;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended
              ? PassKeyraColors.primary
              : PassKeyraColors.border,
          width: isRecommended ? 2 : 1,
        ),
        color: isRecommended
            ? PassKeyraColors.primary.withOpacity(0.05)
            : Colors.transparent,
      ),
      child: Column(
        children: [
          if (isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: PassKeyraColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Text(
                'MEILLEURE OFFRE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getProductTitle(product.id),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: PassKeyraColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getProductDescription(product.id),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: PassKeyraColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      product.price,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: PassKeyraColors.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _purchaseProduct(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecommended
                          ? PassKeyraColors.primary
                          : PassKeyraColors.primary.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Souscrire',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProductTitle(String productId) {
    switch (productId) {
      case PremiumService.monthlySubscriptionId:
        return 'Mensuel';
      case PremiumService.yearlySubscriptionId:
        return 'Annuel';
      case PremiumService.lifetimeId:
        return 'À vie';
      default:
        return 'Premium';
    }
  }

  String _getProductDescription(String productId) {
    switch (productId) {
      case PremiumService.monthlySubscriptionId:
        return 'Facturé chaque mois';
      case PremiumService.yearlySubscriptionId:
        return 'Économisez 50%';
      case PremiumService.lifetimeId:
        return 'Un seul paiement, accès illimité';
      default:
        return '';
    }
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: PassKeyraColors.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: PassKeyraColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: PassKeyraColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: PassKeyraColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PassKeyraColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              color: PassKeyraColors.success,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    bool isComingSoon = false,
  }) {
    return Card(
      elevation: 0,
      color: PassKeyraColors.success.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: PassKeyraColors.success.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: PassKeyraColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: PassKeyraColors.success,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: PassKeyraColors.textPrimary,
                              ),
                        ),
                      ),
                      if (isComingSoon)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: PassKeyraColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Bientôt',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: PassKeyraColors.info,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PassKeyraColors.textSecondary,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
