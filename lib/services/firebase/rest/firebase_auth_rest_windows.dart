import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../secure_storage_service.dart';
import 'cloud_debug_log.dart';

/// Session Firebase Auth obtenue via REST sur Windows.
///
/// Contient les tokens nécessaires pour parler à Firestore REST (idToken) et
/// pour rafraîchir la session après expiration (refreshToken). [uid] est
/// l'identifiant Firebase de l'utilisateur, utilisé pour construire les paths
/// Firestore `users/{uid}/vault/...`.
@immutable
class FirebaseAuthRestSession {
  const FirebaseAuthRestSession({
    required this.idToken,
    required this.refreshToken,
    required this.uid,
    required this.email,
    required this.expiresAt,
    this.displayName,
  });

  final String idToken;
  final String refreshToken;
  final String uid;
  final String email;
  final String? displayName;
  final DateTime expiresAt;

  bool get isExpiringSoon {
    // On considère "expiré" si on est à moins de 60s de l'échéance, pour
    // anticiper le délai réseau d'un appel Firestore.
    return DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 60)));
  }

  Map<String, dynamic> toJson() => {
        'idToken': idToken,
        'refreshToken': refreshToken,
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory FirebaseAuthRestSession.fromJson(Map<String, dynamic> json) {
    return FirebaseAuthRestSession(
      idToken: json['idToken'] as String,
      refreshToken: json['refreshToken'] as String,
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

/// Firebase Auth via REST API pour PassKeyra Desktop Windows.
///
/// **Pourquoi REST** : au 2026-06, FlutterFire n'a pas de plugin
/// `firebase_auth_windows`. `FirebaseAuth.instance` lance `[core/no-app]`
/// dès qu'il est instancié sur Windows. On contourne en parlant directement
/// à l'API Google Identity Toolkit + Secure Token (les endpoints publics que
/// le SDK FlutterFire appelle en interne sur les plateformes supportées).
///
/// **Flux** :
/// 1. L'utilisateur signe avec Google via [GoogleSignInWindows] → on obtient
///    un `id_token` Google.
/// 2. On échange ce id_token contre une session Firebase via
///    `identitytoolkit.googleapis.com/v1/accounts:signInWithIdp`. Réponse :
///    Firebase idToken + refreshToken + uid + email.
/// 3. Sessions stockées chiffrées DPAPI dans SecureStorage.
/// 4. Quand le idToken expire (~1h), on appelle `securetoken.googleapis.com/v1/token`
///    avec `grant_type=refresh_token` pour obtenir un nouveau idToken.
///
/// **Sécurité** : la `apiKey` (= identifiant projet public) est nécessaire pour
/// signer les appels REST. Cf. `firebase_options.dart` — c'est public, pas un
/// secret. La protection vient des Firestore security rules.
class FirebaseAuthRestWindows {
  /// **Singleton** : indispensable pour que TOUTES les instances (chaque page
  /// qui cree un FirebaseAuthService, le FirebaseSyncService, le FirestoreGateway)
  /// partagent la meme session en memoire. Sans ca, une connexion faite sur la
  /// page Cloud Sync ne serait pas visible depuis la HomePage ou les services
  /// background, donnant l'impression de "perdre la connexion".
  factory FirebaseAuthRestWindows({
    required String apiKey,
    SecureStorageService? secureStorage,
    http.Client? httpClient,
  }) {
    _instance ??= FirebaseAuthRestWindows._internal(
      apiKey: apiKey,
      secureStorage: secureStorage ?? SecureStorageService(),
      httpClient: httpClient ?? http.Client(),
    );
    return _instance!;
  }

  FirebaseAuthRestWindows._internal({
    required this.apiKey,
    required SecureStorageService secureStorage,
    required http.Client httpClient,
  })  : _secureStorage = secureStorage,
        _http = httpClient;

  static FirebaseAuthRestWindows? _instance;

  static const String _kSessionKey = 'firebase_rest_session';

  final String apiKey;
  final SecureStorageService _secureStorage;
  final http.Client _http;

  FirebaseAuthRestSession? _currentSession;
  FirebaseAuthRestSession? get currentSession => _currentSession;
  bool get isSignedIn => _currentSession != null;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// Échange un id_token Google contre une session Firebase via Identity
  /// Toolkit. À appeler après que [GoogleSignInWindows.signIn] ait abouti.
  ///
  /// Retourne null si l'API refuse (id_token expiré/invalide, projet
  /// désactivé, etc.).
  Future<FirebaseAuthRestSession?> signInWithGoogleIdToken(
    String googleIdToken,
  ) async {
    try {
      final response = await _http.post(
        Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // requestUri : valeur arbitraire mais doit être un http(s) URI valide.
          // Google la valide format, pas contenu.
          'requestUri': 'http://localhost',
          'postBody':
              'id_token=$googleIdToken&providerId=google.com',
          'returnIdpCredential': true,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode != 200) {
        _log('FirebaseAuthRest - signInWithIdp HTTP ${response.statusCode}: ${response.body}');
        cloudLog('REST signInWithIdp ECHEC HTTP ${response.statusCode}: ${response.body}');
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final session = FirebaseAuthRestSession(
        idToken: body['idToken'] as String,
        refreshToken: body['refreshToken'] as String,
        uid: body['localId'] as String,
        email: (body['email'] as String?) ?? '',
        displayName: body['displayName'] as String?,
        expiresAt: DateTime.now().add(
          Duration(seconds: int.tryParse(body['expiresIn'] as String? ?? '3600') ?? 3600),
        ),
      );

      _currentSession = session;
      await _persistSession(session);
      _log('FirebaseAuthRest - Session Firebase REST créée (uid=${session.uid})');
      cloudLog('REST signInWithIdp OK uid=${session.uid} email=${session.email}');
      return session;
    } catch (e) {
      _log('FirebaseAuthRest - Erreur signInWithGoogleIdToken: $e');
      cloudLog('REST signInWithIdp EXCEPTION: $e');
      return null;
    }
  }

  /// Tente de restaurer une session persistée. Si le idToken est expiré,
  /// utilise le refreshToken pour obtenir un nouveau idToken.
  Future<FirebaseAuthRestSession?> restoreSession() async {
    final persisted = await _readPersistedSession();
    if (persisted == null) {
      cloudLog('REST restoreSession : aucune session persistee DPAPI');
      return null;
    }

    if (!persisted.isExpiringSoon) {
      _currentSession = persisted;
      _log('FirebaseAuthRest - Session persistée encore valide');
      cloudLog('REST restoreSession OK (session valide) uid=${persisted.uid}');
      return persisted;
    }

    // Refresh le idToken via Secure Token API.
    final refreshed = await _refreshIdToken(persisted);
    if (refreshed != null) {
      _currentSession = refreshed;
      await _persistSession(refreshed);
      _log('FirebaseAuthRest - Session rafraîchie via refresh_token');
      cloudLog('REST restoreSession OK (rafraichie) uid=${refreshed.uid}');
      return refreshed;
    }

    _log('FirebaseAuthRest - Refresh échoué, session invalide');
    cloudLog('REST restoreSession ECHEC refresh');
    return null;
  }

  /// Retourne un idToken Firebase valide (en rafraîchissant si besoin).
  /// À appeler avant chaque appel Firestore REST authentifié.
  Future<String?> getValidIdToken() async {
    final session = _currentSession;
    if (session == null) return null;
    if (!session.isExpiringSoon) return session.idToken;

    final refreshed = await _refreshIdToken(session);
    if (refreshed != null) {
      _currentSession = refreshed;
      await _persistSession(refreshed);
      return refreshed.idToken;
    }
    return null;
  }

  /// Sign-out local : efface la session persistée. N'invalide pas le
  /// refresh_token Firebase côté serveur (pas critique, on a aussi le
  /// signOut Google qui révoque l'OAuth Google).
  Future<void> signOut() async {
    _currentSession = null;
    await _secureStorage.deleteKey(_kSessionKey);
    _log('FirebaseAuthRest - Session locale purgée');
  }

  Future<FirebaseAuthRestSession?> _refreshIdToken(
    FirebaseAuthRestSession current,
  ) async {
    try {
      final response = await _http.post(
        Uri.parse(
            'https://securetoken.googleapis.com/v1/token?key=$apiKey'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'grant_type=refresh_token&refresh_token=${current.refreshToken}',
      );

      if (response.statusCode != 200) {
        _log('FirebaseAuthRest - refresh HTTP ${response.statusCode}: ${response.body}');
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return FirebaseAuthRestSession(
        idToken: body['id_token'] as String,
        refreshToken: (body['refresh_token'] as String?) ?? current.refreshToken,
        uid: current.uid,
        email: current.email,
        displayName: current.displayName,
        expiresAt: DateTime.now().add(
          Duration(seconds: int.tryParse(body['expires_in'] as String? ?? '3600') ?? 3600),
        ),
      );
    } catch (e) {
      _log('FirebaseAuthRest - Erreur refresh: $e');
      return null;
    }
  }

  Future<void> _persistSession(FirebaseAuthRestSession session) async {
    final raw = jsonEncode(session.toJson());
    await _secureStorage.writeString(_kSessionKey, raw);
  }

  Future<FirebaseAuthRestSession?> _readPersistedSession() async {
    try {
      final raw = await _secureStorage.readString(_kSessionKey);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return FirebaseAuthRestSession.fromJson(json);
    } catch (e) {
      _log('FirebaseAuthRest - Erreur lecture session persistée: $e');
      return null;
    }
  }
}
