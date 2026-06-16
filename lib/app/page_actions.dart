import 'package:flutter/foundation.dart';

/// Bus d'actions globales pour les raccourcis clavier déclarés au niveau de
/// `PassKeyraAppShell` qui doivent déclencher du code page-spécifique.
///
/// La page (ex: HomePage) enregistre ses callbacks au mount via
/// `didChangeDependencies`, les libère au `dispose`. Le shortcut global lit
/// la valeur courante et l'invoque si elle existe.
///
/// Évite les problèmes de focus tree avec `CallbackShortcuts` placé dans une
/// route Navigator (où aucun descendant n'a forcément le focus initial).
class HomePageActions {
  HomePageActions._();
  static final HomePageActions instance = HomePageActions._();

  final ValueNotifier<VoidCallback?> newEntry = ValueNotifier(null);
  final ValueNotifier<VoidCallback?> focusSearch = ValueNotifier(null);
}
