/// Types de problèmes de sécurité détectés
enum IssueType {
  weakPassword,
  duplicatePassword,
  oldPassword,
}

/// Niveaux de sévérité des problèmes
enum IssueSeverity {
  critical, // Rouge - Action immédiate requise
  warning,  // Orange - À corriger
  info,     // Bleu - Information
}

/// Force d'un mot de passe
enum PasswordStrength {
  veryWeak,  // 0-39 points
  weak,      // 40-59 points
  medium,    // 60-79 points
  strong,    // 80-94 points
  veryStrong, // 95-100 points
}

/// Représente un problème de sécurité individuel
class PasswordIssue {
  final String entryName;
  final IssueType type;
  final IssueSeverity severity;
  final String description;
  final List<String>? relatedEntries; // Pour les doublons

  PasswordIssue({
    required this.entryName,
    required this.type,
    required this.severity,
    required this.description,
    this.relatedEntries,
  });
}

/// Résultat complet de l'analyse de sécurité
class SecurityAnalysisResult {
  /// Score global de sécurité (0-100)
  final int overallScore;

  /// Nombre total de mots de passe analysés
  final int totalPasswords;

  /// Statistiques par niveau de force
  final Map<PasswordStrength, int> strengthDistribution;

  /// Liste de tous les problèmes détectés
  final List<PasswordIssue> issues;

  /// Nombre de mots de passe dupliqués
  final int duplicateCount;

  /// Nombre de mots de passe anciens (>1 an)
  final int oldPasswordCount;

  SecurityAnalysisResult({
    required this.overallScore,
    required this.totalPasswords,
    required this.strengthDistribution,
    required this.issues,
    required this.duplicateCount,
    required this.oldPasswordCount,
  });

  /// Retourne le nombre de mots de passe forts (strong + veryStrong)
  int get strongPasswordCount {
    return (strengthDistribution[PasswordStrength.strong] ?? 0) +
        (strengthDistribution[PasswordStrength.veryStrong] ?? 0);
  }

  /// Retourne le nombre de mots de passe faibles (veryWeak + weak)
  int get weakPasswordCount {
    return (strengthDistribution[PasswordStrength.veryWeak] ?? 0) +
        (strengthDistribution[PasswordStrength.weak] ?? 0);
  }

  /// Retourne la force globale basée sur le score
  PasswordStrength get overallStrength {
    if (overallScore >= 95) return PasswordStrength.veryStrong;
    if (overallScore >= 80) return PasswordStrength.strong;
    if (overallScore >= 60) return PasswordStrength.medium;
    if (overallScore >= 40) return PasswordStrength.weak;
    return PasswordStrength.veryWeak;
  }
}
