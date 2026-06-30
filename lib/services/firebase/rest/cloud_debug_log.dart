import 'dart:io';

/// Logger fichier dedie au diagnostic de la sync cloud desktop (Phase 5).
///
/// Ecrit dans `%LOCALAPPDATA%\com.passkeyra\cloud_debug.log`. Permet de tracer
/// le flux d'authentification REST + Drive en release (ou debugPrint est
/// invisible). A retirer quand la Phase 5 sera stabilisee.
void cloudLog(String message) {
  try {
    final baseDir = Platform.environment['LOCALAPPDATA'];
    if (baseDir == null) return;
    final file = File('$baseDir\\com.passkeyra\\cloud_debug.log');
    file.parent.createSync(recursive: true);
    final now = DateTime.now().toIso8601String();
    file.writeAsStringSync('[$now] $message\n', mode: FileMode.append);
  } catch (_) {
    // Ne jamais faire planter sur le logger.
  }
}
