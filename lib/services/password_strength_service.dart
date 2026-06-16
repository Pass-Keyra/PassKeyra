import 'dart:math';

/// Service d'analyse de la force d'un mot de passe
///
/// Évalue la robustesse d'un mot de passe selon plusieurs critères :
/// - Longueur (critère le plus important)
/// - Complexité (majuscules, minuscules, chiffres, symboles)
/// - Absence de patterns répétitifs
/// - Non-présence dans dictionnaire de mots de passe courants
///
/// Utilisé comme indicateur visuel pour informer l'utilisateur de la
/// robustesse de son mot de passe. La validation effective (longueur
/// minimale, complexité) est assurée par les règles du formulaire de
/// création — ce service ne bloque pas la création.
class PasswordStrengthService {
  // Longueur minimale informative — alignée avec les règles du formulaire.
  // La jauge est purement indicative ; la validation effective est faite
  // par le formulaire (8 car + maj/min/chiffre/symbole).
  static const int minLength = 8; // Minimum absolu
  static const int recommendedLength = 16; // Recommandé
  static const int excellentLength = 20; // Excellent

  /// Score brut 0-100 basé sur la longueur (palier principal) + complexité
  /// (paliers bonus). Voir `analyze()` pour la conversion en niveau qualitatif.
  ///
  /// Barème :
  /// - Palier longueur : 8 → 25, 12 → 50, 16 → 75, 20 → 100
  /// - Bonus maj+min combinés : +25
  /// - Bonus symbole : +25
  /// - Pénalité séquence évidente (1234, abcd, qwerty…) : -25
  /// - Mot du dictionnaire commun → 0 (rejet immédiat)
  /// - < 8 caractères → 0 (rejet immédiat)
  int _computeRawScore(String password) {
    if (password.length < minLength) return 0;
    if (_isCommonPassword(password)) return 0;

    int score;
    if (password.length >= 20) {
      score = 100;
    } else if (password.length >= 16) {
      score = 75;
    } else if (password.length >= 12) {
      score = 50;
    } else {
      score = 25;
    }

    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasSymbol = password.contains(
        RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+\[\]\\\/;~`]'));
    if (hasUpper && hasLower) score += 25;
    if (hasSymbol) score += 25;

    if (_hasObviousSequence(password)) score -= 25;

    return score.clamp(0, 100);
  }

  /// Analyse la force d'un mot de passe
  ///
  /// Returns : PasswordStrength (tooWeak, weak, medium, strong, veryStrong)
  PasswordStrength analyze(String password) {
    if (password.length < minLength) return PasswordStrength.tooWeak;
    if (_isCommonPassword(password)) return PasswordStrength.tooWeak;

    final score = _computeRawScore(password);
    if (score < 25) return PasswordStrength.weak;
    if (score < 50) return PasswordStrength.medium;
    if (score < 75) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  /// Calcule le score numérique 0-100. Reflète directement le score brut
  /// (mêmes paliers que `analyze`) pour une barre de progression cohérente.
  int getScore(String password) {
    if (password.isEmpty) return 0;
    return _computeRawScore(password);
  }

  /// Retourne un message descriptif pour l'utilisateur
  String getMessage(String password) {
    final strength = analyze(password);

    switch (strength) {
      case PasswordStrength.tooWeak:
        if (password.length < minLength) {
          return 'Trop court (minimum $minLength caractères)';
        }
        if (_isCommonPassword(password)) {
          return 'Mot de passe trop courant, choisissez-en un unique';
        }
        return 'Très faible, ajoutez de la complexité';

      case PasswordStrength.weak:
        return 'Faible — visez au moins 12 caractères';

      case PasswordStrength.medium:
        return 'Moyen — ajoutez majuscule + minuscule pour passer à fort';

      case PasswordStrength.strong:
        return 'Fort — ajoutez un caractère spécial pour devenir très fort';

      case PasswordStrength.veryStrong:
        return 'Très fort - Excellent !';
    }
  }

  /// Vérifie si le mot de passe contient des séquences évidentes
  bool _hasObviousSequence(String password) {
    final lower = password.toLowerCase();

    // Séquences numériques
    const numberSequences = [
      '0123', '1234', '2345', '3456', '4567', '5678', '6789',
      '9876', '8765', '7654', '6543', '5432', '4321', '3210',
    ];

    // Séquences alphabétiques
    const letterSequences = [
      'abcd', 'bcde', 'cdef', 'defg', 'efgh', 'fghi', 'ghij',
      'hijk', 'ijkl', 'jklm', 'klmn', 'lmno', 'mnop', 'nopq',
      'opqr', 'pqrs', 'qrst', 'rstu', 'stuv', 'tuvw', 'uvwx',
      'vwxy', 'wxyz',
    ];

    // Patterns courants
    const commonPatterns = [
      'qwerty', 'azerty', 'qwertz', 'asdfgh', 'zxcvbn',
    ];

    for (final seq in numberSequences) {
      if (lower.contains(seq)) return true;
    }

    for (final seq in letterSequences) {
      if (lower.contains(seq)) return true;
    }

    for (final pattern in commonPatterns) {
      if (lower.contains(pattern)) return true;
    }

    return false;
  }

  /// Vérifie si le mot de passe est dans le top des mots de passe courants
  bool _isCommonPassword(String password) {
    final lower = password.toLowerCase();

    // Top 100 des mots de passe les plus courants (version condensée)
    const commonPasswords = [
      'password', '123456', '12345678', 'qwerty', 'abc123', 'monkey',
      'letmein', 'trustno1', 'dragon', 'baseball', 'iloveyou', 'master',
      'sunshine', 'ashley', 'bailey', 'passw0rd', 'shadow', '123123',
      '654321', 'superman', 'qazwsx', 'michael', 'football', 'password1',
      'welcome', 'jesus', 'ninja', 'mustang', 'admin', 'solo',
      'starwars', 'hello', 'freedom', 'whatever', 'trustno', 'ranger',
      'jordan', 'robert', 'daniel', 'andrew', 'london', 'computer',
      'maverick', 'princess', 'tigger', 'charlie', 'jennifer', 'hockey',
      'ranger', 'pepper', 'buster', 'batman', 'hockey', 'harley',
      'summer', '1q2w3e4r', 'zxcvbnm', 'access', 'flower', 'cookie',
      'samsung', 'dallas', 'yankees', 'chelsea', 'orange', 'hunter',
      'michelle', 'cheese', 'secret', 'london', 'canada', 'test',
      'amanda', 'qwerty123', 'passw0rd', 'internet', 'google', 'phoenix',
      'sparky', 'yellow', 'camaro', 'silver', 'killer', 'please',
      'ginger', 'garfield', 'steven', 'taylor', 'pepper', 'joshua',
      'banana', 'hannah', 'michelle', 'starwars', 'zaq12wsx', 'welcome1',
      'admin123', 'letmein', 'login', 'passw', 'azerty123',
    ];

    // Vérification directe
    if (commonPasswords.contains(lower)) return true;

    // Vérification avec suffixes numériques courants (password123, etc.)
    for (final common in commonPasswords) {
      if (lower.startsWith(common) || lower.endsWith(common)) {
        return true;
      }
    }

    // Vérification de variations avec substitutions (p@ssw0rd, etc.)
    final noSubstitutions = lower
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll('7', 't')
        .replaceAll('@', 'a')
        .replaceAll('!', 'i')
        .replaceAll('\$', 's');

    if (commonPasswords.contains(noSubstitutions)) return true;

    return false;
  }

  /// Estime le temps nécessaire pour une attaque brute force
  ///
  /// Basé sur :
  /// - GPU moderne (RTX 4090) : ~30 milliards de hash/sec
  /// - PBKDF2 600k itérations : ~50 000 passwords/sec par GPU
  /// - Farm de 1000 GPUs : 50 millions passwords/sec
  String estimateCrackTime(String password) {
    // Calculer l'espace de clés
    int charsetSize = 0;
    if (password.contains(RegExp(r'[a-z]'))) charsetSize += 26;
    if (password.contains(RegExp(r'[A-Z]'))) charsetSize += 26;
    if (password.contains(RegExp(r'[0-9]'))) charsetSize += 10;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) charsetSize += 32;

    // Nombre de combinaisons possibles
    final combinations = pow(charsetSize, password.length).toDouble();

    // Vitesse d'une farm de 1000 GPUs modernes avec PBKDF2 600k
    const passwordsPerSecond = 50000000.0; // 50 millions/sec

    // Temps moyen pour trouver (on suppose qu'il faut tester 50% de l'espace)
    final secondsTooCrack = (combinations / 2) / passwordsPerSecond;

    // Convertir en unité lisible
    if (secondsTooCrack < 60) {
      return 'quelques secondes';
    } else if (secondsTooCrack < 3600) {
      return '${(secondsTooCrack / 60).round()} minutes';
    } else if (secondsTooCrack < 86400) {
      return '${(secondsTooCrack / 3600).round()} heures';
    } else if (secondsTooCrack < 2592000) {
      return '${(secondsTooCrack / 86400).round()} jours';
    } else if (secondsTooCrack < 31536000) {
      return '${(secondsTooCrack / 2592000).round()} mois';
    } else if (secondsTooCrack < 3153600000) {
      return '${(secondsTooCrack / 31536000).round()} ans';
    } else if (secondsTooCrack < 31536000000000) {
      return '${(secondsTooCrack / 31536000000).round()} siècles';
    } else {
      return 'plusieurs milliards d\'années';
    }
  }
}

/// Niveaux de force d'un mot de passe (purement informatif)
enum PasswordStrength {
  tooWeak,   // < 8 caractères ou mot du dictionnaire commun
  weak,      // 8 caractères (sans complexité supplémentaire)
  medium,    // 12 caractères (sans complexité) ou 8 + maj/min
  strong,    // 12 caractères avec maj/min, ou plus long
  veryStrong // 12+ avec maj/min/symbole, ou 20+ caractères
}
