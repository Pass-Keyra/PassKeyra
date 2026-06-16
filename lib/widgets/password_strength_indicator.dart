import 'package:flutter/material.dart';
import '../services/password_strength_service.dart';
import '../app/app.dart' show PassKeyraColors;

/// Widget d'indication de force de mot de passe MODERNE
///
/// Affiche :
/// - Une barre de progression colorée (rouge → vert)
/// - Le niveau de force (Trop faible, Faible, Moyen, Fort, Très fort)
/// - Le score sur 100
/// - Les critères manquants
///
/// Session 22 - Renforcement sécurité mot de passe maître
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final PasswordStrengthService _strengthService = PasswordStrengthService();

  PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = _strengthService.analyze(password);
    final score = _strengthService.getScore(password);
    final message = _strengthService.getMessage(password);

    // Couleur selon la force
    final color = _getStrengthColor(strength);
    final textColor = _getStrengthTextColor(strength);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône et label
          Row(
            children: [
              Icon(
                _getStrengthIcon(strength),
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Force du mot de passe',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                    fontSize: 14,
                  ),
                ),
              ),
              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score/100',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: 12),

          // Niveau et message
          Text(
            message,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),

          // Conseils si le mot de passe est faible
          if (strength == PasswordStrength.tooWeak ||
              strength == PasswordStrength.weak ||
              strength == PasswordStrength.medium) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Conseils pour améliorer',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ..._getImprovementSuggestions(password)
                      .map((suggestion) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ',
                                    style: TextStyle(
                                        color: Colors.orange[700], fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    suggestion,
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ],
              ),
            ),
          ],

          // Exemple de bon mot de passe
          if (strength == PasswordStrength.tooWeak) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PassKeyraColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 16,
                        color: PassKeyraColors.info,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Exemple recommandé',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: PassKeyraColors.info,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'J\'adore-Les-Pizzas-4fromages!2024',
                    style: TextStyle(
                      color: PassKeyraColors.info,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '16+ caractères, majuscules, minuscules, chiffres, symboles',
                    style: TextStyle(
                      color: PassKeyraColors.info.withOpacity(0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.tooWeak:
        return PassKeyraColors.error;
      case PasswordStrength.weak:
        return Colors.deepOrange;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.lightGreen;
      case PasswordStrength.veryStrong:
        return PassKeyraColors.success;
    }
  }

  Color _getStrengthTextColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.tooWeak:
        return PassKeyraColors.error;
      case PasswordStrength.weak:
        return Colors.deepOrange[700]!;
      case PasswordStrength.medium:
        return Colors.orange[800]!;
      case PasswordStrength.strong:
        return Colors.green[700]!;
      case PasswordStrength.veryStrong:
        return PassKeyraColors.success;
    }
  }

  IconData _getStrengthIcon(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.tooWeak:
        return Icons.dangerous;
      case PasswordStrength.weak:
        return Icons.warning_amber_rounded;
      case PasswordStrength.medium:
        return Icons.info;
      case PasswordStrength.strong:
        return Icons.check_circle;
      case PasswordStrength.veryStrong:
        return Icons.verified;
    }
  }

  List<String> _getImprovementSuggestions(String password) {
    final suggestions = <String>[];

    if (password.length < PasswordStrengthService.minLength) {
      suggestions.add(
          'Ajoutez au moins ${PasswordStrengthService.minLength - password.length} caractères');
    } else if (password.length < PasswordStrengthService.recommendedLength) {
      suggestions.add(
          'Visez ${PasswordStrengthService.recommendedLength}+ caractères pour une meilleure sécurité');
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      suggestions.add('Ajoutez au moins une majuscule');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      suggestions.add('Ajoutez au moins une minuscule');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      suggestions.add('Ajoutez au moins un chiffre');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\\/;~`]').hasMatch(password)) {
      suggestions.add('Ajoutez au moins un symbole (!@#\$%...)');
    }

    if (suggestions.isEmpty) {
      suggestions
          .add('Utilisez une phrase secrète unique (ex: J\'aime-Le-Chocolat!2024)');
    }

    return suggestions;
  }
}
