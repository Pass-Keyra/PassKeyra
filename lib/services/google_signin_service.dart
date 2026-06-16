import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Service singleton pour gérer l'authentification Google partagée
/// entre Firebase Auth et Google Drive
///
/// Ce service garantit qu'une seule instance de GoogleSignIn existe
/// avec les scopes nécessaires pour Firebase ET Drive, évitant ainsi
/// les conflits d'authentification et les double popups.
class GoogleSignInService {
  // Singleton pattern
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  static GoogleSignInService get instance => _instance;

  /// Instance GoogleSignIn partagée
  /// Utilise GoogleSignIn.instance (singleton Google)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Scopes nécessaires pour Firebase + Drive
  static const List<String> _requiredScopes = [
    drive.DriveApi.driveFileScope, // Accès limité aux fichiers créés par PassKeyra (non-sensible, pas de vérification Google requise)
    // Firebase Auth utilise les scopes par défaut (profile, email)
  ];
  static const Duration _restoreRetryCooldown = Duration(seconds: 20);

  Future<GoogleSignInAccount?>? _restoreInFlight;
  DateTime? _lastRestoreAttemptAt;
  GoogleSignInAccount? _lastRestoreResult;

  /// Retourne l'instance GoogleSignIn configurée
  GoogleSignIn get googleSignIn => _googleSignIn;

  /// Initialise GoogleSignIn avec les scopes Drive
  /// Cette méthode doit être appelée AVANT la première authentification
  Future<void> initialize() async {
    await _googleSignIn.initialize();
  }

  /// Retourne le compte Google actuellement connecté
  /// Note: Utilise l'API Google Sign-In 7.x qui n'a pas currentUser/signedInUser
  /// On doit vérifier via attemptLightweightAuthentication()
  Future<GoogleSignInAccount?> getCurrentAccount() async {
    // Tenter une authentification légère sans popup
    final authFuture = _googleSignIn.attemptLightweightAuthentication();
    if (authFuture == null) return null;

    try {
      return await authFuture;
    } catch (e) {
      return null;
    }
  }

  /// Connecte l'utilisateur avec Google (affiche la popup de sélection de compte)
  /// ET demande tous les scopes nécessaires (Firebase + Drive) en une seule fois
  Future<GoogleSignInAccount?> signIn() async {
    try {
      // Initialiser Google Sign-In
      await initialize();

      // Authentifier avec Google (popup de sélection de compte)
      final account = await _googleSignIn.authenticate();

      // Demander les scopes Drive en plus des scopes de base (profile, email)
      final authClient = account.authorizationClient;
      // Vérifier si les scopes Drive sont déjà accordés
      var authorization = await authClient.authorizationForScopes(_requiredScopes);

      if (authorization == null) {
        // Demander explicitement les scopes Drive
        debugPrint('GoogleSignInService - Demande des scopes Drive...');
        await authClient.authorizeScopes(_requiredScopes);
        debugPrint('GoogleSignInService - Scopes Drive accordés');
      }

      debugPrint('GoogleSignInService - Connecté: ${account.email}');
      return account;
    } catch (e) {
      debugPrint('GoogleSignInService - Erreur lors du signIn: $e');
      return null;
    }
  }

  /// Déconnecte l'utilisateur de Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('GoogleSignInService - Erreur lors du signOut: $e');
    }
  }

  /// Révoque l'autorisation Google (identité + scopes Drive) ET déconnecte la
  /// session. Contrairement à [signOut], supprime le grant OAuth côté Google :
  /// la prochaine connexion réaffichera le sélecteur de compte (permet de
  /// changer de compte sans passer par la page Google ni effacer les données).
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('GoogleSignInService - Erreur lors du disconnect: $e');
      // Fallback best-effort : au moins couper la session locale.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
  }

  /// Tente de restaurer silencieusement la session Google
  /// Utilisé au démarrage de l'app pour reconnecter l'utilisateur
  /// sans afficher de popup (si les credentials sont encore valides)
  Future<GoogleSignInAccount?> restoreSession() async {
    // Déduplication: si une restauration est déjà en cours, réutiliser le même Future.
    final inFlight = _restoreInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    // Anti-spam popup: si une tentative récente a déjà échoué, ne pas relancer immédiatement.
    final now = DateTime.now();
    if (_lastRestoreAttemptAt != null &&
        now.difference(_lastRestoreAttemptAt!) < _restoreRetryCooldown &&
        _lastRestoreResult == null) {
      debugPrint('GoogleSignInService - restoreSession ignoré (cooldown actif)');
      return null;
    }

    _restoreInFlight = _restoreSessionInternal();
    try {
      final result = await _restoreInFlight!;
      _lastRestoreResult = result;
      return result;
    } finally {
      _restoreInFlight = null;
    }
  }

  Future<GoogleSignInAccount?> _restoreSessionInternal() async {
    try {
      _lastRestoreAttemptAt = DateTime.now();
      // Tenter une restauration légère (sans popup si possible)
      debugPrint('GoogleSignInService - Tentative de restauration silencieuse...');

      await initialize();

      final authFuture = _googleSignIn.attemptLightweightAuthentication();
      if (authFuture == null) {
        debugPrint('GoogleSignInService - attemptLightweightAuthentication non disponible');
        return null;
      }

      final googleAccount = await authFuture;

      if (googleAccount != null) {
        debugPrint('GoogleSignInService - Session restaurée: ${googleAccount.email}');
      } else {
        debugPrint('GoogleSignInService - Aucune session à restaurer');
      }

      return googleAccount;
    } catch (e) {
      debugPrint('GoogleSignInService - Erreur lors de restoreSession: $e');
      return null;
    }
  }

  /// Vérifie si un utilisateur est actuellement connecté
  /// en tentant une authentification légère
  Future<bool> isSignedIn() async {
    final account = await getCurrentAccount();
    return account != null;
  }
}
