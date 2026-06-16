import 'dart:ui';
import 'package:flutter/material.dart';
import '../app/app.dart';
import '../app/keyboard_shortcuts.dart';
import '../platform/platform_capabilities.dart';
import '../services/onboarding_service.dart';
import 'keyboard_shortcut_hint.dart';

/// Résultat d'une étape de coach mark
enum CoachStepResult {
  primary,  // Bouton principal cliqué (Suivant/Continuer)
  skip,     // Ignorer ou fermer
  finish,   // Terminer
}

/// Système de coach marks réutilisable avec halos pulsants et flou
class CoachMarkSystem {
  /// Affiche une étape de coach mark avec halo pulsant autour d'un élément ciblé
  ///
  /// [context] - BuildContext de la page
  /// [targetKey] - GlobalKey de l'élément à mettre en surbrillance
  /// [pulseController] - AnimationController pour l'animation de pulsation (900ms repeat)
  /// [title] - Titre du coach mark
  /// [message] - Message d'explication
  /// [primaryLabel] - Label du bouton principal
  /// [secondaryLabel] - Label du bouton secondaire (optionnel)
  /// [onWrongClick] - Callback appelé quand l'utilisateur clique hors de la cible (mode interactif)
  /// [clearFocusInset] - Marge autour de l'élément pour la zone claire (par défaut calculé dynamiquement)
  /// [clearFocusRadius] - Rayon des coins de la zone claire (par défaut calculé dynamiquement)
  static Future<CoachStepResult> showCoachStep({
    required BuildContext context,
    required GlobalKey targetKey,
    required AnimationController pulseController,
    required String title,
    required String message,
    required String primaryLabel,
    String? secondaryLabel,
    VoidCallback? onWrongClick,
    double? clearFocusInset,
    double? clearFocusRadius,
    bool fullWidth = false,
    String? stepIndicator,
    AppShortcut? shortcut,
  }) async {
    // Court-circuit global : si l'utilisateur a cliqué "Quitter" pendant cette
    // session, tous les coach marks suivants retournent skip immédiatement
    // sans afficher de dialog. Évite que les callers (settings_page, etc.)
    // qui ne font pas un return entre les étapes continuent à afficher des
    // coach marks après le quit.
    if (OnboardingService.instance.userQuitInCurrentSession) {
      return CoachStepResult.skip;
    }
    final targetContext = targetKey.currentContext;

    // Si le target n'existe pas, afficher un dialog classique
    if (targetContext == null) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (secondaryLabel != null)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(secondaryLabel),
              ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(primaryLabel),
            ),
          ],
        ),
      );
      return result == true ? CoachStepResult.primary : CoachStepResult.skip;
    }

    final renderBox = targetContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return CoachStepResult.skip;
    }

    final overlayRenderBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
    Rect? targetRect;
    Rect? clearFocusRect;
    double finalClearFocusRadius = clearFocusRadius ?? 18;

    if (overlayRenderBox != null) {
      final targetTopLeft = renderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
      final rawRect = Rect.fromLTWH(
        targetTopLeft.dx,
        targetTopLeft.dy,
        renderBox.size.width,
        renderBox.size.height,
      );
      targetRect = rawRect;

      // Calculer l'inset dynamiquement si non fourni
      final baseInset = clearFocusInset ?? (rawRect.longestSide * 0.30).clamp(10.0, 16.0).toDouble();
      final inflated = rawRect.inflate(baseInset);

      // fullWidth : étendre la zone jusqu'aux bords gauche/droit de l'écran
      clearFocusRect = fullWidth
          ? Rect.fromLTRB(0, inflated.top, overlayRenderBox.size.width, inflated.bottom)
          : inflated;

      // Calculer le radius dynamiquement si non fourni
      if (clearFocusRadius == null) {
        finalClearFocusRadius = (rawRect.width > 200) ? 14 : 34;
      }
    }

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: onWrongClick != null, // Interactif si onWrongClick fourni
      barrierLabel: 'coach',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _CoachMarkOverlay(
          targetRect: targetRect,
          clearFocusRect: clearFocusRect,
          clearFocusRadius: finalClearFocusRadius,
          pulseController: pulseController,
          title: title,
          message: message,
          primaryLabel: primaryLabel,
          secondaryLabel: secondaryLabel,
          onWrongClick: onWrongClick,
          stepIndicator: stepIndicator,
          shortcut: shortcut,
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
    );

    if (result == true) {
      return CoachStepResult.primary;
    }
    // L'utilisateur a cliqué "Quitter" : marque TOUS les tutoriels comme
    // terminés (onboarding initial + découverte) pour ne plus le réembêter.
    // Il peut toujours les rejouer manuellement via Mode Découverte.
    await OnboardingService.instance.quitAllTutorials();
    return CoachStepResult.skip;
  }

  /// Construit un halo pulsant autour d'un widget
  ///
  /// Utilisé pour mettre en surbrillance un élément pendant le tutoriel
  /// [key] - GlobalKey pour identifier et positionner l'élément
  /// [child] - Widget à entourer
  /// [pulseController] - AnimationController pour l'animation
  /// [isActive] - Si le halo doit être visible et animé
  /// [shape] - Forme du halo (rectangle ou cercle)
  /// [borderRadius] - Rayon des coins pour les rectangles
  /// [includeBorder] - Inclure une bordure autour de l'élément
  /// [padding] - Padding autour de l'élément
  static Widget buildHalo({
    Key? key,
    required Widget child,
    required AnimationController pulseController,
    required bool isActive,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
    bool includeBorder = false,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    // Desktop : halo STATIQUE (bordure + glow fixe) au lieu d'AnimatedBuilder
    // qui rebuilds un BoxShadow blur à 60fps. C'était la principale source de
    // lags du didacticiel sur Windows (GPU saturé par les recalculs de blur).
    if (isDesktop) {
      return Container(
        key: key,
        padding: padding,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
          border: includeBorder && isActive
              ? Border.all(
                  color: PassKeyraColors.primary.withValues(alpha: 0.65),
                  width: 1.4,
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: PassKeyraColors.primary.withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : const [],
        ),
        child: child,
      );
    }

    return AnimatedBuilder(
      key: key,
      animation: pulseController,
      child: child,
      builder: (context, childWidget) {
        final pulse = pulseController.value;
        final glowAlpha = isActive ? (0.25 + (pulse * 0.35)) : 0.0;
        final blurRadius = isActive ? (12.0 + (pulse * 12.0)) : 0.0;
        final spreadRadius = isActive ? (1.0 + (pulse * 2.0)) : 0.0;
        final scale = isActive ? (1.0 + (pulse * 0.015)) : 1.0;

        return AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              shape: shape,
              borderRadius: shape == BoxShape.rectangle ? borderRadius : null,
              border: includeBorder && isActive
                  ? Border.all(
                      color: PassKeyraColors.primary.withValues(alpha: 0.65),
                      width: 1.4,
                    )
                  : null,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: PassKeyraColors.primary.withValues(alpha: glowAlpha),
                        blurRadius: blurRadius,
                        spreadRadius: spreadRadius,
                      ),
                    ]
                  : const [],
            ),
            child: childWidget,
          ),
        );
      },
    );
  }
}

/// Widget d'overlay pour afficher le coach mark
class _CoachMarkOverlay extends StatelessWidget {
  final Rect? targetRect;
  final Rect? clearFocusRect;
  final double clearFocusRadius;
  final AnimationController pulseController;
  final String title;
  final String message;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onWrongClick;
  final String? stepIndicator;
  final AppShortcut? shortcut;

  const _CoachMarkOverlay({
    required this.targetRect,
    required this.clearFocusRect,
    required this.clearFocusRadius,
    required this.pulseController,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.secondaryLabel,
    this.onWrongClick,
    this.stepIndicator,
    this.shortcut,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Clamper les rectangles dans les limites de l'écran (LTRB évite le bug
    // où left+width > screenWidth coupe le côté droit mais laisse un bord gauche)
    final anchorRect = targetRect == null
        ? null
        : Rect.fromLTRB(
            targetRect!.left.clamp(0.0, screenSize.width),
            targetRect!.top.clamp(0.0, screenSize.height),
            targetRect!.right.clamp(0.0, screenSize.width),
            targetRect!.bottom.clamp(0.0, screenSize.height),
          );

    final focusRect = clearFocusRect == null
        ? null
        : Rect.fromLTRB(
            clearFocusRect!.left.clamp(0.0, screenSize.width),
            clearFocusRect!.top.clamp(0.0, screenSize.height),
            clearFocusRect!.right.clamp(0.0, screenSize.width),
            clearFocusRect!.bottom.clamp(0.0, screenSize.height),
          );

    // Calculer la position de la carte
    const horizontalMargin = 12.0;
    const verticalMargin = 16.0;
    const targetSpacing = 12.0;
    const estimatedCardHeight = 168.0;
    final cardWidth = (screenSize.width * 0.78).clamp(250.0, 330.0).toDouble();

    final placeAboveTarget = anchorRect == null
        ? false
        : anchorRect.center.dy > (screenSize.height * 0.52);

    final cardTop = anchorRect == null
        ? verticalMargin
        : (placeAboveTarget
            ? anchorRect.top - estimatedCardHeight - targetSpacing
            : anchorRect.bottom + targetSpacing);

    final clampedCardTop = cardTop
        .clamp(
          verticalMargin,
          screenSize.height - estimatedCardHeight - verticalMargin,
        )
        .toDouble();

    final rawCardLeft = anchorRect == null
        ? ((screenSize.width - cardWidth) / 2)
        : (anchorRect.center.dx - (cardWidth / 2));

    final clampedCardLeft = rawCardLeft
        .clamp(
          horizontalMargin,
          screenSize.width - cardWidth - horizontalMargin,
        )
        .toDouble();

    return GestureDetector(
      // Mode interactif : détecter les clics hors cible
      onTap: () {
        if (onWrongClick != null) {
          onWrongClick!();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fond avec trou pour la cible.
          // Sur desktop : overlay opaque (pas de BackdropFilter blur, GPU killer).
          // Sur mobile : BackdropFilter avec blur léger (visuel plus fin, GPU OK).
          if (focusRect != null)
            ClipPath(
              clipper: _OverlayExcludeClipper(
                excludedRect: focusRect,
                borderRadius: clearFocusRadius,
              ),
              child: isDesktop
                  ? Container(color: Colors.black.withValues(alpha: 0.35))
                  : BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
            )
          else if (isDesktop)
            Container(color: Colors.black.withValues(alpha: 0.35))
          else
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 1.6, sigmaY: 1.6),
              child: Container(
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ),

          // Carte d'information avec halo pulsant
          Positioned(
            top: clampedCardTop,
            left: clampedCardLeft,
            width: cardWidth,
            child: GestureDetector(
              // Empêcher la propagation du tap à l'overlay parent
              onTap: () {},
              child: AnimatedBuilder(
                animation: pulseController,
                builder: (context, child) {
                  final pulse = pulseController.value;
                  final glowAlpha = 0.18 + (pulse * 0.2);
                  final blurRadius = 14.0 + (pulse * 12.0);
                  final spreadRadius = 0.8 + (pulse * 1.6);

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: PassKeyraColors.primary.withValues(alpha: glowAlpha),
                          blurRadius: blurRadius,
                          spreadRadius: spreadRadius,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Material(
                  color: Colors.transparent,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: PassKeyraColors.primary.withValues(alpha: 0.45),
                        width: 1.4,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: PassKeyraColors.primary,
                                  ),
                                ),
                              ),
                              if (stepIndicator != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: PassKeyraColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    stepIndicator!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: PassKeyraColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          // Affiche le raccourci clavier desktop si la feature
                          // en a un. Strict desktop only (mobile = pas de clavier).
                          if (isDesktop && shortcut != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Raccourci : ',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                KeyboardShortcutHint(shortcut: shortcut!),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final maxPrimaryWidth = (constraints.maxWidth * 0.68)
                                  .clamp(160.0, 240.0)
                                  .toDouble();

                              return Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  if (secondaryLabel != null)
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      child: Text(secondaryLabel!),
                                    ),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: maxPrimaryWidth,
                                    ),
                                    child: FilledButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
                                      child: Text(
                                        primaryLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomClipper pour créer un trou dans l'overlay flouté
class _OverlayExcludeClipper extends CustomClipper<Path> {
  final Rect excludedRect;
  final double borderRadius;

  const _OverlayExcludeClipper({
    required this.excludedRect,
    required this.borderRadius,
  });

  @override
  Path getClip(Size size) {
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          excludedRect,
          Radius.circular(borderRadius),
        ),
      );
    return Path.combine(PathOperation.difference, full, hole);
  }

  @override
  bool shouldReclip(covariant _OverlayExcludeClipper oldClipper) {
    return oldClipper.excludedRect != excludedRect ||
        oldClipper.borderRadius != borderRadius;
  }
}
