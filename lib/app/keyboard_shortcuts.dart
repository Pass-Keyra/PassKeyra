/// Source de vérité unique des raccourcis clavier PassKeyra Desktop.
///
/// Cette enum est consommée par :
/// - [CoachMarkSystem.showCoachStep] via le paramètre `shortcut:` — si fourni
///   ET qu'on est sur desktop, le coach mark affiche les key caps sous le
///   message.
/// - [KeyboardShortcutsPage] — la liste affichée dans Settings est dérivée de
///   cette enum (pas de duplication).
/// - [PassKeyraAppShell.build] — le `CallbackShortcuts` global utilise les
///   identifiants pour binder les bonnes actions.
///
/// **Règle (analogue à la l10n)** : tout nouveau raccourci doit être ajouté
/// ICI d'abord. Puis :
/// 1. Câbler son [CallbackShortcuts] dans `app.dart` (ou la page concernée)
/// 2. Si la feature a un coach mark/didacticiel, passer `shortcut: AppShortcut.X`
///    à `showCoachStep(...)` pour que le tutoriel le mentionne automatiquement
///
/// Le mobile ignore complètement cette enum (raccourcis desktop only).
enum AppShortcut {
  newEntry(
    keys: ['Ctrl', 'N'],
    label: 'Nouvelle entrée',
    description: 'Ouvre le formulaire de création d\'une nouvelle entrée (depuis la page d\'accueil).',
  ),
  search(
    keys: ['Ctrl', 'F'],
    label: 'Rechercher',
    description: 'Donne le focus à la barre de recherche (depuis la page d\'accueil).',
  ),
  lockVault(
    keys: ['Ctrl', 'L'],
    label: 'Verrouiller le coffre',
    description: 'Verrouille immédiatement PassKeyra et retourne à l\'écran de connexion.',
  ),
  openSettings(
    keys: ['Ctrl', ','],
    label: 'Ouvrir les paramètres',
    description: 'Affiche la page des paramètres depuis n\'importe où dans l\'app.',
  ),
  back(
    keys: ['Esc'],
    label: 'Retour / Fermer',
    description: 'Ferme la page ou le dialog en cours et revient en arrière.',
  ),
  submit(
    keys: ['Entrée'],
    label: 'Valider la saisie',
    description: 'Soumet le formulaire actif (mot de passe maître, création d\'entrée, etc.).',
  );

  const AppShortcut({
    required this.keys,
    required this.label,
    required this.description,
  });

  final List<String> keys;
  final String label;
  final String description;
}
