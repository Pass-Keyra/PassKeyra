import 'package:flutter/material.dart';
import '../app/app.dart';
import '../models/security_analysis_result.dart';
import '../services/security_analyzer_service.dart';
import '../services/premium_service.dart';
import '../services/auto_close_service.dart';
import '../services/vault_repository.dart';
import '../services/auth_service.dart';
import '../widgets/coach_mark_system.dart';
import '../l10n/app_localizations.dart';
import 'premium_page.dart';

/// Page d'analyse de sécurité - Fonctionnalité Premium
///
/// Affiche un rapport détaillé de la sécurité du coffre-fort avec :
/// - Score global de sécurité
/// - Statistiques (mots de passe forts, faibles, dupliqués, anciens)
/// - Liste des problèmes détectés
/// - Recommandations d'amélioration
class SecurityReportPage extends StatefulWidget {
  const SecurityReportPage({super.key, this.fromTutorial = false});

  final bool fromTutorial;
  static const String route = '/security-report';

  @override
  State<SecurityReportPage> createState() => _SecurityReportPageState();
}

class _SecurityReportPageState extends State<SecurityReportPage>
    with SingleTickerProviderStateMixin {
  final _premiumService = PremiumService();
  final _autoCloseService = AutoCloseService.instance;
  final _analyzerService = SecurityAnalyzerService();
  VaultRepository? _vaultRepository;
  AuthService? _auth;

  SecurityAnalysisResult? _analysisResult;
  bool _isLoading = true;
  final GlobalKey _scoreCardKey = GlobalKey();
  late final AnimationController _tutorialPulseController;

  @override
  void initState() {
    super.initState();
    _tutorialPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tutorialPulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérer l'AuthService passé depuis la navigation
    final auth = ModalRoute.of(context)?.settings.arguments as AuthService?;
    if (auth != null && _auth == null) {
      _auth = auth;
      _vaultRepository = VaultRepository(_auth!);
      _checkPremiumAndAnalyze();
    }
  }

  Future<void> _checkPremiumAndAnalyze() async {
    // Vérifier l'accès Premium
    if (!_premiumService.isPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPremiumDialog();
        Navigator.pop(context);
      });
      return;
    }

    // Effectuer l'analyse
    await _performAnalysis();
  }

  Future<void> _performAnalysis() async {
    if (_vaultRepository == null) return;

    setState(() => _isLoading = true);

    try {
      final entries = await _vaultRepository!.readAll();
      final l10n = AppLocalizations.of(context)!;
      final result = _analyzerService.analyzeEntries(entries, l10n);

      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
      if (widget.fromTutorial) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _runTutorialCoachMark());
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final errorMessage = l10n.errorDuringAnalysis(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: PassKeyraColors.error,
          ),
        );
      }
    }
  }

  void _showPremiumDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.security, color: PassKeyraColors.primary, size: 48),
        title: Text(l10n.securityAnalysis),
        content: Text(l10n.securityAnalysisPremiumMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, PremiumPage.route);
            },
            child: Text(l10n.viewPremium),
          ),
        ],
      ),
    );
  }

  Future<void> _runTutorialCoachMark() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    await CoachMarkSystem.showCoachStep(
      context: context,
      targetKey: _scoreCardKey,
      pulseController: _tutorialPulseController,
      title: l10n.premiumTutorialSecurityReportTitle,
      message: l10n.premiumTutorialSecurityReportMessage,
      primaryLabel: l10n.onboardingContinue,
      secondaryLabel: l10n.onboardingSkipTutorial,
      stepIndicator: '4 / 7',
      clearFocusInset: 20.0,
      fullWidth: true,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _autoCloseService.onUserActivity(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.securityAnalysis),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelpDialog,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _analysisResult == null
                ? _buildErrorState()
                : _buildAnalysisReport(),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: PassKeyraColors.error),
          const SizedBox(height: 16),
          Text(
            l10n.unableToPerformAnalysis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _performAnalysis,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisReport() {
    final l10n = AppLocalizations.of(context)!;
    final result = _analysisResult!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score global
        _buildScoreCard(result),
        const SizedBox(height: 16),

        // Résumé des statistiques
        _buildSummaryCard(result),
        const SizedBox(height: 24),

        // Liste des problèmes
        if (result.issues.isNotEmpty) ...[
          Text(
            '${l10n.issuesFound} (${result.issues.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...result.issues.map((issue) => _buildIssueCard(issue)),
        ],

        // Recommandations
        const SizedBox(height: 24),
        _buildRecommendationsCard(result),
      ],
    );
  }

  Widget _buildScoreCard(SecurityAnalysisResult result) {
    final l10n = AppLocalizations.of(context)!;
    final scoreColor = _getScoreColor(result.overallScore);
    final strengthLabel = _getStrengthLabel(result.overallStrength);

    return Card(
      key: _scoreCardKey,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.security, color: scoreColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  l10n.securityScore,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Score numérique
            Text(
              '${result.overallScore}/100',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: result.overallScore / 100,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
            const SizedBox(height: 12),

            // Label de force
            Text(
              strengthLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(SecurityAnalysisResult result) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: PassKeyraColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.analysisSummary,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSummaryRow(
              Icons.check_circle,
              PassKeyraColors.success,
              l10n.strongPasswords(result.strongPasswordCount),
            ),
            const SizedBox(height: 8),

            if (result.weakPasswordCount > 0)
              _buildSummaryRow(
                Icons.warning,
                PassKeyraColors.warning,
                l10n.weakPasswords(result.weakPasswordCount),
              ),
            const SizedBox(height: 8),

            if (result.duplicateCount > 0)
              _buildSummaryRow(
                Icons.content_copy,
                PassKeyraColors.warning,
                l10n.duplicatePasswords(result.duplicateCount),
              ),
            const SizedBox(height: 8),

            if (result.oldPasswordCount > 0)
              _buildSummaryRow(
                Icons.schedule,
                PassKeyraColors.warning,
                l10n.oldPasswords(result.oldPasswordCount),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildIssueCard(PasswordIssue issue) {
    final l10n = AppLocalizations.of(context)!;
    final severityColor = _getSeverityColor(issue.severity);
    final severityIcon = _getSeverityIcon(issue.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(severityIcon, color: severityColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getIssueTitle(issue.type),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              issue.entryName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),

            Text(
              issue.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PassKeyraColors.textSecondary,
                  ),
            ),

            if (issue.relatedEntries != null && issue.relatedEntries!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.alsoUsedIn}:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              ...issue.relatedEntries!.map((entry) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      '• $entry',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(SecurityAnalysisResult result) {
    final l10n = AppLocalizations.of(context)!;
    final recommendations = _getRecommendations(result);

    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Card(
      color: PassKeyraColors.primary.withOpacity(0.05),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: PassKeyraColors.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.recommendations,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: PassKeyraColors.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: PassKeyraColors.primary),
            const SizedBox(width: 8),
            Text(l10n.help),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(l10n.securityAnalysisHelp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return PassKeyraColors.success;
    if (score >= 60) return PassKeyraColors.warning;
    return PassKeyraColors.error;
  }

  Color _getSeverityColor(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.critical:
        return PassKeyraColors.error;
      case IssueSeverity.warning:
        return PassKeyraColors.warning;
      case IssueSeverity.info:
        return PassKeyraColors.primary;
    }
  }

  IconData _getSeverityIcon(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.critical:
        return Icons.error;
      case IssueSeverity.warning:
        return Icons.warning;
      case IssueSeverity.info:
        return Icons.info_outline;
    }
  }

  String _getStrengthLabel(PasswordStrength strength) {
    final l10n = AppLocalizations.of(context)!;
    switch (strength) {
      case PasswordStrength.veryWeak:
        return l10n.veryWeak;
      case PasswordStrength.weak:
        return l10n.weak;
      case PasswordStrength.medium:
        return l10n.medium;
      case PasswordStrength.strong:
        return l10n.strong;
      case PasswordStrength.veryStrong:
        return l10n.veryStrong;
    }
  }

  String _getIssueTitle(IssueType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case IssueType.weakPassword:
        return l10n.weakPassword;
      case IssueType.duplicatePassword:
        return l10n.duplicatePassword;
      case IssueType.oldPassword:
        return l10n.oldPassword;
    }
  }

  List<String> _getRecommendations(SecurityAnalysisResult result) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> recommendations = [];

    if (result.weakPasswordCount > 0) {
      recommendations.add(l10n.recommendUseStrongPasswords);
    }
    if (result.duplicateCount > 0) {
      recommendations.add(l10n.recommendUseUniquePasswords);
    }
    if (result.oldPasswordCount > 0) {
      recommendations.add(l10n.recommendUpdateOldPasswords);
    }
    if (result.overallScore < 80) {
      recommendations.add(l10n.recommendUse12PlusChars);
      recommendations.add(l10n.recommendUseSymbols);
    }

    return recommendations;
  }
}
