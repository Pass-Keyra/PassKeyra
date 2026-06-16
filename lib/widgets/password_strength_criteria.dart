import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Widget affichant les critères de force du mot de passe en temps réel
///
/// Change la couleur des critères de gris à vert quand ils sont respectés
class PasswordStrengthCriteria extends StatelessWidget {
  final String password;

  const PasswordStrengthCriteria({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Validation des critères
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%&*?_=+.,;:()\[\]{}~^<>-]').hasMatch(password);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCriterion(
            context,
            isValid: hasMinLength,
            text: l10n.passwordMinLength,
          ),
          const SizedBox(height: 6),
          _buildCriterion(
            context,
            isValid: hasUppercase,
            text: l10n.passwordNeedsUppercase,
          ),
          const SizedBox(height: 6),
          _buildCriterion(
            context,
            isValid: hasLowercase,
            text: l10n.passwordNeedsLowercase,
          ),
          const SizedBox(height: 6),
          _buildCriterion(
            context,
            isValid: hasDigit,
            text: l10n.passwordNeedsDigit,
          ),
          const SizedBox(height: 6),
          _buildCriterion(
            context,
            isValid: hasSpecial,
            text: l10n.passwordNeedsSpecial,
          ),
        ],
      ),
    );
  }

  Widget _buildCriterion(
    BuildContext context, {
    required bool isValid,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isValid ? Colors.green : Colors.grey,
              fontSize: 13,
              fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
