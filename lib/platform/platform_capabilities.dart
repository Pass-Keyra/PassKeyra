import 'dart:io' show Platform;

bool get _isMobile => Platform.isAndroid || Platform.isIOS;
bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

bool get supportsAds => _isMobile;
bool get supportsIAP => _isMobile;
bool get supportsAmbientLight => _isMobile;
bool get supportsInAppReview => _isMobile;
bool get supportsBiometricKeystoreWrap => Platform.isAndroid || Platform.isIOS;
// Sync cloud Firebase : V1 mobile uniquement. Phase 5 du plan desktop activera
// FlutterFire Windows + OAuth web flow pour le desktop.
bool get supportsCloudSync => _isMobile;
