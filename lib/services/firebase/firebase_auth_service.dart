import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../models/cloud_user.dart';
import '../google_signin_service.dart';

/// Service d'authentification Firebase pour la synchronisation cloud
///
/// Utilise Google Sign-In pour l'authentification OAuth 2.0,
/// unifiant ainsi le compte Google utilisé pour Drive et Firebase Sync.
/// Utilisé uniquement pour les utilisateurs Premium.
class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignInService? googleSignInService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignInService = googleSignInService ?? GoogleSignInService.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignInService _googleSignInService;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Utilisateur Firebase actuellement connecté
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Retourne le CloudUser actuellement connecté, ou null si déconnecté
  CloudUser? get currentCloudUser {
    final user = currentFirebaseUser;
    if (user == null) return null;

    return CloudUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      createdAt: user.metadata.creationTime,
    );
  }

  /// Retourne true si un utilisateur est connecté
  bool get isSignedIn => currentFirebaseUser != null;

  /// Stream des changements d'état d'authentification
  Stream<CloudUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return CloudUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        createdAt: user.metadata.creationTime,
      );
    });
  }

  /// Tente de restaurer silencieusement la session Google Sign-In
  ///
  /// Cette méthode doit être appelée au démarrage pour récupérer automatiquement
  /// la session si l'utilisateur était précédemment connecté.
  ///
  /// Retourne null si aucune session précédente ou si la restauration échoue
  Future<CloudUser?> restoreSession() async {
    try {
      _log('FirebaseAuthService - Tentative de restauration silencieuse de la session...');

      // Vérifier si Firebase a déjà un utilisateur (persistance automatique)
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        _log('FirebaseAuthService - Session Firebase déjà active: ${currentUser.email}');
        return CloudUser(
          uid: currentUser.uid,
          email: currentUser.email ?? '',
          displayName: currentUser.displayName,
          createdAt: currentUser.metadata.creationTime,
        );
      }

      // Tenter de restaurer silencieusement via GoogleSignInService
      _log('FirebaseAuthService - Tentative de restauration Google Sign-In silencieuse...');
      final googleAccount = await _googleSignInService.restoreSession();

      if (googleAccount == null) {
        _log('FirebaseAuthService - Aucune session Google précédente');
        return null;
      }

      _log('FirebaseAuthService - Session Google restaurée: ${googleAccount.email}');

      // Obtenir les credentials et se reconnecter à Firebase
      final googleAuth = googleAccount.authentication;
      if (googleAuth.idToken == null) {
        _log('FirebaseAuthService - ID token manquant, restauration échouée');
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        _log('FirebaseAuthService - Reconnexion Firebase échouée');
        return null;
      }

      _log('FirebaseSyncService - Session restaurée avec succès: ${user.email}');

      return CloudUser(
        uid: user.uid,
        email: user.email ?? googleAccount.email,
        displayName: user.displayName ?? googleAccount.displayName,
        createdAt: user.metadata.creationTime,
      );
    } catch (e) {
      _log('FirebaseAuthService - Erreur restauration session (non critique): $e');
      return null;
    }
  }

  /// Connecte l'utilisateur avec Google Sign-In
  ///
  /// Cette méthode unifie le compte Google utilisé pour Drive et Firebase Sync.
  /// Elle crée automatiquement un compte Firebase s'il n'existe pas encore.
  ///
  /// Throws [PlatformException] si la connexion Google échoue
  /// Throws [FirebaseAuthException] si l'authentification Firebase échoue
  /// Returns null si l'utilisateur annule la connexion
  Future<CloudUser?> signInWithGoogle() async {
    try {
      // Authentifier avec Google via GoogleSignInService
      _log('FirebaseAuthService - Démarrage authentification Google...');
      final googleAccount = await _googleSignInService.signIn();

      if (googleAccount == null) {
        // Utilisateur a annulé
        _log('FirebaseAuthService - Connexion annulée par l\'utilisateur');
        return null;
      }

      // Obtenir les credentials d'authentification Google
      // Note: googleAccount.authentication est maintenant synchrone dans google_sign_in 7.x
      final googleAuth = googleAccount.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Impossible d\'obtenir l\'ID token Google');
      }

      // Créer les credentials Firebase avec l'ID token
      // Note: accessToken n'est pas nécessaire pour Firebase Auth
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Se connecter à Firebase avec les credentials Google
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Échec de connexion Firebase');
      }

      _log('FirebaseAuthService - Connecté en tant que ${user.email}');

      return CloudUser(
        uid: user.uid,
        email: user.email ?? googleAccount.email,
        displayName: user.displayName ?? googleAccount.displayName,
        createdAt: user.metadata.creationTime,
      );
    } on PlatformException catch (e) {
      _log('FirebaseAuthService - Erreur plateforme: ${e.code} - ${e.message}');

      if (e.code == 'sign_in_canceled') {
        throw Exception(
          'Connexion impossible. Causes possibles :\n'
          '\n'
          '1. Google Play Services manquant ou obsolète\n'
          '   → Mettez à jour depuis le Play Store\n'
          '\n'
          '2. Aucun compte Google configuré sur cet appareil\n'
          '   → Paramètres > Comptes > Ajouter un compte Google\n'
          '\n'
          '3. Appareil incompatible (ROM custom, Huawei sans GMS)\n'
          '   → Fonctionnalité non disponible sur cet appareil\n'
          '\n'
          'Code erreur : ${e.code}'
        );
      } else if (e.code == 'sign_in_failed' || e.code == 'network_error') {
        throw Exception(
          'Échec de la connexion.\n'
          '\n'
          'Vérifiez votre connexion Internet et réessayez.\n'
          '\n'
          'Code erreur : ${e.code}'
        );
      }
      rethrow;
    } on FirebaseAuthException catch (e) {
      _log('FirebaseAuthService - Erreur Firebase: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _log('FirebaseAuthService - Erreur inattendue connexion: $e');
      rethrow;
    }
  }

  /// Déconnecte l'utilisateur de Firebase et Google
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignInService.signOut();
      _log('FirebaseAuthService - Déconnexion réussie (Firebase + Google)');
    } catch (e) {
      _log('FirebaseAuthService - Erreur déconnexion: $e');
      rethrow;
    }
  }

  /// Supprime le compte de l'utilisateur actuellement connecté
  ///
  /// ATTENTION : Cette action est irréversible et supprime toutes les données cloud
  ///
  /// Throws [FirebaseAuthException] si la suppression échoue
  /// - 'requires-recent-login' : L'utilisateur doit se reconnecter avant de supprimer
  Future<void> deleteAccount() async {
    try {
      final user = currentFirebaseUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      // Déconnecter aussi de Google
      await _googleSignInService.signOut();

      await user.delete();
      _log('FirebaseAuthService - Compte supprimé avec succès');
    } on FirebaseAuthException catch (e) {
      _log('FirebaseAuthService - Erreur suppression compte: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _log('FirebaseAuthService - Erreur inattendue suppression: $e');
      rethrow;
    }
  }

  /// Met à jour le nom d'affichage de l'utilisateur
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = currentFirebaseUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      await user.updateDisplayName(displayName);
      await user.reload();
      _log('FirebaseAuthService - Nom d\'affichage mis à jour: $displayName');
    } catch (e) {
      _log('FirebaseAuthService - Erreur màj nom affichage: $e');
      rethrow;
    }
  }
}

