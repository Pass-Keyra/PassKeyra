import 'dart:math';

/// Génère des mots de passe aléatoires selon des options simples.
class PasswordGenerator {
  static String generate({
    int length = 16,
    bool includeLower = true,
    bool includeUpper = true,
    bool includeDigits = true,
    bool includeSymbols = false,
  }) {
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const symbols = '!@#\$%&*?-_=+.,;:()[]{}';

    // Construire la liste des types de caractères sélectionnés
    final charSets = <String>[];
    if (includeLower) charSets.add(lower);
    if (includeUpper) charSets.add(upper);
    if (includeDigits) charSets.add(digits);
    if (includeSymbols) charSets.add(symbols);

    // Si aucun type n'est sélectionné, utiliser les minuscules par défaut
    if (charSets.isEmpty) charSets.add(lower);

    final rnd = Random.secure();
    final chars = <String>[];

    // Nombre de types de caractères sélectionnés
    final numTypes = charSets.length;

    // Calculer combien de caractères de chaque type (distribution équitable)
    final charsPerType = length ~/ numTypes;
    final remainder = length % numTypes;

    // Ajouter le nombre équitable de caractères pour chaque type
    for (var i = 0; i < charSets.length; i++) {
      final charSet = charSets[i];
      // Ajouter charsPerType caractères (+ 1 pour les premiers types si remainder > 0)
      final count = charsPerType + (i < remainder ? 1 : 0);

      for (var j = 0; j < count; j++) {
        chars.add(charSet[rnd.nextInt(charSet.length)]);
      }
    }

    // Mélanger aléatoirement tous les caractères
    chars.shuffle(rnd);

    return chars.join();
  }
}























