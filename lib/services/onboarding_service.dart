import 'package:shared_preferences/shared_preferences.dart';

enum OnboardingStatus {
  nonVu,
  skip,
  partie1Terminee,
  termine,
}

/// Types de tutoriels Mode Découverte
enum DiscoveryTutorial {
  premium,                 // Fonctionnalités Premium (visible uniquement si Premium)
  firstEntry,              // Tutoriel première création d'entrée
  firstCloudBackup,        // Phase 2 du tutoriel cloud (page authentifiée, 4 coach marks)
  firstCloudBackupPhase1,  // Phase 1 du tutoriel cloud (choix de provider, 1 coach mark)
}

class OnboardingService {
  OnboardingService._();

  static final OnboardingService instance = OnboardingService._();

  /// Flag in-memory : passe à `true` dès que l'utilisateur clique "Quitter"
  /// sur n'importe quel coach mark, pendant la session courante.
  ///
  /// Consommé par `CoachMarkSystem.showCoachStep` et `HomePage._showCoachStep`
  /// qui court-circuitent (return `.skip` immédiat sans afficher de dialog)
  /// dès que ce flag est `true`. Évite que les chaînes de coach marks
  /// (`step1 → step2 → step3`) continuent à afficher des popups après Quitter
  /// même si les callers ne font pas un `return` propre entre les étapes.
  ///
  /// Reset à `false` automatiquement quand l'utilisateur relance un tutoriel
  /// via Mode Découverte (`markPreVaultCompleted`, `resetDiscoveryTutorial`, etc.).
  bool _userQuitInCurrentSession = false;
  bool get userQuitInCurrentSession => _userQuitInCurrentSession;
  void resetQuitFlagForReplay() {
    _userQuitInCurrentSession = false;
  }

  static const String _statusKey = 'onboarding_status';
  static const String _forcePostVaultKey = 'onboarding_force_post_vault';
  static const String _pendingPremiumTutorialKey = 'pending_premium_tutorial';
  static const String _pendingFirstEntryPhase2Key = 'pending_first_entry_phase2';
  static const String _discoveryPrefix = 'discovery_completed_';

  Future<OnboardingStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statusKey) ?? 'non_vu';
    return _statusFromRaw(raw);
  }

  Future<void> setStatus(OnboardingStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, _statusToRaw(status));
  }

  Future<void> skipTutorial() async {
    await setStatus(OnboardingStatus.skip);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_forcePostVaultKey, false);
  }

  Future<void> markPreVaultCompleted() async {
    await setStatus(OnboardingStatus.partie1Terminee);
  }

  Future<void> markTutorialCompleted() async {
    await setStatus(OnboardingStatus.termine);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_forcePostVaultKey, false);
  }

  /// Quitte définitivement TOUS les tutoriels (onboarding initial + tutos
  /// découverte qui pourraient se déclencher automatiquement plus tard).
  /// L'utilisateur peut toujours les rejouer manuellement via Mode Découverte.
  ///
  /// Appelé quand l'utilisateur clique "Quitter" dans un coach mark.
  Future<void> quitAllTutorials() async {
    // Set immédiat du flag in-memory : court-circuite tout coach mark qui
    // pourrait s'afficher entre maintenant et la fin de l'écriture async ci-dessous.
    _userQuitInCurrentSession = true;
    await setStatus(OnboardingStatus.termine);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_forcePostVaultKey, false);
    await prefs.setBool(_pendingPremiumTutorialKey, false);
    await prefs.setBool(_pendingFirstEntryPhase2Key, false);
    for (final tutorial in DiscoveryTutorial.values) {
      final key = '$_discoveryPrefix${_discoveryTutorialToKey(tutorial)}';
      await prefs.setBool(key, true);
    }
  }

  Future<void> requestPostVaultReplay() async {
    resetQuitFlagForReplay();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_forcePostVaultKey, true);
    await setStatus(OnboardingStatus.partie1Terminee);
  }

  Future<void> requestPremiumTutorial() async {
    resetQuitFlagForReplay();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingPremiumTutorialKey, true);
  }

  Future<bool> consumeShouldShowPremiumTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_pendingPremiumTutorialKey) ?? false;
    if (pending) await prefs.setBool(_pendingPremiumTutorialKey, false);
    return pending;
  }

  Future<void> requestFirstEntryPhase2() async {
    resetQuitFlagForReplay();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pendingFirstEntryPhase2Key, true);
  }

  Future<bool> consumeShouldShowFirstEntryPhase2() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_pendingFirstEntryPhase2Key) ?? false;
    if (pending) await prefs.setBool(_pendingFirstEntryPhase2Key, false);
    return pending;
  }

  Future<bool> consumeShouldShowPostVaultTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final forceReplay = prefs.getBool(_forcePostVaultKey) ?? false;
    if (forceReplay) {
      await prefs.setBool(_forcePostVaultKey, false);
      return true;
    }
    return await getStatus() == OnboardingStatus.partie1Terminee;
  }

  OnboardingStatus _statusFromRaw(String raw) {
    switch (raw) {
      case 'skip':
        return OnboardingStatus.skip;
      case 'partie1_terminee':
        return OnboardingStatus.partie1Terminee;
      case 'termine':
        return OnboardingStatus.termine;
      case 'non_vu':
      default:
        return OnboardingStatus.nonVu;
    }
  }

  String _statusToRaw(OnboardingStatus status) {
    switch (status) {
      case OnboardingStatus.nonVu:
        return 'non_vu';
      case OnboardingStatus.skip:
        return 'skip';
      case OnboardingStatus.partie1Terminee:
        return 'partie1_terminee';
      case OnboardingStatus.termine:
        return 'termine';
    }
  }

  // ========== Mode Découverte ==========

  /// Vérifie si un tutoriel découverte a été complété
  Future<bool> isDiscoveryCompleted(DiscoveryTutorial tutorial) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_discoveryPrefix${_discoveryTutorialToKey(tutorial)}';
    return prefs.getBool(key) ?? false;
  }

  /// Marque un tutoriel découverte comme complété
  Future<void> markDiscoveryCompleted(DiscoveryTutorial tutorial) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_discoveryPrefix${_discoveryTutorialToKey(tutorial)}';
    await prefs.setBool(key, true);
  }

  /// Réinitialise un tutoriel découverte (pour rejouer)
  Future<void> resetDiscoveryTutorial(DiscoveryTutorial tutorial) async {
    resetQuitFlagForReplay();
    final prefs = await SharedPreferences.getInstance();
    final key = '$_discoveryPrefix${_discoveryTutorialToKey(tutorial)}';
    await prefs.setBool(key, false);
  }

  /// Obtient la liste des tutoriels découverte complétés
  Future<List<DiscoveryTutorial>> getCompletedDiscoveries() async {
    final completed = <DiscoveryTutorial>[];
    for (final tutorial in DiscoveryTutorial.values) {
      if (await isDiscoveryCompleted(tutorial)) {
        completed.add(tutorial);
      }
    }
    return completed;
  }

  String _discoveryTutorialToKey(DiscoveryTutorial tutorial) {
    switch (tutorial) {
      case DiscoveryTutorial.premium:
        return 'premium';
      case DiscoveryTutorial.firstEntry:
        return 'first_entry';
      case DiscoveryTutorial.firstCloudBackup:
        return 'first_cloud_backup';
      case DiscoveryTutorial.firstCloudBackupPhase1:
        return 'first_cloud_backup_phase1';
    }
  }

}
