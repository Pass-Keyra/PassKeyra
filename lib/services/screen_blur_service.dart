import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Active FLAG_SECURE côté natif Android pour empêcher screenshots,
/// screen recording et capture par services d'accessibilité.
class ScreenBlurService {
  static final ScreenBlurService _instance = ScreenBlurService._internal();
  factory ScreenBlurService() => _instance;
  static ScreenBlurService get instance => _instance;
  ScreenBlurService._internal();

  static const String _keyBlurEnabled = 'screen_blur_enabled';
  static const MethodChannel _channel = MethodChannel('passkeyra/screen_blur');

  bool _isEnabled = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_keyBlurEnabled) ?? true;
    await _applyNative(_isEnabled);
    if (kDebugMode) {
      debugPrint('ScreenBlurService - FLAG_SECURE ${_isEnabled ? "activé" : "désactivé"}');
    }
  }

  bool get isEnabled => _isEnabled;

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBlurEnabled, enabled);
    await _applyNative(enabled);
    if (kDebugMode) {
      debugPrint('ScreenBlurService - FLAG_SECURE ${enabled ? "activé" : "désactivé"}');
    }
  }

  Future<void> _applyNative(bool enabled) async {
    try {
      await _channel.invokeMethod<bool>('setSecure', {'enabled': enabled});
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('ScreenBlurService - PlatformException: ${e.message}');
      }
    } on MissingPluginException {
      // Plateforme non supportée (iOS, web, desktop) — silencieusement ignoré.
    }
  }
}
