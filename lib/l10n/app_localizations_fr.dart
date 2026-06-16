// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'PassKeyra';

  @override
  String get settings => 'Paramètres';

  @override
  String get security => 'Sécurité';

  @override
  String get premium => 'Premium';

  @override
  String get organization => 'Organisation';

  @override
  String get data => 'Données';

  @override
  String get application => 'Application';

  @override
  String get changeMasterPassword => 'Changer le code secret';

  @override
  String get changeMasterPasswordSubtitle => 'Modifier votre code de sécurité';

  @override
  String get biometricAuth => 'Authentification biométrique';

  @override
  String get biometricAuthSubtitle =>
      'Utiliser l\'empreinte digitale ou Face ID';

  @override
  String get biometricAuthNotAvailable => 'Non disponible sur cet appareil';

  @override
  String get lockTimeout => 'Délai de verrouillage';

  @override
  String get autoClose => 'Fermeture automatique';

  @override
  String get blurScreen => 'Cacher le contenu en arrière-plan';

  @override
  String get blurScreenSubtitle =>
      'Masque le contenu dans le sélecteur d\'apps';

  @override
  String get premiumTitle => 'PassKeyra Premium';

  @override
  String get premiumSubtitle => 'Découvrez les fonctionnalités à venir';

  @override
  String get premiumOnlyTooltip => 'Premium uniquement';

  @override
  String get customCategories => 'Catégories personnalisées';

  @override
  String get customCategoriesSubtitle => 'Gérez vos catégories';

  @override
  String get export => 'Export';

  @override
  String get exportSubtitle => 'Sauvegarder vos données';

  @override
  String get localBackupTitle => 'Sauvegarde locale';

  @override
  String get localBackupExportSubtitle => 'Exportez votre sauvegarde locale';

  @override
  String get about => 'À propos';

  @override
  String get aboutPremium => 'PassKeyra v1.1.0 (Premium activé)';

  @override
  String get aboutFree => 'PassKeyra v1.1.0';

  @override
  String get biometricMigrationTitle => 'Sécurité renforcée';

  @override
  String get biometricMigrationMessage =>
      'PassKeyra a renforcé la protection biométrique de votre coffre. Pour activer cette nouvelle protection sur votre appareil, vous devez ressaisir votre mot de passe maître une seule fois. Le déverrouillage par empreinte digitale ou reconnaissance faciale fonctionnera ensuite normalement.';

  @override
  String get biometricMigrationButton => 'Saisir mon mot de passe maître';

  @override
  String get dangerZone => 'Zone dangereuse';

  @override
  String get deleteCloudAccount => 'Supprimer mon compte cloud';

  @override
  String get deleteCloudAccountDescription =>
      'Supprime définitivement votre compte Firebase et stoppe la synchronisation entre vos appareils. Vos données locales et vos sauvegardes Drive/OneDrive ne sont PAS affectées.';

  @override
  String get deleteCloudAccountWarning =>
      'Cette action est irréversible. Votre compte Firebase et toutes les données synchronisées dans le cloud seront supprimés. Vous pourrez créer un nouveau compte cloud plus tard si vous le souhaitez.';

  @override
  String get deleteCloudAccountConfirm => 'Supprimer définitivement';

  @override
  String get deleteCloudAccountSuccess => 'Compte cloud supprimé';

  @override
  String get deleteCloudAccountReauthRequired =>
      'Pour des raisons de sécurité, reconnectez-vous à Google puis réessayez.';

  @override
  String get havePromoCode => 'J\'ai un code promo';

  @override
  String get redeemPromoCodeError =>
      'Impossible d\'ouvrir Google Play Store. Vérifiez que l\'application est installée.';

  @override
  String get rateApp => 'Noter cette application';

  @override
  String get rateAppSubtitle =>
      'Laissez un avis sur l\'App Store ou Play Store';

  @override
  String get thankYouSupport => 'Merci pour votre soutien !';

  @override
  String get unlockVault => 'Déverrouiller le coffre';

  @override
  String get secureSetup => 'Configuration sécurisée';

  @override
  String get createMasterPassword =>
      'Créez votre code secret pour protéger vos mots de passe.';

  @override
  String get newMasterPassword => 'Nouveau code secret';

  @override
  String get masterPassword => 'Code secret';

  @override
  String get confirmPassword => 'Confirmer le code secret';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get createAccount => 'Créer';

  @override
  String get passwordsDontMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordNoSpaces => 'Un espace est présent (non autorisé)';

  @override
  String get passwordMinLength => 'Au moins 8 caractères';

  @override
  String get passwordNeedsUppercase => 'Au moins 1 majuscule requise (A-Z)';

  @override
  String get passwordNeedsLowercase => 'Au moins 1 minuscule requise (a-z)';

  @override
  String get passwordNeedsDigit => 'Au moins 1 chiffre requis (0-9)';

  @override
  String get passwordNeedsSpecial =>
      'Au moins 1 caractère spécial requis (!@#\$%...)';

  @override
  String get masterPasswordCreatedSuccess => 'Code secret créé avec succès !';

  @override
  String get incorrectMasterPassword => 'Code secret incorrect.';

  @override
  String loginAttemptsRemainingWarning(int n) {
    return 'Il vous reste $n tentatives avant le blocage de votre coffre pour 24 heures.';
  }

  @override
  String get loginAttemptsLastChance =>
      'Attention : une erreur supplémentaire bloquera votre coffre pendant 24 heures.';

  @override
  String get masterPasswordChangeIntroTitle =>
      'Changement du mot de passe maître';

  @override
  String get masterPasswordChangeIntroBody =>
      'Vous allez modifier votre mot de passe maître. Une sauvegarde de sécurité de vos données sera créée automatiquement.\n\nSi vous rencontrez un problème dans les 30 prochains jours, vous pourrez revenir à l\'état actuel en utilisant votre ancien mot de passe.\n\nSouhaitez-vous continuer ?';

  @override
  String get masterPasswordChangeCloudUpdateTitle =>
      'Mise à jour de votre coffre en ligne';

  @override
  String get masterPasswordChangeCloudUpdateBody =>
      'Vos données sont en cours de mise à jour avec votre nouveau mot de passe.\n\nNe fermez pas l\'application.';

  @override
  String masterPasswordChangeCloudProgress(int done, int total) {
    return '$done / $total entrées synchronisées';
  }

  @override
  String get masterPasswordChangeSuccessTitle => 'Mot de passe maître modifié';

  @override
  String get masterPasswordChangeSuccessBody =>
      'Votre mot de passe maître a été changé avec succès.\n\nDeux sauvegardes ont été créées automatiquement :\n• Une sauvegarde de sécurité conservée 30 jours, qui vous permet de revenir à l\'état précédent si nécessaire (avec votre ancien mot de passe).\n• Une nouvelle sauvegarde à jour avec votre nouveau mot de passe.\n\nVos données sont protégées dans tous les cas.';

  @override
  String get masterPasswordChangeSeeBackups => 'Voir mes sauvegardes';

  @override
  String get masterPasswordChangeFinish => 'Terminer';

  @override
  String get securityBackupBadge => 'Sauvegarde de sécurité';

  @override
  String securityBackupSubtitle(String date, String expiry) {
    return 'Créée le $date. Disponible jusqu\'au $expiry.';
  }

  @override
  String get securityBackupRestoreWarningTitle => 'Restaurer un état précédent';

  @override
  String get securityBackupRestoreWarningBody =>
      'Cette sauvegarde a été créée avant votre dernier changement de mot de passe maître.\n\nPour la restaurer, vous devrez saisir votre ancien mot de passe. Vos données actuelles seront remplacées par celles de cette sauvegarde.\n\nSouhaitez-vous continuer ?';

  @override
  String get biometryDesktopComingSoon => 'Windows Hello — bientôt disponible';

  @override
  String get lockTimeoutDisabled => 'Désactivé';

  @override
  String get crossDeviceKeyChangedTitle =>
      'Mot de passe maître modifié sur un autre appareil';

  @override
  String get crossDeviceKeyChangedBody =>
      'Votre mot de passe maître a été changé sur un autre appareil. Vos données en ligne ne sont plus accessibles avec votre mot de passe actuel depuis cet appareil.\n\nPour continuer à utiliser PassKeyra ici, importez votre dernière sauvegarde depuis l\'appareil où vous avez fait le changement, puis saisissez votre nouveau mot de passe.';

  @override
  String get crossDeviceKeyChangedLater => 'Plus tard';

  @override
  String get onboardingBiometryDesktopMessage =>
      'Cette fonctionnalité arrivera dans une prochaine mise à jour.';

  @override
  String get incorrectMasterPasswordBiometryDisabledAfter3Failures =>
      'Code secret incorrect. Biométrie désactivée après 3 tentatives échouées.';

  @override
  String get biometryNotActivated => 'La biométrie n\'a pas pu être activée.';

  @override
  String get connectionProblem => 'Problème de connexion ?';

  @override
  String get helpAndSettings => 'Aide et paramètres';

  @override
  String get connectionIssues => 'Problèmes de connexion';

  @override
  String get languageSettings => 'Paramètres de langue';

  @override
  String get importBackup => 'Importer une sauvegarde';

  @override
  String get resetApp => 'Réinitialiser l\'application';

  @override
  String get importBackupDescription => 'Restaurer une sauvegarde précédente';

  @override
  String get resetAppDescription => 'Effacer toutes les données et recommencer';

  @override
  String get searchPlaceholder => 'Rechercher... (nom, identifiant, URL, tag)';

  @override
  String get all => 'Toutes';

  @override
  String get entry => 'entrée';

  @override
  String get entries => 'entrées';

  @override
  String get noEntries => 'Aucune entrée';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get addFirstPassword =>
      'Appuyez sur + pour ajouter votre premier mot de passe';

  @override
  String get add => 'Ajouter';

  @override
  String get edit => 'Modifier';

  @override
  String get copyPassword => 'Copier le mot de passe';

  @override
  String get copyAllInfo => 'Copier toutes les infos';

  @override
  String get allInfoCopied => 'Infos copiées dans le presse-papiers';

  @override
  String get copyUsername => 'Copier l\'identifiant';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get close => 'Fermer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get passwordCopied =>
      'Mot de passe copié (effacé automatiquement dans 30s)';

  @override
  String get usernameCopied => 'Identifiant copié';

  @override
  String get urlCopied => 'URL copiée';

  @override
  String get sortByDateDesc => 'Plus récent en premier';

  @override
  String get sortByDateAsc => 'Plus ancien en premier';

  @override
  String get sortByNameAsc => 'Nom (A-Z)';

  @override
  String get sortByNameDesc => 'Nom (Z-A)';

  @override
  String get name => 'Nom';

  @override
  String get username => 'Identifiant';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwords => 'Mots de passe';

  @override
  String get additionalPasswordsShort => 'Additionnels';

  @override
  String get url => 'URL';

  @override
  String get notes => 'Notes';

  @override
  String get tags => 'Tags';

  @override
  String get category => 'Catégorie';

  @override
  String get additionalPasswords => 'Mots de passe additionnels';

  @override
  String get additionalPasswordLabel => 'Mot de passe additionnel';

  @override
  String get required => 'Obligatoire';

  @override
  String get optional => 'Optionnel';

  @override
  String get generatePassword => 'Générer un mot de passe';

  @override
  String get passwordLength => 'Longueur';

  @override
  String get includeUppercase => 'Majuscules (A-Z)';

  @override
  String get includeLowercase => 'Minuscules (a-z)';

  @override
  String get includeNumbers => 'Chiffres (0-9)';

  @override
  String get includeSymbols => 'Symboles (!@#\$...)';

  @override
  String get deleteEntryTitle => 'Supprimer l\'entrée';

  @override
  String get deleteEntryMessage =>
      'Êtes-vous sûr de vouloir supprimer cette entrée ?';

  @override
  String get deleteEntryConfirm => 'Tapez « SUPPRIMER » pour confirmer';

  @override
  String get deleteKeyword => 'SUPPRIMER';

  @override
  String get deleteSuccess => 'Entrée supprimée';

  @override
  String get lockTimeoutImmediate => 'Immédiatement';

  @override
  String get lockTimeout30s => '30 secondes';

  @override
  String get lockTimeout1m => '1 minute';

  @override
  String get lockTimeout2m => '2 minutes';

  @override
  String get lockTimeout5m => '5 minutes';

  @override
  String get lockTimeout10m => '10 minutes';

  @override
  String get lockTimeout30m => '30 minutes';

  @override
  String get autoCloseDisabled => 'Désactivé';

  @override
  String get autoClose30s => '30 secondes';

  @override
  String get autoClose1m => '1 minute';

  @override
  String get autoClose2m => '2 minutes';

  @override
  String get autoClose5m => '5 minutes';

  @override
  String get language => 'Langue';

  @override
  String get languageSubtitle => 'Changez la langue de l\'application';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get french => 'Français';

  @override
  String get english => 'Anglais';

  @override
  String get spanish => 'Espagnol';

  @override
  String get languageChanged => 'Langue modifiée avec succès';

  @override
  String get blurEnabled => 'Floutage de l\'écran activé';

  @override
  String get blurDisabled => 'Floutage de l\'écran désactivé';

  @override
  String get biometryEnabled => 'Biométrie activée';

  @override
  String get biometryDisabled => 'Biométrie désactivée';

  @override
  String get biometryError =>
      'Vous devez d\'abord vous reconnecter avec votre code secret';

  @override
  String get mustReconnect =>
      'Erreur : Vous devez d\'abord vous reconnecter avec votre code secret';

  @override
  String importSuccess(int count) {
    return '$count entrées importées avec succès.\nLa biométrie a été désactivée pour des raisons de sécurité.\nL\'application va se fermer.';
  }

  @override
  String get exportSuccess => 'Export réussi';

  @override
  String get importError => 'Erreur d\'import';

  @override
  String get error => 'Erreur';

  @override
  String get createdAt => 'Créé';

  @override
  String get updatedAt => 'Modifié';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get viewEntry => 'Voir l\'entrée';

  @override
  String get editEntry => 'Modifier l\'entrée';

  @override
  String get newEntry => 'Nouvelle entrée';

  @override
  String get errorCreatingMasterPassword =>
      'Erreur lors de la création du code secret';

  @override
  String get checkMasterPasswordOrBiometry =>
      '1. Vérifiez votre code secret ou utilisez la biométrie.';

  @override
  String get restoreFromBackup => '2. Restaurer depuis une sauvegarde :';

  @override
  String get myLocalBackups => 'Ma sauvegarde locale :';

  @override
  String get noLocalBackup => 'Aucune sauvegarde locale.';

  @override
  String get backupEntry => 'entrée';

  @override
  String get backupEntries => 'entrées';

  @override
  String get restoreFromBackupButton => 'Restaurer depuis une sauvegarde';

  @override
  String get importSourceTitle => 'Choisir la source d\'import';

  @override
  String get importFromLocalFile => 'Fichier local';

  @override
  String get importFromCloud => 'Sauvegarde cloud';

  @override
  String get resetApplication => 'Réinitialiser l\'application';

  @override
  String get resetApplicationConfirm =>
      'Êtes-vous sûr de vouloir réinitialiser l\'application ?\n\nToutes vos données (mots de passe, paramètres, sauvegardes) seront définitivement supprimées.\n\nTapez RESET pour confirmer :';

  @override
  String get resetConfirmWord => 'RESET';

  @override
  String get typeResetToConfirm => 'Tapez RESET pour confirmer';

  @override
  String get applicationResetSuccess => 'Application réinitialisée avec succès';

  @override
  String get biometryNotConfigured =>
      'Biométrie non configurée. Utilisez votre code secret.';

  @override
  String get biometricUnlockError =>
      'Erreur lors du déverrouillage biométrique';

  @override
  String biometricError(String error) {
    return 'Erreur biométrique : $error';
  }

  @override
  String get biometryTemporarilyBlocked =>
      'Biométrie temporairement bloquée. Utilisez votre code secret.';

  @override
  String get importError2 => 'Erreur lors de l\'import';

  @override
  String get vaultAlreadyExists => 'Coffre déjà existant';

  @override
  String get vaultExistsMessage =>
      'Un coffre existe déjà.\n\nL\'import va EFFACER toutes les données actuelles et les remplacer par la sauvegarde.\n\nTapez IMPORT pour confirmer :';

  @override
  String get understood => 'Compris';

  @override
  String get importConfirmWord => 'IMPORT';

  @override
  String invalidBackup(String error) {
    return 'Sauvegarde invalide : $error';
  }

  @override
  String get backupMasterPassword => 'Confirmation du code secret';

  @override
  String get backupPasswordInstructions =>
      'Entrez le code secret de la sauvegarde pour la déchiffrer :';

  @override
  String get import => 'Importer';

  @override
  String get importInProgress => 'Import en cours...';

  @override
  String get pleaseWait => 'Veuillez patienter';

  @override
  String get decryptionInProgress => 'Déchiffrement en cours...';

  @override
  String get decryptionError => 'Erreur de déchiffrement';

  @override
  String get incorrectBackupPassword =>
      'Mot de passe incorrect ou sauvegarde corrompue.';

  @override
  String importFailed(String error) {
    return 'Échec de l\'import : $error';
  }

  @override
  String get other => 'Autre';

  @override
  String get personalCategory => 'Personnel';

  @override
  String get workCategory => 'Travail';

  @override
  String get bankCategory => 'Banque';

  @override
  String get socialCategory => 'Social';

  @override
  String get emailCategory => 'Email';

  @override
  String get shoppingCategory => 'Shopping';

  @override
  String get entertainmentCategory => 'Divertissement';

  @override
  String get sortBy => 'Trier par';

  @override
  String get filterByCategory => 'Filtrer par catégorie';

  @override
  String get premiumFeatures => 'Fonctionnalités Premium';

  @override
  String get premiumDescription =>
      'Fonctionnalités à venir pour les abonnés PassKeyra Premium';

  @override
  String get cloudSync => 'Synchronisation Cloud';

  @override
  String get cloudSyncDescription =>
      'Synchronisation automatique sur tous vos appareils';

  @override
  String get biometricVault => 'Coffre Biométrique';

  @override
  String get biometricVaultDescription =>
      'Sécurité renforcée avec authentification biométrique';

  @override
  String get prioritySupport => 'Support Prioritaire';

  @override
  String get prioritySupportDescription =>
      'Obtenez de l\'aide plus rapidement avec le support prioritaire';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get manageCategoriesTitle => 'Gérer les catégories';

  @override
  String get addCategory => 'Ajouter une catégorie';

  @override
  String get editCategory => 'Modifier la catégorie';

  @override
  String get deleteCategory => 'Supprimer la catégorie';

  @override
  String get categoryName => 'Nom de la catégorie';

  @override
  String get categoryColor => 'Couleur de la catégorie';

  @override
  String get categoryIcon => 'Icône de la catégorie';

  @override
  String get selectColor => 'Sélectionner une couleur';

  @override
  String get deleteCategoryConfirm => 'Supprimer cette catégorie ?';

  @override
  String get categorySaved => 'Catégorie enregistrée';

  @override
  String get categoryDeleted => 'Catégorie supprimée';

  @override
  String get import2 => 'Importer';

  @override
  String get importFromFile => 'Importer depuis un fichier';

  @override
  String get importInstructions =>
      'Sélectionnez un fichier de sauvegarde PassKeyra (.json) à importer';

  @override
  String get selectFile => 'Sélectionner un fichier';

  @override
  String get noFileSelected => 'Aucun fichier sélectionné';

  @override
  String get importWarning =>
      'Attention : Ceci remplacera toutes vos données actuelles !';

  @override
  String get exportToFile => 'Exporter vers un fichier';

  @override
  String get exportInstructions =>
      'Exportez tous vos mots de passe vers un fichier de sauvegarde sécurisé';

  @override
  String get exportButton => 'Exporter maintenant';

  @override
  String get exportWarning => 'Conservez ce fichier en lieu sûr !';

  @override
  String get fileExported => 'Fichier exporté avec succès';

  @override
  String get autoClose45s => '45 secondes';

  @override
  String get securityAnalysis => 'Analyse de sécurité';

  @override
  String get securityScore => 'Score de sécurité';

  @override
  String get securityAnalysisPremiumMessage =>
      'L\'analyse de sécurité est une fonctionnalité Premium. Passez à Premium pour scanner vos mots de passe et détecter les faiblesses.';

  @override
  String get viewPremium => 'Voir Premium';

  @override
  String get score => 'Score';

  @override
  String get veryWeak => 'Très faible';

  @override
  String get weak => 'Faible';

  @override
  String get medium => 'Moyen';

  @override
  String get strong => 'Fort';

  @override
  String get veryStrong => 'Très fort';

  @override
  String get analysisSummary => 'Résumé de l\'analyse';

  @override
  String strongPasswords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots de passe forts',
      one: '1 mot de passe fort',
      zero: 'Aucun mot de passe fort',
    );
    return '$_temp0';
  }

  @override
  String weakPasswords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots de passe faibles',
      one: '1 mot de passe faible',
      zero: 'Aucun mot de passe faible',
    );
    return '$_temp0';
  }

  @override
  String duplicatePasswords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots de passe dupliqués',
      one: '1 mot de passe dupliqué',
      zero: 'Aucun doublon',
    );
    return '$_temp0';
  }

  @override
  String oldPasswords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots de passe anciens',
      one: '1 mot de passe ancien',
      zero: 'Aucun mot de passe ancien',
    );
    return '$_temp0';
  }

  @override
  String get issuesFound => 'Problèmes détectés';

  @override
  String get weakPassword => 'Mot de passe faible';

  @override
  String get duplicatePassword => 'Mot de passe dupliqué';

  @override
  String get oldPassword => 'Mot de passe ancien';

  @override
  String get alsoUsedIn => 'Également utilisé dans';

  @override
  String get recommendations => 'Recommandations';

  @override
  String get recommendUseStrongPasswords =>
      'Utilisez des mots de passe plus complexes pour une meilleure sécurité';

  @override
  String get recommendUseUniquePasswords =>
      'Évitez de réutiliser les mêmes mots de passe';

  @override
  String get recommendUpdateOldPasswords =>
      'Mettez à jour les mots de passe anciens au moins une fois par an';

  @override
  String get recommendUse12PlusChars =>
      'Utilisez au moins 12 caractères pour vos mots de passe';

  @override
  String get recommendUseSymbols =>
      'Incluez des symboles pour renforcer la sécurité';

  @override
  String get help => 'Aide';

  @override
  String get securityAnalysisHelp =>
      'L\'analyse de sécurité examine tous vos mots de passe et détecte :\n\n• Mots de passe faibles (trop courts ou simples)\n• Mots de passe dupliqués (utilisés plusieurs fois)\n• Mots de passe anciens (non changés depuis >1 an)\n\nLe score de sécurité est calculé selon :\n• Longueur du mot de passe\n• Variété des caractères (majuscules, minuscules, chiffres, symboles)\n• Complexité globale';

  @override
  String errorDuringAnalysis(String error) {
    return 'Erreur lors de l\'analyse : $error';
  }

  @override
  String get unableToPerformAnalysis => 'Impossible d\'effectuer l\'analyse';

  @override
  String get retry => 'Réessayer';

  @override
  String passwordNotUpdatedYears(int years) {
    return 'Non mis à jour depuis $years an(s)';
  }

  @override
  String get passwordTooShort => 'Trop court (< 8 caractères)';

  @override
  String get passwordShouldBe12Plus => 'Devrait faire 12+ caractères';

  @override
  String get passwordNoUppercase => 'Aucune majuscule';

  @override
  String get passwordNoLowercase => 'Aucune minuscule';

  @override
  String get passwordNoNumbers => 'Aucun chiffre';

  @override
  String get passwordNoSymbols => 'Aucun symbole';

  @override
  String get weakPasswordGeneric => 'Mot de passe faible';

  @override
  String usedInEntries(int count) {
    return 'Utilisé dans $count entrées';
  }

  @override
  String get customIcon => 'Icône personnalisée';

  @override
  String get chooseIcon => 'Choisir une icône';

  @override
  String get changeIcon => 'Changer d\'icône';

  @override
  String get iconSelected => 'Icône sélectionnée';

  @override
  String get chooseColor => 'Choisir une couleur';

  @override
  String get customIconsPremiumFeature =>
      'Les icônes personnalisées sont réservées aux utilisateurs Premium. Passez à Premium pour débloquer cette fonctionnalité et bien plus encore !';

  @override
  String get categoryIconsTab => 'Icônes';

  @override
  String get categoryEmojisTab => 'Emojis';

  @override
  String get categoryEmojisPremium =>
      'Les emojis pour les catégories sont réservés aux utilisateurs Premium';

  @override
  String get categoryColorPicker => 'Palette complète';

  @override
  String get categoryPredefinedColors => 'Couleurs prédéfinies';

  @override
  String get theme => 'Thème';

  @override
  String get themeSubtitle => 'Mode clair, sombre ou système';

  @override
  String get selectTheme => 'Sélectionner un thème';

  @override
  String get themeMode => 'Mode d\'affichage';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get systemMode => 'Mode automatique';

  @override
  String get systemModeSubtitle => 'Basé sur la luminosité ambiante';

  @override
  String get darkVariant => 'Variante du mode sombre';

  @override
  String get standardDark => 'Sombre standard';

  @override
  String get standardDarkSubtitle => 'Mode sombre classique';

  @override
  String get amoledBlack => 'Noir AMOLED';

  @override
  String get amoledBlackSubtitle => 'Noir pur pour écrans OLED';

  @override
  String get darkGrey => 'Gris foncé';

  @override
  String get darkGreySubtitle => 'Gris personnalisé élégant';

  @override
  String get darkThemePremiumFeature =>
      'Les variantes de mode sombre avancées (AMOLED Black et Gris foncé) sont réservées aux utilisateurs Premium. Passez à Premium pour débloquer ces thèmes et bien plus encore !';

  @override
  String get colorPalette => 'Palette de couleurs';

  @override
  String get colorPaletteBlue => 'Bleue (Classique)';

  @override
  String get colorPaletteGreen => 'Verte';

  @override
  String get colorPaletteRedPink => 'Rouge/Rose';

  @override
  String get colorPalettePurple => 'Violette';

  @override
  String get colorPaletteOrange => 'Orange';

  @override
  String get colorPalettePremiumFeature =>
      'Les palettes de couleurs personnalisées sont réservées aux utilisateurs Premium. Passez à Premium pour débloquer toutes les palettes et bien plus encore !';

  @override
  String get fontFamily => 'Police de caractères';

  @override
  String get fontRoboto => 'Roboto';

  @override
  String get fontLato => 'Lato';

  @override
  String get fontMontserrat => 'Montserrat';

  @override
  String get fontOpenSans => 'Open Sans';

  @override
  String get fontFamilyPremiumFeature =>
      'Les polices personnalisées sont réservées aux utilisateurs Premium. Passez à Premium pour débloquer toutes les polices et bien plus encore !';

  @override
  String get cloudBackup => 'Sauvegarde Cloud';

  @override
  String get cloudBackupSubtitle => 'Sauvegarder sur le cloud';

  @override
  String get cloudBackupTitle => 'Sauvegarde Cloud';

  @override
  String get cloudProviderSelectionDescription =>
      'Choisissez votre service cloud préféré pour sauvegarder vos mots de passe de manière sécurisée. Vous pourrez changer de service à tout moment.';

  @override
  String get selectCloudProvider => 'Choisir un service cloud';

  @override
  String get switchProviderTitle => 'Changer de service cloud';

  @override
  String switchProviderMessage(Object currentProvider, Object newProvider) {
    return 'Se déconnecter de $currentProvider et basculer vers $newProvider ?';
  }

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get uploadToCloud => 'Sauvegarder vers le cloud';

  @override
  String get restoreFromCloud => 'Restaurer depuis le cloud';

  @override
  String get cloudBackupSuccess => 'Backup cloud réussi';

  @override
  String get cloudDisconnectTitle => 'Déconnecter le compte Google ?';

  @override
  String get cloudDisconnectMessage =>
      'La sauvegarde Google Drive et la synchronisation Premium utilisent le même compte Google : la sync est l\'extension Premium de la sauvegarde Drive. Déconnecter interrompt donc les deux. Vos données locales et vos sauvegardes déjà présentes dans le cloud sont conservées. Vous pourrez vous reconnecter et choisir un autre compte à tout moment.';

  @override
  String get cloudDisconnectConfirm => 'Déconnecter';

  @override
  String get cloudDisconnectGenericTitle => 'Déconnecter le compte cloud ?';

  @override
  String get cloudDisconnectGenericMessage =>
      'Cette action désactive la sauvegarde automatique, déconnecte votre compte cloud et efface la configuration du provider. Vos sauvegardes déjà présentes dans le cloud et vos données locales sont conservées.';

  @override
  String cloudBackupFailed(Object error) {
    return 'Échec du backup cloud : $error';
  }

  @override
  String get noCloudBackups => 'Aucune sauvegarde cloud trouvée';

  @override
  String lastCloudBackup(Object date) {
    return 'Dernière sauvegarde : $date';
  }

  @override
  String get cloudQuotaExceeded => 'Quota cloud dépassé';

  @override
  String get cloudProviderNotAvailable => 'Service cloud indisponible';

  @override
  String authenticateWith(Object provider) {
    return 'Se connecter à $provider';
  }

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get deleteBackup => 'Supprimer la sauvegarde';

  @override
  String get downloadBackup => 'Télécharger la sauvegarde';

  @override
  String get restore => 'Restaurer';

  @override
  String cloudRestoreConfirmation(Object date) {
    return 'Restaurer la sauvegarde du $date ? Cette action remplacera toutes vos données actuelles.';
  }

  @override
  String cloudRestoreSuccess(Object count) {
    return 'Sauvegarde restaurée avec succès ($count entrées)';
  }

  @override
  String cloudRestoreFailed(Object error) {
    return 'Échec de la restauration : $error';
  }

  @override
  String get restoreSuccessAutoClose =>
      'Restauration réussie !\n\nL\'application va se fermer automatiquement dans 2 secondes pour appliquer les changements.';

  @override
  String cloudDeleteConfirmation(Object date) {
    return 'Supprimer définitivement la sauvegarde du $date ?';
  }

  @override
  String get cloudBackupDeleted => 'Sauvegarde supprimée';

  @override
  String cloudDeleteFailed(Object error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get cloudNoBackupsHint =>
      'Appuyez sur le bouton ci-dessous pour créer votre première sauvegarde';

  @override
  String cloudRateLimitMessage(Object minutes) {
    return 'Veuillez attendre $minutes minute(s) avant le prochain backup';
  }

  @override
  String get cloudAuthenticationFailed => 'Échec de l\'authentification';

  @override
  String get cloudNoAuthService => 'Service d\'authentification non disponible';

  @override
  String get cloudSyncTitle => 'Synchronisation cloud';

  @override
  String get cloudSyncSubtitle => 'Sync automatique temps réel entre appareils';

  @override
  String get cloudSyncSettings => 'Paramètres de synchronisation';

  @override
  String get cloudSyncAccount => 'Compte cloud';

  @override
  String get cloudSyncNoAccount => 'Aucun compte Google connecté';

  @override
  String get cloudSyncSignIn => 'Se connecter avec Google';

  @override
  String get cloudSyncSignOut => 'Se déconnecter';

  @override
  String get cloudSyncAutomatic => 'Synchronisation automatique';

  @override
  String get cloudSyncEnabled =>
      'Les modifications sont synchronisées automatiquement';

  @override
  String get cloudSyncDisabled => 'Synchronisation manuelle uniquement';

  @override
  String get cloudSyncManualActions => 'Actions manuelles';

  @override
  String get cloudSyncUpload => 'Envoyer vers le cloud';

  @override
  String get cloudSyncDownload => 'Télécharger depuis le cloud';

  @override
  String get cloudSyncPremiumFeature => 'Feature Premium';

  @override
  String get cloudSyncPremiumMessage =>
      'La synchronisation cloud temps réel nécessite PassKeyra Premium';

  @override
  String get syncStatusIdle => 'Inactif';

  @override
  String get syncStatusSyncing => 'Synchronisation en cours...';

  @override
  String get syncStatusSuccess => 'Synchronisé';

  @override
  String get syncStatusError => 'Erreur de synchronisation';

  @override
  String get syncStatusConflict => 'Conflit détecté';

  @override
  String get syncLastSyncNever => 'Jamais synchronisé';

  @override
  String get syncLastSyncJustNow => 'À l\'instant';

  @override
  String syncLastSyncMinutes(Object minutes) {
    return 'Il y a $minutes min';
  }

  @override
  String syncLastSyncHours(Object hours) {
    return 'Il y a $hours h';
  }

  @override
  String syncLastSyncDays(Object days) {
    return 'Il y a $days jours';
  }

  @override
  String syncEntriesUploaded(Object count) {
    return '$count entrées synchronisées';
  }

  @override
  String syncEntriesDownloaded(Object count) {
    return '$count entrées téléchargées';
  }

  @override
  String syncMergeCompleted(Object count) {
    return 'Merge terminé ($count entrées)';
  }

  @override
  String get syncConflictResolved =>
      'Conflit résolu (version la plus récente conservée)';

  @override
  String get syncEnabled => 'Synchronisation activée';

  @override
  String get syncDisabled => 'Synchronisation désactivée';

  @override
  String get syncErrorOffline => 'Erreur : Aucune connexion internet';

  @override
  String get syncErrorAuth => 'Erreur : Authentification expirée';

  @override
  String get syncErrorQuota => 'Erreur : Quota Firebase dépassé';

  @override
  String get helpLogosTitle => 'Signification des logos';

  @override
  String get helpLogoCloud => 'Logo Cloud (☁️)';

  @override
  String get helpLogoCloudSubtitle => 'Backup automatique Google Drive';

  @override
  String get helpLogoSync => 'Logo Sync (⇄)';

  @override
  String get helpLogoSyncSubtitle => 'Synchronisation Firebase temps réel';

  @override
  String get helpColorLegend => 'Code couleur (pour les 2 logos) :';

  @override
  String get helpColorBlue => 'Bleu';

  @override
  String get helpColorBlueMeaning => 'Activé et prêt';

  @override
  String get helpColorPurple => 'Violet';

  @override
  String get helpColorPurpleMeaning => 'Synchronisation en cours';

  @override
  String get helpColorGreen => 'Vert';

  @override
  String get helpColorGreenMeaning => 'Opération réussie';

  @override
  String get helpColorRed => 'Rouge';

  @override
  String get helpColorRedMeaning => 'Erreur';

  @override
  String get helpColorGrey => 'Gris';

  @override
  String get helpColorGreyMeaning => 'Désactivé';

  @override
  String syncConnectedAs(Object email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get syncDisconnected => 'Déconnecté';

  @override
  String get syncAutoLabel => 'Sync auto';

  @override
  String get syncManualLabel => 'Sync manuelle';

  @override
  String get androidVersionWarningTitle => 'Fonctionnalités limitées';

  @override
  String get androidVersionWarningMessage =>
      'Votre version d\'Android (< 8.0) ne supporte pas la restauration de sauvegardes. Pour une expérience complète, veuillez utiliser Android 8.0 ou supérieur. Création et affichage de sauvegardes restent disponibles.';

  @override
  String get onboardingFirstChoiceTitle => 'Didacticiel de démarrage';

  @override
  String get onboardingFirstChoiceMessage =>
      'Souhaitez-vous un guide rapide pour commencer ?';

  @override
  String get onboardingStartTutorial => 'Commencer le didacticiel';

  @override
  String get onboardingSkipTutorial => 'Quitter';

  @override
  String get onboardingQuitTitle => 'Tutoriel quitté';

  @override
  String get onboardingQuitMessage =>
      'Vous pouvez le rejouer à tout moment depuis Paramètres → Didacticiel.';

  @override
  String get onboardingMasterPasswordTitle => 'Alerte mot de passe maître';

  @override
  String get onboardingMasterPasswordMessage =>
      'Votre mot de passe maître est la seule clé. S\'il est perdu, aucune restauration n\'est possible.';

  @override
  String get onboardingSecurityRequirements => 'Exigences de sécurité :';

  @override
  String get onboardingRuleLength => 'Minimum 12 caractères (16+ recommandé)';

  @override
  String get onboardingRuleComplexity =>
      'Majuscules, minuscules, chiffres, symboles';

  @override
  String get onboardingRuleDictionary => 'Éviter les mots du dictionnaire';

  @override
  String get onboardingRuleUnique => 'Mot de passe unique, jamais réutilisé';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingFinish => 'Terminer';

  @override
  String get onboardingCreateFirstEntry => 'Créer ma première entrée';

  @override
  String get onboardingStepSearchTitle => 'Recherche rapide';

  @override
  String get onboardingStepSearchBody =>
      'La recherche permet de filtrer les entrées par nom, identifiant, URL ou tag.';

  @override
  String get onboardingStepSettingsTitle => 'Accès aux paramètres';

  @override
  String get onboardingStepSettingsBody =>
      'Ce menu regroupe tous les paramètres de sécurité et les autres options.';

  @override
  String get onboardingStepAddTitle => 'Création d\'une entrée';

  @override
  String get onboardingStepAddBody =>
      'Le bouton + permet de créer une nouvelle entrée dans le coffre.';

  @override
  String get onboardingStepCopyAllTitle => 'Copier une entrée';

  @override
  String get onboardingStepCopyAllBody =>
      'Ce bouton copie toutes les informations utiles de l\'entrée : identifiant, mot de passe, URL et notes si présents.';

  @override
  String get onboardingRestart => 'Relancer le didacticiel';

  @override
  String get onboardingRestartDescription =>
      'Rejouer l\'intégralité du didacticiel de prise en main';

  @override
  String get onboardingWillRestart =>
      'Le didacticiel sera relancé au prochain lancement de l\'application.';

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String get onboardingFinishLater => 'Finir plus tard';

  @override
  String get onboardingSecurityPauseTitle => 'Découverte de la sécurité';

  @override
  String get onboardingSecurityPauseMessage =>
      'Continuer avec un aperçu des fonctionnalités de sécurité ? (3 étapes rapides)';

  @override
  String get onboardingSecurityReportTitle => 'Analyse de sécurité';

  @override
  String get onboardingSecurityReportMessage =>
      'Le rapport de sécurité analyse les mots de passe et détecte les problèmes : mots de passe faibles, réutilisés ou compromis.';

  @override
  String get onboardingLockTimeoutTitle => 'Verrouillage automatique';

  @override
  String get onboardingLockTimeoutMessage =>
      'L\'application se verrouille automatiquement après une période d\'inactivité pour protéger les données.';

  @override
  String get onboardingBiometryTitle => 'Authentification biométrique';

  @override
  String get onboardingBiometryMessage =>
      'Déverrouillage rapide et sécurisé avec empreinte digitale ou reconnaissance faciale.';

  @override
  String get onboardingClickHere =>
      'Veuillez cliquer sur l\'élément en surbrillance';

  @override
  String get onboardingCompleteMessage =>
      'Vous connaissez maintenant toutes les fonctionnalités essentielles de PassKeyra. Bonne utilisation !';

  @override
  String get discoveryModeTitle => 'Didacticiel';

  @override
  String get discoveryModeSubtitle =>
      'Apprenez à utiliser toutes les fonctionnalités de PassKeyra à votre rythme';

  @override
  String get discoverySteps => 'étapes';

  @override
  String get discoveryCompleted => 'Terminé';

  @override
  String get discoveryStart => 'Démarrer';

  @override
  String get discoveryReplay => 'Rejouer';

  @override
  String get discoveryEntriesTitle => 'Gestion avancée des entrées';

  @override
  String get discoveryEntriesDescription =>
      'Découvrez comment consulter, modifier et organiser vos entrées';

  @override
  String get discoveryEntriesViewTitle => 'Consulter une entrée';

  @override
  String get discoveryEntriesViewMessage =>
      'Touchez une entrée dans la liste pour afficher tous ses détails : mot de passe, identifiant, URL, notes et catégorie.';

  @override
  String get discoveryEntriesCopyTitle => 'Copier rapidement';

  @override
  String get discoveryEntriesCopyMessage =>
      'Touchez le mot de passe ou l\'identifiant pour le copier instantanément dans le presse-papiers.';

  @override
  String get discoveryEntriesGeneratorTitle => 'Générateur de mots de passe';

  @override
  String get discoveryEntriesGeneratorMessage =>
      'Utilisez le générateur pour créer des mots de passe forts et uniques. Personnalisez la longueur et les caractères inclus.';

  @override
  String get discoveryEntriesAdditionalTitle => 'Mots de passe additionnels';

  @override
  String get discoveryEntriesAdditionalMessage =>
      'Ajoutez plusieurs mots de passe à une même entrée (ex: mot de passe principal + code PIN).';

  @override
  String get discoveryEntriesCategoriesTitle => 'Catégories personnalisées';

  @override
  String get discoveryEntriesCategoriesMessage =>
      'Créez vos propres catégories pour organiser vos entrées comme vous le souhaitez.';

  @override
  String get discoveryBackupTitle => 'Sauvegarde & Synchronisation';

  @override
  String get discoveryBackupDescription =>
      'Protégez vos données et synchronisez entre appareils';

  @override
  String get discoveryBackupLocalTitle => 'Sauvegardes locales';

  @override
  String get discoveryBackupLocalMessage =>
      'Exportez vos données sur votre appareil pour les sauvegarder ou les transférer. Vous pouvez aussi importer depuis un fichier de sauvegarde.';

  @override
  String get discoveryBackupDriveTitle => 'Google Drive';

  @override
  String get discoveryBackupDriveMessage =>
      'Sauvegardez automatiquement vos données cryptées sur Google Drive pour les retrouver en cas de problème.';

  @override
  String get discoveryBackupSyncTitle => 'Synchronisation Firebase';

  @override
  String get discoveryBackupSyncMessage =>
      'Synchronisez automatiquement vos entrées entre tous vos appareils en temps réel (fonctionnalité Premium).';

  @override
  String get discoveryBackupConflictsTitle => 'Résolution de conflits';

  @override
  String get discoveryBackupConflictsMessage =>
      'En cas de modifications simultanées sur plusieurs appareils, choisissez quelle version conserver.';

  @override
  String get discoveryAppearanceTitle => 'Apparence & Premium';

  @override
  String get discoveryAppearanceDescription =>
      'Personnalisez l\'interface et découvrez les fonctionnalités Premium';

  @override
  String get discoveryAppearanceThemesTitle => 'Thèmes';

  @override
  String get discoveryAppearanceThemesMessage =>
      'Choisissez parmi 4 thèmes : Clair, Sombre, AMOLED Black, ou Gris foncé. Le mode adaptatif ajuste automatiquement selon la lumière ambiante.';

  @override
  String get discoveryAppearancePalettesTitle => 'Palettes de couleurs';

  @override
  String get discoveryAppearancePalettesMessage =>
      'Personnalisez l\'interface avec 5 palettes de couleurs différentes (fonctionnalité Premium).';

  @override
  String get discoveryAppearanceFontsTitle => 'Polices personnalisées';

  @override
  String get discoveryAppearanceFontsMessage =>
      'Changez la police de l\'application parmi 4 choix disponibles (fonctionnalité Premium).';

  @override
  String get discoveryAppearancePremiumTitle => 'PassKeyra Premium';

  @override
  String get discoveryAppearancePremiumMessage =>
      'Déverrouillez toutes les fonctionnalités : palettes, polices, sync temps réel, analyse de sécurité avancée, et plus encore !';

  @override
  String get discoveryPremiumTitle => 'Fonctionnalités Premium';

  @override
  String get discoveryPremiumDescription =>
      'Découvrez toutes les fonctionnalités exclusives Premium';

  @override
  String get discoveryPremiumIntroMessage =>
      'Découvrez toutes les fonctionnalités exclusives de PassKeyra Premium.';

  @override
  String get discoveryPremiumPalettesTitle => 'Palettes & Polices';

  @override
  String get discoveryPremiumPalettesMessage =>
      'Personnalisez l\'apparence avec des palettes de couleurs et des polices exclusives Premium.';

  @override
  String get discoveryPremiumSecurityTitle => 'Analyse de sécurité';

  @override
  String get discoveryPremiumSecurityMessage =>
      'L\'analyse de sécurité vérifie la force de vos mots de passe et détecte les problèmes (mots de passe faibles, réutilisés ou compromis).';

  @override
  String get discoveryPremiumCompleteMessage =>
      'Vous connaissez maintenant toutes les fonctionnalités Premium de PassKeyra!';

  @override
  String get onboardingStepSortTitle => 'Tri & filtres';

  @override
  String get onboardingStepSortBody =>
      'Triez les entrées par nom ou par date avec ce bouton. Réorganisez rapidement votre liste pour trouver ce que vous cherchez.';

  @override
  String get onboardingStepCategoriesTitle => 'Filtres par catégorie';

  @override
  String get onboardingStepCategoriesBody =>
      'Appuyez sur une catégorie pour filtrer vos entrées. Faites défiler horizontalement pour voir toutes les catégories disponibles.';

  @override
  String get onboardingSettingsSecurityTitle => 'Paramètres de sécurité';

  @override
  String get onboardingSettingsSecurityBody =>
      'Cette section permet de configurer le verrouillage automatique, la biométrie et toutes les options de sécurité de votre coffre.';

  @override
  String get onboardingSettingsBackupTitle => 'Sauvegarde & Synchronisation';

  @override
  String get onboardingSettingsBackupBody =>
      'Gérez vos sauvegardes locales et cloud, et configurez la synchronisation entre vos appareils.';

  @override
  String get onboardingSettingsAppearanceTitle => 'Apparence';

  @override
  String get onboardingSettingsAppearanceBody =>
      'Personnalisez la langue, le thème et les catégories de votre application.';

  @override
  String get onboardingBackupLocalTitle => 'Sauvegarde locale';

  @override
  String get onboardingBackupLocalBody =>
      'Exportez votre coffre sur cet appareil ou restaurez-le depuis une sauvegarde existante.';

  @override
  String get onboardingBackupCloudTitle => 'Sauvegarde cloud';

  @override
  String get onboardingBackupCloudBody =>
      'Sauvegardez votre coffre dans le cloud pour y accéder depuis tous vos appareils.';

  @override
  String get onboardingChangeMasterPasswordTitle => 'Mot de passe maître';

  @override
  String get onboardingChangeMasterPasswordMessage =>
      'Votre mot de passe maître est la seule clé de votre coffre. Vous pouvez le modifier ici à tout moment.';

  @override
  String get onboardingAutoCloseTitle => 'Fermeture automatique';

  @override
  String get onboardingAutoCloseMessage =>
      'L\'application peut se fermer automatiquement après une période d\'inactivité pour une protection supplémentaire.';

  @override
  String get onboardingLoginAttemptsTitle => 'Tentatives de connexion';

  @override
  String get onboardingLoginAttemptsMessage =>
      'Limitez le nombre de tentatives échouées avant le blocage temporaire du coffre.';

  @override
  String get premiumTutorialIntroTitle => 'Bienvenue dans PassKeyra Premium !';

  @override
  String get premiumTutorialIntroMessage =>
      'Découvrons vos nouvelles fonctionnalités.';

  @override
  String get premiumTutorialNoAdsTitle => 'Sans publicités';

  @override
  String get premiumTutorialNoAdsMessage =>
      'En tant qu\'utilisateur Premium, profitez d\'une expérience sans publicité ni interruption.';

  @override
  String get premiumTutorialCloudSyncTitle => 'Synchronisation cloud';

  @override
  String get premiumTutorialCloudSyncMessage =>
      'Activez la synchronisation pour maintenir votre coffre à jour sur tous vos appareils. Nécessite un compte Google connecté à PassKeyra.';

  @override
  String get premiumTutorialBackupTitle => 'Liste des sauvegardes';

  @override
  String get premiumTutorialBackupMessage =>
      'Vos sauvegardes apparaissent ici. Chaque nouvelle sauvegarde remplace la précédente - votre coffre est toujours protégé.';

  @override
  String get premiumTutorialAutoBackupTitle => 'Sauvegarde automatique';

  @override
  String get premiumTutorialAutoBackupMessage =>
      'Activez la sauvegarde automatique pour que votre coffre soit enregistré dans le cloud à chaque modification.';

  @override
  String get premiumTutorialManualBackupTitle => 'Sauvegarde manuelle';

  @override
  String get premiumTutorialManualBackupMessage =>
      'Appuyez sur ce bouton pour enregistrer immédiatement votre coffre dans le cloud.';

  @override
  String get premiumTutorialProviderNameTitle => 'Votre fournisseur actuel';

  @override
  String get premiumTutorialProviderNameMessage =>
      'Le nom affiché ici indique votre fournisseur de sauvegarde cloud. Vous pouvez le modifier à tout moment via l\'icône en haut à droite.';

  @override
  String get premiumTutorialChangeProviderTitle => 'Changer de fournisseur';

  @override
  String get premiumTutorialChangeProviderMessage =>
      'Appuyez sur l\'icône cloud en haut à droite pour changer de fournisseur de stockage cloud à tout moment.';

  @override
  String get premiumTutorialIconsTitle => 'Icônes & Mots de passe multiples';

  @override
  String get premiumTutorialIconsMessage =>
      'Personnalisez chaque entrée avec un emoji et ajoutez plusieurs mots de passe par entrée depuis la page d\'édition.';

  @override
  String get premiumTutorialSecurityTitle => 'Sécurité & Apparence';

  @override
  String get premiumTutorialSecurityMessage =>
      'Consultez votre score de sécurité dans Paramètres › Sécurité. Personnalisez polices et palettes depuis Paramètres › Apparence.';

  @override
  String get premiumTutorialSecurityReportTitle =>
      'Analyse de sécurité débloquée !';

  @override
  String get premiumTutorialSecurityReportMessage =>
      'Voici votre rapport de sécurité. Consultez votre score global et les recommandations pour renforcer vos mots de passe. Accessible à tout moment depuis Paramètres › Sécurité.';

  @override
  String get premiumTutorialCompleteMessage =>
      'Vous avez découvert toutes vos fonctionnalités Premium. Profitez pleinement de PassKeyra !';

  @override
  String get premiumLocalAutoBackupTitle => 'Sauvegarde locale automatique';

  @override
  String get premiumLocalAutoBackupDescription =>
      'Sauvegarde chiffrée automatique sur votre appareil à chaque modification du coffre';

  @override
  String get premiumTutorialLocalBackupTitle => 'Sauvegarde locale automatique';

  @override
  String get premiumTutorialLocalBackupMessage =>
      'Activez cette option pour que votre coffre soit automatiquement sauvegardé sur votre appareil à chaque modification, indépendamment du cloud.';

  @override
  String get cloudSyncRequiresGoogle =>
      'La synchronisation nécessite un compte Google connecté à PassKeyra.';

  @override
  String get premiumTutorialEmojiTitle => 'Personnalisation';

  @override
  String get premiumTutorialEmojiMessage =>
      'Appuyez ici pour associer un emoji à cette entrée. Chaque entrée peut avoir sa propre icône.';

  @override
  String get premiumTutorialMultiPasswordTitle => 'Mots de passe multiples';

  @override
  String get premiumTutorialMultiPasswordMessage =>
      'Ajoutez plusieurs mots de passe à une même entrée, idéal si vous utilisez plusieurs combinaisons pour un même service.';

  @override
  String get firstEntryTutorialNameTitle => 'Nom de l\'entrée';

  @override
  String get firstEntryTutorialNameMessage =>
      'Saisissez un nom reconnaissable pour identifier ce compte facilement.';

  @override
  String get firstEntryTutorialCategoryTitle => 'Catégorie';

  @override
  String get firstEntryTutorialCategoryMessage =>
      'Classez cette entrée dans une catégorie pour retrouver vos comptes plus rapidement.';

  @override
  String get firstEntryTutorialUsernameTitle => 'Identifiant';

  @override
  String get firstEntryTutorialUsernameMessage =>
      'Entrez votre identifiant ou adresse e-mail pour ce compte.';

  @override
  String get firstEntryTutorialPasswordTitle => 'Mot de passe';

  @override
  String get firstEntryTutorialPasswordMessage =>
      'Entrez votre mot de passe, ou ouvrez le générateur pour en créer un sécurisé.';

  @override
  String get firstEntryTutorialOpenGenerator => 'Ouvrir le générateur';

  @override
  String get firstEntryTutorialGeneratorLengthTitle => 'Longueur';

  @override
  String get firstEntryTutorialGeneratorLengthMessage =>
      'Glissez le curseur pour choisir la longueur (16 caractères ou plus recommandé).';

  @override
  String get firstEntryTutorialGeneratorLowerTitle => 'Minuscules';

  @override
  String get firstEntryTutorialGeneratorLowerMessage =>
      'Incluez des lettres minuscules (a-z) pour renforcer votre mot de passe.';

  @override
  String get firstEntryTutorialGeneratorUpperTitle => 'Majuscules';

  @override
  String get firstEntryTutorialGeneratorUpperMessage =>
      'Ajoutez des majuscules (A-Z) pour complexifier le mot de passe.';

  @override
  String get firstEntryTutorialGeneratorDigitsTitle => 'Chiffres';

  @override
  String get firstEntryTutorialGeneratorDigitsMessage =>
      'Incluez des chiffres (0-9) pour augmenter la sécurité.';

  @override
  String get firstEntryTutorialGeneratorSymbolsTitle => 'Symboles';

  @override
  String get firstEntryTutorialGeneratorSymbolsMessage =>
      'Ajoutez des symboles (!@#\$…) pour maximiser la résistance aux attaques.';

  @override
  String get firstEntryTutorialUrlTitle => 'URL';

  @override
  String get firstEntryTutorialUrlMessage =>
      'Ajoutez l\'adresse du site web associé à ce compte (optionnel).';

  @override
  String get firstEntryTutorialNotesTitle => 'Notes';

  @override
  String get firstEntryTutorialNotesMessage =>
      'Ajoutez des informations complémentaires : questions de sécurité, codes, etc.';

  @override
  String get firstEntryTutorialTagsTitle => 'Tags';

  @override
  String get firstEntryTutorialTagsMessage =>
      'Ajoutez des tags séparés par des virgules pour faciliter la recherche.';

  @override
  String get firstEntryTutorialEmojiTitle => 'Icône personnalisée';

  @override
  String get firstEntryTutorialEmojiMessage =>
      'Associez un emoji à cette entrée pour la reconnaître d\'un coup d\'œil.';

  @override
  String get firstEntryTutorialAdditionalPasswordsTitle =>
      'Mots de passe additionnels';

  @override
  String get firstEntryTutorialAdditionalPasswordsMessage =>
      'Ajoutez plusieurs mots de passe à une même entrée (PIN, profils multiples…).';

  @override
  String get firstEntryTutorialSaveTitle => 'Enregistrer l\'entrée';

  @override
  String get firstEntryTutorialSaveMessage =>
      'Tout est prêt ! Appuyez sur le bouton ✓ pour enregistrer cette entrée dans votre coffre.';

  @override
  String get firstEntryTutorialSaveAction => 'J\'ai compris';

  @override
  String get firstEntryTutorialCardTitle => 'Votre première entrée !';

  @override
  String get firstEntryTutorialCardMessage =>
      'Votre entrée est enregistrée. Voyons les actions disponibles sur chaque carte.';

  @override
  String get firstEntryTutorialCopyPasswordTitle => 'Copier le mot de passe';

  @override
  String get firstEntryTutorialCopyPasswordMessage =>
      'Ce bouton copie uniquement le mot de passe (effacé automatiquement après 30 s).';

  @override
  String get firstEntryTutorialCopyAllTitle => 'Copier toutes les informations';

  @override
  String get firstEntryTutorialCopyAllMessage =>
      'Ce bouton copie en une fois le nom, l\'identifiant, le mot de passe, l\'URL et les notes.';

  @override
  String get firstEntryTutorialTapCardTitle => 'Consulter l\'entrée';

  @override
  String get firstEntryTutorialTapCardMessage =>
      'Appuyez sur la carte pour voir le détail complet et modifier l\'entrée.';

  @override
  String get discoveryFirstEntryTitle => 'Créer une entrée';

  @override
  String get discoveryFirstEntryDescription =>
      'Apprenez à créer, remplir et gérer votre première entrée de A à Z.';

  @override
  String get discoveryFirstEntrySteps => '14 étapes';
}
