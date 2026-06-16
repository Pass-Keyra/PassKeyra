import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import '../platform/platform_capabilities.dart';

import '../services/secure_storage_service.dart';
import '../services/auth_service.dart';
import '../services/lock_service.dart';
import '../services/vault_repository.dart';
import '../services/crypto_service.dart';
import '../services/crypto_isolate.dart';
import '../models/password_entry.dart';
import '../models/backup_payload.dart';
import '../models/custom_category.dart';
import 'home_page.dart';
import '../services/backup_repository.dart';
import '../app/app.dart';
import '../services/review_service.dart';
import '../services/language_service.dart';
import '../services/ad_service.dart';
import '../services/onboarding_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/password_strength_indicator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static const String route = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = AuthService(SecureStorageService());
  final _localAuth = LocalAuthentication();
  late final BackupRepository _backupRepo;
  late final AnimationController _glowAnimationController;
  late final Animation<double> _glowAnimation;
  late final AnimationController _zoomAnimationController;
  late final Animation<double> _zoomAnimation;
  // Desktop : oscillation horizontale légère du logo au déverrouillage,
  // remplace le glow pulsant + zoom (trop coûteux en GPU sur Windows).
  late final AnimationController _shakeAnimationController;
  late final Animation<double> _shakeAnimation;
  late final ScrollController _scrollController;

  bool _isLoading = false;
  bool _biometryAvailable = false;
  bool _isFirstTime = false;
  bool _isBiometryInProgress = false;
  bool _hasAttemptedAutoBiometry = false;
  bool _isUnlocking = false;
  bool _userInteractedWithField = false;
  bool _showMasterPasswordWarning = false;
  bool _hasHandledOnboardingChoice = false;
  bool _obscurePassword = true; // Visibilité champ mot de passe principal
  bool _obscureConfirmPassword = true; // Visibilité champ confirmation mot de passe
  String _currentPassword = '';

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  int _failedLoginAttempts = 0;
  int _maxLoginAttempts = _defaultMaxLoginAttempts;
  DateTime? _loginLockedUntil;

  static const int _defaultMaxLoginAttempts = 10;
  static const int _minMaxLoginAttempts = 5;
  static const int _maxMaxLoginAttempts = 10;
  static const int _cooldownStartAttempt = 5;
  static const int _biometryDisableThreshold = 3;
  static const Duration _loginLockDuration = Duration(minutes: 1);
  static const Duration _vaultBlockDurationLevel1 = Duration(hours: 24);
  static const Duration _vaultBlockDurationLevel2 = Duration(hours: 48);
  static const Duration _vaultBlockDurationLevel3 = Duration(hours: 72);
  static const Duration _vaultBlockEscalationWindow = Duration(days: 7);
  static const Duration _failedAttemptResetWindow = Duration(days: 28);
  static const String _kFailedLoginAttempts = 'failed_login_attempts';
  static const String _kLoginLockUntilMs = 'login_lock_until_ms';
  static const String _kMaxLoginAttempts = 'max_login_attempts';
  static const String _kVaultBlockCount = 'vault_block_count';
  static const String _kLastVaultBlockAtMs = 'last_vault_block_at_ms';
  static const String _kLastFailedLoginAtMs = 'last_failed_login_at_ms';

  @override
  void initState() {
    super.initState();
    debugPrint('LoginPage - initState()');
    _backupRepo = BackupRepository();
    _scrollController = ScrollController();

    // Configurer la barre d'état avec des icônes sombres (pour fond clair)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Icônes sombres pour fond clair
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    // Animation de pulsation du glow (expansion depuis le bord de l'aura)
    _glowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Animation de zoom caméra
    _zoomAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _zoomAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Shake desktop : 6 oscillations rapides puis retour à 0, amplitude
    // décroissante. Très léger pour le GPU (simple Matrix4 translate).
    _shakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -3.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 0.0), weight: 1),
    ]).animate(_shakeAnimationController);

    _checkFirstTime();
    _checkBiometry();
    _loadLoginGuardState();

    // Load banner with a small delay to ensure AdMob is initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _loadBannerAd();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _glowAnimationController.dispose();
    _zoomAnimationController.dispose();
    _shakeAnimationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() async {
    debugPrint('Tentative de chargement bannière pub...');
    debugPrint('isPremium: ${AdService.instance.isPremium}');

    _bannerAd = await AdService.instance.createBannerAd();
    if (_bannerAd != null) {
      debugPrint('Bannière créée, chargement en cours...');
      _bannerAd!.load().then((_) {
        debugPrint('Bannière publicitaire chargée avec succès!');
        // CORRECTION: Attendre le prochain frame pour éviter les rebuilds pendant la saisie
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _isBannerAdLoaded = true);
              debugPrint('État mis à jour: _isBannerAdLoaded = true');
            }
          });
        }
      }).catchError((error) {
        debugPrint('Erreur chargement pub: $error');
        debugPrint('Type d\'erreur: ${error.runtimeType}');
      });
    } else {
      debugPrint('Mode Premium ou Consentement refusé - Pas de pub');
    }
  }

  /// Lance l'animation de déverrouillage : pulsation du glow + zoom caméra
  Future<void> _playUnlockAnimation() async {
    setState(() => _isUnlocking = true);

    // Sur desktop : oscillation horizontale légère du logo (pas de
    // RadialGradient + BoxShadow animés, trop coûteux GPU).
    if (isDesktop) {
      await _shakeAnimationController.forward(from: 0);
      return;
    }

    // Scroll automatique hybride : seulement si la page est scrollée > 100px
    if (_scrollController.hasClients && _scrollController.offset > 100) {
      // Scroll fluide vers le haut pour rendre l'animation visible
      await _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // Lancer la pulsation du glow en boucle (clignotement répété)
    _glowAnimationController.repeat(reverse: true);

    // Lancer le zoom caméra et attendre qu'il se termine
    await _zoomAnimationController.forward();
  }

  Future<void> _checkFirstTime() async {
    // Utiliser la même logique que LockService pour détecter la première installation
    debugPrint('LoginPage - Vérification première installation...');
    
    final salt = await _auth.secureStorage.readSalt();
    bool vaultHasData = false;
    try {
      final box = Hive.isBoxOpen('vault_blob')
          ? Hive.box<String>('vault_blob')
          : await Hive.openBox<String>('vault_blob');
      vaultHasData = box.isNotEmpty;
    } catch (e) {
      debugPrint('LoginPage - Impossible de lire vault_blob pour détection first-install: $e');
    }
    debugPrint('LoginPage - Salt existe : ${salt != null}');
    debugPrint('LoginPage - Coffre contient des données : $vaultHasData');
    
    // Si le salt existe, le compte existe (même si le coffre est vide)
    // Un coffre vide est un coffre valide
    final isFirstTime = salt == null && !vaultHasData;
    debugPrint('LoginPage - Première installation : $isFirstTime');
    
    setState(() => _isFirstTime = isFirstTime);

    if (_isFirstTime) {
      await _hydrateOnboardingState();
      await _maybeShowOnboardingChoice();
    }
    
    // Recharger la disponibilité biométrique après vérification du premier lancement
    if (!_isFirstTime) {
      await _checkBiometry();
    }
  }

  Future<void> _hydrateOnboardingState() async {
    final status = await OnboardingService.instance.getStatus();
    if (!mounted) return;
    setState(() {
      _showMasterPasswordWarning = status == OnboardingStatus.partie1Terminee;
    });
  }

  Future<void> _maybeShowOnboardingChoice() async {
    if (!mounted || !_isFirstTime || _hasHandledOnboardingChoice) return;
    _hasHandledOnboardingChoice = true;

    final status = await OnboardingService.instance.getStatus();
    if (status != OnboardingStatus.nonVu) {
      if (!mounted) return;
      setState(() {
        _showMasterPasswordWarning = status == OnboardingStatus.partie1Terminee;
      });
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final startTutorial = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.onboardingFirstChoiceTitle),
        content: Text(l10n.onboardingFirstChoiceMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.onboardingSkipTutorial),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.onboardingStartTutorial),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (startTutorial != true) {
      await OnboardingService.instance.skipTutorial();
      if (!mounted) return;
      setState(() => _showMasterPasswordWarning = false);
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.onboardingMasterPasswordTitle),
        content: Text(l10n.onboardingMasterPasswordMessage),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.onboardingNext),
          ),
        ],
      ),
    );

    await OnboardingService.instance.markPreVaultCompleted();
    if (!mounted) return;
    setState(() => _showMasterPasswordWarning = true);
  }

  Future<void> _checkBiometry() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();
      final hasBiometry = available.isNotEmpty;
      final biometryEnabled = await _auth.secureStorage.isBiometryEnabled();
      final isAvailable = canCheck && isSupported && hasBiometry && biometryEnabled;
      
      debugPrint('LoginPage - Biométrie disponible: $isAvailable');
      debugPrint('LoginPage - canCheck: $canCheck, isSupported: $isSupported, hasBiometry: $hasBiometry, enabled: $biometryEnabled');
      
      setState(() => _biometryAvailable = isAvailable);
      
      // Déclencher la biométrie automatiquement si elle est disponible ET qu'on n'est pas en première installation
      // Mais PAS si l'utilisateur a déjà commencé à interagir avec le champ de mot de passe
      if (!_hasAttemptedAutoBiometry && isAvailable && !_isFirstTime && !_userInteractedWithField) {
        debugPrint('LoginPage - Conditions remplies pour biométrie automatique');
        debugPrint('LoginPage - _isFirstTime: $_isFirstTime');
        debugPrint('LoginPage - isAvailable: $isAvailable');
        _hasAttemptedAutoBiometry = true;

        // Lancer la biométrie après le prochain frame pour que l'UI soit stable
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isBiometryInProgress && !_userInteractedWithField) {
            debugPrint('LoginPage - Lancement de la biométrie automatique...');
            _loginWithBiometry();
          }
        });
      } else {
        debugPrint('LoginPage - âŒ Biométrie automatique NON déclenchée:');
        debugPrint('  - _hasAttemptedAutoBiometry: $_hasAttemptedAutoBiometry');
        debugPrint('  - isAvailable: $isAvailable');
        debugPrint('  - _isFirstTime: $_isFirstTime');
        debugPrint('  - _userInteractedWithField: $_userInteractedWithField');
      }
    } catch (e) {
      debugPrint('LoginPage - Biométrie indisponible : $e');
      setState(() => _biometryAvailable = false);
    }
  }

  Future<void> _createMasterPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.passwordsDontMatch)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // CORRECTION ANR: L'appel à unlockWithMasterPassword utilise maintenant deriveKeyInIsolate
      // qui s'exécute dans un isolate séparé, évitant de bloquer l'UI
      final ok = await _auth.unlockWithMasterPassword(_passwordController.text);

      if (ok && _biometryAvailable) {
        try {
          await _auth.storeWrappedKeyForBiometrics();
        } catch (e) {
          debugPrint('LoginPage - Échec stockage clé biométrique : $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.biometryNotActivated)),
            );
          }
        }
      }

      setState(() => _isLoading = false);

      if (!mounted) return;
      if (ok) {
        LockService.instance.unlock();
        LockService.instance.clearAutoLockFlag();
        // Incrémenter le compteur de déverrouillages pour la demande d'avis
        ReviewService().incrementUnlockCount();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.masterPasswordCreatedSuccess)),
        );
        // Fermer le clavier puis jouer l'animation de déverrouillage.
        FocusScope.of(context).unfocus();
        await _playUnlockAnimation();
        if (!mounted) return;
        if (_showMasterPasswordWarning) {
          await OnboardingService.instance.markPreVaultCompleted();
        }
        Navigator.of(context).pushReplacementNamed(HomePage.route, arguments: _auth);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorCreatingMasterPassword)),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final canAttempt = await _canAttemptLogin();
    if (!canAttempt) return;
    setState(() => _isLoading = true);

    try {
      // CORRECTION ANR: L'appel à unlockWithMasterPassword utilise maintenant deriveKeyInIsolate
      // qui s'exécute dans un isolate séparé, évitant de bloquer l'UI
      final ok = await _auth.unlockWithMasterPassword(_passwordController.text);

      setState(() => _isLoading = false);
      if (!mounted) return;

      if (ok) {
        await _registerLoginSuccess();

        // Si biométrie activée, régénérer le wrap matériel pour qu'une éventuelle
        // migration de clé Keystore (hw1: invalidée) ne se répète pas au prochain login.
        if (_biometryAvailable) {
          try {
            final biometryEnabled = await _auth.secureStorage.isBiometryEnabled();
            if (biometryEnabled) {
              await _auth.storeWrappedKeyForBiometrics();
            }
          } catch (e) {
            debugPrint('LoginPage - Echec re-wrap biometrique post-login: $e');
          }
        }

        LockService.instance.unlock();
        LockService.instance.clearAutoLockFlag();
        // Incrémenter le compteur de déverrouillages pour la demande d'avis
        ReviewService().incrementUnlockCount();
        // Fermer le clavier puis jouer l'animation de déverrouillage.
        FocusScope.of(context).unfocus();
        await _playUnlockAnimation();
        if (!mounted) return;
        // Navigation immédiate avec nettoyage de la pile (comme pour biométrie)
        Navigator.of(context).pushNamedAndRemoveUntil(
          HomePage.route,
          (route) => false,
          arguments: _auth,
        );
      } else {
        final biometryDisabled = await _registerLoginFailure();
        if (!mounted) return;
        // Compteur visuel : avertir l'utilisateur quand il s'approche du
        // blocage 24h. _failedLoginAttempts vient d'être incrémenté par
        // _registerLoginFailure(), donc remaining tient compte du dernier échec.
        final remaining = _maxLoginAttempts - _failedLoginAttempts;
        final l10n = AppLocalizations.of(context)!;
        final messenger = ScaffoldMessenger.of(context);
        // 1 essai restant : message critique rouge
        if (remaining == 1) {
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.loginAttemptsLastChance)),
                ],
              ),
              backgroundColor: PassKeyraColors.error,
              duration: const Duration(seconds: 6),
            ),
          );
        }
        // 2 ou 3 essais restants : avertissement orange
        else if (remaining >= 1 && remaining <= 3) {
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l10n.loginAttemptsRemainingWarning(remaining)),
                  ),
                ],
              ),
              backgroundColor: PassKeyraColors.warning,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        // Cas standard : message d'origine
        else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                biometryDisabled
                    ? l10n.incorrectMasterPasswordBiometryDisabledAfter3Failures
                    : l10n.incorrectMasterPassword,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: ${e.toString()}')),
        );
      }
    }
  }

  /// Dialog explicatif quand la cle Keystore biometrique a ete invalidee/migree (fix C3).
  /// Informe l'utilisateur qu'il doit ressaisir son mot de passe maitre une fois.
  Future<void> _showBiometricMigrationDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.security, size: 48),
        title: Text(l10n.biometricMigrationTitle),
        content: Text(l10n.biometricMigrationMessage),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.biometricMigrationButton),
          ),
        ],
      ),
    );
  }

  /// Affiche le dialog combiné "Aide et paramètres" avec connexion + langue
  Future<void> _showHelpAndSettingsDialog() async {
    final l10n = AppLocalizations.of(context)!;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.helpAndSettings,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Section 1 : Problèmes de connexion
                Row(
                  children: [
                    const Icon(Icons.help_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.connectionIssues,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l10n.checkMasterPasswordOrBiometry),
                const SizedBox(height: 12),
                Text(l10n.restoreFromBackup),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () {
                    Navigator.pop(context);
                    _showImportSourceDialog();
                  },
                  icon: const Icon(Icons.history),
                  label: Text(l10n.restoreFromBackupButton),
                ),
                const SizedBox(height: 8),
                Text(l10n.myLocalBackups),
                const SizedBox(height: 8),
                FutureBuilder<List<LocalBackup>>(
                  future: _backupRepo.listLocalBackups(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final backups = snapshot.data ?? [];
                    if (backups.isEmpty) {
                      return Text(l10n.noLocalBackup);
                    }
                    return Column(
                      children: backups.map((backup) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.insert_drive_file_outlined),
                          title: Text(DateFormat('dd/MM/yyyy HH:mm').format(backup.payload.exportedAt.toLocal())),
                          subtitle: Text(backup.fileName),
                          onTap: () async {
                            Navigator.pop(context);
                            final content = await readBackupFileSafe(File(backup.filePath));
                            await _importBackupFromContent(content);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.share_outlined),
                            onPressed: () async {
                              await Share.shareXFiles([
                                XFile(
                                  backup.filePath,
                                  mimeType: 'application/json',
                                  name: backup.fileName,
                                ),
                              ], text: 'Sauvegarde PassKeyra');
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetApp();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PassKeyraColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: Text(l10n.resetApplication),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Section 2 : Paramètres de langue
                Row(
                  children: [
                    const Icon(Icons.language, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.languageSettings,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      const Text('FR  '),
                      Text(l10n.french),
                    ],
                  ),
                  value: 'fr',
                  groupValue: LanguageService().currentLocale.languageCode,
                  onChanged: (value) async {
                    if (value != null) {
                      await LanguageService().setLanguageByCode(value);
                      if (!mounted) return;
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      const Text('EN  '),
                      Text(l10n.english),
                    ],
                  ),
                  value: 'en',
                  groupValue: LanguageService().currentLocale.languageCode,
                  onChanged: (value) async {
                    if (value != null) {
                      await LanguageService().setLanguageByCode(value);
                      if (!mounted) return;
                      Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      const Text('ES  '),
                      Text(l10n.spanish),
                    ],
                  ),
                  value: 'es',
                  groupValue: LanguageService().currentLocale.languageCode,
                  onChanged: (value) async {
                    if (value != null) {
                      await LanguageService().setLanguageByCode(value);
                      if (!mounted) return;
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _resetApp() async {
    // Demander confirmation avec validation par texte
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser l\'application'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cette action va supprimer TOUTES les données de PassKeyra :\n\n'
                  '• Votre code secret\n'
                  '• Tous vos mots de passe enregistrés\n'
                  '• Tous les paramètres\n\n'
                  'Cette action est IRRÉVERSIBLE.\n',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pour confirmer, tapez "réinitialiser" ci-dessous :',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: textController,
                  inputFormatters: [LengthLimitingTextInputFormatter(64)],
                  decoration: const InputDecoration(
                    labelText: 'Tapez "réinitialiser"',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().toLowerCase() != 'réinitialiser') {
                      return 'Vous devez taper "réinitialiser"';
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
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: PassKeyraColors.error,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      setState(() => _isLoading = true);
      
      // 1. Supprimer le stockage sécurisé
      await _auth.secureStorage.deleteAll();
      
      // 2. Supprimer le coffre Hive
      if (Hive.isBoxOpen('vault_blob')) {
        final box = Hive.box<String>('vault_blob');
        await box.clear();
        await box.close();
      }
      
      // 3. Supprimer les SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Application réinitialisée avec succès'),
          backgroundColor: PassKeyraColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Attendre que le message s'affiche
      await Future.delayed(const Duration(seconds: 2));
      
      // Recharger la page
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(LoginPage.route);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: PassKeyraColors.error,
        ),
      );
    }
  }

  Future<void> _loginWithBiometry() async {
    // Éviter les déclenchements multiples
    if (_isBiometryInProgress) {
      debugPrint('LoginPage - Biométrie déjà en cours, annulation');
      return;
    }
    
    debugPrint('LoginPage - ========== DÉBUT AUTHENTIFICATION BIOMÉTRIQUE ==========');
    debugPrint('LoginPage - justAutoLocked=${LockService.instance.justAutoLocked}');
    debugPrint('LoginPage - _biometryAvailable=$_biometryAvailable');
    
    _isBiometryInProgress = true;
    
    // Vérifier que la clé wrapped existe
    final wrappedKey = await _auth.secureStorage.readWrappedKey();
    debugPrint('LoginPage - Clé wrapped présente: ${wrappedKey != null} (longueur: ${wrappedKey?.length ?? 0})');
    
    if (wrappedKey == null) {
      debugPrint('LoginPage - ERREUR: Aucune clé wrapped trouvée!');
      _isBiometryInProgress = false;
      LockService.instance.clearAutoLockFlag();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.biometryNotConfigured)),
        );
      }
      return;
    }
    
    try {
      // Auth biométrique au niveau applicatif via local_auth (accepte STRONG,
      // WEAK et CONVENIENCE → permet face unlock sur tablettes/Pixel).
      // Une fois authentifié, unlockWithBiometrics() fait juste le unwrap
      // Keystore sans nouveau prompt.
      debugPrint('LoginPage - Lancement de local_auth.authenticate()...');
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour déverrouiller PassKeyra',
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

      _isBiometryInProgress = false;
      if (!mounted) {
        LockService.instance.clearAutoLockFlag();
        return;
      }

      if (!authenticated) {
        // Annulation user ou échec : silencieux, le prompt local_auth a géré l'UX.
        LockService.instance.clearAutoLockFlag();
        return;
      }

      debugPrint('LoginPage - Auth biométrique OK, appel unlockWithBiometrics()...');
      final ok = await _auth.unlockWithBiometrics();
      debugPrint('LoginPage - Résultat unlockWithBiometrics: $ok');

      if (!mounted) {
        LockService.instance.clearAutoLockFlag();
        return;
      }

      {
        if (ok && mounted) {
          await _registerLoginSuccess();
          debugPrint('LoginPage - Déverrouillage biométrique réussi!');
          
          // Déverrouiller immédiatement
          debugPrint('LoginPage - Appel de LockService.unlock()...');
          LockService.instance.unlock();
          LockService.instance.clearAutoLockFlag();
          // Incrémenter le compteur de déverrouillages pour la demande d'avis
          ReviewService().incrementUnlockCount();

          // Fermer le clavier puis jouer l'animation de déverrouillage.
          FocusScope.of(context).unfocus();
          await _playUnlockAnimation();
          if (!mounted) return;

          // Navigation IMMEDIATE avec nettoyage complet de la pile
          // Ne PAS attendre le stream, car ça crée des conflits
          debugPrint('LoginPage - Navigation IMMEDIATE vers HomePage...');
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              HomePage.route,
              (route) => false, // Supprimer toutes les routes
              arguments: _auth,
            );
            debugPrint('LoginPage - Navigation lancée');
          }
        } else {
          debugPrint('LoginPage - âŒ Échec unlockWithBiometrics');
          LockService.instance.clearAutoLockFlag();
          if (mounted) {
            if (_auth.requiresBiometricMigration) {
              _auth.clearBiometricMigrationFlag();
              await _showBiometricMigrationDialog();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.biometricUnlockError)),
              );
            }
          }
        }
      }
    } on PlatformException catch (e) {
      _isBiometryInProgress = false;
      LockService.instance.clearAutoLockFlag();
      debugPrint('LoginPage - âŒ PlatformException: ${e.code} - ${e.message}');
      debugPrint('LoginPage - Stack: ${e.stacktrace}');
      
      // Ne pas afficher d'erreur si l'utilisateur a simplement annulé
      if (e.code != 'NotAvailable' && 
          e.code != 'NotEnrolled' && 
          e.code != 'UserCanceled' &&
          e.code != 'LockedOut' &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.biometricError(e.message ?? e.code))),
        );
      } else if (e.code == 'LockedOut' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.biometryTemporarilyBlocked),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stack) {
      _isBiometryInProgress = false;
      LockService.instance.clearAutoLockFlag();
      debugPrint('LoginPage - âŒ Exception: $e');
      debugPrint('LoginPage - Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.biometricError(e.toString()))),
        );
      }
    }
    
    debugPrint('LoginPage - ========== FIN AUTHENTIFICATION BIOMÉTRIQUE ==========');
  }

  Future<void> _loadLoginGuardState() async {
    // Mitigation M2 : compteurs de rate limit lus depuis SecureStorage (chiffré
    // AES-GCM) au lieu de SharedPreferences (modifiable par toute app sur device
    // compromis).
    final ss = _auth.secureStorage;
    _failedLoginAttempts = await ss.readInt(_kFailedLoginAttempts) ?? 0;
    final configuredMaxAttempts =
        await ss.readInt(_kMaxLoginAttempts) ?? _defaultMaxLoginAttempts;
    _maxLoginAttempts = configuredMaxAttempts
        .clamp(_minMaxLoginAttempts, _maxMaxLoginAttempts)
        .toInt();
    if (_maxLoginAttempts != configuredMaxAttempts) {
      await ss.writeInt(_kMaxLoginAttempts, _maxLoginAttempts);
    }

    final lastFailedLoginAtMs = await ss.readInt(_kLastFailedLoginAtMs);
    if (lastFailedLoginAtMs != null) {
      final lastFailedLoginAt =
          DateTime.fromMillisecondsSinceEpoch(lastFailedLoginAtMs);
      if (DateTime.now().difference(lastFailedLoginAt) > _failedAttemptResetWindow) {
        _failedLoginAttempts = 0;
        _loginLockedUntil = null;
        await ss.writeInt(_kFailedLoginAttempts, 0);
        await ss.deleteKey(_kLoginLockUntilMs);
        await ss.deleteKey(_kLastFailedLoginAtMs);
        await ss.deleteKey(_kVaultBlockCount);
        await ss.deleteKey(_kLastVaultBlockAtMs);
      }
    }

    final lockUntilMs = await ss.readInt(_kLoginLockUntilMs);
    if (lockUntilMs != null) {
      final lockUntil = DateTime.fromMillisecondsSinceEpoch(lockUntilMs);
      if (lockUntil.isAfter(DateTime.now())) {
        _loginLockedUntil = lockUntil;
      } else {
        _loginLockedUntil = null;
        _failedLoginAttempts = 0;
        await ss.deleteKey(_kLoginLockUntilMs);
        await ss.writeInt(_kFailedLoginAttempts, 0);
      }
    }
  }

  Future<void> _registerLoginSuccess() async {
    _failedLoginAttempts = 0;
    _loginLockedUntil = null;
    final ss = _auth.secureStorage;
    await ss.writeInt(_kFailedLoginAttempts, 0);
    await ss.deleteKey(_kLoginLockUntilMs);
    await ss.deleteKey(_kLastFailedLoginAtMs);
    await ss.deleteKey(_kVaultBlockCount);
    await ss.deleteKey(_kLastVaultBlockAtMs);
  }

  Future<bool> _registerLoginFailure() async {
    final ss = _auth.secureStorage;
    final now = DateTime.now();
    final lastFailedLoginAtMs = await ss.readInt(_kLastFailedLoginAtMs);
    if (lastFailedLoginAtMs != null) {
      final lastFailedLoginAt =
          DateTime.fromMillisecondsSinceEpoch(lastFailedLoginAtMs);
      if (now.difference(lastFailedLoginAt) > _failedAttemptResetWindow) {
        _failedLoginAttempts = 0;
        await ss.writeInt(_kFailedLoginAttempts, 0);
        await ss.deleteKey(_kVaultBlockCount);
        await ss.deleteKey(_kLastVaultBlockAtMs);
      }
    }

    _failedLoginAttempts += 1;
    if (_failedLoginAttempts > _maxLoginAttempts) {
      _failedLoginAttempts = _maxLoginAttempts;
    }
    await ss.writeInt(_kFailedLoginAttempts, _failedLoginAttempts);
    await ss.writeInt(_kLastFailedLoginAtMs, now.millisecondsSinceEpoch);
    final biometryDisabled = await _disableBiometryAfterRepeatedFailures();

    if (_failedLoginAttempts >= _maxLoginAttempts) {
      final previousBlockAtMs = await ss.readInt(_kLastVaultBlockAtMs);
      final previousBlockCount = await ss.readInt(_kVaultBlockCount) ?? 0;

      int blockCountInWindow = 1;
      if (previousBlockAtMs != null) {
        final previousBlockAt =
            DateTime.fromMillisecondsSinceEpoch(previousBlockAtMs);
        final withinEscalationWindow =
            now.difference(previousBlockAt) <= _vaultBlockEscalationWindow;
        blockCountInWindow =
            withinEscalationWindow ? (previousBlockCount + 1) : 1;
      }

      final vaultBlockDuration = _getVaultBlockDuration(blockCountInWindow);
      _loginLockedUntil = now.add(vaultBlockDuration);
      await ss.writeInt(
        _kLoginLockUntilMs,
        _loginLockedUntil!.millisecondsSinceEpoch,
      );
      await ss.writeInt(_kVaultBlockCount, blockCountInWindow);
      await ss.writeInt(_kLastVaultBlockAtMs, now.millisecondsSinceEpoch);
      return biometryDisabled;
    }

    if (_failedLoginAttempts >= _cooldownStartAttempt) {
      _loginLockedUntil = DateTime.now().add(_loginLockDuration);
      await ss.writeInt(
        _kLoginLockUntilMs,
        _loginLockedUntil!.millisecondsSinceEpoch,
      );
    }
    return biometryDisabled;
  }

  Future<bool> _disableBiometryAfterRepeatedFailures() async {
    if (_failedLoginAttempts < _biometryDisableThreshold) {
      return false;
    }
    final biometryEnabled = await _auth.secureStorage.isBiometryEnabled();
    if (!biometryEnabled) {
      return false;
    }
    await _auth.secureStorage.setBiometryEnabled(false);
    await _auth.secureStorage.deleteWrappedKey();
    if (mounted) {
      setState(() => _biometryAvailable = false);
    }
    return true;
  }

  Future<bool> _canAttemptLogin() async {
    if (_loginLockedUntil == null) return true;

    final now = DateTime.now();
    if (_loginLockedUntil!.isAfter(now)) {
      final remaining = _loginLockedUntil!.difference(now).inSeconds + 1;
      if (mounted) {
        final isVaultBlocked = _failedLoginAttempts >= _maxLoginAttempts;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVaultBlocked
                  ? 'Coffre temporairement bloque. Reessayez dans ${_formatRemainingDuration(remaining)}.'
                  : 'Trop de tentatives. Nouvelle tentative dans ${remaining}s.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    // Cooldown expire : on enleve juste le verrou temporel, sans reset du compteur.
    _loginLockedUntil = null;
    await _auth.secureStorage.deleteKey(_kLoginLockUntilMs);
    return true;
  }

  Duration _getVaultBlockDuration(int blockCountInWindow) {
    if (blockCountInWindow <= 1) {
      return _vaultBlockDurationLevel1;
    }
    if (blockCountInWindow == 2) {
      return _vaultBlockDurationLevel2;
    }
    return _vaultBlockDurationLevel3;
  }

  String _formatRemainingDuration(int remainingSeconds) {
    final duration = Duration(seconds: remainingSeconds);
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes == 0) return '${hours}h';
      return '${hours}h ${minutes}min';
    }
    if (duration.inMinutes >= 1) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds.remainder(60);
      if (seconds == 0) return '${minutes}min';
      return '${minutes}min ${seconds}s';
    }
    return '${duration.inSeconds}s';
  }

  /// Affiche la liste des sauvegardes locales et permet d'en sélectionner une
  Future<void> _selectLocalBackup() async {
    debugPrint('Import - Chargement des sauvegardes locales...');

    // Charger les sauvegardes locales
    final localBackups = await _backupRepo.listLocalBackups();

    if (localBackups.isEmpty) {
      // Aucune sauvegarde locale â†’ Fallback sur FilePicker
      debugPrint('Import - Aucune sauvegarde locale trouvée, fallback sur FilePicker');
      await _importBackup();
      return;
    }

    // Afficher dialog de sélection
    final l10n = AppLocalizations.of(context)!;
    final selectedBackup = await showDialog<LocalBackup>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.myLocalBackups),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: localBackups.length,
            itemBuilder: (context, index) {
              final backup = localBackups[index];
              return ListTile(
                leading: const Icon(Icons.archive),
                title: Text(backup.fileName),
                subtitle: Text(
                  '${backup.payload.entryCount} ${backup.payload.entryCount > 1 ? l10n.backupEntries : l10n.backupEntry} • ${DateFormat('dd/MM/yyyy HH:mm').format(backup.payload.exportedAt.toLocal())}',
                ),
                onTap: () => Navigator.pop(context, backup),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (selectedBackup == null) {
      debugPrint('Import - Aucune sauvegarde sélectionnée');
      return;
    }

    // Restaurer la sauvegarde sélectionnée
    debugPrint('Import - Sauvegarde sélectionnée: ${selectedBackup.fileName}');

    // Afficher indicateur de chargement (PBKDF2 prend ~500ms)
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Restauration en cours'),
              ],
            ),
          ),
        ),
      );
    }

    await _importBackupFromContent(selectedBackup.payload.toJsonString());
    // Note: Le dialog est géré par _importBackupFromContent (redirection contrôlée vers LoginPage)
  }

  /// Affiche un dialog pour choisir la source d'import (fichier local ou cloud)
  Future<void> _showImportSourceDialog() async {
    final l10n = AppLocalizations.of(context)!;

    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importSourceTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(l10n.importFromLocalFile),
              onTap: () => Navigator.pop(context, 'local'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: Text(l10n.importFromCloud),
              onTap: () => Navigator.pop(context, 'cloud'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (source == 'local') {
      // Import depuis sauvegardes locales (fallback sur FilePicker si aucune)
      await _selectLocalBackup();
    } else if (source == 'cloud') {
      // Navigation vers la page Cloud Backup pour restaurer depuis cloud
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/cloud-backup',
          arguments: _auth,
        );
      }
    }
  }

  Future<void> _importBackup() async {
    debugPrint('Import - Début de l\'import...');
    
    // Sélectionner un fichier
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    
    if (result == null || result.files.isEmpty) {
      debugPrint('Import - Annulé par l\'utilisateur');
      return;
    }
    
    try {
      debugPrint('Import - Lecture du fichier : ${result.files.first.name}');
      final file = File(result.files.first.path!);
      final content = await readBackupFileSafe(file);

      // Afficher indicateur de chargement (PBKDF2 prend ~500ms)
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Restauration en cours'),
                ],
              ),
            ),
          ),
        );
      }

      await _importBackupFromContent(content);
    } catch (e, stackTrace) {
      debugPrint('Import - ERREUR : $e');
      debugPrint('Import - Stack trace : $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.importError2),
            backgroundColor: PassKeyraColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _importBackupFromContent(String rawContent) async {
    try {
      // Vérifier si un coffre existe déjà
      final hasExistingVault = await _auth.secureStorage.readSalt() != null;
      
      if (hasExistingVault) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              icon: Icon(Icons.warning_amber, color: PassKeyraColors.warning, size: 48),
              title: Text(AppLocalizations.of(context)!.vaultAlreadyExists),
              content: const Text(
                'Impossible d\'importer une sauvegarde.\n\n'
                'Un coffre est déjà enregistré sur cet appareil.\n\n'
                'Solutions :\n'
                '1. Utiliser une sauvegarde locale disponible ci-dessous\n'
                'OU\n'
                '2. Réinitialiser l\'app via Paramètres\n'
                '3. Fermer complètement l\'app puis réessayer',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.understood),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      debugPrint('Import - Parsing JSON...');
      final raw = jsonDecode(rawContent) as Map<String, dynamic>;
      debugPrint('Import - JSON parsé. Clés trouvées : ${raw.keys.join(", ")}');

      BackupPayload payload;
      try {
        payload = BackupPayload.fromJson(raw);
      } on FormatException catch (e) {
        debugPrint('Import - Format invalide : ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.invalidBackup(e.message))),
          );
        }
        return;
      }

      // Demander le code secret de la sauvegarde
      final passwordController = TextEditingController();
      final formKey = GlobalKey<FormState>();
      bool obscurePassword = true;

      final password = await showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.backupMasterPassword),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppLocalizations.of(context)!.backupPasswordInstructions),
                    const SizedBox(height: 16),
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        inputFormatters: [LengthLimitingTextInputFormatter(256)],
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.masterPassword,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) {
                          final value = v ?? '';
                          if (value.isEmpty) return AppLocalizations.of(context)!.required;
                          // Mitigation L2 : passphrases avec espaces autorisees.
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, passwordController.text);
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.import),
                ),
              ],
            );
          },
        ),
      );
      
      if (password == null || !mounted) {
        debugPrint('Import - Annulé (pas de mot de passe)');
        return;
      }
      
      debugPrint('Import - Code secret fourni');
      
      // Déchiffrer avec le mot de passe fourni
      final crypto = CryptoService();
      
      // Vérifier que les champs nécessaires existent
      debugPrint('Import - Vérification des champs...');
      debugPrint('Import - Sel (base64) : ${payload.salt.substring(0, 16)}...');
      debugPrint('Import - IV (base64) : ${payload.iv.substring(0, 16)}...');
      debugPrint('Import - Ciphertext (base64) : ${payload.ciphertext.substring(0, 16)}...');
      debugPrint('Import - Tag (base64) : ${payload.tag.substring(0, 16)}...');
      
      debugPrint('Import - Décodage du sel...');
      final salt = base64Decode(payload.salt);
      debugPrint('Import - Sel décodé : ${salt.length} octets');

      debugPrint('Import - Dérivation de la clé avec ${payload.iterations} itérations...');
      // CORRECTION ANR: Dériver la clé dans un isolate séparé pour éviter de bloquer l'UI
      // CORRECTION CRITIQUE: Utiliser payload.iterations pour la rétrocompatibilité (150k vs 600k)
      final key = await deriveKeyInIsolate(
        password: password,
        salt: salt,
        iterations: payload.iterations,
      );
      debugPrint('Import - Clé dérivée : ${key.length} octets');
      
      debugPrint('Import - Déchiffrement des données...');
      final encryptedJson = jsonEncode(payload.encryptedMap());
      final decrypted = crypto.decryptToJson(encryptedJson, key);
      debugPrint('Import - Déchiffrement réussi. Clés : ${decrypted.keys.join(", ")}');
      
      if (!decrypted.containsKey('entries')) {
        debugPrint('Import - Champ "entries" manquant dans les données déchiffrées');
        throw Exception('Aucune entrée trouvée dans la sauvegarde');
      }
      
      debugPrint('Import - Parsing des entrées...');
      final entriesList = decrypted['entries'];
      if (entriesList is! List) {
        debugPrint('Import - "entries" n\'est pas une liste : ${entriesList.runtimeType}');
        throw Exception('Format invalide : "entries" doit être une liste');
      }
      
      final entries = entriesList
          .map((e) => PasswordEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      debugPrint('Import - ${entries.length} entrées parsées avec succès');

      // CORRECTION: Restaurer les catégories si elles existent dans la sauvegarde
      if (decrypted.containsKey('categories')) {
        debugPrint('Import - Restauration des catégories...');
        final categoriesList = decrypted['categories'];
        if (categoriesList is List && categoriesList.isNotEmpty) {
          final categories = categoriesList
              .map((c) => CustomCategory.fromJson(c as Map<String, dynamic>))
              .toList();

          // Sauvegarder les catégories dans SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final List<Map<String, dynamic>> jsonList = categories.map((cat) => cat.toJson()).toList();
          await prefs.setString('custom_categories', jsonEncode(jsonList));
          debugPrint('Import - ${categories.length} catégories restaurées');
        }
      }

      // IMPORT INITIAL : Transaction atomique pour éviter salt écrasé avec coffre vide
      // CRITIQUE: Le salt ne doit être écrasé QUE si l'import réussit complètement

      debugPrint('==================================================');
      debugPrint('Import - DÉBUT TRANSACTION ATOMIQUE');
      debugPrint('Import - Nombre d\'entrées à importer: ${entries.length}');
      debugPrint('==================================================');

      // 1. Sauvegarder l'ancien salt (pour rollback en cas d'erreur)
      debugPrint('Import - [ÉTAPE 1/6] Lecture de l\'ancien salt...');
      final oldSalt = await _auth.secureStorage.readSalt();
      debugPrint('Import - Ancien salt lu: ${oldSalt != null ? "OUI (longueur: ${oldSalt.length})" : "AUCUN (première installation)"}');

      try {
        // 2. Définir manuellement la clé de session SANS écraser le salt dans le storage
        // Cette clé a été calculée plus haut avec deriveKeyInIsolate(password, salt)
        // setManualKey() définit seulement _currentKey en mémoire, ne touche PAS au storage
        debugPrint('Import - [ÉTAPE 2/6] Définition manuelle de la clé de session (EN MÉMOIRE UNIQUEMENT)...');
        _auth.setManualKey(
          key,
          payload.salt,
          iterations: payload.iterations,
        );
        debugPrint('Import - Clé définie en mémoire (salt du backup: ${payload.salt.length} chars)');

        // Vérifier que le salt dans le storage n'a PAS changé
        final saltCheck1 = await _auth.secureStorage.readSalt();
        debugPrint('Import - VÉRIFICATION: Salt dans storage = ${saltCheck1 == oldSalt ? "INCHANGÉ " : "MODIFIÉ âŒ"}');

        // 3. Importer les entrées AVANT d'écraser le salt
        // Si ça échoue ici, le salt ne sera PAS écrasé
        debugPrint('Import - [ÉTAPE 3/6] Sauvegarde de ${entries.length} entrées (transaction atomique)...');
        final repo = VaultRepository(_auth);
        await repo.saveAll(entries);
        debugPrint('Import - ${entries.length} entrées sauvegardées avec succès dans Hive');

        // Vérifier que le salt n'a toujours PAS changé
        final saltCheck2 = await _auth.secureStorage.readSalt();
        debugPrint('Import - VÉRIFICATION: Salt dans storage = ${saltCheck2 == oldSalt ? "TOUJOURS INCHANGÉ " : "MODIFIÉ PAR SAVEALL âŒ"}');

        // 4. SEULEMENT maintenant qu'on est sûr que tout a réussi, écraser le salt
        debugPrint('Import - [ÉTAPE 4/6] Écriture du NOUVEAU salt dans le stockage sécurisé...');
        await _auth.secureStorage.saveSalt(payload.salt);
        final saltCheck3 = await _auth.secureStorage.readSalt();
        debugPrint('Import - Nouveau salt écrit: ${saltCheck3 == payload.salt ? "OK " : "ÉCHEC âŒ"}');

        // 5. Créer le token de validation avec la nouvelle clé
        debugPrint('Import - [ÉTAPE 5/6] Création du token de validation...');
        await _auth.forceCreateValidationToken();
        debugPrint('Import - Token de validation créé');

        // 6. Vérification finale
        debugPrint('Import - [ÉTAPE 6/6] Vérification finale...');
        final finalSalt = await _auth.secureStorage.readSalt();
        debugPrint('Import - Salt final = ${finalSalt == payload.salt ? "BACKUP SALT " : "AUTRE âŒ"}');
        debugPrint('==================================================');
        debugPrint('Import - TRANSACTION ATOMIQUE RÉUSSIE');
        debugPrint('==================================================');

      } catch (e, stackTrace) {
        // ROLLBACK: Restaurer l'ancien salt si l'import a échoué
        debugPrint('==================================================');
        debugPrint('Import - âŒ ERREUR DURANT LA TRANSACTION');
        debugPrint('Import - Type d\'erreur: ${e.runtimeType}');
        debugPrint('Import - Message: $e');
        debugPrint('Import - Stack trace: $stackTrace');
        debugPrint('==================================================');

        if (oldSalt != null) {
          debugPrint('Import - ðŸ”„ DÉBUT ROLLBACK: Restauration de l\'ancien salt...');
          await _auth.secureStorage.saveSalt(oldSalt);
          final saltAfterRollback = await _auth.secureStorage.readSalt();
          debugPrint('Import - Rollback terminé: ${saltAfterRollback == oldSalt ? "SUCCÃˆS " : "ÉCHEC âŒ"}');
        } else {
          debugPrint('Import - ROLLBACK IGNORÉ: Aucun ancien salt à restaurer (première installation)');
        }

        debugPrint('==================================================');
        debugPrint('Import - RELANCEMENT DE L\'EXCEPTION VERS LE BLOC CATCH PARENT');
        debugPrint('==================================================');

        // Relancer l'exception pour que le bloc catch parent la gère
        rethrow;
      }
      
      // DÉSACTIVER automatiquement la biométrie après import
      // Car la clé biométrique devient incompatible avec le nouveau sel
      debugPrint('Import - Désactivation automatique de la biométrie...');
      await _auth.secureStorage.setBiometryEnabled(false);
      debugPrint('Import - Biométrie désactivée (l\'utilisateur devra la réactiver)');
      
      if (!mounted) return;
      LockService.instance.unlock();
      LockService.instance.clearAutoLockFlag();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${entries.length} entrées importées avec succès.\nLa biométrie a été désactivée pour des raisons de sécurité.\nL\'application va se fermer.'),
          backgroundColor: PassKeyraColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        LoginPage.route,
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('Import - ERREUR : $e');
      debugPrint('Import - Stack trace : $stackTrace');
      
      if (mounted) {
        String errorMessage = 'Erreur lors de l\'import';
        if (e.toString().contains('FormatException')) {
          errorMessage = 'Fichier JSON corrompu ou invalide';
        } else if (e.toString().contains('type cast')) {
          errorMessage = 'Format de sauvegarde incompatible';
        } else if (e.toString().contains('Cipher') || e.toString().contains('decrypt')) {
          errorMessage = 'Code secret incorrect ou fichier corrompu';
        } else if (e.toString().contains('Exception:')) {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        } else {
          errorMessage = 'Erreur : ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: PassKeyraColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<Widget> _buildContent(BuildContext context) {
    return [
      // Logo avec effet de glow pulsant et zoom centré (mobile),
      // ou simple shake au déverrouillage (desktop, plus léger).
      Center(
        child: isDesktop
            ? AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, _) => Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: Image.asset(
                    'assets/icons/PassKeyra_centered_glow.png',
                    width: 156,
                    height: 156,
                    cacheWidth: 468,
                    cacheHeight: 468,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              )
            : AnimatedBuilder(
          animation: Listenable.merge([_glowAnimation, _zoomAnimation]),
          builder: (context, child) {
            // Calculer les stops et couleurs pour l'effet de pulsation depuis l'anneau blanc
            final progress = _glowAnimation.value;

            // Position de l'anneau blanc (environ 40% du rayon) - point de départ de la pulsation
            final startPos = 0.40;
            // Position maximale d'expansion (100%)
            final maxPos = 1.0;

            // Position actuelle de la vague d'expansion
            final wavePos = startPos + (maxPos - startPos) * progress;

            // Créer un dégradé qui se fonce en s'éloignant
            final baseOpacity = 0.15;
            final darkOpacity = 0.25;

            return Transform.scale(
              scale: _zoomAnimation.value,
              alignment: Alignment.center, // Centrage explicite pour l'animation
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      // Centre : transparent
                      Colors.transparent,
                      // Juste avant l'anneau blanc : transparent
                      Colors.transparent,
                      // À l'anneau blanc : début de la pulsation bleue (clair)
                      PassKeyraColors.glowBlue.withOpacity(baseOpacity * progress),
                      // Vague d'expansion : bleu qui se fonce progressivement
                      PassKeyraColors.glowBlue.withOpacity(darkOpacity * progress),
                      // Au-delà de la vague : transparent
                      Colors.transparent,
                    ],
                    stops: [
                      0.0,
                      startPos - 0.03,
                      startPos,
                      wavePos,
                      wavePos + 0.08,
                    ],
                  ),
                  boxShadow: [
                    // Ombre externe qui pulse avec l'aura
                    BoxShadow(
                      color: PassKeyraColors.glowBlue.withOpacity(0.2 * progress),
                      blurRadius: 50 + (30 * progress),
                      spreadRadius: 10 + (15 * progress),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icons/PassKeyra_centered_glow.png',
                    width: 156,
                    height: 156,
                    // Pré-rastérise l'asset 1330×1330 à ~3× la taille affichée pour
                    // rester net sur les écrans DPI 125–200 % de Windows.
                    cacheWidth: 468,
                    cacheHeight: 468,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 24),

      // Tous les éléments qui doivent disparaître lors du déverrouillage
      AnimatedOpacity(
        opacity: _isUnlocking ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PassKeyra',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isFirstTime ? AppLocalizations.of(context)!.secureSetup : AppLocalizations.of(context)!.unlockVault,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Formulaire
            if (_isFirstTime) ...[
              Text(
                AppLocalizations.of(context)!.createMasterPassword,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],

            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              inputFormatters: [LengthLimitingTextInputFormatter(256)],
              textInputAction: TextInputAction.done,
              autofocus: true,
              onFieldSubmitted: (_) {
                if (_isLoading || !_canCreateAccount()) return;
                if (_isFirstTime) {
                  _createMasterPassword();
                } else {
                  _loginWithPassword();
                }
              },
              decoration: InputDecoration(
                labelText: _isFirstTime ? AppLocalizations.of(context)!.newMasterPassword : AppLocalizations.of(context)!.masterPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              onTap: () {
                // Marquer que l'utilisateur a interagi avec le champ
                // Cela empêchera la biométrie automatique de se déclencher
                setState(() => _userInteractedWithField = true);
              },
              onChanged: (value) {
                // Mettre à jour le mot de passe en cours pour l'indicateur de force
                if (_isFirstTime) {
                  setState(() => _currentPassword = value);
                }
              },
              validator: (v) {
                final value = v ?? '';
                if (value.isEmpty) return AppLocalizations.of(context)!.required;
                // Mitigation L2 : passphrases avec espaces autorisees.
                if (value.length < 8) return AppLocalizations.of(context)!.passwordMinLength;

                // Validation de complexité (uniquement à la création)
                if (_isFirstTime) {
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return AppLocalizations.of(context)!.passwordNeedsUppercase;
                  }
                  if (!RegExp(r'[a-z]').hasMatch(value)) {
                    return AppLocalizations.of(context)!.passwordNeedsLowercase;
                  }
                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return AppLocalizations.of(context)!.passwordNeedsDigit;
                  }
                  if (!RegExp(r'[!@#$%&*?_=+.,;:()\[\]{}~^<>-]').hasMatch(value)) {
                    return AppLocalizations.of(context)!.passwordNeedsSpecial;
                  }
                }

                return null;
              },
            ),

            if (_isFirstTime) ...[
              const SizedBox(height: 16),
              PasswordStrengthIndicator(password: _currentPassword),
              if (_showMasterPasswordWarning) const SizedBox(height: 16),

              if (_showMasterPasswordWarning)
                // Avertissement securite critique - Session 22
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PassKeyraColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: PassKeyraColors.warning.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: PassKeyraColors.warning,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .onboardingMasterPasswordTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: PassKeyraColors.warning,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!
                            .onboardingMasterPasswordMessage,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!
                            .onboardingSecurityRequirements,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildRequirement(
                        AppLocalizations.of(context)!.onboardingRuleLength,
                      ),
                      _buildRequirement(
                        AppLocalizations.of(context)!.onboardingRuleComplexity,
                      ),
                      _buildRequirement(
                        AppLocalizations.of(context)!.onboardingRuleDictionary,
                      ),
                      _buildRequirement(
                        AppLocalizations.of(context)!.onboardingRuleUnique,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                inputFormatters: [LengthLimitingTextInputFormatter(256)],
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.confirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                onTap: () {
                  // Marquer que l'utilisateur a interagi avec le champ
                  setState(() => _userInteractedWithField = true);
                },
                validator: (v) {
                  final value = v ?? '';
                  if (value.isEmpty) return AppLocalizations.of(context)!.confirmPassword;
                  // Mitigation L2 : passphrases avec espaces autorisees.
                  if (value != _passwordController.text) {
                    return AppLocalizations.of(context)!.passwordsDontMatch;
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 32),

            // Bouton principal avec effet de glow
            Container(
              decoration: _isLoading ? null : PassKeyraColors.primaryGlow(opacity: 0.25, blurRadius: 30.0),
              child: FilledButton(
                // Session 22 - Bloquer si mot de passe trop faible ou pas d'acknowledgement
                onPressed: _canCreateAccount() ? (_isFirstTime ? _createMasterPassword : _loginWithPassword) : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isFirstTime ? AppLocalizations.of(context)!.createAccount : AppLocalizations.of(context)!.unlock),
              ),
            ),

            // Bouton biométrie
            if (_biometryAvailable && !_isFirstTime) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _loginWithBiometry,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.fingerprint),
                label: Text(AppLocalizations.of(context)!.biometricAuth),
              ),
            ],

            // Divider et options supplémentaires (uniquement si nécessaire)
            if (_isFirstTime || !_isFirstTime) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // Bouton Import (uniquement pour première installation)
            if (_isFirstTime)
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _showImportSourceDialog,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.file_upload),
                label: const Text('Importer une sauvegarde'),
              ),

            // Lien "Aide et paramètres" (uniquement si coffre existant)
            if (!_isFirstTime) ...[
              TextButton(
                onPressed: _isLoading ? null : _showHelpAndSettingsDialog,
                child: Text(
                  AppLocalizations.of(context)!.helpAndSettings,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: _isBannerAdLoaded && _bannerAd != null
          ? Container(
              height: _bannerAd!.size.height.toDouble(),
              alignment: Alignment.center,
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
      body: Stack(
        children: [
          // Contenu principal
          SafeArea(
            top: false,    // Supprimer le padding blanc en haut
            left: false,   // Supprimer le padding blanc sur les côtés
            right: false,  // pour éviter la bordure blanche
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24), // Pas de padding horizontal
              child: Form(
                key: _formKey,
                // CORRECTION: Toujours utiliser SingleChildScrollView avec AlwaysScrollableScrollPhysics
                // pour permettre le scroll en tout temps, même quand le clavier est fermé
                child: SingleChildScrollView(
                  controller: _scrollController, // Ajout du contrôleur pour scroll automatique
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    // Forcer une hauteur minimale pour centrer le contenu
                    constraints: BoxConstraints(
                      minHeight: screenHeight - topPadding - 48, // 24*2 padding vertical
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        // Sur desktop, le formulaire login est capé à 500px de
                        // large : évite l'effet "champ étiré sur 1920px" qui
                        // n'a aucun sens sur grand écran.
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 500 : double.infinity,
                        ),
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24), // Padding horizontal pour le contenu
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildContent(context),
                      ),
                    ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper pour afficher une exigence de sécurité - Session 22
  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: PassKeyraColors.success.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Vérifie si le formulaire de création peut être soumis.
  /// La force du mot de passe est purement informative — la validation
  /// (longueur, complexité) est assurée par le validator du TextFormField.
  bool _canCreateAccount() {
    if (_isLoading) return false;
    return true;
  }
}


