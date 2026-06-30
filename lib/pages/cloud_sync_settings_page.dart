import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/cloud_user.dart';
import '../models/sync_state.dart';
import '../services/auth_service.dart';
import '../services/firebase/firebase_auth_service.dart';
import '../services/firebase/firebase_sync_service.dart';
import '../services/vault_repository.dart';
import '../widgets/coach_mark_system.dart';
import 'cloud_login_page.dart';
import 'cloud_sync_help_page.dart';

class CloudSyncSettingsPage extends StatefulWidget {
  const CloudSyncSettingsPage({
    super.key,
    required this.authService,
    required this.vaultRepository,
    this.startTutorial = false,
  });

  final AuthService authService;
  final VaultRepository vaultRepository;
  final bool startTutorial;

  @override
  State<CloudSyncSettingsPage> createState() => _CloudSyncSettingsPageState();
}

class _CloudSyncSettingsPageState extends State<CloudSyncSettingsPage>
    with SingleTickerProviderStateMixin {
  final _firebaseAuthService = FirebaseAuthService();
  late final FirebaseSyncService _syncService;
  late final AnimationController _coachPulseController;

  CloudUser? _currentUser;
  SyncStatus _syncStatus = SyncStatus.initial;
  bool _syncEnabled = false;
  bool _isLoading = false;
  bool _isTutorialRunning = false;
  bool _didInit = false;

  final _syncSwitchKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _coachPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _syncService = FirebaseSyncService(
      authService: widget.authService,
      firebaseAuthService: _firebaseAuthService,
    );
    _loadInitialState();
    _listenToSyncStatus();
    _listenToAuthState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    if (widget.startTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runCloudSyncTutorial();
      });
    }
  }

  @override
  void dispose() {
    _coachPulseController.dispose();
    _syncService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    _currentUser = _firebaseAuthService.currentCloudUser;
    _syncEnabled = await _syncService.isSyncEnabled();
    if (!mounted) return;
    setState(() {});
  }

  void _listenToSyncStatus() {
    _syncService.syncStatusStream.listen((status) {
      if (!mounted) return;
      setState(() => _syncStatus = status);
    });
  }

  void _listenToAuthState() {
    _firebaseAuthService.authStateChanges.listen((user) {
      if (!mounted) return;
      setState(() => _currentUser = _firebaseAuthService.currentCloudUser);
    });
  }

  Future<void> _runCloudSyncTutorial() async {
    setState(() => _isTutorialRunning = true);
    final l10n = AppLocalizations.of(context)!;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _syncSwitchKey,
      pulseController: _coachPulseController,
      title: l10n.premiumTutorialCloudSyncTitle,
      message: l10n.premiumTutorialCloudSyncMessage,
      primaryLabel: l10n.onboardingNext,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '1 / 1',
    );

    setState(() => _isTutorialRunning = false);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _handleLogin() async {
    final user = await Navigator.of(context).push<CloudUser>(
      MaterialPageRoute(builder: (_) => const CloudLoginPage()),
    );
    if (user == null || !mounted) return;
    setState(() => _currentUser = user);
    _showSuccessSnackbar('Connecté à ${user.email}');
  }

  Future<void> _handleLogout() async {
    final confirm = await _showConfirmDialog(
      'Déconnexion',
      'Voulez-vous vraiment vous déconnecter ?\n\nLa synchronisation sera désactivée.',
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _syncService.setSyncEnabled(false);
      await _firebaseAuthService.signOut();
      if (!mounted) return;
      setState(() {
        _currentUser = null;
        _syncEnabled = false;
        _isLoading = false;
      });
      _showSuccessSnackbar('Déconnecté avec succès');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackbar('Erreur lors de la déconnexion: $e');
    }
  }

  Future<void> _toggleSync(bool enabled) async {
    if (!enabled) {
      final confirm = await _showConfirmDialog(
        'Désactiver la synchronisation',
        'Les modifications ne seront plus synchronisées automatiquement.',
      );
      if (confirm != true) return;
    }

    setState(() => _isLoading = true);
    try {
      await _syncService.setSyncEnabled(enabled);
      if (!mounted) return;
      setState(() {
        _syncEnabled = enabled;
        _isLoading = false;
      });
      _showSuccessSnackbar(
        enabled ? 'Synchronisation activée' : 'Synchronisation désactivée',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackbar('Erreur: $e');
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synchronisation cloud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Aide',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CloudSyncHelpPage(
                    onDeleteAccountRequested:
                        _currentUser != null ? _confirmDeleteAccount : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAccountSection(theme),
                if (_currentUser != null) ...[
                  const SizedBox(height: 24),
                  _buildSyncSection(theme),
                ],
              ],
            ),
    );
  }

  /// Affiche le dialog de confirmation puis exécute la suppression du compte cloud.
  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 48),
        title: Text(l10n.deleteCloudAccount),
        content: Text(l10n.deleteCloudAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteCloudAccountConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      // 1. Stopper la sync Firestore (listener) avant le delete
      await _syncService.setSyncEnabled(false);

      // 2. Supprimer le compte Firebase Auth (sign-out Google inclus)
      await _firebaseAuthService.deleteAccount();

      if (!mounted) return;
      setState(() {
        _currentUser = null;
        _syncEnabled = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deleteCloudAccountSuccess),
          backgroundColor: Colors.green,
        ),
      );

      // Pop pour revenir à l'écran précédent (la page sync n'a plus de sens)
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Cas spécial : Firebase exige une reconnexion récente
      final isReauthRequired = e.toString().contains('requires-recent-login');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isReauthRequired
                ? l10n.deleteCloudAccountReauthRequired
                : '${l10n.error}: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildAccountSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Compte cloud',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_currentUser == null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.cloudSyncRequiresGoogle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _handleLogin,
                icon: const Icon(Icons.login),
                label: const Text('Se connecter avec Google'),
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(_currentUser!.email),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync_alt, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Synchronisation automatique',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CoachMarkSystem.buildHalo(
              key: _syncSwitchKey,
              pulseController: _coachPulseController,
              isActive: _isTutorialRunning,
              borderRadius: BorderRadius.circular(12),
              child: SwitchListTile(
                value: _syncEnabled,
                onChanged: _toggleSync,
                title: const Text('Activer la synchronisation'),
                subtitle: Text(
                  _syncEnabled
                      ? 'Les modifications sont synchronisées automatiquement'
                      : 'Synchronisation manuelle uniquement',
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (_syncEnabled &&
                (_syncStatus.state != SyncState.idle ||
                    _syncStatus.lastSync != null)) ...[
              const Divider(),
              ListTile(
                leading: _getSyncStateIcon(_syncStatus.state),
                title: Text(_getSyncStateText(_syncStatus.state)),
                subtitle: _syncStatus.lastSync != null
                    ? Text(
                        'Dernière sync: ${_formatDateTime(_syncStatus.lastSync!)}')
                    : const Text('Jamais synchronisé'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Icon _getSyncStateIcon(SyncState state) {
    switch (state) {
      case SyncState.idle:
        return const Icon(Icons.cloud_off, color: Colors.grey);
      case SyncState.syncing:
        return const Icon(Icons.sync, color: Colors.blue);
      case SyncState.success:
        return const Icon(Icons.cloud_done, color: Colors.green);
      case SyncState.error:
        return const Icon(Icons.error, color: Colors.red);
      case SyncState.conflict:
        return const Icon(Icons.warning, color: Colors.orange);
    }
  }

  String _getSyncStateText(SyncState state) {
    switch (state) {
      case SyncState.idle:
        return 'Inactif';
      case SyncState.syncing:
        return 'Synchronisation en cours...';
      case SyncState.success:
        return 'Synchronisé';
      case SyncState.error:
        return 'Erreur de synchronisation';
      case SyncState.conflict:
        return 'Conflit détecté';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inHours < 1) return 'Il y a ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'Il y a ${difference.inHours} h';
    return 'Il y a ${difference.inDays} jours';
  }
}
