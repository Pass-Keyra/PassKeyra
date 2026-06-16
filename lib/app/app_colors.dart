import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// Classe abstraite définissant la structure d'une palette de couleurs PassKeyra
abstract class AppColorPalette {
  // Couleur principale (pour icônes et éléments de marque)
  Color get primary;

  // Couleur du reflet/glow (utilisée pour le fond des cartes)
  Color get glow;

  // Dégradé de textes (du plus foncé au plus clair)
  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;
  Color get textSubtle;

  // Bordures et séparateurs
  Color get border;
  Color get divider;

  // Couleurs sémantiques (identiques pour toutes les palettes)
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2196F3);

  // Couleurs pour le mode light
  Color get primaryContainer;
  Color get onPrimaryContainer;
  Color get secondary;
  Color get secondaryContainer;
  Color get onSecondaryContainer;
  Color get tertiary;
  Color get tertiaryContainer;
  Color get onTertiaryContainer;

  // Couleurs pour le mode dark
  Color get darkPrimary;
  Color get darkOnPrimary;
  Color get darkPrimaryContainer;
  Color get darkOnPrimaryContainer;
  Color get darkSecondary;
  Color get darkSecondaryContainer;
  Color get darkOnSecondaryContainer;
  Color get darkTertiary;
  Color get darkTertiaryContainer;
  Color get darkOnTertiaryContainer;

  // Effets de glow
  BoxDecoration primaryGlowEffect({double opacity = 0.3, double blurRadius = 40.0}) {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: opacity),
          blurRadius: blurRadius,
          spreadRadius: blurRadius / 4,
        ),
      ],
    );
  }
}

// ============================================================================
// PALETTE BLEUE (Gratuit - Actuelle)
// ============================================================================
class BlueColorPalette extends AppColorPalette {
  @override
  Color get primary => const Color(0xFF2196F3);

  @override
  Color get glow => const Color(0xFF198CF0);

  @override
  Color get textPrimary => const Color(0xFF546E7A);

  @override
  Color get textSecondary => const Color(0xFF78909C);

  @override
  Color get textTertiary => const Color(0xFF90A4AE);

  @override
  Color get textSubtle => const Color(0xFFB0BEC5);

  @override
  Color get border => const Color(0xFFCFD8DC);

  @override
  Color get divider => const Color(0xFFECEFF1);

  // Mode light
  @override
  Color get primaryContainer => const Color(0xFFBBDEFB);

  @override
  Color get onPrimaryContainer => const Color(0xFF1976D2);

  @override
  Color get secondary => const Color(0xFF29B6F6);

  @override
  Color get secondaryContainer => const Color(0xFFB3E5FC);

  @override
  Color get onSecondaryContainer => const Color(0xFF0277BD);

  @override
  Color get tertiary => const Color(0xFFFF9800);

  @override
  Color get tertiaryContainer => const Color(0xFFFFE0B2);

  @override
  Color get onTertiaryContainer => const Color(0xFFE65100);

  // Mode dark
  @override
  Color get darkPrimary => const Color(0xFF64B5F6);

  @override
  Color get darkOnPrimary => const Color(0xFF0D47A1);

  @override
  Color get darkPrimaryContainer => const Color(0xFF1976D2);

  @override
  Color get darkOnPrimaryContainer => const Color(0xFFBBDEFB);

  @override
  Color get darkSecondary => const Color(0xFF4DD0E1);

  @override
  Color get darkSecondaryContainer => const Color(0xFF00838F);

  @override
  Color get darkOnSecondaryContainer => const Color(0xFFB2EBF2);

  @override
  Color get darkTertiary => const Color(0xFFFFB74D);

  @override
  Color get darkTertiaryContainer => const Color(0xFFF57C00);

  @override
  Color get darkOnTertiaryContainer => const Color(0xFFFFE0B2);
}

// ============================================================================
// PALETTE VERTE (Premium)
// ============================================================================
class GreenColorPalette extends AppColorPalette {
  @override
  Color get primary => const Color(0xFF4CAF50);

  @override
  Color get glow => const Color(0xFF43A047);

  @override
  Color get textPrimary => const Color(0xFF4D6F4E);

  @override
  Color get textSecondary => const Color(0xFF6D8F6E);

  @override
  Color get textTertiary => const Color(0xFF8FA990);

  @override
  Color get textSubtle => const Color(0xFFB0C5B1);

  @override
  Color get border => const Color(0xFFC8DFC9);

  @override
  Color get divider => const Color(0xFFE8F5E9);

  // Mode light
  @override
  Color get primaryContainer => const Color(0xFFC8E6C9);

  @override
  Color get onPrimaryContainer => const Color(0xFF2E7D32);

  @override
  Color get secondary => const Color(0xFF66BB6A);

  @override
  Color get secondaryContainer => const Color(0xFFA5D6A7);

  @override
  Color get onSecondaryContainer => const Color(0xFF1B5E20);

  @override
  Color get tertiary => const Color(0xFF8BC34A);

  @override
  Color get tertiaryContainer => const Color(0xFFDCEDC8);

  @override
  Color get onTertiaryContainer => const Color(0xFF33691E);

  // Mode dark
  @override
  Color get darkPrimary => const Color(0xFF81C784);

  @override
  Color get darkOnPrimary => const Color(0xFF1B5E20);

  @override
  Color get darkPrimaryContainer => const Color(0xFF388E3C);

  @override
  Color get darkOnPrimaryContainer => const Color(0xFFC8E6C9);

  @override
  Color get darkSecondary => const Color(0xFF9CCC65);

  @override
  Color get darkSecondaryContainer => const Color(0xFF558B2F);

  @override
  Color get darkOnSecondaryContainer => const Color(0xFFDCEDC8);

  @override
  Color get darkTertiary => const Color(0xFFAED581);

  @override
  Color get darkTertiaryContainer => const Color(0xFF689F38);

  @override
  Color get darkOnTertiaryContainer => const Color(0xFFF1F8E9);
}

// ============================================================================
// PALETTE ROUGE/ROSE (Premium)
// ============================================================================
class RedPinkColorPalette extends AppColorPalette {
  @override
  Color get primary => const Color(0xFFE91E63);

  @override
  Color get glow => const Color(0xFFD81B60);

  @override
  Color get textPrimary => const Color(0xFF7A4F55);

  @override
  Color get textSecondary => const Color(0xFF9C6F76);

  @override
  Color get textTertiary => const Color(0xFFB89099);

  @override
  Color get textSubtle => const Color(0xFFD4B0B8);

  @override
  Color get border => const Color(0xFFE8C9CF);

  @override
  Color get divider => const Color(0xFFFCE4EC);

  // Mode light
  @override
  Color get primaryContainer => const Color(0xFFF8BBD0);

  @override
  Color get onPrimaryContainer => const Color(0xFFC2185B);

  @override
  Color get secondary => const Color(0xFFEC407A);

  @override
  Color get secondaryContainer => const Color(0xFFF48FB1);

  @override
  Color get onSecondaryContainer => const Color(0xFF880E4F);

  @override
  Color get tertiary => const Color(0xFFFF5722);

  @override
  Color get tertiaryContainer => const Color(0xFFFFCCBC);

  @override
  Color get onTertiaryContainer => const Color(0xFFBF360C);

  // Mode dark
  @override
  Color get darkPrimary => const Color(0xFFF48FB1);

  @override
  Color get darkOnPrimary => const Color(0xFF880E4F);

  @override
  Color get darkPrimaryContainer => const Color(0xFFC2185B);

  @override
  Color get darkOnPrimaryContainer => const Color(0xFFF8BBD0);

  @override
  Color get darkSecondary => const Color(0xFFFF6F00);

  @override
  Color get darkSecondaryContainer => const Color(0xFFE65100);

  @override
  Color get darkOnSecondaryContainer => const Color(0xFFFFE0B2);

  @override
  Color get darkTertiary => const Color(0xFFFF8A65);

  @override
  Color get darkTertiaryContainer => const Color(0xFFD84315);

  @override
  Color get darkOnTertiaryContainer => const Color(0xFFFFCCBC);
}

// ============================================================================
// PALETTE VIOLETTE (Premium)
// ============================================================================
class PurpleColorPalette extends AppColorPalette {
  @override
  Color get primary => const Color(0xFF9C27B0);

  @override
  Color get glow => const Color(0xFF8E24AA);

  @override
  Color get textPrimary => const Color(0xFF6A5070);

  @override
  Color get textSecondary => const Color(0xFF8A7090);

  @override
  Color get textTertiary => const Color(0xFFA890AE);

  @override
  Color get textSubtle => const Color(0xFFC5B0CB);

  @override
  Color get border => const Color(0xFFD8C9DD);

  @override
  Color get divider => const Color(0xFFF3E5F5);

  // Mode light
  @override
  Color get primaryContainer => const Color(0xFFE1BEE7);

  @override
  Color get onPrimaryContainer => const Color(0xFF7B1FA2);

  @override
  Color get secondary => const Color(0xFFAB47BC);

  @override
  Color get secondaryContainer => const Color(0xFFCE93D8);

  @override
  Color get onSecondaryContainer => const Color(0xFF4A148C);

  @override
  Color get tertiary => const Color(0xFF673AB7);

  @override
  Color get tertiaryContainer => const Color(0xFFD1C4E9);

  @override
  Color get onTertiaryContainer => const Color(0xFF311B92);

  // Mode dark
  @override
  Color get darkPrimary => const Color(0xFFCE93D8);

  @override
  Color get darkOnPrimary => const Color(0xFF4A148C);

  @override
  Color get darkPrimaryContainer => const Color(0xFF7B1FA2);

  @override
  Color get darkOnPrimaryContainer => const Color(0xFFE1BEE7);

  @override
  Color get darkSecondary => const Color(0xFF9575CD);

  @override
  Color get darkSecondaryContainer => const Color(0xFF512DA8);

  @override
  Color get darkOnSecondaryContainer => const Color(0xFFD1C4E9);

  @override
  Color get darkTertiary => const Color(0xFFB39DDB);

  @override
  Color get darkTertiaryContainer => const Color(0xFF5E35B1);

  @override
  Color get darkOnTertiaryContainer => const Color(0xFFEDE7F6);
}

// ============================================================================
// PALETTE ORANGE (Premium)
// ============================================================================
class OrangeColorPalette extends AppColorPalette {
  @override
  Color get primary => const Color(0xFFFF9800);

  @override
  Color get glow => const Color(0xFFFB8C00);

  @override
  Color get textPrimary => const Color(0xFF7A5F4F);

  @override
  Color get textSecondary => const Color(0xFF9C7F6F);

  @override
  Color get textTertiary => const Color(0xFFB8A090);

  @override
  Color get textSubtle => const Color(0xFFD4C0B0);

  @override
  Color get border => const Color(0xFFE8D9C9);

  @override
  Color get divider => const Color(0xFFFFF3E0);

  // Mode light
  @override
  Color get primaryContainer => const Color(0xFFFFE0B2);

  @override
  Color get onPrimaryContainer => const Color(0xFFF57C00);

  @override
  Color get secondary => const Color(0xFFFFB74D);

  @override
  Color get secondaryContainer => const Color(0xFFFFCC80);

  @override
  Color get onSecondaryContainer => const Color(0xFFE65100);

  @override
  Color get tertiary => const Color(0xFFFF6F00);

  @override
  Color get tertiaryContainer => const Color(0xFFFFCCBC);

  @override
  Color get onTertiaryContainer => const Color(0xFFBF360C);

  // Mode dark
  @override
  Color get darkPrimary => const Color(0xFFFFCC80);

  @override
  Color get darkOnPrimary => const Color(0xFFE65100);

  @override
  Color get darkPrimaryContainer => const Color(0xFFF57C00);

  @override
  Color get darkOnPrimaryContainer => const Color(0xFFFFE0B2);

  @override
  Color get darkSecondary => const Color(0xFFFFAB40);

  @override
  Color get darkSecondaryContainer => const Color(0xFFFF6F00);

  @override
  Color get darkOnSecondaryContainer => const Color(0xFFFFE0B2);

  @override
  Color get darkTertiary => const Color(0xFFFF8A65);

  @override
  Color get darkTertiaryContainer => const Color(0xFFD84315);

  @override
  Color get darkOnTertiaryContainer => const Color(0xFFFFCCBC);
}

// ============================================================================
// FACTORY pour obtenir une palette selon l'enum ColorPalette
// ============================================================================
AppColorPalette getPaletteFromEnum(ColorPalette palette) {
  switch (palette) {
    case ColorPalette.blue:
      return BlueColorPalette();
    case ColorPalette.green:
      return GreenColorPalette();
    case ColorPalette.redPink:
      return RedPinkColorPalette();
    case ColorPalette.purple:
      return PurpleColorPalette();
    case ColorPalette.orange:
      return OrangeColorPalette();
  }
}
