import 'dart:io' show Platform;

bool get _isMobile => Platform.isAndroid || Platform.isIOS;
bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

bool get supportsAds => _isMobile;
bool get supportsIAP => _isMobile;
bool get supportsAmbientLight => _isMobile;
bool get supportsInAppReview => _isMobile;
bool get supportsBiometricKeystoreWrap => Platform.isAndroid || Platform.isIOS;
// Sync cloud Firebase : mobile + desktop Windows (depuis Phase 5 REST).
// Sur Windows : Firebase Auth via REST Google Identity Toolkit (cf.
// `firebase_auth_rest_windows.dart`), Firestore CRUD via REST API (cf.
// `firestore_rest_client.dart`). FlutterFire n'a pas de plugin Windows natif
// au 2026-06 — on contourne en Dart pur.
bool get supportsCloudSync => _isMobile || Platform.isWindows;

// Backups cloud (Google Drive / OneDrive) : indépendants de Firebase Auth.
// Drive utilise OAuth Google direct (`GoogleSignInWindows`), OneDrive utilise
// Azure AD OAuth (`aad_oauth`). Activables sur Windows en Phase 5.
bool get supportsCloudBackup => _isMobile || Platform.isWindows;
