import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/password_entry.dart';
import '../models/backup_payload.dart';
import '../models/custom_category.dart';
import '../services/auth_service.dart';
import '../services/backup_repository.dart';
import '../services/vault_repository.dart';
import '../services/crypto_service.dart';
import '../services/crypto_isolate.dart';
import '../services/auto_close_service.dart';
import '../services/category_service.dart';
import '../services/premium_service.dart';
import '../services/sync_coordinator_service.dart';
import '../widgets/coach_mark_system.dart';
import '../widgets/premium_badge.dart';
import '../app/app.dart';
import 'login_page.dart';
import 'premium_page.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key, this.startTutorial = false});
  static const String route = '/import-export';
  static final ValueNotifier<bool> localAutoBackupNotifier = ValueNotifier<bool>(false);
  final bool startTutorial;

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage>
    with SingleTickerProviderStateMixin {
  late final VaultRepository _repo;
  late final CryptoService _crypto;
  late final BackupRepository _backupRepo;
  List<LocalBackup> _localBackups = [];
  List<LocalBackup> _snapshotBackups = [];
  bool _isLoading = false;
  bool _exportOnly = false;
  bool _argsInitialized = false;

  // Auto-backup local
  bool _localAutoBackupEnabled = false;
  final _autoBackupSwitchKey = GlobalKey();

  // Tutorial
  late final AnimationController _coachPulseController;
  bool _isTutorialRunning = false;
  String? _activeTargetKey;
  final _exportButtonKey = GlobalKey();
  final _backupsListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _crypto = CryptoService();
    _backupRepo = BackupRepository();
    _loadLocalBackups();
    _loadLocalAutoBackupSetting();

    _coachPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsInitialized) return;
    _argsInitialized = true;

    // Récupérer l'AuthService depuis les arguments de route
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    AuthService? auth;

    bool startTutorialFromRoute = false;
    bool startTutorialAutoBackupFromRoute = false;
    if (routeArgs is AuthService) {
      auth = routeArgs;
    } else if (routeArgs is Map<String, dynamic>) {
      auth = routeArgs['authService'] as AuthService?;
      _exportOnly = routeArgs['mode'] == 'exportOnly';
      startTutorialFromRoute = routeArgs['startTutorial'] == true;
      startTutorialAutoBackupFromRoute = routeArgs['startTutorialAutoBackup'] == true;
    }

    if (auth != null) {
      _repo = VaultRepository(auth);
    }

    if ((widget.startTutorial || startTutorialFromRoute) && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runImportExportTutorial();
      });
    } else if (startTutorialAutoBackupFromRoute && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runAutoBackupTutorial();
      });
    }
  }

  @override
  void dispose() {
    _coachPulseController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalAutoBackupSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('local_auto_backup_enabled') ?? false;
    ImportExportPage.localAutoBackupNotifier.value = value;
    SyncCoordinatorService.localBackupStateNotifier.value =
        value ? LocalBackupState.idle : LocalBackupState.disabled;
    if (mounted) {
      setState(() {
        _localAutoBackupEnabled = value;
      });
    }
  }

  Future<void> _toggleLocalAutoBackup(bool value) async {
    if (!PremiumService().isPremium) {
      await showPremiumLockedDialog(
        context,
        featureName: 'Sauvegarde locale automatique',
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('local_auto_backup_enabled', value);
    ImportExportPage.localAutoBackupNotifier.value = value;
    SyncCoordinatorService.localBackupStateNotifier.value =
        value ? LocalBackupState.idle : LocalBackupState.disabled;
    if (mounted) setState(() => _localAutoBackupEnabled = value);
  }

  Future<void> _runAutoBackupTutorial() async {
    setState(() { _isTutorialRunning = true; _activeTargetKey = 'autoBackup'; });
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _autoBackupSwitchKey,
      pulseController: _coachPulseController,
      title: l10n.premiumTutorialLocalBackupTitle,
      message: l10n.premiumTutorialLocalBackupMessage,
      primaryLabel: l10n.onboardingFinish,
      fullWidth: true,
      stepIndicator: '1 / 1',
    );

    if (mounted) setState(() { _isTutorialRunning = false; _activeTargetKey = null; });
    if (mounted) Navigator.pop(context);
  }

  Future<void> _runImportExportTutorial() async {
    setState(() => _isTutorialRunning = true);
    final l10n = AppLocalizations.of(context)!;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Étape 1 : Export
    setState(() => _activeTargetKey = 'export');
    final step1 = await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _exportButtonKey,
      pulseController: _coachPulseController,
      title: l10n.discoveryBackupLocalTitle,
      message: l10n.discoveryBackupLocalMessage,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '1 / 2',
    );

    if (step1 != CoachStepResult.primary || !mounted) {
      setState(() {
        _isTutorialRunning = false;
        _activeTargetKey = null;
      });
      if (mounted) Navigator.pop(context);
      return;
    }

    // Étape 2 : Liste des sauvegardes
    setState(() => _activeTargetKey = 'backups');
    await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _backupsListKey,
      pulseController: _coachPulseController,
      title: l10n.myLocalBackups,
      message: "Les sauvegardes locales permettent de restaurer les données en cas de besoin. Elles sont stockées sur cet appareil.",
      primaryLabel: l10n.onboardingFinish,
      fullWidth: true,
      stepIndicator: '2 / 2',
    );

    setState(() {
      _isTutorialRunning = false;
      _activeTargetKey = null;
    });
    if (mounted) Navigator.pop(context);
  }

  Future<void> _loadLocalBackups() async {
    final backups = await _backupRepo.listLocalBackups();
    final snapshots = await _backupRepo.listSnapshotBackups();
    if (mounted) {
      setState(() {
        _localBackups = backups;
        _snapshotBackups = snapshots;
      });
    }
  }

  /// Importe les catégories depuis une sauvegarde
  /// Remplace toutes les catégories actuelles par celles de la sauvegarde
  Future<void> _importCategories(CategoryService categoryService, List<CustomCategory> categories) async {
    // Sauvegarder directement les catégories importées dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = categories.map((cat) => cat.toJson()).toList();
    await prefs.setString('custom_categories', jsonEncode(jsonList));
    debugPrint('Catégories sauvegardées dans SharedPreferences : ${categories.length} catégories');
  }

  /// Construit le `BackupPayload` chiffré à partir de l'état courant du coffre.
  /// N'écrit rien sur disque — c'est au caller de décider du devenir du payload.
  Future<BackupPayload> _buildEncryptedPayload() async {
    final entries = await _repo.readAll();
    final key = _repo.auth.currentKey;
    if (key == null) throw Exception('Coffre verrouillé');

    final salt = await _repo.auth.secureStorage.readSalt();
    if (salt == null) {
      throw Exception('Sel introuvable - impossible de générer la sauvegarde');
    }

    final categoryService = CategoryService();
    final categories = categoryService.getAllCategories();

    final exportData = {
      'entries': entries.map((e) => e.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    final encryptedJson = _crypto.encryptJson(exportData, key);
    final encryptedMap = jsonDecode(encryptedJson) as Map<String, dynamic>;

    return BackupPayload(
      salt: salt,
      iv: encryptedMap['iv'] as String,
      ciphertext: encryptedMap['ciphertext'] as String,
      tag: encryptedMap['tag'] as String,
      exportedAt: DateTime.now(),
      entryCount: entries.length,
      // CRITIQUE: stocker les VRAIES itérations utilisées pour dériver la clé
      // de session (sinon le restore re-dériverait avec un mauvais nombre).
      iterations: _repo.auth.currentKeyIterations ?? CryptoService.defaultIterations,
    );
  }

  /// Exporter vers un fichier (partage natif via la share sheet).
  Future<void> _exportVault() async {
    setState(() => _isLoading = true);
    try {
      final payload = await _buildEncryptedPayload();
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'passkeyra_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(payload.toJsonString());

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json', name: fileName)],
        text: 'Sauvegarde PassKeyra',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Crée une sauvegarde locale dans le stockage de l'app (max 1 conservée).
  Future<void> _saveLocalBackup() async {
    setState(() => _isLoading = true);
    try {
      final payload = await _buildEncryptedPayload();
      await _backupRepo.saveLocalBackup(payload);
      if (!mounted) return;
      await _loadLocalBackups();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.exportSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmAndDeleteBackup(LocalBackup backup) async {
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: PassKeyraColors.error, size: 48),
        title: Text(l10n.deleteCategory),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.deleteEntryMessage),
                const SizedBox(height: 16),
                Text(
                  l10n.deleteEntryConfirm,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: confirmController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.deleteKeyword.toLowerCase(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.toLowerCase() != l10n.deleteKeyword.toLowerCase()) {
                      return l10n.deleteEntryConfirm;
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
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: PassKeyraColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    confirmController.dispose();

    if (confirmed == true) {
      await _backupRepo.deleteBackup(backup);
      await _loadLocalBackups();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deleteSuccess),
          backgroundColor: PassKeyraColors.success,
        ),
      );
    }
  }

  void _showSecurityInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.security, color: PassKeyraColors.primary, size: 48),
        title: Text(l10n.security),
        content: Text(l10n.exportWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.understood),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreFromBackup(LocalBackup backup) async {
    final l10n = AppLocalizations.of(context)!;
    // Afficher un dialogue de confirmation car cela va écraser toutes les données actuelles
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: PassKeyraColors.warning, size: 48),
        title: Text(l10n.restoreFromBackup),
        content: Text(l10n.importWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: PassKeyraColors.warning),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
              child: Form(
                key: formKey,
                child: TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
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

    if (password == null || !mounted) return;

    try {
      setState(() => _isLoading = true);

      // Lire le contenu de la sauvegarde (avec validation de taille)
      final content = await readBackupFileSafe(File(backup.filePath));
      final raw = jsonDecode(content) as Map<String, dynamic>;

      final payload = BackupPayload.fromJson(raw);

      final salt = base64Decode(payload.salt);
      final encryptedJson = jsonEncode(payload.encryptedMap());

      // Fallback d'itérations : essaye `payload.iterations`, puis 600k, puis 150k.
      // Mirror du flux cloud restore — tolère les backups dont le champ
      // `iterations` ne reflète pas exactement les itérations utilisées pour
      // chiffrer (anciennes versions du code, etc.).
      final candidateIterations = <int>[payload.iterations];
      if (!candidateIterations.contains(CryptoService.defaultIterations)) {
        candidateIterations.add(CryptoService.defaultIterations);
      }
      if (!candidateIterations.contains(150000)) {
        candidateIterations.add(150000);
      }

      Map<String, dynamic>? decrypted;
      List<int>? key;
      int? usedIterations;
      Object? lastDecryptError;
      for (final candidate in candidateIterations) {
        try {
          final candidateKey = await deriveKeyInIsolate(
            password: password,
            salt: salt,
            iterations: candidate,
          );
          decrypted = _crypto.decryptToJson(encryptedJson, candidateKey);
          key = candidateKey;
          usedIterations = candidate;
          break;
        } catch (e) {
          lastDecryptError = e;
        }
      }

      if (decrypted == null || key == null || usedIterations == null) {
        throw lastDecryptError ?? Exception('DECRYPTION_FAILED');
      }

      if (!decrypted.containsKey('entries')) {
        throw Exception('Aucune entrée trouvée dans la sauvegarde');
      }

      final entriesList = decrypted['entries'];
      if (entriesList is! List) {
        throw Exception('Format invalide : "entries" doit être une liste');
      }

      final entries = entriesList
          .map((e) => PasswordEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      // CORRECTION: Restaurer les catégories si elles existent dans la sauvegarde
      if (decrypted.containsKey('categories')) {
        final categoriesList = decrypted['categories'];
        if (categoriesList is List && categoriesList.isNotEmpty) {
          final categoryService = CategoryService();
          await categoryService.initialize();

          // Importer les catégories depuis la sauvegarde
          final categories = categoriesList
              .map((c) => CustomCategory.fromJson(c as Map<String, dynamic>))
              .toList();

          // Sauvegarder les catégories importées
          await _importCategories(categoryService, categories);
          debugPrint('Restauration - ${categories.length} catégories importées');
        }
      }

      // Réutiliser l'AuthService déjà résolu dans didChangeDependencies
      // (gère AuthService direct ET Map<String, dynamic> en arguments).
      final auth = _repo.auth;

      // RESTAURATION : Transaction atomique pour éviter salt écrasé avec coffre vide
      // CRITIQUE: Le salt ne doit être écrasé QUE si l'import réussit complètement

      debugPrint('==================================================');
      debugPrint('Restauration - DÉBUT TRANSACTION ATOMIQUE');
      debugPrint('Restauration - Nombre d\'entrées à importer: ${entries.length}');
      debugPrint('==================================================');

      // 1. Sauvegarder l'ancien salt (pour rollback en cas d'erreur)
      debugPrint('Restauration - [ÉTAPE 1/7] Lecture de l\'ancien salt...');
      final oldSalt = await auth.secureStorage.readSalt();
      debugPrint('Restauration - Ancien salt lu: ${oldSalt != null ? "OUI (longueur: ${oldSalt.length})" : "AUCUN"}');

      try {
        // 2. Définir manuellement la clé de session SANS écraser le salt dans le storage
        // Cette clé a été calculée plus haut avec deriveKeyInIsolate(password, salt)
        // setManualKey() définit seulement _currentKey en mémoire, ne touche PAS au storage
        debugPrint('Restauration - [ÉTAPE 2/7] Définition manuelle de la clé de session (EN MÉMOIRE UNIQUEMENT)...');
        auth.setManualKey(
          key,
          payload.salt,
          iterations: usedIterations,
        );
        debugPrint('Restauration - Clé définie en mémoire (salt du backup: ${payload.salt.length} chars)');

        // Vérifier que le salt dans le storage n'a PAS changé
        final saltCheck1 = await auth.secureStorage.readSalt();
        debugPrint('Restauration - VÉRIFICATION: Salt dans storage = ${saltCheck1 == oldSalt ? "INCHANGÉ " : "MODIFIÉ "}');

        // 3. Importer les entrées AVANT d'écraser le salt
        // Si ça échoue ici, le salt ne sera PAS écrasé
        debugPrint('Restauration - [ÉTAPE 3/7] Sauvegarde de ${entries.length} entrées (transaction atomique)...');
        final repo = VaultRepository(auth);
        await repo.saveAll(entries);
        debugPrint('Restauration - ${entries.length} entrées sauvegardées avec succès dans Hive');

        // Vérifier que le salt n'a toujours PAS changé
        final saltCheck2 = await auth.secureStorage.readSalt();
        debugPrint('Restauration - VÉRIFICATION: Salt dans storage = ${saltCheck2 == oldSalt ? "TOUJOURS INCHANGÉ " : "MODIFIÉ PAR SAVEALL "}');

        // 4. SEULEMENT maintenant qu'on est sûr que tout a réussi, écraser le salt
        debugPrint('Restauration - [ÉTAPE 4/7] Écriture du NOUVEAU salt dans le stockage sécurisé...');
        await auth.secureStorage.saveSalt(payload.salt);
        // Persister aussi les itérations pour que les futurs unlocks utilisent la bonne valeur
        // au premier essai (et ne déclenchent pas la boucle de fallback PBKDF2 = double dérivation).
        await auth.secureStorage.saveKeyIterations(usedIterations);
        final saltCheck3 = await auth.secureStorage.readSalt();
        debugPrint('Restauration - Nouveau salt écrit: ${saltCheck3 == payload.salt ? "OK " : "ÉCHEC "}');

        // 5. Créer le token de validation avec la nouvelle clé
        debugPrint('Restauration - [ÉTAPE 5/7] Création du token de validation...');
        await auth.forceCreateValidationToken();
        debugPrint('Restauration - Token de validation créé');

        // 6. Désactiver automatiquement la biométrie après restauration
        debugPrint('Restauration - [ÉTAPE 6/7] Désactivation de la biométrie...');
        await auth.secureStorage.setBiometryEnabled(false);
        debugPrint('Restauration - Biométrie désactivée');

        // 7. Vérification finale
        debugPrint('Restauration - [ÉTAPE 7/7] Vérification finale...');
        final finalSalt = await auth.secureStorage.readSalt();
        debugPrint('Restauration - Salt final = ${finalSalt == payload.salt ? "BACKUP SALT " : "AUTRE "}');
        debugPrint('==================================================');
        debugPrint('Restauration - TRANSACTION ATOMIQUE RÉUSSIE');
        debugPrint('==================================================');

      } catch (e, stackTrace) {
        // ROLLBACK: Restaurer l'ancien salt si l'import a échoué
        debugPrint('==================================================');
        debugPrint('Restauration - ERREUR DURANT LA TRANSACTION');
        debugPrint('Restauration - Type d\'erreur: ${e.runtimeType}');
        debugPrint('Restauration - Message: $e');
        debugPrint('Restauration - Stack trace: $stackTrace');
        debugPrint('==================================================');

        if (oldSalt != null) {
          debugPrint('Restauration - DÉBUT ROLLBACK: Restauration de l\'ancien salt...');
          await auth.secureStorage.saveSalt(oldSalt);
          final saltAfterRollback = await auth.secureStorage.readSalt();
          debugPrint('Restauration - Rollback terminé: ${saltAfterRollback == oldSalt ? "SUCCÈS " : "ÉCHEC "}');
        } else {
          debugPrint('Restauration - ROLLBACK IGNORÉ: Aucun ancien salt à restaurer');
        }

        debugPrint('==================================================');
        debugPrint('Restauration - RELANCEMENT DE L\'EXCEPTION VERS LE BLOC CATCH PARENT');
        debugPrint('==================================================');

        // Relancer l'exception pour que le bloc catch parent la gère
        rethrow;
      }

      if (!mounted) return;

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

      Navigator.of(context).pushNamedAndRemoveUntil(
        LoginPage.route,
        (route) => false,
      );

    } catch (e) {
      debugPrint('Erreur lors de la restauration : $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getRestoreErrorMessage(e)),
          backgroundColor: PassKeyraColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    return AppLocalizations.of(context)!.importFailed(errorString);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_exportOnly) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.localBackupTitle),
        ),
        body: GestureDetector(
          onTap: () => AutoCloseService.instance.onUserActivity(),
          onPanStart: (_) => AutoCloseService.instance.onUserActivity(),
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.export,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.exportSubtitle),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _exportVault,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload),
                      label: Text(l10n.exportButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.localBackupTitle),
      ),
      body: GestureDetector(
        onTap: () => AutoCloseService.instance.onUserActivity(),
        onPanStart: (_) => AutoCloseService.instance.onUserActivity(),
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            CoachMarkSystem.buildHalo(
              key: _autoBackupSwitchKey,
              pulseController: _coachPulseController,
              isActive: _isTutorialRunning && _activeTargetKey == 'autoBackup',
              borderRadius: BorderRadius.circular(12),
              child: Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.phone_android_outlined),
                  title: Row(
                    children: [
                      const Expanded(child: Text('Sauvegarde locale automatique')),
                      if (!PremiumService().isPremium) const PremiumBadge(),
                    ],
                  ),
                  subtitle: const Text('Sauvegarde sur cet appareil à chaque modification du coffre'),
                  value: _localAutoBackupEnabled,
                  onChanged: _toggleLocalAutoBackup,
                ),
              ),
            ),
            const SizedBox(height: 12),
            CoachMarkSystem.buildHalo(
              key: _backupsListKey,
              pulseController: _coachPulseController,
              isActive: _isTutorialRunning && _activeTargetKey == 'backups',
              borderRadius: BorderRadius.circular(12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.myLocalBackups,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline, size: 20),
                            onPressed: () => _showSecurityInfo(context),
                            tooltip: l10n.security,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_localBackups.isEmpty)
                        Text(l10n.noLocalBackup),
                      if (_localBackups.isNotEmpty)
                        ..._localBackups.map(
                          (backup) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.insert_drive_file_outlined),
                            title: Text(
                              backup.payload.entryCount > 0
                                  ? '${backup.payload.entryCount} ${backup.payload.entryCount > 1 ? l10n.backupEntries : l10n.backupEntry} • ${DateFormat('dd/MM/yyyy HH:mm').format(backup.payload.exportedAt.toLocal())}'
                                  : DateFormat('dd/MM/yyyy HH:mm').format(backup.payload.exportedAt.toLocal()),
                            ),
                            subtitle: Text(backup.fileName),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  await _confirmAndDeleteBackup(backup);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: const Icon(Icons.delete_outline, color: PassKeyraColors.error),
                                    title: Text(l10n.delete),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Ligne 1 : Sauvegarder + Restaurer (actions miroir sur le local)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveLocalBackup,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Créer une sauvegarde'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: (_isLoading || _localBackups.isEmpty)
                                  ? null
                                  : () => _restoreFromBackup(_localBackups.first),
                              icon: const Icon(Icons.restore),
                              label: const Text('Restauration'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Ligne 2 : Exporter vers un fichier (partage natif)
                      CoachMarkSystem.buildHalo(
                        key: _exportButtonKey,
                        pulseController: _coachPulseController,
                        isActive: _isTutorialRunning && _activeTargetKey == 'export',
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _exportVault,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload),
                            label: Text(l10n.exportButton),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_snapshotBackups.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSnapshotBackupsCard(l10n),
            ],
          ],
          ),
        ),
      ),
    );
  }

  /// Card "Sauvegardes de sécurité" : affiche les snapshots pré-changement
  /// de mot de passe maître, avec date de création + expiration + bouton
  /// de restauration (qui ouvre un dialog de confirmation explicite).
  Widget _buildSnapshotBackupsCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: PassKeyraColors.info, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.securityBackupBadge,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._snapshotBackups.map((backup) {
              final dateStr = DateFormat('dd/MM/yyyy').format(
                  backup.payload.exportedAt.toLocal());
              final expiry = backup.payload.exportedAt
                  .add(const Duration(days: BackupRepository.snapshotRetentionDays));
              final expiryStr = DateFormat('dd/MM/yyyy').format(expiry.toLocal());
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_outlined),
                title: Text(l10n.securityBackupSubtitle(dateStr, expiryStr)),
                subtitle: Text(
                  backup.payload.entryCount > 0
                      ? '${backup.payload.entryCount} ${backup.payload.entryCount > 1 ? l10n.backupEntries : l10n.backupEntry}'
                      : '',
                ),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.restore),
                  label: Text(l10n.restore),
                  onPressed: _isLoading
                      ? null
                      : () => _restoreSnapshotWithConfirmation(backup),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Affiche un dialog d'avertissement explicite avant de restaurer un
  /// snapshot pré-changement (l'utilisateur doit comprendre qu'il aura
  /// besoin de son ancien mot de passe maître).
  Future<void> _restoreSnapshotWithConfirmation(LocalBackup backup) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            size: 40, color: PassKeyraColors.warning),
        title: Text(l10n.securityBackupRestoreWarningTitle),
        content: Text(l10n.securityBackupRestoreWarningBody),
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
    if (confirmed == true && mounted) {
      await _restoreFromBackup(backup);
    }
  }
}
