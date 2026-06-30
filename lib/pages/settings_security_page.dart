import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/app.dart';
import '../l10n/app_localizations.dart';
import '../models/backup_payload.dart';
import '../platform/platform_capabilities.dart';
import '../services/ad_service.dart';
import '../services/auth_service.dart';
import '../services/auto_close_service.dart';
import '../services/backup_repository.dart';
import '../services/category_service.dart';
import '../services/crypto_service.dart';
import '../services/firebase/firebase_sync_service.dart';
import '../services/lock_service.dart';
import '../services/premium_service.dart';
import '../services/secure_storage_service.dart';
import '../services/security_analyzer_service.dart';
import '../services/sync_coordinator_service.dart';
import '../services/vault_repository.dart';
import '../widgets/coach_mark_system.dart';
import '../widgets/premium_badge.dart';
import 'import_export_page.dart';
import 'security_report_page.dart';

class SettingsSecurityPage extends StatefulWidget {
  const SettingsSecurityPage({
    super.key,
    required this.auth,
    this.startTutorial = false,
  });

  final AuthService auth;
  final bool startTutorial;

  @override
  State<SettingsSecurityPage> createState() => _SettingsSecurityPageState();
}

class _SettingsSecurityPageState extends State<SettingsSecurityPage>
    with SingleTickerProviderStateMixin {
  static const int _minMaxLoginAttempts = 5;
  static const int _maxMaxLoginAttempts = 10;
  static const int _defaultMaxLoginAttempts = 10;
  static const String _kMaxLoginAttempts = 'max_login_attempts';

  final _localAuth = LocalAuthentication();
  final _storage = SecureStorageService();
  final _lockService = LockService.instance;
  final _autoCloseService = AutoCloseService.instance;
  final _premiumService = PremiumService();
  final _analyzerService = SecurityAnalyzerService();

  bool _biometryEnabled = false;
  bool _biometryAvailable = false;
  String? _biometricMode;
  Duration _lockTimeout = const Duration(minutes: 2);
  Duration _autoCloseTimeout = const Duration(minutes: 1);
  bool _autoCloseEnabled = false;
  int _maxLoginAttempts = _defaultMaxLoginAttempts;
  bool _isPremium = false;
  int _securityScore = 0;
  bool _didInit = false;

  // GlobalKeys pour le didacticiel
  final _changeMasterPasswordKey = GlobalKey();
  final _biometryKey = GlobalKey();
  final _lockTimeoutKey = GlobalKey();
  final _autoCloseKey = GlobalKey();
  final _loginAttemptsKey = GlobalKey();
  final _securityReportKey = GlobalKey();

  // Animation pour les halos du tutoriel
  late final AnimationController _coachPulseController;
  bool _isTutorialRunning = false;
  String? _activeTargetKey;

  @override
  void initState() {
    super.initState();
    _coachPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _loadSettings().then((_) {
      if (widget.startTutorial && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _runSecurityTutorial();
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    final enabled = await _storage.isBiometryEnabled();
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    // FIX : lire depuis SecureStorage (même source que LoginPage._loadLoginGuardState).
    // SharedPreferences était l'ancien stockage avant la mitigation M2 et créait
    // une désynchronisation invisible (le user voyait 10 même après avoir choisi 5).
    final configuredMaxAttempts =
        await _storage.readInt(_kMaxLoginAttempts) ?? _defaultMaxLoginAttempts;
    final maxLoginAttempts = configuredMaxAttempts
        .clamp(_minMaxLoginAttempts, _maxMaxLoginAttempts)
        .toInt();
    if (maxLoginAttempts != configuredMaxAttempts) {
      await _storage.writeInt(_kMaxLoginAttempts, maxLoginAttempts);
    }

    int securityScore = 0;
    if (_premiumService.isPremium) {
      try {
        final repo = VaultRepository(widget.auth);
        final entries = await repo.readAll();
        final l10n = AppLocalizations.of(context)!;
        final result = _analyzerService.analyzeEntries(entries, l10n);
        securityScore = result.overallScore;
      } catch (_) {
        securityScore = 0;
      }
    }

    if (!mounted) return;
    final biometricMode = await _storage.readBiometricMode();

    setState(() {
      _biometryEnabled = enabled;
      _biometryAvailable = canCheck && isSupported;
      _biometricMode = biometricMode;
      _lockTimeout = _lockService.lockTimeout;
      _autoCloseTimeout = _autoCloseService.autoCloseTimeout;
      _autoCloseEnabled = _autoCloseService.isEnabled;
      _maxLoginAttempts = maxLoginAttempts;
      _isPremium = AdService.instance.isPremium;
      _securityScore = securityScore;
    });
  }

  Future<void> _toggleBiometry(bool value) async {
    if (value) {
      try {
        if (widget.auth.currentKey == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.mustReconnect),
              backgroundColor: PassKeyraColors.error,
            ),
          );
          return;
        }

        final l10n = AppLocalizations.of(context)!;
        final canStrong = await _storage.canUseStrongBiometric();

        if (canStrong) {
          // Class 3 : le BiometricPrompt est pilote par le plugin Kotlin
          // avec CryptoObject. Pas de local_auth.authenticate().
          await widget.auth.storeWrappedKeyForBiometrics(
            promptTitle: l10n.biometricAuth,
            promptSubtitle: l10n.biometricAuthSubtitle,
            promptCancel: l10n.cancel,
          );
          if (!mounted) return;
          setState(() {
            _biometryEnabled = true;
            _biometricMode = 'strong';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.biometryEnabled),
              backgroundColor: PassKeyraColors.success,
            ),
          );
        } else {
          // Class 1/2 : consentement eclaire puis local_auth.
          final warningAccepted = await _storage.isBiometricWeakWarningAccepted();
          if (!warningAccepted) {
            final accepted = await _showWeakBiometricConsentDialog();
            if (accepted != true) return;
            await _storage.setBiometricWeakWarningAccepted(true);
          }

          final authenticated = await _localAuth.authenticate(
            localizedReason: l10n.biometricAuth,
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
              sensitiveTransaction: true,
            ),
            authMessages: const [
              AndroidAuthMessages(
                signInTitle: 'Authentification requise',
                biometricHint: 'Vérifiez votre identité',
                cancelButton: 'Annuler',
                biometricNotRecognized: 'Non reconnu. Réessayez.',
                goToSettingsButton: 'Paramètres',
                goToSettingsDescription: 'La biométrie n\'est pas configurée sur cet appareil.',
                biometricRequiredTitle: 'Biométrie requise',
              ),
            ],
          );

          if (!authenticated) return;

          await widget.auth.storeWrappedKeyForBiometrics();
          if (!mounted) return;
          setState(() {
            _biometryEnabled = true;
            _biometricMode = 'weak';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.biometryEnabled),
              backgroundColor: PassKeyraColors.success,
            ),
          );
        }
      } on PlatformException catch (e) {
        if (!mounted) return;
        if (e.code == 'NotEnrolled') {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(
                Icons.fingerprint,
                size: 48,
                color: PassKeyraColors.primary,
              ),
              title: const Text('Biométrie non configurée'),
              content: const Text(
                'Aucune biométrie n\'est enregistrée sur cet appareil. '
                'Configurez une empreinte digitale ou la reconnaissance faciale '
                'dans les Paramètres Android puis réessayez.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Compris'),
                ),
              ],
            ),
          );
        } else if (e.code != 'UserCanceled' && e.code != 'BIOMETRIC_ERROR') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : ${e.message ?? e.code}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await _storage.setBiometryEnabled(false);
    await _storage.deleteWrappedKey();
    if (!mounted) return;
    setState(() {
      _biometryEnabled = false;
      _biometricMode = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.biometryDisabled)),
    );
  }

  Future<bool?> _showWeakBiometricConsentDialog() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.info_outline, size: 48, color: Colors.orange),
        title: Text(l10n.weakBiometricWarningTitle),
        content: Text(l10n.weakBiometricWarningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.weakBiometricWarningKeepPassword),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.weakBiometricWarningActivateAnyway),
          ),
        ],
      ),
    );
  }

  Future<void> _changeMasterPassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var obscureCurrentPassword = true;
    var obscureNewPassword = true;
    var obscureConfirmPassword = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.changeMasterPassword),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrentPassword,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.masterPassword,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrentPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              obscureCurrentPassword = !obscureCurrentPassword;
                            });
                          },
                        ),
                      ),
                      validator: (v) =>
                          (v ?? '').isEmpty ? AppLocalizations.of(context)!.required : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.newMasterPassword,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      validator: (v) {
                        final value = v ?? '';
                        if (value.isEmpty || value.length < 8) {
                          return AppLocalizations.of(context)!.required;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.confirmPassword,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setStateDialog(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return AppLocalizations.of(context)!.required;
                        if (v != newPasswordController.text) {
                          return AppLocalizations.of(context)!.passwordsDontMatch;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, true);
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          );
        },
      ),
    );

    if (result != true) return;

    // Inhibe le verrouillage automatique pendant tout le wizard : les 2
    // dérivations PBKDF2 (oldKey + newKey) prennent ~10s sur Windows pure-Dart
    // et un alt-tab transitoire suffirait sinon à lock l'utilisateur au milieu.
    _lockService.setInhibitAutoLock(true);

    // Loader bloquant pendant la validation initiale (lecture vault avec
    // l'ancien pwd ~5s) — sinon l'écran semble figé.
    final loaderDismiss = _showBlockingLoader();
    try {
      final oldPassword = currentPasswordController.text;
      final newPassword = newPasswordController.text;

      // Validation de l'ancien mot de passe via un AuthService temporaire
      // (évite de toucher la session active si l'ancien pwd est mauvais).
      final testAuth = AuthService(SecureStorageService());
      final unlocked = await testAuth.unlockWithMasterPassword(oldPassword);
      if (!unlocked) throw Exception(AppLocalizations.of(context)!.incorrectMasterPassword);
      final testRepo = VaultRepository(testAuth);
      await testRepo.readAll();

      // Ferme le loader avant d'afficher le dialog d'introduction.
      loaderDismiss();

      if (!mounted) return;

      // Étape 1 : dialog d'introduction au wizard.
      final continueWizard = await _showChangeMasterPasswordIntroDialog();
      if (continueWizard != true || !mounted) return;

      // Loader bloquant pendant les opérations longues (snapshot + PBKDF2
      // dérivation new key + re-chiffrement vault + nouveau backup) — empêche
      // l'utilisateur de croire que l'app est figée.
      final loaderDismiss2 = _showBlockingLoader();
      try {
        // Étape 2 : créer la sauvegarde de sécurité avec la CLÉ COURANTE
        // (= ancienne, avant changement). Le snapshot sera donc déchiffrable
        // avec l'ancien mot de passe maître — base du rollback 30 jours.
        final snapshotPayload = await _buildEncryptedPayloadWithCurrentKey();
        await BackupRepository().saveSnapshotBackup(snapshotPayload);

        // Étape 3 : changement effectif + re-chiffrement vault local.
        final oldKey = await widget.auth.changeMasterPassword(oldPassword, newPassword);
        final repo = VaultRepository(widget.auth);
        await repo.reEncryptVault(oldKey);

        // Étape 3 bis : créer automatiquement une nouvelle sauvegarde locale
        // chiffrée avec le NOUVEAU mot de passe. Garantit que l'utilisateur a
        // toujours un backup à jour, même s'il oublie d'en créer un manuellement.
        // Transparent freemium ET premium. Vient remplacer l'ancien backup
        // normal via la rotation `maxLocalBackups = 1` (le snapshot pré-changement
        // est dans une famille de fichiers séparée et n'est pas écrasé).
        final newPayload = await _buildEncryptedPayloadWithCurrentKey();
        await BackupRepository().saveLocalBackup(newPayload);
      } finally {
        loaderDismiss2();
      }

      // Étape 4 : si Firestore sync est actif, re-uploader toutes les entrées
      // avec la nouvelle clé (sinon les données cloud restent illisibles).
      final shouldReuploadCloud = await _shouldReuploadFirestore();
      if (shouldReuploadCloud && mounted) {
        await _runFirestoreReuploadWithProgress();
        // Étape 4 bis : pousser le nouveau fingerprint de clé pour que les
        // autres appareils détectent le changement (Option C re-keying).
        try {
          final coord = _buildSyncCoordinator();
          await coord?.firebaseSyncService.uploadKeyFingerprint();
        } catch (_) {
          // Best effort : l'upload du fingerprint ne doit pas bloquer
          // le succès du wizard si Firestore est down ponctuellement.
        }
      }

      if (!mounted) return;

      // Dialog de succès final (remplace l'ancien SnackBar).
      await _showChangeMasterPasswordSuccessDialog();
    } catch (e) {
      loaderDismiss();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _lockService.setInhibitAutoLock(false);
    }
  }

  /// Affiche un dialog modal indismissible avec un CircularProgressIndicator.
  /// Retourne une fonction qui dismissera le loader quand appelée.
  VoidCallback _showBlockingLoader() {
    bool dismissed = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      ),
    );
    return () {
      if (dismissed) return;
      dismissed = true;
      if (mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      }
    };
  }

  /// Construit un BackupPayload chiffré avec la clé de session **courante**.
  /// Utilisé pour la sauvegarde de sécurité créée juste avant un changement
  /// de mot de passe maître (snapshot pré-changement).
  ///
  /// Duplique délibérément la logique de
  /// `ImportExportPage._buildEncryptedPayload` pour éviter d'introduire une
  /// dépendance entre les deux pages.
  Future<BackupPayload> _buildEncryptedPayloadWithCurrentKey() async {
    final repo = VaultRepository(widget.auth);
    final entries = await repo.readAll();
    final key = widget.auth.currentKey;
    if (key == null) throw Exception('Coffre verrouillé');

    final salt = await widget.auth.secureStorage.readSalt();
    if (salt == null) {
      throw Exception('Sel introuvable - impossible de créer la sauvegarde de sécurité');
    }

    final categoryService = CategoryService();
    final categories = categoryService.getAllCategories();

    final exportData = {
      'entries': entries.map((e) => e.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    final crypto = CryptoService();
    final encryptedJson = crypto.encryptJson(exportData, key);
    final encryptedMap = jsonDecode(encryptedJson) as Map<String, dynamic>;

    return BackupPayload(
      salt: salt,
      iv: encryptedMap['iv'] as String,
      ciphertext: encryptedMap['ciphertext'] as String,
      tag: encryptedMap['tag'] as String,
      exportedAt: DateTime.now(),
      entryCount: entries.length,
      iterations: widget.auth.currentKeyIterations ?? CryptoService.defaultIterations,
    );
  }

  /// True si Firestore sync est activée ET que l'utilisateur est connecté
  /// (donc des entrées cloud doivent être re-uploadées avec la nouvelle clé).
  Future<bool> _shouldReuploadFirestore() async {
    // Sur desktop V1, Firebase n'est pas configuré → pas de cloud à mettre à jour.
    if (!supportsCloudSync) return false;
    try {
      final coord = _buildSyncCoordinator();
      if (coord == null) return false;
      if (!coord.firebaseAuthService.isSignedIn) return false;
      return await coord.firebaseSyncService.isSyncEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Tente d'instancier SyncCoordinatorService. Retourne null si Firebase n'est
  /// pas initialisé (cas Windows V1) ou si l'instanciation échoue.
  SyncCoordinatorService? _buildSyncCoordinator() {
    try {
      return SyncCoordinatorService(
        authService: widget.auth,
        vaultRepository: VaultRepository(widget.auth),
      );
    } catch (_) {
      return null;
    }
  }

  /// Affiche un dialog modal avec barre de progression pendant le re-upload
  /// des entrées Firestore avec la nouvelle clé.
  Future<void> _runFirestoreReuploadWithProgress() async {
    final l10n = AppLocalizations.of(context)!;
    final coord = _buildSyncCoordinator();
    if (coord == null) return;
    final syncService = coord.firebaseSyncService;
    final repo = VaultRepository(widget.auth);
    final entries = await repo.readAll();
    final progress = ValueNotifier<(int, int)>((0, entries.length));

    // ignore: unused_local_variable
    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.masterPasswordChangeCloudUpdateTitle),
        content: ValueListenableBuilder<(int, int)>(
          valueListenable: progress,
          builder: (context, value, _) {
            final (done, total) = value;
            final ratio = total == 0 ? 1.0 : done / total;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.masterPasswordChangeCloudUpdateBody),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: ratio),
                const SizedBox(height: 8),
                Text(
                  l10n.masterPasswordChangeCloudProgress(done, total),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
    );

    try {
      await syncService.forceReuploadAll(
        entries,
        onProgress: (done, total) {
          progress.value = (done, total);
        },
      );
    } finally {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  /// Dialog d'introduction au workflow de changement de mot de passe maître.
  /// Retourne true si l'utilisateur confirme.
  Future<bool?> _showChangeMasterPasswordIntroDialog() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_outline, size: 40, color: PassKeyraColors.info),
        title: Text(l10n.masterPasswordChangeIntroTitle),
        content: Text(l10n.masterPasswordChangeIntroBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.onboardingContinue),
          ),
        ],
      ),
    );
  }

  /// Dialog de succès final avec lien vers la page des sauvegardes.
  Future<void> _showChangeMasterPasswordSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, size: 48, color: Colors.green),
        title: Text(l10n.masterPasswordChangeSuccessTitle),
        content: Text(l10n.masterPasswordChangeSuccessBody),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ImportExportPage.route,
                  arguments: widget.auth);
            },
            child: Text(l10n.masterPasswordChangeSeeBackups),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.masterPasswordChangeFinish),
          ),
        ],
      ),
    );
  }

  String _getLockTimeoutLabel(Duration timeout) {
    final l10n = AppLocalizations.of(context)!;
    // Convention partagée avec LockService : >= 86400s (24h) = "jamais verrouiller".
    if (timeout.inSeconds >= 86400) return l10n.lockTimeoutDisabled;
    if (timeout == Duration.zero) return l10n.lockTimeoutImmediate;
    if (timeout.inSeconds == 30) return l10n.lockTimeout30s;
    if (timeout.inSeconds == 45) return l10n.autoClose45s;
    if (timeout.inMinutes == 1) return l10n.lockTimeout1m;
    if (timeout.inMinutes == 2) return l10n.lockTimeout2m;
    if (timeout.inMinutes == 5) return l10n.lockTimeout5m;
    if (timeout.inMinutes == 10) return l10n.lockTimeout10m;
    if (timeout.inMinutes == 30) return l10n.lockTimeout30m;
    return '${timeout.inMinutes} min';
  }

  String _getAutoCloseLabel() {
    final l10n = AppLocalizations.of(context)!;
    if (!_autoCloseEnabled) return l10n.autoCloseDisabled;
    if (_autoCloseTimeout.inSeconds == 30) return l10n.autoClose30s;
    if (_autoCloseTimeout.inSeconds == 45) return l10n.autoClose45s;
    if (_autoCloseTimeout.inMinutes == 1) return l10n.autoClose1m;
    if (_autoCloseTimeout.inMinutes == 2) return l10n.autoClose2m;
    if (_autoCloseTimeout.inMinutes == 5) return l10n.autoClose5m;
    return '${_autoCloseTimeout.inMinutes} min';
  }

  String _getMaxLoginAttemptsLabel() => '$_maxLoginAttempts tentatives';

  void _showLockTimeoutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.lockTimeout),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _durationOption(l10n.lockTimeoutImmediate, Duration.zero),
            _durationOption(l10n.lockTimeout30s, const Duration(seconds: 30)),
            _durationOption(l10n.autoClose45s, const Duration(seconds: 45)),
            _durationOption(l10n.lockTimeout1m, const Duration(minutes: 1)),
            _durationOption(l10n.lockTimeout2m, const Duration(minutes: 2)),
            // Desktop : option "Désactivé" supplémentaire (mobile la garde
            // toujours active pour rester sécurisé en sortie de poche).
            if (isDesktop)
              _durationOption(l10n.lockTimeoutDisabled, const Duration(days: 1)),
          ],
        ),
      ),
    );
  }

  Widget _durationOption(String title, Duration value) {
    return RadioListTile<Duration>(
      title: Text(title),
      value: value,
      groupValue: _lockTimeout,
      onChanged: (v) async {
        if (v == null) return;
        await _lockService.setLockTimeout(v);
        if (!mounted) return;
        setState(() => _lockTimeout = v);
        Navigator.pop(context);
      },
    );
  }

  void _showAutoCloseDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.autoClose),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Groupe radio unique : null = "Désactivé", sinon la durée.
            // Évite que la pastille "Désactivé" et une durée restent cochées
            // simultanément.
            _autoCloseOption(l10n.autoCloseDisabled, null),
            _autoCloseOption(l10n.autoClose30s, const Duration(seconds: 30)),
            _autoCloseOption(l10n.autoClose45s, const Duration(seconds: 45)),
            _autoCloseOption(l10n.autoClose1m, const Duration(minutes: 1)),
          ],
        ),
      ),
    );
  }

  Widget _autoCloseOption(String title, Duration? value) {
    // Valeur du groupe : null quand la fermeture auto est désactivée.
    final selected = _autoCloseEnabled ? _autoCloseTimeout : null;
    return RadioListTile<Duration?>(
      title: Text(title),
      value: value,
      groupValue: selected,
      onChanged: (v) async {
        if (v == null) {
          await _autoCloseService.setEnabled(false);
          if (!mounted) return;
          setState(() => _autoCloseEnabled = false);
        } else {
          await _autoCloseService.setAutoCloseTimeout(v);
          await _autoCloseService.setEnabled(true);
          if (!mounted) return;
          setState(() {
            _autoCloseTimeout = v;
            _autoCloseEnabled = true;
          });
        }
        Navigator.pop(context);
      },
    );
  }

  void _showMaxLoginAttemptsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentatives de connexion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _maxMaxLoginAttempts - _minMaxLoginAttempts + 1,
            (index) {
              final value = _minMaxLoginAttempts + index;
              return RadioListTile<int>(
                activeColor: PassKeyraColors.primary,
                title: Text('$value tentatives'),
                subtitle: value == _defaultMaxLoginAttempts
                    ? const Text('Valeur recommandée')
                    : null,
                value: value,
                groupValue: _maxLoginAttempts,
                onChanged: (selected) async {
                  if (selected == null) return;
                  // FIX : écrire dans SecureStorage (clé chiffrée AES-GCM),
                  // pas SharedPreferences. LoginPage lit depuis SecureStorage
                  // pour le rate-limit (mitigation M2). Si on écrit ailleurs
                  // les 2 valeurs divergent et le compteur reste à 10.
                  await _storage.writeInt(_kMaxLoginAttempts, selected);
                  if (!mounted) return;
                  setState(() => _maxLoginAttempts = selected);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getSecurityScoreColor(int score) {
    if (score >= 80) return PassKeyraColors.success;
    if (score >= 60) return PassKeyraColors.warning;
    return PassKeyraColors.error;
  }

  String _getScoreLabel(int score) {
    final l10n = AppLocalizations.of(context)!;
    if (score >= 95) return l10n.veryStrong;
    if (score >= 80) return l10n.strong;
    if (score >= 60) return l10n.medium;
    if (score >= 40) return l10n.weak;
    return l10n.veryWeak;
  }

  @override
  void dispose() {
    _coachPulseController.dispose();
    super.dispose();
  }

  Future<void> _runSecurityTutorial() async {
    setState(() => _isTutorialRunning = true);
    final l10n = AppLocalizations.of(context)!;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    void _endTutorial() {
      setState(() {
        _isTutorialRunning = false;
        _activeTargetKey = null;
      });
    }

    // Sur desktop, l'étape "Fermeture automatique" est retirée → 4 étapes
    // au lieu de 5. La numérotation s'adapte automatiquement.
    final totalSteps = isDesktop ? 4 : 5;

    // Étape 1 : Mot de passe maître
    setState(() => _activeTargetKey = 'change_master_password');
    final step1 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _changeMasterPasswordKey,
      pulseController: _coachPulseController,
      title: l10n.onboardingChangeMasterPasswordTitle,
      message: l10n.onboardingChangeMasterPasswordMessage,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      clearFocusInset: 20.0,
      stepIndicator: '1 / $totalSteps',
    );
    if (step1 != CoachStepResult.primary || !mounted) {
      _endTutorial();
      Navigator.pop(context, true);
      return;
    }

    // Étape 2 : Biométrie (sur desktop, message adapté "bientôt disponible")
    setState(() => _activeTargetKey = 'biometry');
    final step2 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _biometryKey,
      pulseController: _coachPulseController,
      title: l10n.onboardingBiometryTitle,
      message: isDesktop
          ? l10n.onboardingBiometryDesktopMessage
          : l10n.onboardingBiometryMessage,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '2 / $totalSteps',
    );
    if (step2 != CoachStepResult.primary || !mounted) {
      _endTutorial();
      Navigator.pop(context, true);
      return;
    }

    // Étape 3 : Verrouillage automatique
    setState(() => _activeTargetKey = 'lock_timeout');
    final step3 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _lockTimeoutKey,
      pulseController: _coachPulseController,
      title: l10n.onboardingLockTimeoutTitle,
      message: l10n.onboardingLockTimeoutMessage,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '3 / $totalSteps',
    );
    if (step3 != CoachStepResult.primary || !mounted) {
      _endTutorial();
      Navigator.pop(context, true);
      return;
    }

    // Étape 4 : Fermeture automatique (mobile uniquement)
    if (!isDesktop) {
      setState(() => _activeTargetKey = 'auto_close');
      final step4 = await CoachMarkSystem.showCoachStep(
        context: context,
        targetKey: _autoCloseKey,
        pulseController: _coachPulseController,
        title: l10n.onboardingAutoCloseTitle,
        message: l10n.onboardingAutoCloseMessage,
        primaryLabel: l10n.onboardingNext,
        secondaryLabel: l10n.onboardingSkipTutorial,
        stepIndicator: '4 / $totalSteps',
      );
      if (step4 != CoachStepResult.primary || !mounted) {
        _endTutorial();
        Navigator.pop(context, true);
        return;
      }
    }

    // Étape finale : Tentatives de connexion (4/4 desktop, 5/5 mobile)
    setState(() => _activeTargetKey = 'login_attempts');
    await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _loginAttemptsKey,
      pulseController: _coachPulseController,
      title: l10n.onboardingLoginAttemptsTitle,
      message: l10n.onboardingLoginAttemptsMessage,
      primaryLabel: l10n.onboardingFinish,
      stepIndicator: '$totalSteps / $totalSteps',
    );

    _endTutorial();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Sécurité')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Protection du compte',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          CoachMarkSystem.buildHalo(
            key: _changeMasterPasswordKey,
            pulseController: _coachPulseController,
            isActive: _isTutorialRunning && _activeTargetKey == 'change_master_password',
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: const Icon(Icons.vpn_key),
              title: Text(l10n.changeMasterPassword),
              subtitle: const Text('Modifier votre mot de passe principal'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _changeMasterPassword,
            ),
          ),
          CoachMarkSystem.buildHalo(
            key: _biometryKey,
            pulseController: _coachPulseController,
            isActive: _isTutorialRunning && _activeTargetKey == 'biometry',
            borderRadius: BorderRadius.circular(12),
            child: SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text(l10n.biometricAuth),
              subtitle: Text(
                isDesktop
                    ? l10n.biometryDesktopComingSoon
                    : (_biometryAvailable
                        ? (_biometryEnabled && _biometricMode == 'strong'
                            ? l10n.biometricAuthSubtitleStrong
                            : (_biometryEnabled && _biometricMode == 'weak'
                                ? l10n.biometricAuthSubtitleWeak
                                : l10n.biometricAuthSubtitle))
                        : l10n.biometricAuthNotAvailable),
              ),
              value: _biometryEnabled,
              onChanged: _biometryAvailable ? _toggleBiometry : null,
            ),
          ),
          CoachMarkSystem.buildHalo(
            key: _lockTimeoutKey,
            pulseController: _coachPulseController,
            isActive: _isTutorialRunning && _activeTargetKey == 'lock_timeout',
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: const Icon(Icons.timer),
              title: Text(l10n.lockTimeout),
              subtitle: Text(_getLockTimeoutLabel(_lockTimeout)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showLockTimeoutDialog,
            ),
          ),
          // Fermeture automatique : non pertinente sur desktop
          // (la fermeture surprise de fenêtre PC sans avertissement perturberait
          // l'utilisateur). Reste disponible sur mobile.
          if (!isDesktop)
            CoachMarkSystem.buildHalo(
              key: _autoCloseKey,
              pulseController: _coachPulseController,
              isActive: _isTutorialRunning && _activeTargetKey == 'auto_close',
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: const Icon(Icons.close),
                title: Text(l10n.autoClose),
                subtitle: Text(_getAutoCloseLabel()),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showAutoCloseDialog,
              ),
            ),
          CoachMarkSystem.buildHalo(
            key: _loginAttemptsKey,
            pulseController: _coachPulseController,
            isActive: _isTutorialRunning && _activeTargetKey == 'login_attempts',
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Tentatives de connexion'),
              subtitle: Text(_getMaxLoginAttemptsLabel()),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showMaxLoginAttemptsDialog,
            ),
          ),
          // Analyse de sécurité avancée — toujours visible avec badge Premium
          // si non-Premium, pour maximiser la découvrabilité de la feature.
          const SizedBox(height: 8),
          CoachMarkSystem.buildHalo(
            key: _securityReportKey,
            pulseController: _coachPulseController,
            isActive: _isTutorialRunning && _activeTargetKey == 'security_report',
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isPremium
                      ? _getSecurityScoreColor(_securityScore).withOpacity(0.1)
                      : PassKeyraColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.security,
                  color: _isPremium
                      ? _getSecurityScoreColor(_securityScore)
                      : PassKeyraColors.primary,
                ),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(l10n.securityAnalysis)),
                  if (!_isPremium) const PremiumBadge(),
                ],
              ),
              subtitle: Text(
                _isPremium
                    ? '${l10n.score}: $_securityScore/100 - ${_getScoreLabel(_securityScore)}'
                    : 'Score de sécurité, mots de passe faibles, doublons',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                if (!_isPremium) {
                  await showPremiumLockedDialog(
                    context,
                    featureName: l10n.securityAnalysis,
                    customMessage:
                        'L\'analyse de sécurité avancée détecte les mots de passe faibles, '
                        'les doublons et fournit un score global de sécurité. '
                        'Réservée aux utilisateurs Premium.',
                  );
                  return;
                }
                await Navigator.pushNamed(
                  context,
                  SecurityReportPage.route,
                  arguments: widget.auth,
                );
                _loadSettings();
              },
            ),
          ),
        ],
      ),
    );
  }
}
