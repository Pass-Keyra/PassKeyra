import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'cloud_backup_provider.dart';
import 'providers/google_drive_backup_provider.dart';
import 'providers/onedrive_backup_provider.dart';
// import 'providers/dropbox_backup_provider.dart'; // Désactivé temporairement (limite 50 users)

/// Types de providers cloud supportés
enum CloudProvider {
  /// Google Drive (Android, iOS, Web, Desktop)
  googleDrive,

  /// Dropbox (Android, iOS) - Non implémenté pour l'instant
  dropbox,

  /// OneDrive (Android, iOS, Desktop) - Non implémenté pour l'instant
  onedrive,

  /// iCloud (iOS uniquement) - Non implémenté pour l'instant
  icloud,
}

/// Factory pour créer les providers de backup cloud
///
/// Pattern utilisé: Factory Pattern
/// Permet de créer des instances de CloudBackupProvider selon
/// le type demandé et la plateforme actuelle.
class CloudBackupFactory {
  /// Crée une instance de CloudBackupProvider pour le type donné
  ///
  /// [provider] - Type de provider à créer
  ///
  /// Returns: Instance du provider correspondant
  /// Throws: UnsupportedError si le provider n'est pas disponible sur cette plateforme
  static CloudBackupProvider createProvider(CloudProvider provider) {
    // Vérifier si le provider est disponible sur cette plateforme
    if (!isProviderAvailable(provider)) {
      throw UnsupportedError(
        '${provider.displayName} n\'est pas disponible sur cette plateforme',
      );
    }

    switch (provider) {
      case CloudProvider.googleDrive:
        return GoogleDriveBackupProvider();

      case CloudProvider.dropbox:
        // return DropboxBackupProvider(); // Désactivé temporairement (limite 50 users)
        throw UnimplementedError(
          'Dropbox sera disponible après avoir atteint 50 utilisateurs',
        );

      case CloudProvider.onedrive:
        return OneDriveBackupProvider();

      case CloudProvider.icloud:
        // TODO: Implémenter ICloudBackupProvider en Phase 4
        throw UnimplementedError(
          'iCloud sera disponible dans une prochaine version',
        );
    }
  }

  /// Retourne la liste des providers disponibles sur la plateforme actuelle
  ///
  /// La disponibilité dépend de:
  /// - La plateforme (Android, iOS, Web, Desktop)
  /// - Les packages installés
  /// - L'état d'implémentation
  static List<CloudProvider> getAvailableProviders() {
    final providers = <CloudProvider>[];

    // Google Drive - Disponible sur toutes les plateformes
    providers.add(CloudProvider.googleDrive);

    // Dropbox - Disponible sur Android et iOS uniquement
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      providers.add(CloudProvider.dropbox);
    }

    // OneDrive - Disponible sur Android, iOS, Desktop
    if (!kIsWeb) {
      providers.add(CloudProvider.onedrive);
    }

    // iCloud - Disponible sur iOS uniquement (quand implémenté)
    // if (!kIsWeb && Platform.isIOS) {
    //   providers.add(CloudProvider.icloud);
    // }

    return providers;
  }

  /// Vérifie si un provider est disponible sur la plateforme actuelle
  ///
  /// [provider] - Provider à vérifier
  ///
  /// Returns: true si disponible, false sinon
  static bool isProviderAvailable(CloudProvider provider) {
    return getAvailableProviders().contains(provider);
  }

  /// Retourne le provider par défaut pour la plateforme actuelle
  ///
  /// Logique de sélection:
  /// - Android: Google Drive (écosystème Google)
  /// - iOS: Google Drive (le plus universel, iCloud pas encore implémenté)
  /// - Web: Google Drive (seul disponible)
  /// - Desktop: Google Drive (universel)
  static CloudProvider getDefaultProvider() {
    if (kIsWeb) {
      return CloudProvider.googleDrive;
    }

    if (Platform.isAndroid) {
      return CloudProvider.googleDrive; // Écosystème Google
    }

    if (Platform.isIOS) {
      // Préférer iCloud quand implémenté, sinon Google Drive
      return isProviderAvailable(CloudProvider.icloud)
          ? CloudProvider.icloud
          : CloudProvider.googleDrive;
    }

    // Desktop (Windows, macOS, Linux)
    return CloudProvider.googleDrive;
  }
}

/// Extension pour obtenir le nom d'affichage d'un CloudProvider
extension CloudProviderExtension on CloudProvider {
  /// Nom d'affichage du provider (pour UI)
  String get displayName {
    switch (this) {
      case CloudProvider.googleDrive:
        return 'Google Drive';
      case CloudProvider.dropbox:
        return 'Dropbox';
      case CloudProvider.onedrive:
        return 'OneDrive';
      case CloudProvider.icloud:
        return 'iCloud';
    }
  }

  /// Description du provider (pour UI) - Retourne chaîne vide (descriptions retirées)
  String get description {
    return ''; // Descriptions supprimées à la demande de l'utilisateur
  }

  /// Indique si le provider est actuellement implémenté
  bool get isImplemented {
    switch (this) {
      case CloudProvider.googleDrive:
        return true; // Phase 1 - Implémenté
      case CloudProvider.dropbox:
        return false; // Phase 2 - Désactivé temporairement (limite 50 users Dropbox)
      case CloudProvider.onedrive:
        return true; // Phase 3 - Implémenté
      case CloudProvider.icloud:
        return false; // Phase 4 - À venir
    }
  }

  /// Tag pour UI (ex: "Bientôt", "iOS uniquement")
  String? get tag {
    if (!isImplemented) {
      return 'Bientôt disponible';
    }

    if (this == CloudProvider.icloud) {
      return 'iOS uniquement';
    }

    return null;
  }

  /// Icône du provider (pour UI) - Font Awesome official logos
  IconData get icon {
    switch (this) {
      case CloudProvider.googleDrive:
        return FontAwesomeIcons.googleDrive; // Logo officiel Google Drive
      case CloudProvider.dropbox:
        return FontAwesomeIcons.dropbox; // Logo officiel Dropbox
      case CloudProvider.onedrive:
        return FontAwesomeIcons.microsoft; // Logo officiel Microsoft/OneDrive
      case CloudProvider.icloud:
        return FontAwesomeIcons.apple; // Logo Apple pour iCloud
    }
  }

  /// Couleur officielle du provider (pour UI)
  Color get brandColor {
    switch (this) {
      case CloudProvider.googleDrive:
        return const Color(0xFF4285F4); // Bleu Google Drive officiel
      case CloudProvider.dropbox:
        return const Color(0xFF0061FE); // Bleu Dropbox officiel
      case CloudProvider.onedrive:
        return const Color(0xFF0078D4); // Bleu Microsoft/OneDrive officiel
      case CloudProvider.icloud:
        return const Color(0xFF3C99FD); // Bleu iCloud officiel
    }
  }

  /// Icône de taille large pour les cartes de sélection (pour UI)
  Widget getLargeIcon({double size = 48.0}) {
    return Icon(
      icon,
      size: size,
      color: brandColor,
    );
  }
}
