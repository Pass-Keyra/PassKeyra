import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service pour copier du texte dans le presse-papiers avec effacement automatique
/// Supporte Android 13+ avec masquage du contenu dans l'historique
class SecureClipboardService {
  static Timer? _clearTimer;
  static const MethodChannel _channel = MethodChannel('secure_clipboard');
  
  /// Copie le texte et programme son effacement après le délai spécifié
  /// Sur Android 13+, masque le contenu dans l'historique du presse-papier
  static Future<void> copyWithAutoClear(String text, {Duration delay = const Duration(seconds: 30)}) async {
    try {
      // Essayer d'utiliser la méthode native sécurisée (Android 13+)
      if (Platform.isAndroid) {
        try {
          await _channel.invokeMethod('copySecure', {
            'text': text,
            'sensitive': true, // Masquer dans l'historique
          });
          debugPrint('SecureClipboardService - Copie sécurisée réussie (Android 13+)');
        } catch (e) {
          // Fallback sur la méthode Flutter standard
          debugPrint('SecureClipboardService - Fallback sur méthode standard: $e');
          await Clipboard.setData(ClipboardData(text: text));
        }
      } else {
        // iOS ou autres plateformes : méthode standard
        await Clipboard.setData(ClipboardData(text: text));
      }
    } catch (e) {
      // Fallback final sur la méthode Flutter standard
      debugPrint('SecureClipboardService - Erreur copie sécurisée, fallback: $e');
      await Clipboard.setData(ClipboardData(text: text));
    }
    
    _clearTimer?.cancel();
    _clearTimer = Timer(delay, () async {
      await clearNow();
    });
  }
  
  /// Annule l'effacement automatique programmé
  static void cancelAutoClear() {
    _clearTimer?.cancel();
  }
  
  /// Efface immédiatement le presse-papiers
  static Future<void> clearNow() async {
    _clearTimer?.cancel();
    try {
      if (Platform.isAndroid) {
        try {
          await _channel.invokeMethod('clearClipboard');
          debugPrint('SecureClipboardService - Effacement sécurisé réussi');
        } catch (e) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } else {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } catch (e) {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
  }
}
