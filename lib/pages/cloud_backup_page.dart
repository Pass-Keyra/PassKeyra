import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../l10n/app_localizations.dart';

import '../services/cloud_backup/cloud_backup_service.dart';
import '../services/cloud_backup/cloud_backup_provider.dart';
import '../services/cloud_backup/cloud_backup_factory.dart'; // Pour CloudProvider enum
import '../services/cloud_backup/models/cloud_backup_metadata.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../services/google_signin_service.dart';
import '../services/firebase/firebase_auth_service.dart';
import '../services/vault_repository.dart';
import '../services/crypto_service.dart';
import '../services/crypto_isolate.dart';
import '../services/category_service.dart';
import '../services/onboarding_service.dart';
import '../services/premium_service.dart';
import '../models/backup_payload.dart';
import '../models/password_entry.dart';
import '../models/custom_category.dart';
import '../widgets/coach_mark_system.dart';
import '../widgets/premium_badge.dart';
import 'login_page.dart';

/// Page de gestion des sauvegardes cloud (Google Drive)
///
/// Fonctionnalités:
/// - Authentification Google Drive
/// - Upload manuel de backup chiffré
/// - Liste des backups existants
/// - Téléchargement et restauration
/// - Suppression de backups
///
/// Feature 9 (GRATUIT) - MVP Google Drive uniquement
class CloudBackupPage extends StatefulWidget {
  const CloudBackupPage({super.key, this.startTutorial = false});
  static const String route = '/cloud-backup';
  final bool startTutorial;

  @override
  State<CloudBackupPage> createState() => _CloudBackupPageState();
}

class _CloudBackupPageState extends State<CloudBackupPage>
    with SingleTickerProviderStateMixin {
  final _cloudService = CloudBackupService();
  final _crypto = CryptoService();
  AuthService? _auth;
  VaultRepository? _vaultRepository;

  bool _isLoading = true;
  bool _isAuthenticated = false;
  List<CloudBackupMetadata> _backups = [];
  String? _errorMessage;
  CloudQuota? _quota;
  bool _isAndroidBelowOreo = false; // Android < 8.0

  // Multi-provider: Provider actuellement affiché dans la vue
  CloudProvider? _selectedViewProvider;

  // Tutorial
  late final AnimationController _coachPulseController;
  bool _isTutorialRunning = false;
  String? _activeTargetKey;
  final _connectButtonKey = GlobalKey();
  final _backupsListKey = GlobalKey();
  final _autoBackupKey = GlobalKey();
  final _manualBackupKey = GlobalKey();
  final _changeProviderKey = GlobalKey();
  final _providerNameKey = GlobalKey();
  final _providerChooserKey = GlobalKey();
  bool _tutorialInitialized = false;
  bool _pendingStartTutorial = false;
  bool _pendingStartTutorialAutoOnly = false;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  @override
  void initState() {
    super.initState();
    _coachPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _checkAndroidVersion();
    _initializeCloudService();
  }

  Future<void> _checkAndroidVersion() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      // API 26 = Android 8.0 (Oreo)
      setState(() {
        _isAndroidBelowOreo = androidInfo.version.sdkInt < 26;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Récupérer les arguments (peut être AuthService ou Map avec startTutorial)
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    bool shouldStartTutorial = widget.startTutorial;

    if (routeArgs is AuthService) {
      if (_auth == null) {
        _auth = routeArgs;
        _vaultRepository = VaultRepository(_auth!);
      }
    } else if (routeArgs is Map<String, dynamic>) {
      if (_auth == null && routeArgs['authService'] != null) {
        _auth = routeArgs['authService'] as AuthService;
        _vaultRepository = VaultRepository(_auth!);
      }
      shouldStartTutorial = routeArgs['startTutorial'] == true || shouldStartTutorial;
      if (routeArgs['startTutorialAutoBackupOnly'] == true) _pendingStartTutorialAutoOnly = true;
    }

    if (shouldStartTutorial) _pendingStartTutorial = true;
  }

  @override
  void dispose() {
    _coachPulseController.dispose();
    super.dispose();
  }

  Future<void> _runCloudBackupTutorial() async {
    setState(() => _isTutorialRunning = true);
    final l10n = AppLocalizations.of(context)!;
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    void cleanup() {
      if (mounted) setState(() { _isTutorialRunning = false; _activeTargetKey = null; });
    }

    // Helper interne : affiche un coach mark et retourne true si l'utilisateur
    // a cliqué sur le bouton primaire (continuer/terminer).
    Future<bool> step({
      required String targetKey,
      required GlobalKey key,
      required String title,
      required String message,
      required String stepIndicator,
      String? primaryLabel,
      String? secondaryLabel,
    }) async {
      if (!mounted) return false;
      setState(() => _activeTargetKey = targetKey);
      final result = await CoachMarkSystem.showCoachStep(
        context: context,
        targetKey: key,
        pulseController: _coachPulseController,
        title: title,
        message: message,
        primaryLabel: primaryLabel ?? l10n.onboardingNext,
        secondaryLabel: secondaryLabel ?? l10n.onboardingSkipTutorial,
        stepIndicator: stepIndicator,
      );
      return result == CoachStepResult.primary && mounted;
    }

    // PHASE 1 : aucun provider sélectionné → introduire le choix inline.
    // Le coach mark unique pointe sur la liste de providers affichée dans le
    // body. Marqué via le drapeau dédié `firstCloudBackupPhase1` pour que le
    // tutoriel ne se redéclenche pas à chaque visite organique sans provider.
    // `firstCloudBackup` (phase 2) reste à false ici : phase 2 doit pouvoir
    // fire plus tard quand l'utilisateur sera authentifié.
    if (_cloudService.selectedProviderType == null) {
      // Si phase 1 a déjà été vue, ne rien faire (sauf cas onboarding force replay).
      final phase1Done = await OnboardingService.instance
          .isDiscoveryCompleted(DiscoveryTutorial.firstCloudBackupPhase1);
      if (phase1Done && !_pendingStartTutorial) {
        cleanup();
        await _completeAndMaybePop(markDiscoveryCompleted: false);
        return;
      }

      setState(() => _activeTargetKey = 'providerChooser');
      await CoachMarkSystem.showCoachStep(
        context: context,
        targetKey: _providerChooserKey,
        pulseController: _coachPulseController,
        title: 'Choisir un service cloud',
        message: 'Choisissez ici votre service cloud (Google Drive, OneDrive ou Dropbox) pour sauvegarder votre coffre.',
        primaryLabel: l10n.onboardingFinish,
        fullWidth: true,
        stepIndicator: '1 / 1',
      );
      cleanup();
      // Phase 1 vue (terminée ou skippée) : on la marque pour éviter le re-fire.
      await OnboardingService.instance.markDiscoveryCompleted(DiscoveryTutorial.firstCloudBackupPhase1);
      await _completeAndMaybePop(markDiscoveryCompleted: false);
      return;
    }

    // ENTRE-DEUX : provider choisi mais pas authentifié → aucun coach mark.
    // Le bouton "Se connecter à <provider>" parle de lui-même ; on laisse
    // l'utilisateur faire l'OAuth. Phase 2 démarrera à la prochaine visite
    // une fois authentifié (firstCloudBackup toujours non complété).
    if (!_isAuthenticated) {
      cleanup();
      await _completeAndMaybePop(markDiscoveryCompleted: false);
      return;
    }

    // PHASE 2 : authentifié → 4 étapes
    // Ordre : changer provider → auto-backup → liste des sauvegardes → bouton manuel.
    // Seule la complétion réelle de la 4/4 marque firstCloudBackup à true. Un
    // skip avant 4/4 laisse le drapeau à false pour permettre une nouvelle visite.
    final s1 = await step(
      targetKey: 'changeProvider',
      key: _changeProviderKey,
      title: 'Changer de provider',
      message: 'Vous pouvez changer de provider cloud à tout moment via cette icône.',
      stepIndicator: '1 / 4',
    );
    if (!s1) { cleanup(); await _completeAndMaybePop(markDiscoveryCompleted: false); return; }

    final s2 = await step(
      targetKey: 'autoBackup',
      key: _autoBackupKey,
      title: l10n.premiumTutorialAutoBackupTitle,
      message: l10n.premiumTutorialAutoBackupMessage,
      stepIndicator: '2 / 4',
    );
    if (!s2) { cleanup(); await _completeAndMaybePop(markDiscoveryCompleted: false); return; }

    final s3 = await step(
      targetKey: 'backups',
      key: _backupsListKey,
      title: 'Vos sauvegardes',
      message: 'Vos sauvegardes cloud récentes apparaissent ici. Vous pouvez les restaurer ou les supprimer.',
      stepIndicator: '3 / 4',
    );
    if (!s3) { cleanup(); await _completeAndMaybePop(markDiscoveryCompleted: false); return; }

    await step(
      targetKey: 'manualBackup',
      key: _manualBackupKey,
      title: 'Sauvegarde manuelle',
      message: 'Lancez une sauvegarde cloud immédiate à tout moment depuis ce bouton.',
      stepIndicator: '4 / 4',
      primaryLabel: l10n.onboardingFinish,
      secondaryLabel: null,
    );

    cleanup();
    // Seul site qui passe true : fin réelle de la branche B authentifiée.
    await _completeAndMaybePop(markDiscoveryCompleted: true);
  }

  /// Marque le tutoriel comme complété et pop la page si elle a été poussée
  /// avec `startTutorial: true` (replay depuis le tutoriel premium).
  /// En première visite organique, l'utilisateur reste sur la page.
  ///
  /// [markDiscoveryCompleted] : ne marquer le drapeau `firstCloudBackup` comme
  /// complété QUE quand la branche authentifiée a vraiment fini ses 4 coach
  /// marks. Pour la branche non-authentifiée (juste connect button) ou un skip
  /// précoce, on laisse le drapeau à `false` pour que l'utilisateur revoie le
  /// tutoriel complet la prochaine fois qu'il visitera la page (typiquement
  /// après s'être authentifié).
  Future<void> _completeAndMaybePop({required bool markDiscoveryCompleted}) async {
    if (markDiscoveryCompleted) {
      await OnboardingService.instance.markDiscoveryCompleted(DiscoveryTutorial.firstCloudBackup);
    }
    // Sécurité : si on arrive depuis la chaîne d'onboarding de base, on s'assure
    // que le statut global passe à `termine` quoi qu'il arrive.
    await OnboardingService.instance.markTutorialCompleted();
    if (_pendingStartTutorial && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _runAutoBackupOnlyTutorial() async {
    if (!_isAuthenticated || !mounted) {
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() { _isTutorialRunning = true; _activeTargetKey = 'autoBackup'; });
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _autoBackupKey,
      pulseController: _coachPulseController,
      title: l10n.premiumTutorialAutoBackupTitle,
      message: l10n.premiumTutorialAutoBackupMessage,
      primaryLabel: l10n.onboardingFinish,
      stepIndicator: '1 / 1',
    );
    if (mounted) setState(() { _isTutorialRunning = false; _activeTargetKey = null; });
    if (mounted) Navigator.pop(context);
  }

  // ─────────────────────────────────────────────────────────────────
  // Choix de provider inline (remplace l'ancienne CloudProviderSelectionPage)
  // ─────────────────────────────────────────────────────────────────

  /// Sauvegarde le provider choisi dans les prefs et re-initialise le service
  /// pour rebuild l'UI : `selectedProviderType` passe à non-null, ce qui fait
  /// disparaître la liste inline et apparaître le bouton Connect.
  Future<void> _pickProvider(CloudProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_cloud_provider', provider.name);
    await prefs.setBool('cloud_provider_selected', true);
    if (!mounted) return;
    // Reset le drapeau pour permettre une éventuelle re-évaluation du tutoriel
    // (typiquement pour fire la phase 2 après authentification ultérieure).
    _tutorialInitialized = false;
    await _initializeCloudService();
  }

  /// Scaffold complet quand aucun provider n'est sélectionné. Rend une liste
  /// de provider cards avec le coach mark phase 1 dessus.
  Widget _buildProviderChooserScaffold(AppLocalizations loc, ThemeData theme) {
    final providers = CloudBackupFactory.getAvailableProviders();
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.cloudBackup),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.cloudBackupTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.cloudProviderSelectionDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 24),
              CoachMarkSystem.buildHalo(
                key: _providerChooserKey,
                pulseController: _coachPulseController,
                isActive: _isTutorialRunning && _activeTargetKey == 'providerChooser',
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: providers
                      .map((p) => _buildInlineProviderCard(p, theme))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card pour un provider, dans la liste de choix inline. Tap = sélection
  /// immédiate (les providers non implémentés sont désactivés).
  Widget _buildInlineProviderCard(CloudProvider provider, ThemeData theme) {
    final isImplemented = provider.isImplemented;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isImplemented ? () => _pickProvider(provider) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: provider.brandColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  provider.icon,
                  size: 28,
                  color: provider.brandColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      provider.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (provider.tag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          provider.tag!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isImplemented)
                Icon(Icons.arrow_forward_ios, size: 16, color: theme.textTheme.bodySmall?.color),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeCloudService() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Aucun redirect vers une page séparée : si aucun provider n'est
      // sélectionné, le build() de cette page rendra une liste de choix
      // inline (état "no provider"). Le coach mark phase 1 du didacticiel
      // s'affiche alors directement sur cette liste.
      await _cloudService.initialize();

      // Initialiser le provider de vue (un seul provider supporté)
      _selectedViewProvider = _cloudService.selectedProviderType;
      _log('CloudBackupPage - Vue initialisée: ${_selectedViewProvider?.displayName ?? "aucun"}');

      // Le provider a déjà été sélectionné par l'utilisateur, pas besoin de forcer
      // Vérifier l'authentification
      _isAuthenticated = await _cloudService.isAuthenticated();

      // Si authentifié, charger les backups
      if (_isAuthenticated) {
        try {
          await _loadBackups();
          await _loadQuota();
        } catch (loadError) {
          // Si échec du chargement, re-vérifier l'authentification
          // (utile pour Android 7 avec race conditions)
          final stillAuth = await _cloudService.isAuthenticated();
          setState(() {
            _isAuthenticated = stillAuth;
            if (!stillAuth) {
              _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
            } else {
              _errorMessage = loadError.toString();
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      // Démarrer le tutoriel selon l'état courant :
      // - Phase 1 (no provider) : si firstCloudBackupPhase1 non encore complétée.
      // - Phase 2 (authentifié) : si firstCloudBackup non encore complétée.
      // - État "entre-deux" (provider mais pas auth) : aucun tutoriel.
      // - Force replay (`_pendingStartTutorial`) : on lance quand même.
      if (mounted && !_tutorialInitialized) {
        final phase1Done = await OnboardingService.instance
            .isDiscoveryCompleted(DiscoveryTutorial.firstCloudBackupPhase1);
        final phase2Done = await OnboardingService.instance
            .isDiscoveryCompleted(DiscoveryTutorial.firstCloudBackup);

        bool shouldRun = _pendingStartTutorial;
        if (!shouldRun) {
          if (_cloudService.selectedProviderType == null) {
            shouldRun = !phase1Done;
          } else if (_isAuthenticated) {
            shouldRun = !phase2Done;
          }
        }

        if (shouldRun && mounted) {
          _tutorialInitialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _runCloudBackupTutorial());
        } else if (_pendingStartTutorialAutoOnly && mounted) {
          _tutorialInitialized = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoBackupOnlyTutorial());
        }
      }
    }
  }

  Future<void> _loadBackups() async {
    try {
      final backups = await _cloudService.listBackups();
      setState(() {
        _backups = backups;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        // Si erreur liée à l'authentification, mettre à jour l'état
        if (e.toString().contains('Non authentifié') ||
            e.toString().contains('API Drive non initialisée') ||
            e.toString().contains('non authentifié')) {
          _isAuthenticated = false;
        }
      });
    }
  }

  Future<void> _loadQuota() async {
    try {
      final quota = await _cloudService.getQuota();
      setState(() {
        _quota = quota;
      });
    } catch (e) {
      // Quota non critique, ne pas afficher l'erreur
      _log('Failed to load quota: $e');
    }
  }

  /// Affiche un dialog de confirmation avant de changer de provider
  Future<bool?> _showSwitchProviderDialog(CloudProvider newProvider) async {
    final currentProvider = _cloudService.selectedProviderType;
    if (currentProvider == null) return true;

    final localizations = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.switchProviderTitle),
        content: Text(
          localizations.switchProviderMessage(
            currentProvider.displayName,
            newProvider.displayName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.confirm),
          ),
        ],
      ),
    );
  }

  /// Change le provider courant et tente l'authentification (modèle single-provider).
  /// Si l'utilisateur en avait déjà un autre, il est déconnecté avant.
  Future<void> _changeProvider(CloudProvider newProvider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Si un provider différent est déjà sélectionné, le déconnecter d'abord.
      if (_cloudService.selectedProviderType != null &&
          _cloudService.selectedProviderType != newProvider) {
        _log('CloudBackup - Déconnexion du provider précédent : ${_cloudService.selectedProviderType?.displayName}');
        await _cloudService.signOut();
      }

      await _cloudService.selectProvider(newProvider);

      setState(() {
        _selectedViewProvider = newProvider;
        _isAuthenticated = false;
        _backups = [];
        _quota = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Gère la sélection d'un provider via RadioButton (modèle single-provider).
  /// Sélectionne le provider + lance l'authentification immédiatement.
  Future<void> _handleProviderSelection(CloudProvider selectedProvider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Si un autre provider était sélectionné, le déconnecter
      if (_cloudService.selectedProviderType != null &&
          _cloudService.selectedProviderType != selectedProvider) {
        _log('CloudBackup - Déconnexion automatique de ${_cloudService.selectedProviderType?.displayName}');
        await _cloudService.signOut();
      }

      // Sélectionner et authentifier
      await _cloudService.selectProvider(selectedProvider);
      _log('CloudBackup - Sélection de ${selectedProvider.displayName}');

      final authenticated = await _cloudService.authenticate();

      if (authenticated) {
        setState(() {
          _selectedViewProvider = selectedProvider;
          _isAuthenticated = true;
        });

        await _loadBackups();
        await _loadQuota();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${selectedProvider.displayName} sélectionné et connecté'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Authentification ${selectedProvider.displayName} échouée';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _cloudService.authenticate();

      if (success) {
        setState(() {
          _isAuthenticated = true;
        });

        // Charger les backups après authentification
        await _loadBackups();
        await _loadQuota();

        // Auto-déclencher la phase 2 du tutoriel cloud si jamais elle n'a pas
        // encore été vue. On vient de passer en état authentifié sur la même
        // instance — sans cela, l'utilisateur devrait quitter et revenir pour
        // que le tutoriel se déclenche au prochain init.
        if (mounted && !_isTutorialRunning) {
          final phase2Done = await OnboardingService.instance
              .isDiscoveryCompleted(DiscoveryTutorial.firstCloudBackup);
          if (!phase2Done && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _runCloudBackupTutorial();
            });
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.cloudBackupSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.cloudAuthenticationFailed;
        });
      }
    } on PlatformException catch (e) {
      // Afficher un message d'erreur plus détaillé pour les erreurs de plateforme
      setState(() {
        if (e.code == 'sign_in_failed') {
          _errorMessage = '${AppLocalizations.of(context)!.cloudAuthenticationFailed}\n\n'
              'Erreur: Configuration OAuth manquante ou incorrecte.\n'
              'Vérifiez que les empreintes SHA sont ajoutées dans Firebase Console.';
        } else if (e.code == 'network_error') {
          _errorMessage = '${AppLocalizations.of(context)!.cloudAuthenticationFailed}\n\n'
              'Erreur: Problème de connexion réseau.\n'
              'Vérifiez votre connexion Internet.';
        } else if (e.code == 'sign_in_canceled') {
          _errorMessage = 'Authentification annulée';
        } else {
          _errorMessage = '${AppLocalizations.of(context)!.cloudAuthenticationFailed}\n\n'
              'Code: ${e.code}\n${e.message ?? ""}';
        }
      });
      // Log pour debug
      _log('PlatformException lors de l\'authentification:');
      _log('  Code: ${e.code}');
      _log('  Message: ${e.message}');
      _log('  Details: ${e.details}');
    } catch (e) {
      setState(() {
        // Afficher l'exception complète (y compris les messages détaillés du provider)
        final errorString = e.toString();
        // Si c'est une Exception avec message détaillé, l'afficher
        if (errorString.contains('Exception:')) {
          // Extraire le message après "Exception: "
          final match = RegExp(r'Exception:\s*(.+)').firstMatch(errorString);
          if (match != null) {
            _errorMessage = match.group(1)!.trim();
          } else {
            _errorMessage = errorString.replaceFirst('Exception: ', '');
          }
        } else {
          _errorMessage = '${AppLocalizations.of(context)!.cloudAuthenticationFailed}\n\n$e';
        }
      });
      // Log pour debug
      _log('Exception lors de l\'authentification:');
      _log('  Type: ${e.runtimeType}');
      _log('  Message: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    // Cas Google Drive : la sauvegarde Drive et la sync Premium partagent le
    // MÊME compte Google → on fait une déconnexion Google complète (révoque le
    // grant OAuth + coupe la sync). Cas OneDrive : la sync (Firebase, liée au
    // compte Google) est indépendante du backup OneDrive → on ne touche PAS à
    // Google/Firebase, on déconnecte uniquement le provider OneDrive.
    final isDrive = _cloudService.selectedProviderType == CloudProvider.googleDrive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.cloud_off, size: 48, color: Colors.orange),
        title: Text(isDrive ? l10n.cloudDisconnectTitle : l10n.cloudDisconnectGenericTitle),
        content: Text(isDrive ? l10n.cloudDisconnectMessage : l10n.cloudDisconnectGenericMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.cloudDisconnectConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (isDrive) {
        // Google Drive : la sync Premium et la backup Drive reposent sur le même
        // compte Google. On coupe la sync (Firebase signOut), on révoque le grant
        // OAuth (disconnect → le sélecteur réapparaîtra), on persiste le flag sync
        // à OFF. (OneDrive : on saute ce bloc, la sync Google reste intacte.)
        try {
          await FirebaseAuthService().signOut();
        } catch (e) {
          _log('CloudBackup - signOut Firebase (non bloquant): $e');
        }
        try {
          await GoogleSignInService.instance.disconnect();
        } catch (e) {
          _log('CloudBackup - disconnect Google (non bloquant): $e');
        }
        try {
          await SecureStorageService().setFirebaseSyncEnabled(false);
        } catch (e) {
          _log('CloudBackup - désactivation flag sync (non bloquant): $e');
        }
      }
      await _cloudService.disconnectCompletely();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sauvegarde cloud désactivée'),
          backgroundColor: Colors.orange,
        ),
      );

      // Pop pour revenir aux settings (le provider est désélectionné, on ne
      // peut plus afficher cette page utilement).
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadBackup() async {
    if (_vaultRepository == null || _auth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cloudNoAuthService),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier rate limiting
    final timeRemaining = _cloudService.getTimeUntilNextUpload();
    if (timeRemaining != null) {
      final minutes = timeRemaining.inMinutes + 1;
      final message = AppLocalizations.of(context)!.cloudRateLimitMessage(minutes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Demander le master password à l'utilisateur pour chiffrer le backup
      final masterPassword = await _askForMasterPassword(
        AppLocalizations.of(context)!.backupMasterPassword,
      );

      if (masterPassword == null || !mounted) return;

      // Lire les entrées et catégories
      final entries = await _vaultRepository!.readAll();
      final categoryService = CategoryService();
      await categoryService.initialize();
      final categories = categoryService.getAllCategories();

      _log('==================================================');
      _log('CloudBackup EXPORT - ${entries.length} entrées lues');
      _log('CloudBackup EXPORT - ${categories.length} catégories lues');
      _log('CloudBackup EXPORT - Catégories : ${categories.map((c) => c.name).join(", ")}');
      _log('==================================================');

      // Créer les données à exporter
      final exportData = {
        'entries': entries.map((e) => e.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };

      // Générer un salt aléatoire
      final saltBase64 = _crypto.generateSaltBase64();
      final salt = base64Decode(saltBase64);

      // Dériver la clé en isolate pour éviter de bloquer l'UI (600k iterations ~500ms)
      final key = await deriveKeyInIsolate(password: masterPassword, salt: salt);

      // Chiffrer les données
      final encryptedJson = _crypto.encryptJson(exportData, key);
      final encryptedMap = jsonDecode(encryptedJson) as Map<String, dynamic>;

      // Créer le backup payload chiffré
      final payload = BackupPayload(
        salt: base64Encode(salt),
        iv: encryptedMap['iv'] as String,
        ciphertext: encryptedMap['ciphertext'] as String,
        tag: encryptedMap['tag'] as String,
        exportedAt: DateTime.now(),
        entryCount: entries.length,
        iterations: CryptoService.defaultIterations, // Stocker iterations pour rétrocompatibilité
      );

      // Upload vers le cloud
      await _cloudService.uploadBackup(payload);

      // Nettoyer les anciennes sauvegardes (garde uniquement la plus récente)
      try {
        await _cloudService.cleanOldBackups();
      } catch (e) {
        _log('Failed to clean old backups: $e');
        // Ne pas bloquer le flux principal si la cleanup échoue
      }

      // Recharger la liste (en ignorant les erreurs d'auth)
      try {
        // Vérifier que l'utilisateur est toujours authentifié
        final stillAuthenticated = await _cloudService.isAuthenticated();
        if (stillAuthenticated) {
          await _loadBackups();
          setState(() {
            _isAuthenticated = true;
          });
        } else {
          // Token expiré après upload, mais upload a réussi
          setState(() {
            _isAuthenticated = false;
          });
        }
      } catch (loadError) {
        // Ignorer les erreurs de chargement de liste
        // L'upload a réussi, c'est le principal
        _log('Failed to reload backups after upload: $loadError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cloudBackupSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Erreur durant l'upload lui-même
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cloudBackupFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadBackup(CloudBackupMetadata backup) async {
    if (_vaultRepository == null || _auth == null) {
      return;
    }

    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.restoreFromCloud),
        content: Text(
          AppLocalizations.of(context)!.cloudRestoreConfirmation(
              backup.getFormattedDate(Localizations.localeOf(context).languageCode)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.restore),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      void log(String message) {
        if (kDebugMode) {
          _log(message);
        }
      }

      log('==================================================');
      log('CloudBackup - DÉBUT RESTAURATION');
      log('==================================================');

      // Demander le master password à l'utilisateur pour déchiffrer
      final masterPassword = await _askForMasterPassword(
        AppLocalizations.of(context)!.backupMasterPassword,
      );

      if (masterPassword == null || !mounted) {
        log('CloudBackup - ANNULÉ: Mot de passe non fourni ou widget démonté');
        return;
      }

      log('CloudBackup - [1/6] Mot de passe reçu');

      // Télécharger le backup chiffré (depuis le provider courant unique)
      log('CloudBackup - [2/6] Téléchargement du backup...');
      final payload = await _cloudService.downloadBackup(backup.id);
      log('CloudBackup - Backup téléchargé');

      // Dériver la clé avec fallback d'itérations pour récupérer les backups
      // dont le champ `iterations` peut être incohérent avec la clé réellement utilisée.
      log('CloudBackup - [3/6] Dérivation de la clé / tentative déchiffrement...');
      final salt = base64Decode(payload.salt);
      final encryptedJson = jsonEncode(payload.encryptedMap());
      log('CloudBackup - [4/6] Déchiffrement des données...');

      final candidateIterations = <int>[payload.iterations];
      if (!candidateIterations.contains(CryptoService.defaultIterations)) {
        candidateIterations.add(CryptoService.defaultIterations);
      }
      if (!candidateIterations.contains(150000)) {
        candidateIterations.add(150000);
      }
      log('RESTORE_ITER_CANDIDATES ${candidateIterations.join(",")}');

      Map<String, dynamic>? decrypted;
      Object? lastDecryptError;
      int? usedIterations;
      List<int>? successfulKey;
      for (final candidate in candidateIterations) {
        final deriveStart = DateTime.now();
        try {
          log('RESTORE_DERIVE_ISOLATE_START iterations=$candidate');
          final key = await deriveKeyInIsolate(
            password: masterPassword,
            salt: salt,
            iterations: candidate,
          );
          final deriveMs = DateTime.now().difference(deriveStart).inMilliseconds;
          log('RESTORE_DERIVE_ISOLATE_OK iterations=$candidate tookMs=$deriveMs');

          decrypted = _crypto.decryptToJson(encryptedJson, key);
          usedIterations = candidate;
          successfulKey = key;
          log('RESTORE_DECRYPT_OK iterations=$candidate');
          break;
        } catch (e) {
          lastDecryptError = e;
          log('RESTORE_DECRYPT_FAIL iterations=$candidate err=$e');
        }
      }

      if (decrypted == null) {
        throw lastDecryptError ?? Exception('DECRYPTION_FAILED');
      }
      log('CloudBackup - DÉCHIFFREMENT RÉUSSI');
      if (usedIterations == null) {
        throw Exception('RESTORE_INTERNAL_ERROR_NO_ITERATIONS');
      }
      if (successfulKey == null) {
        throw Exception('RESTORE_INTERNAL_ERROR_NO_KEY');
      }

      if (!decrypted.containsKey('entries')) {
        throw Exception('Aucune entrée trouvée dans la sauvegarde');
      }

      // Extraire les entrées
      final entriesList = decrypted['entries'];
      if (entriesList is! List) {
        throw Exception('Format invalide : "entries" doit être une liste');
      }

      final entries = entriesList
          .map((e) => PasswordEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      // Restaurer les catégories si elles existent
      log('==================================================');
      log('CloudBackup RESTORE - Vérification présence catégories dans backup...');

      if (decrypted.containsKey('categories')) {
        final categoriesList = decrypted['categories'];
        log('CloudBackup RESTORE - Catégories présentes');

        if (categoriesList is List && categoriesList.isNotEmpty) {
          log('CloudBackup RESTORE - Nombre de catégories trouvées: ${categoriesList.length}');

          final categoryService = CategoryService();
          await categoryService.initialize();

          final categories = categoriesList
              .map((c) => CustomCategory.fromJson(c as Map<String, dynamic>))
              .toList();

          log('CloudBackup RESTORE - Import catégories');

          // Import des catégories sauvegardées (même logique que import_export_page)
          final prefs = await SharedPreferences.getInstance();
          final jsonList = categories.map((c) => c.toJson()).toList();
          await prefs.setString('custom_categories', jsonEncode(jsonList));

          log('CloudBackup RESTORE - ${categories.length} catégories sauvegardées');
        } else {
          log('CloudBackup RESTORE - categoriesList vide ou invalide');
        }
      } else {
        log('CloudBackup RESTORE - Pas de clé "categories"');
      }
      log('==================================================');

      // RESTAURATION CLOUD : Importer les entrées dans le coffre ACTUEL
      // CRITIQUE: Ne JAMAIS modifier le salt du coffre actuel
      // Les entrées déchiffrées seront automatiquement re-chiffrées avec la clé actuelle

      log('==================================================');
      log('CloudBackup - DÉBUT IMPORT DES ENTRÉES');
      log('CloudBackup - Nombre d\'entrées à importer: ${entries.length}');
      log('==================================================');

      // Les entrées ont été déchiffrées avec le salt/mot de passe du backup
      // Maintenant on les sauvegarde avec saveAll() qui va automatiquement
      // les RE-CHIFFRER avec la clé actuelle du coffre (currentKey)
      log('CloudBackup - Sauvegarde de ${entries.length} entrées avec la clé actuelle du coffre...');
      final hadActiveSessionKey = _auth!.currentKey != null;
      log('RESTORE_SESSION_KEY_ACTIVE beforeSave=$hadActiveSessionKey');
      // CRITIQUE: Injecter la clé déchiffrée en mémoire pour permettre saveAll()
      // sans modifier le salt persistant du coffre.
      _auth!.setManualKey(
        successfulKey,
        payload.salt,
        iterations: usedIterations,
      );
      log('RESTORE_SET_MANUAL_KEY_OK iterations=$usedIterations');
      await _vaultRepository!.saveAll(entries);
      log('CloudBackup - ${entries.length} entrées sauvegardées avec succès');
      // IMPORTANT: saveAll() a utilisé la clé du backup (setManualKey juste avant).
      // On doit donc toujours persister le contexte associé à cette clé, sinon
      // le redémarrage peut retomber sur un état incohérent (première ouverture / clé invalide).
      await _auth!.secureStorage.saveSalt(payload.salt);
      await _auth!.secureStorage.saveKeyIterations(usedIterations);
      await _auth!.forceCreateValidationToken();
      await _auth!.secureStorage.setBiometryEnabled(false);
      log('RESTORE_PERSIST_CONTEXT_OK iterations=$usedIterations hadActiveSessionKey=$hadActiveSessionKey');
      log('==================================================');
      log('CloudBackup - IMPORT RÉUSSI');
      log('==================================================');

      log('CloudBackup - [6/6] Restauration terminée avec succès');
      log('==================================================');

      if (mounted) {
        // Afficher le dialogue de fermeture automatique (sans attendre de réponse)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            content: Text(
              AppLocalizations.of(context)!.restoreSuccessAutoClose,
              textAlign: TextAlign.center,
            ),
          ),
        );

        // Attendre 2 secondes avant de fermer l'application
        await Future.delayed(const Duration(seconds: 2));

        log('CloudBackup - Redirection contrôlée vers LoginPage...');
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginPage.route,
          (route) => false,
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        _log('==================================================');
        _log('CloudBackup - ERREUR DE RESTAURATION');
        _log('CloudBackup - Type: ${e.runtimeType}');
        _log('CloudBackup - Message: $e');
        _log('CloudBackup - Stack trace:');
        _log(stackTrace.toString());
        _log('==================================================');
      }
      // Vérifier si l'utilisateur est toujours authentifié après l'erreur
      try {
        final stillAuthenticated = await _cloudService.isAuthenticated();
        setState(() {
          _errorMessage = e.toString();
          _isAuthenticated = stillAuthenticated;
        });
      } catch (authCheckError) {
        // Erreur lors de la vérification d'auth → considérer comme déconnecté
        setState(() {
          _errorMessage = e.toString();
          _isAuthenticated = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getRestoreErrorMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBackup(CloudBackupMetadata backup) async {
    // Demander confirmation
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteBackup),
        content: Text(
          l10n.cloudDeleteConfirmation(
              backup.getFormattedDate(Localizations.localeOf(context).languageCode)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _cloudService.deleteBackup(backup.id);

      // Recharger la liste (en ignorant les erreurs d'auth)
      try {
        final stillAuthenticated = await _cloudService.isAuthenticated();
        if (stillAuthenticated) {
          await _loadBackups();
          setState(() {
            _isAuthenticated = true;
          });
        } else {
          setState(() {
            _isAuthenticated = false;
          });
        }
      } catch (loadError) {
        // Ignorer les erreurs de chargement de liste
        // La suppression a réussi, c'est le principal
        _log('Failed to reload backups after delete: $loadError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cloudBackupDeleted),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      // Erreur durant la suppression elle-même
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cloudDeleteFailed(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Demande le master password à l'utilisateur (pour chiffrement/déchiffrement)
  /// Note: Ne valide PAS le mot de passe (validation se fait lors du déchiffrement)
  Future<String?> _askForMasterPassword(String title) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    final password = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                autofocus: true,
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, passwordController.text);
                }
              },
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ],
        ),
      ),
    );

    passwordController.dispose();
    return password;
  }

  /// Retourne un message d'erreur convivial pour les erreurs de restauration
  String _getRestoreErrorMessage(dynamic e) {
    final errorString = e.toString();

    // Vérifier si c'est une erreur de déchiffrement (mot de passe incorrect)
    if (errorString.contains('DECRYPTION_FAILED') ||
        errorString.contains('InvalidCipherTextException')) {
      return AppLocalizations.of(context)!.incorrectBackupPassword;
    }

    // Autres erreurs : utiliser le message générique
    return AppLocalizations.of(context)!.cloudRestoreFailed(errorString);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    // État "no provider" : la liste de choix est rendue inline dans le body
    // de cette même page, en remplacement du redirect vers une page séparée.
    if (_cloudService.selectedProviderType == null && !_isLoading) {
      return _buildProviderChooserScaffold(localizations, theme);
    }

    return Scaffold(
      appBar: AppBar(
        title: CoachMarkSystem.buildHalo(
          key: _providerNameKey,
          pulseController: _coachPulseController,
          isActive: _activeTargetKey == 'providerName',
          child: Text(
            _selectedViewProvider != null
                ? '${localizations.cloudBackup} : ${_selectedViewProvider!.displayName}'
                : localizations.cloudBackup,
          ),
        ),
        actions: [
          // Sélecteur de provider (toujours visible si provider sélectionné)
          if (_cloudService.selectedProviderType != null)
            CoachMarkSystem.buildHalo(
              key: _changeProviderKey,
              pulseController: _coachPulseController,
              isActive: _isTutorialRunning && _activeTargetKey == 'changeProvider',
              borderRadius: BorderRadius.circular(24),
              child: PopupMenuButton<CloudProvider>(
              icon: FaIcon(
                (_selectedViewProvider ?? _cloudService.selectedProviderType)?.icon ?? Icons.cloud,
                color: (_selectedViewProvider ?? _cloudService.selectedProviderType)?.brandColor ?? Colors.blue,
              ),
              tooltip: localizations.selectCloudProvider,
              onSelected: (provider) async {
                // Modèle single-provider : changement avec confirmation si différent.
                if (provider != _selectedViewProvider) {
                  final confirmed = await _showSwitchProviderDialog(provider);
                  if (confirmed == true) {
                    await _changeProvider(provider);
                  }
                }
              },
              itemBuilder: (context) {
                return CloudBackupFactory.getAvailableProviders()
                  .map((provider) {
                    final isActive = _cloudService.selectedProviderType == provider;
                    final isCurrentView = provider == _selectedViewProvider;

                    return PopupMenuItem(
                      value: provider,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            provider.icon,
                            color: provider.brandColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(provider.displayName)),
                          // Badge "Actif" si le provider est sélectionné
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Actif',
                                style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          // Œil pour la vue actuellement affichée
                          if (isCurrentView) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.visibility, size: 16, color: Colors.blue),
                          ],
                        ],
                      ),
                    );
                  })
                  .toList();
              },
            ),
            ), // fin buildHalo changeProvider
          // Bouton déconnexion (si authentifié)
          if (_isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: localizations.signOut,
              onPressed: _signOut,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAuthenticated
              ? _buildAuthenticationView(localizations)
              : _buildBackupsListView(localizations, locale, theme),
      floatingActionButton: _isAuthenticated && !_isLoading
          ? CoachMarkSystem.buildHalo(
              key: _manualBackupKey,
              pulseController: _coachPulseController,
              isActive: _isTutorialRunning && _activeTargetKey == 'manual',
              borderRadius: BorderRadius.circular(32),
              child: FloatingActionButton.extended(
                onPressed: _uploadBackup,
                icon: const Icon(Icons.cloud_upload),
                label: Text(localizations.uploadToCloud),
              ),
            )
          : null,
    );
  }

  Widget _buildAuthenticationView(AppLocalizations localizations) {
    final currentProvider = _cloudService.currentProvider;
    final currentProviderType = _cloudService.selectedProviderType;
    final availableProviders = CloudBackupFactory.getAvailableProviders();
    final isPremium = PremiumService().isPremium;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône du provider avec branding dynamique
            if (currentProvider != null)
              Icon(
                currentProvider.providerIcon,
                size: 80,
                color: currentProvider.providerColor.withValues(alpha: 0.5),
              )
            else
              Icon(
                Icons.cloud_off,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
            const SizedBox(height: 24),
            Text(
              localizations.selectCloudProvider,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.cloudBackupSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // VERSION GRATUITE : Dropdown avec 1 seul provider actif
            if (!isPremium && availableProviders.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: DropdownButton<CloudProvider>(
                  value: currentProviderType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: availableProviders.map((provider) {
                    return DropdownMenuItem(
                      value: provider,
                      child: Row(
                        children: [
                          Icon(
                            provider.icon,
                            color: provider.brandColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            provider.displayName,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newProvider) async {
                    if (newProvider != null && newProvider != currentProviderType) {
                      await _changeProvider(newProvider);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
            // VERSION PREMIUM : RadioButtons pour sélection unique de provider
            if (isPremium && availableProviders.length > 1) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Premium - Sélection du provider',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choisissez 1 seul provider pour la sauvegarde automatique',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...availableProviders.map((provider) {
                      final isActive = _cloudService.selectedProviderType == provider;
                      final currentActiveProvider = _cloudService.selectedProviderType;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? provider.brandColor.withValues(alpha: 0.05)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? provider.brandColor.withValues(alpha: 0.3)
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: RadioListTile<CloudProvider>(
                          value: provider,
                          groupValue: currentActiveProvider,
                          onChanged: (selectedProvider) async {
                            if (selectedProvider != null) {
                              await _handleProviderSelection(selectedProvider);
                            }
                          },
                          title: Row(
                            children: [
                              Icon(
                                provider.icon,
                                color: provider.brandColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(provider.displayName),
                              ),
                              // Badge de statut (connecté / non connecté)
                              if (isActive)
                                FutureBuilder<bool>(
                                  future: _cloudService.isAuthenticated(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      );
                                    }

                                    final isAuthenticated = snapshot.data ?? false;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAuthenticated
                                            ? Colors.green.withValues(alpha: 0.2)
                                            : Colors.orange.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isAuthenticated ? Icons.check_circle : Icons.warning,
                                            size: 14,
                                            color: isAuthenticated ? Colors.green : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isAuthenticated ? 'Connecté' : 'Non connecté',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isAuthenticated ? Colors.green : Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Bouton d'authentification avec branding dynamique
            if (currentProvider != null)
              CoachMarkSystem.buildHalo(
                key: _connectButtonKey,
                pulseController: _coachPulseController,
                isActive: _isTutorialRunning && _activeTargetKey == 'connect',
                borderRadius: BorderRadius.circular(8),
                child: Builder(
                  builder: (context) {
                    // Single-provider : texte avec nom du provider courant.
                    final buttonText = localizations.authenticateWith(
                      currentProviderType?.displayName ?? 'Cloud',
                    );
                    final buttonColor = currentProvider.providerColor;

                    return FilledButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.login),
                      label: Text(buttonText),
                      style: FilledButton.styleFrom(
                        backgroundColor: buttonColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Afficher le message d'erreur uniquement si aucun backup n'est visible
            // Si des backups sont visibles, le provider est authentifié (erreur temporaire ignorée)
            if (_errorMessage != null && _backups.isEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackupsListView(
    AppLocalizations localizations,
    String locale,
    ThemeData theme,
  ) {
    return Column(
      children: [
        // Avertissement Android < 8.0
        if (_isAndroidBelowOreo)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.androidVersionWarningTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.androidVersionWarningMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Quota info (si disponible)
        if (_quota != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cloudService.currentProvider?.providerName ?? 'Cloud Storage',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${CloudQuota.formatBytes(_quota!.usedBytes)} / ${CloudQuota.formatBytes(_quota!.totalBytes)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Toggle sauvegarde automatique (Premium uniquement)
        CoachMarkSystem.buildHalo(
          key: _autoBackupKey,
          pulseController: _coachPulseController,
          isActive: _isTutorialRunning && _activeTargetKey == 'autoBackup',
          borderRadius: BorderRadius.circular(12),
          child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: FutureBuilder<bool>(
            future: _cloudService.isAutoBackupEnabled(),
            builder: (context, snapshot) {
              final isAutoBackupEnabled = snapshot.data ?? false;
              final isPremium = PremiumService().isPremium;

              return SwitchListTile(
                value: isAutoBackupEnabled,
                onChanged: (value) async {
                  // Vérifier Premium si activation demandée
                  if (value && !isPremium) {
                    if (!context.mounted) return;
                    await showPremiumLockedDialog(
                      context,
                      featureName: 'Sauvegardes automatiques cloud',
                      customMessage:
                          'Les sauvegardes automatiques cloud sont une fonctionnalité Premium. '
                          'Passez à Premium pour bénéficier d\'un historique automatique de vos données sur ${_cloudService.currentProvider?.providerName ?? 'le cloud'}.',
                    );
                    return;
                  }

                  await _cloudService.setAutoBackupEnabled(value);

                  // Si activé, déclencher l'authentification immédiatement
                  if (value) {
                    final success = await _cloudService.authenticateIfAutoBackupEnabled();
                    if (!success) {
                      // Si l'authentification échoue, désactiver l'auto backup
                      await _cloudService.setAutoBackupEnabled(false);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur de connexion à ${_cloudService.currentProvider?.providerName ?? 'cloud'}. Veuillez réessayer.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      setState(() {});
                      return;
                    }
                  }

                  setState(() {}); // Refresh pour afficher la nouvelle valeur

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Sauvegardes automatiques ${_cloudService.currentProvider?.providerName ?? 'cloud'} activées'
                            : 'Sauvegardes automatiques désactivées',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                title: Row(
                  children: [
                    const Expanded(child: Text('Sauvegardes automatiques')),
                    if (!isPremium) const PremiumBadge(),
                  ],
                ),
                subtitle: Text(
                  isAutoBackupEnabled
                      ? 'Backup automatique après chaque modification'
                      : isPremium
                          ? 'Aucune sauvegarde automatique'
                          : 'Premium requis',
                  style: TextStyle(
                    color: !isPremium && !isAutoBackupEnabled
                        ? Colors.orange
                        : null,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.cloud_sync,
                  color: isAutoBackupEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              );
            },
          ),
        ),
        ), // fin buildHalo autoBackup

        // Error message (uniquement si aucun backup visible)
        if (_errorMessage != null && _backups.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),

        // Liste des backups (clé de tutoriel ici : couvre uniquement la liste, pas le FAB)
        Expanded(
          child: CoachMarkSystem.buildHalo(
            key: _backupsListKey,
            pulseController: _coachPulseController,
            isActive: _isTutorialRunning && _activeTargetKey == 'backups',
            borderRadius: BorderRadius.circular(12),
            child: _backups.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            size: 64,
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.noCloudBackups,
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations.cloudNoBackupsHint,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadBackups,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _backups.length,
                      itemBuilder: (context, index) {
                        final backup = _backups[index];
                        return _buildBackupCard(backup, locale, theme, localizations);
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupCard(
    CloudBackupMetadata backup,
    String locale,
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showBackupActions(backup, localizations),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.backup,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Afficher nombre d'entrées + date (comme les sauvegardes locales)
                    Text(
                      backup.entryCount != null && backup.entryCount! > 0
                          ? '${backup.entryCount} ${backup.entryCount! > 1 ? localizations.backupEntries : localizations.backupEntry} • ${backup.getFormattedDate(locale)}'
                          : backup.getFormattedDate(locale),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.storage,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          backup.formattedSize,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions rapides
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: localizations.downloadBackup,
                    onPressed: () => _downloadBackup(backup),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: localizations.deleteBackup,
                    color: Colors.red,
                    onPressed: () => _deleteBackup(backup),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBackupActions(CloudBackupMetadata backup, AppLocalizations localizations) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(localizations.downloadBackup),
              onTap: () {
                Navigator.pop(context);
                _downloadBackup(backup);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                localizations.deleteBackup,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteBackup(backup);
              },
            ),
          ],
        ),
      ),
    );
  }
}

