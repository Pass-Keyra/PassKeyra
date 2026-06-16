import '../models/password_entry.dart';
import '../models/security_analysis_result.dart';
import '../l10n/app_localizations.dart';

/// Service d'analyse de sécurité des mots de passe
///
/// Analyse tous les mots de passe du coffre-fort et génère un rapport
/// de sécurité complet avec score, problèmes détectés et recommandations.
class SecurityAnalyzerService {
  // Singleton pattern
  static final SecurityAnalyzerService _instance =
      SecurityAnalyzerService._internal();
  factory SecurityAnalyzerService() => _instance;
  SecurityAnalyzerService._internal();

  /// Analyse complète de toutes les entrées du coffre-fort
  SecurityAnalysisResult analyzeEntries(List<PasswordEntry> entries, AppLocalizations l10n) {
    if (entries.isEmpty) {
      return SecurityAnalysisResult(
        overallScore: 100,
        totalPasswords: 0,
        strengthDistribution: {},
        issues: [],
        duplicateCount: 0,
        oldPasswordCount: 0,
      );
    }

    // Compteurs et listes de collecte
    final Map<PasswordStrength, int> distribution = {
      for (var strength in PasswordStrength.values) strength: 0,
    };
    final List<PasswordIssue> issues = [];
    int totalScore = 0;
    int passwordCount = 0;

    // Analyser les mots de passe principaux
    for (var entry in entries) {
      final strength = _getPasswordStrength(entry.password);
      final score = _calculatePasswordStrength(entry.password);

      distribution[strength] = (distribution[strength] ?? 0) + 1;
      totalScore += score;
      passwordCount++;

      // Problèmes de mots de passe faibles
      if (strength == PasswordStrength.veryWeak ||
          strength == PasswordStrength.weak) {
        issues.add(PasswordIssue(
          entryName: entry.name,
          type: IssueType.weakPassword,
          severity: strength == PasswordStrength.veryWeak
              ? IssueSeverity.critical
              : IssueSeverity.warning,
          description: _getWeaknessDescription(entry.password, l10n),
        ));
      }

      // Analyser les mots de passe additionnels (fonctionnalité Premium)
      for (var addPwd in entry.additionalPasswords) {
        final pwd = addPwd['password'];
        if (pwd != null && pwd.isNotEmpty) {
          final addStrength = _getPasswordStrength(pwd);
          final addScore = _calculatePasswordStrength(pwd);

          distribution[addStrength] = (distribution[addStrength] ?? 0) + 1;
          totalScore += addScore;
          passwordCount++;

          if (addStrength == PasswordStrength.veryWeak ||
              addStrength == PasswordStrength.weak) {
            final label = addPwd['label'] ?? l10n.additionalPasswordLabel;
            issues.add(PasswordIssue(
              entryName: '${entry.name} ($label)',
              type: IssueType.weakPassword,
              severity: addStrength == PasswordStrength.veryWeak
                  ? IssueSeverity.critical
                  : IssueSeverity.warning,
              description: _getWeaknessDescription(pwd, l10n),
            ));
          }
        }
      }

      // Problèmes de mots de passe anciens (non modifiés depuis >1 an)
      final age = DateTime.now().difference(entry.updatedAt);
      if (age.inDays > 365) {
        final years = (age.inDays / 365).floor();
        issues.add(PasswordIssue(
          entryName: entry.name,
          type: IssueType.oldPassword,
          severity: IssueSeverity.warning,
          description: l10n.passwordNotUpdatedYears(years),
        ));
      }
    }

    // Détection des doublons
    final duplicateIssues = _findDuplicates(entries, l10n);
    issues.addAll(duplicateIssues);

    // Calcul du score global
    final overallScore = passwordCount > 0 ? (totalScore / passwordCount).round() : 100;

    return SecurityAnalysisResult(
      overallScore: overallScore,
      totalPasswords: passwordCount,
      strengthDistribution: distribution,
      issues: issues,
      duplicateCount:
          duplicateIssues.where((i) => i.type == IssueType.duplicatePassword).length,
      oldPasswordCount:
          issues.where((i) => i.type == IssueType.oldPassword).length,
    );
  }

  /// Calcule la force d'un mot de passe (score 0-100)
  int _calculatePasswordStrength(String password) {
    int score = 0;

    // Score de longueur (max 30 points)
    if (password.length >= 8) score += 10;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;

    // Score de variété de caractères (max 40 points)
    if (RegExp(r'[a-z]').hasMatch(password)) score += 10; // Minuscules
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 10; // Majuscules
    if (RegExp(r'[0-9]').hasMatch(password)) score += 10; // Chiffres
    if (RegExp(r'[!@#$%&*?_=+.,;:()\[\]{}]').hasMatch(password)) {
      score += 10; // Symboles
    }

    // Score d'entropie (caractères uniques, max 30 points)
    final uniqueChars = password.split('').toSet().length;
    if (uniqueChars >= 8) score += 10;
    if (uniqueChars >= 12) score += 10;
    if (uniqueChars >= 16) score += 10;

    return score.clamp(0, 100);
  }

  /// Convertit un score en niveau de force
  PasswordStrength _getPasswordStrength(String password) {
    final score = _calculatePasswordStrength(password);

    if (score >= 95) return PasswordStrength.veryStrong;
    if (score >= 80) return PasswordStrength.strong;
    if (score >= 60) return PasswordStrength.medium;
    if (score >= 40) return PasswordStrength.weak;
    return PasswordStrength.veryWeak;
  }

  /// Génère une description des faiblesses d'un mot de passe
  String _getWeaknessDescription(String password, AppLocalizations l10n) {
    final List<String> weaknesses = [];

    if (password.length < 8) weaknesses.add(l10n.passwordTooShort);
    if (password.length < 12) weaknesses.add(l10n.passwordShouldBe12Plus);
    if (!RegExp(r'[A-Z]').hasMatch(password)) weaknesses.add(l10n.passwordNoUppercase);
    if (!RegExp(r'[a-z]').hasMatch(password)) weaknesses.add(l10n.passwordNoLowercase);
    if (!RegExp(r'[0-9]').hasMatch(password)) weaknesses.add(l10n.passwordNoNumbers);
    if (!RegExp(r'[!@#$%&*?_=+.,;:()\[\]{}]').hasMatch(password)) {
      weaknesses.add(l10n.passwordNoSymbols);
    }

    return weaknesses.isEmpty ? l10n.weakPasswordGeneric : weaknesses.join(', ');
  }

  /// Détecte les mots de passe dupliqués
  List<PasswordIssue> _findDuplicates(List<PasswordEntry> entries, AppLocalizations l10n) {
    final Map<String, List<String>> passwordMap = {};
    final List<PasswordIssue> duplicateIssues = [];

    // Collecter tous les mots de passe avec leurs entrées associées
    for (var entry in entries) {
      // Mot de passe principal
      passwordMap.putIfAbsent(entry.password, () => []).add(entry.name);

      // Mots de passe additionnels
      for (var addPwd in entry.additionalPasswords) {
        final pwd = addPwd['password'];
        if (pwd != null && pwd.isNotEmpty) {
          final label = addPwd['label'] ?? l10n.additionalPasswordLabel;
          passwordMap.putIfAbsent(pwd, () => []).add('${entry.name} ($label)');
        }
      }
    }

    // Identifier les doublons (utilisé 2+ fois)
    passwordMap.forEach((password, entryNames) {
      if (entryNames.length >= 2) {
        // Créer un problème pour le premier usage
        duplicateIssues.add(PasswordIssue(
          entryName: entryNames.first,
          type: IssueType.duplicatePassword,
          severity: IssueSeverity.warning,
          description: l10n.usedInEntries(entryNames.length),
          relatedEntries: entryNames.skip(1).toList(),
        ));
      }
    });

    return duplicateIssues;
  }
}
