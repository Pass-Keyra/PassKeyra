import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'secure_storage_service.dart';

/// Service de gestion du verrouillage de l'application
/// Utilise un StreamController pour diffuser l'état de verrouillage
/// Architecture simple : Stream → UI
class LockService {
  static LockService? _instance;
  static LockService get instance {
    _instance ??= LockService._();
    return _instance!;
  }

  LockService._();

  // Stream pour diffuser l'état de verrouillage
  final _lockController = StreamController<bool>.broadcast();
  Stream<bool> get lockStream => _lockController.stream;

  // État actuel
  bool _isLocked = true; // Verrouillé par défaut
  bool get isLocked => _isLocked;
  
  // Flag pour indiquer si on vient de se verrouiller automatiquement
  bool _justAutoLocked = false;
  bool get justAutoLocked => _justAutoLocked;

  // Délai de verrouillage (en secondes)
  Duration _lockTimeout = const Duration(seconds: 120); // 2 minutes par défaut
  Duration get lockTimeout => _lockTimeout;

  // Heure de la dernière mise en pause
  DateTime? _pauseTime;
  
  // Flag pour ignorer le prochain événement resumed après un déverrouillage
  bool _ignoreNextResume = false;

  final SecureStorageService _secureStorage = SecureStorageService();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Initialise le service
  Future<void> init() async {
    _log('LockService - Initialisation...');
    
    // 1. Vérifier si c'est la première installation
    _log('LockService - Vérification première installation...');

    // Note: _safeRead() gère automatiquement les erreurs BAD_DECRYPT
    // en supprimant uniquement la clé corrompue, pas tout le storage
    final salt = await _secureStorage.readSalt();
    final saltExists = salt != null;
    bool vaultHasData = false;
    try {
      final box = Hive.isBoxOpen('vault_blob')
          ? Hive.box<String>('vault_blob')
          : await Hive.openBox<String>('vault_blob');
      vaultHasData = box.isNotEmpty;
    } catch (e) {
      _log('LockService - Impossible de lire vault_blob pour détection first-install: $e');
    }

    _log('LockService - Salt existe : $saltExists');
    _log('LockService - Coffre contient des données : $vaultHasData');
    
    // 2. Détecter la première installation
    // Si pas de salt → Première installation
    // Note: On ne vérifie PAS le contenu du coffre car un coffre vide est valide
    final isFirstInstall = !saltExists && !vaultHasData;
    
    if (isFirstInstall) {
      _log('LockService - PREMIÈRE INSTALLATION DÉTECTÉE');
      _log('   → Salt existe : $saltExists');
      _log('   → Coffre contient des données : $vaultHasData');
      _isLocked = false; // Pas verrouillé pour permettre la création
    } else {
      _log('LockService - Compte existant détecté - APP VERROUILLÉE');
      _log('   → Salt existe : $saltExists');
      _log('   → Coffre contient des données : $vaultHasData');
      _isLocked = true; // Verrouillé pour demander le code secret
    }
    
    // 3. Charger le délai de verrouillage depuis les préférences
    final prefs = await SharedPreferences.getInstance();
    final timeoutSeconds = prefs.getInt('lock_timeout_seconds') ?? 120; // 2 minutes par défaut
    _lockTimeout = Duration(seconds: timeoutSeconds);
    
    _log('LockService - État final : ${_isLocked ? "VERROUILLÉ" : "DÉVERROUILLÉ"}');
    _log('LockService - Délai de verrouillage : ${_lockTimeout.inSeconds}s');
  }

  /// Définit le délai de verrouillage
  Future<void> setLockTimeout(Duration timeout) async {
    _log('LockService - Nouveau délai : ${timeout.inSeconds} secondes');
    _lockTimeout = timeout;
    
    // Sauvegarder dans les préférences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lock_timeout_seconds', timeout.inSeconds);
  }

  /// Verrouille l'application
  void lock() {
    if (!_isLocked) {
      _log('LockService - VERROUILLAGE ACTIVÉ');
      _isLocked = true;
      _justAutoLocked = true; // Marquer qu'on vient de se verrouiller
      _lockController.add(true);
    }
  }

  /// Déverrouille l'application
  void unlock() {
    if (_isLocked) {
      _log('LockService - DÉVERROUILLAGE ACTIVÉ');
      _isLocked = false;
      _lockController.add(false);
      
      // Réinitialiser _pauseTime pour éviter que onAppResumed ne pense qu'on revient de l'arrière-plan
      _log('LockService - Réinitialisation de _pauseTime (était: $_pauseTime)');
      _pauseTime = null;
      
      // Ignorer le prochain événement resumed (fermeture de la biométrie)
      _ignoreNextResume = true;
      _log('LockService - Flag _ignoreNextResume activé pour éviter le reverrouillage lors de la fermeture de la biométrie');
    }
  }
  
  /// Réinitialise le flag de verrouillage automatique
  void clearAutoLockFlag() {
    _log('LockService - Réinitialisation du flag auto-lock');
    _justAutoLocked = false;
  }

  /// Flag interne : quand `true`, `onAppPaused()` et `onAppResumed()` ne
  /// déclenchent PAS de verrouillage automatique. Utilisé pendant les
  /// opérations critiques longues (changement de mot de passe maître, ~10s
  /// de PBKDF2 desktop) pour éviter qu'un alt-tab Windows transitoire ne
  /// verrouille l'utilisateur au milieu du wizard.
  bool _inhibitAutoLock = false;
  void setInhibitAutoLock(bool inhibit) {
    _log('LockService - Inhibit auto-lock : $inhibit');
    _inhibitAutoLock = inhibit;
    if (!inhibit) {
      // En sortant de l'inhibition, on oublie un éventuel _pauseTime
      // accumulé pour ne pas lock immédiatement au prochain onAppResumed.
      _pauseTime = null;
    }
  }

  /// Appelé quand l'app passe en arrière-plan
  void onAppPaused() {
    if (_inhibitAutoLock) {
      _log('LockService - onAppPaused IGNORÉ (inhibit actif)');
      return;
    }
    _pauseTime = DateTime.now();
    _log('LockService - App mise en pause à ${_pauseTime!.hour}:${_pauseTime!.minute}:${_pauseTime!.second}');

    // Si délai = 0 (immédiat), verrouiller tout de suite
    if (_lockTimeout.inSeconds == 0) {
      _log('LockService - Mode IMMÉDIAT - Verrouillage instantané !');
      lock();
    } else {
      _log('LockService - Délai de ${_lockTimeout.inSeconds}s avant verrouillage');
    }
  }

  /// Appelé quand l'app revient au premier plan
  void onAppResumed() {
    if (_inhibitAutoLock) {
      _log('LockService - onAppResumed IGNORÉ (inhibit actif)');
      _pauseTime = null;
      return;
    }
    // Vérifier le flag _ignoreNextResume (fermeture de la biométrie)
    if (_ignoreNextResume) {
      _log('LockService - Événement resumed IGNORÉ (fermeture de la biométrie)');
      _ignoreNextResume = false;
      return;
    }
    
    if (_pauseTime == null) {
      _log('LockService - App reprise (pas de pause précédente)');
      return;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_pauseTime!);
    _log('LockService - App reprise à ${now.hour}:${now.minute}:${now.second}');
    _log('LockService - Temps écoulé : ${elapsed.inSeconds} secondes');

    // Si on était déjà verrouillé, ne rien faire
    if (_isLocked) {
      _log('LockService - Déjà verrouillé, rien à faire');
      return;
    }

    // Vérifier si le délai est dépassé
    if (_lockTimeout.inSeconds == 0) {
      // Mode immédiat : toujours verrouiller
      _log('LockService - Mode IMMÉDIAT - Verrouillage !');
      lock();
    } else if (_lockTimeout.inSeconds >= 86400) {
      // 24h ou plus = jamais verrouiller
      _log('LockService - Mode JAMAIS - Pas de verrouillage');
    } else if (elapsed >= _lockTimeout) {
      // Délai dépassé : verrouiller
      _log('LockService - Délai dépassé (${elapsed.inSeconds}s > ${_lockTimeout.inSeconds}s) - Verrouillage !');
      lock();
    } else {
      _log('LockService - Délai non atteint (${elapsed.inSeconds}s < ${_lockTimeout.inSeconds}s) - Pas de verrouillage');
    }
  }

  /// Ferme le service
  void dispose() {
    _log('LockService - Fermeture');
    _lockController.close();
  }

  Future<void> fullReset() async {
    _log('LockService - Réinitialisation complète du stockage sécurisé & préférences');
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      if (Hive.isBoxOpen('vault_blob')) {
        final box = Hive.box<String>('vault_blob');
        await box.clear();
        await box.close();
      } else {
        final box = await Hive.openBox<String>('vault_blob');
        await box.clear();
        await box.close();
      }
      _log('LockService - Coffre Hive vidé');
    } catch (e) {
      _log('LockService - Impossible de purger Hive : $e');
    }
  }
}

