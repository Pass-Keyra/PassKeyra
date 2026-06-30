// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'PassKeyra';

  @override
  String get settings => 'Configuración';

  @override
  String get settingsSubtitle =>
      'Elija una sección para gestionar su aplicación fácilmente.';

  @override
  String get security => 'Seguridad';

  @override
  String get appearance => 'Apariencia';

  @override
  String get premium => 'Premium';

  @override
  String get backupAndSync => 'Copia de seguridad y sincronización';

  @override
  String get keyboardShortcuts => 'Atajos de teclado';

  @override
  String get aboutAndSupport => 'Acerca de y soporte';

  @override
  String get organization => 'Organización';

  @override
  String get data => 'Datos';

  @override
  String get application => 'Aplicación';

  @override
  String get changeMasterPassword => 'Cambiar Contraseña Maestra';

  @override
  String get changeMasterPasswordSubtitle => 'Modifica tu código de seguridad';

  @override
  String get biometricAuth => 'Autenticación Biométrica';

  @override
  String get biometricAuthSubtitle => 'Usar huella dactilar o Face ID';

  @override
  String get biometricAuthNotAvailable => 'No disponible en este dispositivo';

  @override
  String get lockTimeout => 'Tiempo de Bloqueo';

  @override
  String get autoClose => 'Cierre Automático';

  @override
  String get blurScreen => 'Ocultar Contenido en Segundo Plano';

  @override
  String get blurScreenSubtitle =>
      'Ocultar contenido en el selector de aplicaciones';

  @override
  String get premiumTitle => 'PassKeyra Premium';

  @override
  String get premiumSubtitle => 'Descubre las próximas funciones';

  @override
  String get premiumOnlyTooltip => 'Solo Premium';

  @override
  String get customCategories => 'Categorías Personalizadas';

  @override
  String get customCategoriesSubtitle => 'Gestiona tus categorías';

  @override
  String get export => 'Exportar';

  @override
  String get exportSubtitle => 'Respalda tus datos';

  @override
  String get localBackupTitle => 'Copia de seguridad local';

  @override
  String get localBackupExportSubtitle => 'Exporta tu copia de seguridad local';

  @override
  String get about => 'Acerca de';

  @override
  String get aboutPremium => 'PassKeyra v1.1.11 (Premium activado)';

  @override
  String get aboutFree => 'PassKeyra v1.1.11';

  @override
  String get biometricMigrationTitle => 'Seguridad reforzada';

  @override
  String get biometricMigrationMessage =>
      'PassKeyra ha reforzado la protección biométrica de tu caja fuerte. Para activar esta nueva protección en tu dispositivo, debes introducir tu contraseña maestra una sola vez. El desbloqueo por huella dactilar o reconocimiento facial funcionará normalmente después.';

  @override
  String get biometricMigrationButton => 'Introducir mi contraseña maestra';

  @override
  String get dangerZone => 'Zona peligrosa';

  @override
  String get deleteCloudAccount => 'Eliminar mi cuenta cloud';

  @override
  String get deleteCloudAccountDescription =>
      'Elimina permanentemente tu cuenta Firebase y detiene la sincronización entre tus dispositivos. Tus datos locales y tus copias de seguridad Drive/OneDrive NO se ven afectados.';

  @override
  String get deleteCloudAccountWarning =>
      'Esta acción es irreversible. Tu cuenta Firebase y todos los datos sincronizados en la nube se eliminarán. Podrás crear una nueva cuenta cloud más tarde si lo deseas.';

  @override
  String get deleteCloudAccountConfirm => 'Eliminar permanentemente';

  @override
  String get deleteCloudAccountSuccess => 'Cuenta cloud eliminada';

  @override
  String get deleteCloudAccountReauthRequired =>
      'Por razones de seguridad, vuelve a conectarte a Google e inténtalo de nuevo.';

  @override
  String get havePromoCode => 'Tengo un código promocional';

  @override
  String get redeemPromoCodeError =>
      'No se puede abrir Google Play Store. Comprueba que la aplicación esté instalada.';

  @override
  String get rateApp => 'Calificar Esta App';

  @override
  String get rateAppSubtitle => 'Deja una reseña en la App Store o Play Store';

  @override
  String get thankYouSupport => '¡Gracias por tu apoyo!';

  @override
  String get unlockVault => 'Desbloquear Caja Fuerte';

  @override
  String get secureSetup => 'Configuración Segura';

  @override
  String get createMasterPassword =>
      'Crea tu contraseña maestra para proteger tus contraseñas.';

  @override
  String get newMasterPassword => 'Nueva Contraseña Maestra';

  @override
  String get masterPassword => 'Contraseña Maestra';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get unlock => 'Desbloquear';

  @override
  String get createAccount => 'Crear';

  @override
  String get passwordsDontMatch => 'Las contraseñas no coinciden';

  @override
  String get passwordNoSpaces => 'Espacio detectado (no permitido)';

  @override
  String get passwordMinLength => 'Al menos 8 caracteres';

  @override
  String get passwordNeedsUppercase => 'Se requiere al menos 1 mayúscula (A-Z)';

  @override
  String get passwordNeedsLowercase => 'Se requiere al menos 1 minúscula (a-z)';

  @override
  String get passwordNeedsDigit => 'Se requiere al menos 1 dígito (0-9)';

  @override
  String get passwordNeedsSpecial =>
      'Se requiere al menos 1 carácter especial (!@#\$%...)';

  @override
  String get masterPasswordCreatedSuccess =>
      '¡Contraseña maestra creada con éxito!';

  @override
  String get incorrectMasterPassword => 'Contraseña maestra incorrecta.';

  @override
  String loginAttemptsRemainingWarning(int n) {
    return 'Le quedan $n intentos antes de que su caja fuerte se bloquee durante 24 horas.';
  }

  @override
  String get loginAttemptsLastChance =>
      'Atención: un intento fallido más bloqueará su caja fuerte durante 24 horas.';

  @override
  String get masterPasswordChangeIntroTitle =>
      'Cambio de la contraseña maestra';

  @override
  String get masterPasswordChangeIntroBody =>
      'Va a modificar su contraseña maestra. Se creará automáticamente una copia de seguridad de sus datos.\n\nSi tiene algún problema en los próximos 30 días, podrá volver al estado actual usando su contraseña anterior.\n\n¿Desea continuar?';

  @override
  String get masterPasswordChangeCloudUpdateTitle =>
      'Actualizando su caja fuerte en línea';

  @override
  String get masterPasswordChangeCloudUpdateBody =>
      'Sus datos se están actualizando con su nueva contraseña maestra.\n\nNo cierre la aplicación.';

  @override
  String masterPasswordChangeCloudProgress(int done, int total) {
    return '$done / $total entradas sincronizadas';
  }

  @override
  String get masterPasswordChangeSuccessTitle =>
      'Contraseña maestra modificada';

  @override
  String get masterPasswordChangeSuccessBody =>
      'Su contraseña maestra se ha cambiado correctamente.\n\nSe han creado automáticamente dos copias de seguridad:\n• Una copia de seguridad conservada durante 30 días, que le permite volver al estado anterior si es necesario (con su contraseña anterior).\n• Una nueva copia de seguridad actualizada con su nueva contraseña.\n\nSus datos están protegidos en cualquier caso.';

  @override
  String get masterPasswordChangeSeeBackups => 'Ver mis copias de seguridad';

  @override
  String get masterPasswordChangeFinish => 'Finalizar';

  @override
  String get securityBackupBadge => 'Copia de seguridad';

  @override
  String securityBackupSubtitle(String date, String expiry) {
    return 'Creada el $date. Disponible hasta el $expiry.';
  }

  @override
  String get securityBackupRestoreWarningTitle =>
      'Restaurar un estado anterior';

  @override
  String get securityBackupRestoreWarningBody =>
      'Esta copia de seguridad se creó antes del último cambio de su contraseña maestra.\n\nPara restaurarla, deberá introducir su contraseña anterior. Sus datos actuales serán reemplazados por los de esta copia.\n\n¿Desea continuar?';

  @override
  String get biometryDesktopComingSoon => 'Windows Hello — próximamente';

  @override
  String get lockTimeoutDisabled => 'Desactivado';

  @override
  String get crossDeviceKeyChangedTitle =>
      'Contraseña maestra modificada en otro dispositivo';

  @override
  String get crossDeviceKeyChangedBody =>
      'Su contraseña maestra se ha cambiado en otro dispositivo. Sus datos en línea ya no son accesibles con su contraseña actual desde este dispositivo.\n\nPara seguir usando PassKeyra aquí, importe su última copia de seguridad desde el dispositivo donde realizó el cambio y luego introduzca su nueva contraseña.';

  @override
  String get crossDeviceKeyChangedLater => 'Más tarde';

  @override
  String get onboardingBiometryDesktopMessage =>
      'Esta función estará disponible en una próxima actualización.';

  @override
  String get incorrectMasterPasswordBiometryDisabledAfter3Failures =>
      'Contraseña maestra incorrecta. La biometría se desactivó tras 3 intentos fallidos.';

  @override
  String get biometryNotActivated => 'No se pudo activar la biometría.';

  @override
  String get weakBiometricWarningTitle =>
      'Desbloqueo biométrico menos seguro en este dispositivo';

  @override
  String get weakBiometricWarningMessage =>
      'Este dispositivo no cuenta con biometría fuerte. El desbloqueo biométrico es más práctico, pero menos seguro que tu contraseña maestra: una persona con acceso a tu teléfono podría saltárselo.\n\nTu caja fuerte sigue cifrada con tu contraseña maestra.\n\n¿Activar el desbloqueo biométrico de todas formas?';

  @override
  String get weakBiometricWarningActivateAnyway => 'Activar de todas formas';

  @override
  String get weakBiometricWarningKeepPassword => 'Mantener contraseña maestra';

  @override
  String get biometricReEnrollmentTitle => 'Huella modificada';

  @override
  String get biometricReEnrollmentMessage =>
      'Por tu seguridad, los cambios en tus huellas han desactivado el desbloqueo biométrico. Introduce tu contraseña maestra una vez para reactivarlo.';

  @override
  String get biometricReEnrollmentButton => 'Introducir mi contraseña maestra';

  @override
  String get biometricUpgraded => 'Protección biométrica reforzada';

  @override
  String get biometricAuthSubtitleStrong => 'Protección reforzada (hardware)';

  @override
  String get biometricAuthSubtitleWeak => 'Protección estándar';

  @override
  String get selectAnEntry => 'Seleccione una entrada';

  @override
  String get selectAnEntryHint =>
      'Haga clic en una entrada para ver sus detalles';

  @override
  String get connectionProblem => '¿Problema de Conexión?';

  @override
  String get helpAndSettings => 'Ayuda y Configuración';

  @override
  String get connectionIssues => 'Problemas de Conexión';

  @override
  String get languageSettings => 'Configuración de Idioma';

  @override
  String get importBackup => 'Importar Respaldo';

  @override
  String get resetApp => 'Restablecer Aplicación';

  @override
  String get importBackupDescription => 'Restaurar un respaldo anterior';

  @override
  String get resetAppDescription => 'Borrar todos los datos y empezar de nuevo';

  @override
  String get searchPlaceholder => 'Buscar... (nombre, usuario, URL, etiqueta)';

  @override
  String get all => 'Todos';

  @override
  String get entry => 'entrada';

  @override
  String get entries => 'entradas';

  @override
  String get noEntries => 'Sin entradas';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get addFirstPassword => 'Toca + para agregar tu primera contraseña';

  @override
  String get add => 'Agregar';

  @override
  String get edit => 'Editar';

  @override
  String get copyPassword => 'Copiar Contraseña';

  @override
  String get copyAllInfo => 'Copiar toda la información';

  @override
  String get allInfoCopied => 'Información copiada al portapapeles';

  @override
  String get copyUsername => 'Copiar Usuario';

  @override
  String get delete => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get close => 'Cerrar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get passwordCopied => 'Contraseña copiada (borrado automático en 30s)';

  @override
  String get usernameCopied => 'Usuario copiado';

  @override
  String get urlCopied => 'URL copiada';

  @override
  String get sortByDateDesc => 'Más reciente primero';

  @override
  String get sortByDateAsc => 'Más antiguo primero';

  @override
  String get sortByNameAsc => 'Nombre (A-Z)';

  @override
  String get sortByNameDesc => 'Nombre (Z-A)';

  @override
  String get name => 'Nombre';

  @override
  String get username => 'Usuario';

  @override
  String get password => 'Contraseña';

  @override
  String get passwords => 'Contraseñas';

  @override
  String get additionalPasswordsShort => 'Adicionales';

  @override
  String get url => 'URL';

  @override
  String get notes => 'Notas';

  @override
  String get tags => 'Etiquetas';

  @override
  String get category => 'Categoría';

  @override
  String get additionalPasswords => 'Contraseñas Adicionales';

  @override
  String get additionalPasswordLabel => 'Contraseña adicional';

  @override
  String get required => 'Requerido';

  @override
  String get optional => 'Opcional';

  @override
  String get generatePassword => 'Generar Contraseña';

  @override
  String get passwordLength => 'Longitud';

  @override
  String get includeUppercase => 'Mayúsculas (A-Z)';

  @override
  String get includeLowercase => 'Minúsculas (a-z)';

  @override
  String get includeNumbers => 'Números (0-9)';

  @override
  String get includeSymbols => 'Símbolos (!@#\$...)';

  @override
  String get deleteEntryTitle => 'Eliminar Entrada';

  @override
  String get deleteEntryMessage =>
      '¿Estás seguro de que deseas eliminar esta entrada?';

  @override
  String get deleteEntryConfirm => 'Escribe \"ELIMINAR\" para confirmar';

  @override
  String get deleteKeyword => 'ELIMINAR';

  @override
  String get deleteSuccess => 'Entrada eliminada';

  @override
  String get lockTimeoutImmediate => 'Inmediatamente';

  @override
  String get lockTimeout30s => '30 segundos';

  @override
  String get lockTimeout1m => '1 minuto';

  @override
  String get lockTimeout2m => '2 minutos';

  @override
  String get lockTimeout5m => '5 minutos';

  @override
  String get lockTimeout10m => '10 minutos';

  @override
  String get lockTimeout30m => '30 minutos';

  @override
  String get autoCloseDisabled => 'Desactivado';

  @override
  String get autoClose30s => '30 segundos';

  @override
  String get autoClose1m => '1 minuto';

  @override
  String get autoClose2m => '2 minutos';

  @override
  String get autoClose5m => '5 minutos';

  @override
  String get language => 'Idioma';

  @override
  String get languageSubtitle => 'Cambiar idioma de la aplicación';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get french => 'Francés';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get languageChanged => 'Idioma cambiado con éxito';

  @override
  String get blurEnabled => 'Desenfoque de pantalla activado';

  @override
  String get blurDisabled => 'Desenfoque de pantalla desactivado';

  @override
  String get biometryEnabled => 'Biometría activada';

  @override
  String get biometryDisabled => 'Biometría desactivada';

  @override
  String get biometryError =>
      'Primero debes reconectarte con tu contraseña maestra';

  @override
  String get mustReconnect =>
      'Error: Primero debes reconectarte con tu contraseña maestra';

  @override
  String importSuccess(int count) {
    return '$count entradas importadas con éxito.\nLa biometría se ha desactivado por razones de seguridad.\nLa aplicación se cerrará.';
  }

  @override
  String get exportSuccess => 'Exportación exitosa';

  @override
  String get importError => 'Error de importación';

  @override
  String get error => 'Error';

  @override
  String get createdAt => 'Creado';

  @override
  String get updatedAt => 'Actualizado';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get viewEntry => 'Ver Entrada';

  @override
  String get editEntry => 'Editar Entrada';

  @override
  String get newEntry => 'Nueva Entrada';

  @override
  String get errorCreatingMasterPassword =>
      'Error al crear la contraseña maestra';

  @override
  String get checkMasterPasswordOrBiometry =>
      '1. Verifica tu contraseña maestra o usa biometría.';

  @override
  String get restoreFromBackup => '2. Restaurar desde respaldo:';

  @override
  String get myLocalBackups => 'Mi respaldo local:';

  @override
  String get noLocalBackup => 'Sin respaldo local.';

  @override
  String get backupEntry => 'entrada';

  @override
  String get backupEntries => 'entradas';

  @override
  String get restoreFromBackupButton => 'Restaurar desde respaldo';

  @override
  String get importSourceTitle => 'Elegir fuente de importación';

  @override
  String get importFromLocalFile => 'Archivo local';

  @override
  String get importFromCloud => 'Respaldo en la nube';

  @override
  String get resetApplication => 'Restablecer aplicación';

  @override
  String get resetApplicationConfirm =>
      '¿Estás seguro de que deseas restablecer la aplicación?\n\nTodos tus datos (contraseñas, configuraciones, respaldos) se eliminarán permanentemente.\n\nEscribe RESET para confirmar:';

  @override
  String get resetConfirmWord => 'RESET';

  @override
  String get typeResetToConfirm => 'Escribe RESET para confirmar';

  @override
  String get applicationResetSuccess => 'Aplicación restablecida con éxito';

  @override
  String get biometryNotConfigured =>
      'Biometría no configurada. Usa tu contraseña maestra.';

  @override
  String get biometricUnlockError => 'Error durante el desbloqueo biométrico';

  @override
  String biometricError(String error) {
    return 'Error biométrico: $error';
  }

  @override
  String get biometryTemporarilyBlocked =>
      'Biometría bloqueada temporalmente. Usa tu contraseña maestra.';

  @override
  String get importError2 => 'Error durante la importación';

  @override
  String get vaultAlreadyExists => 'La caja fuerte ya existe';

  @override
  String get vaultExistsMessage =>
      'Ya existe una caja fuerte.\n\nImportar BORRARÁ todos los datos actuales y los reemplazará con el respaldo.\n\nEscribe IMPORTAR para confirmar:';

  @override
  String get understood => 'Entendido';

  @override
  String get importConfirmWord => 'IMPORTAR';

  @override
  String invalidBackup(String error) {
    return 'Respaldo inválido: $error';
  }

  @override
  String get backupMasterPassword => 'Confirmar Contraseña Maestra';

  @override
  String get backupPasswordInstructions =>
      'Introduce la contraseña maestra del respaldo para descifrarlo:';

  @override
  String get import => 'Importar';

  @override
  String get importInProgress => 'Importación en curso...';

  @override
  String get pleaseWait => 'Por favor espera';

  @override
  String get decryptionInProgress => 'Descifrado en curso...';

  @override
  String get decryptionError => 'Error de descifrado';

  @override
  String get incorrectBackupPassword =>
      'Contraseña incorrecta o respaldo corrupto.';

  @override
  String importFailed(String error) {
    return 'Importación fallida: $error';
  }

  @override
  String get other => 'Otro';

  @override
  String get personalCategory => 'Personal';

  @override
  String get workCategory => 'Trabajo';

  @override
  String get bankCategory => 'Banco';

  @override
  String get socialCategory => 'Social';

  @override
  String get emailCategory => 'Correo';

  @override
  String get shoppingCategory => 'Compras';

  @override
  String get entertainmentCategory => 'Entretenimiento';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get filterByCategory => 'Filtrar por categoría';

  @override
  String get premiumFeatures => 'Funciones Premium';

  @override
  String get premiumDescription =>
      'Próximas funciones para suscriptores de PassKeyra Premium';

  @override
  String get cloudSync => 'Sincronización en la Nube';

  @override
  String get cloudSyncDescription =>
      'Sincronización automática en todos tus dispositivos';

  @override
  String get biometricVault => 'Caja Fuerte Biométrica';

  @override
  String get biometricVaultDescription =>
      'Seguridad mejorada con autenticación biométrica';

  @override
  String get prioritySupport => 'Soporte Prioritario';

  @override
  String get prioritySupportDescription =>
      'Obtén ayuda más rápido con soporte prioritario';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get manageCategoriesTitle => 'Gestionar Categorías';

  @override
  String get addCategory => 'Agregar Categoría';

  @override
  String get editCategory => 'Editar Categoría';

  @override
  String get deleteCategory => 'Eliminar Categoría';

  @override
  String get categoryName => 'Nombre de Categoría';

  @override
  String get categoryColor => 'Color de Categoría';

  @override
  String get categoryIcon => 'Icono de Categoría';

  @override
  String get selectColor => 'Seleccionar Color';

  @override
  String get deleteCategoryConfirm => '¿Eliminar esta categoría?';

  @override
  String get categorySaved => 'Categoría guardada';

  @override
  String get categoryDeleted => 'Categoría eliminada';

  @override
  String get import2 => 'Importar';

  @override
  String get importFromFile => 'Importar desde Archivo';

  @override
  String get importInstructions =>
      'Selecciona un archivo de respaldo de PassKeyra (.json) para importar';

  @override
  String get selectFile => 'Seleccionar Archivo';

  @override
  String get noFileSelected => 'Ningún archivo seleccionado';

  @override
  String get importWarning =>
      'Advertencia: ¡Esto reemplazará todos tus datos actuales!';

  @override
  String get exportToFile => 'Exportar a Archivo';

  @override
  String get exportInstructions =>
      'Exporta todas tus contraseñas a un archivo de respaldo seguro';

  @override
  String get exportButton => 'Exportar Ahora';

  @override
  String get exportWarning => '¡Guarda este archivo en un lugar seguro!';

  @override
  String get fileExported => 'Archivo exportado con éxito';

  @override
  String get autoClose45s => '45 segundos';

  @override
  String get securityAnalysis => 'Análisis de Seguridad';

  @override
  String get securityScore => 'Puntuación de Seguridad';

  @override
  String get securityAnalysisPremiumMessage =>
      'El Análisis de Seguridad es una función Premium. Actualiza a Premium para escanear tus contraseñas y detectar debilidades.';

  @override
  String get viewPremium => 'Ver Premium';

  @override
  String get score => 'Puntuación';

  @override
  String get veryWeak => 'Muy Débil';

  @override
  String get weak => 'Débil';

  @override
  String get medium => 'Medio';

  @override
  String get strong => 'Fuerte';

  @override
  String get veryStrong => 'Muy Fuerte';

  @override
  String get analysisSummary => 'Resumen del Análisis';

  @override
  String strongPasswords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contraseñas fuertes',
      one: '1 contraseña fuerte',
      zero: 'Ninguna contraseña fuerte',
    );
    return '$_temp0';
  }

  @override
  String weakPasswords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contraseñas débiles',
      one: '1 contraseña débil',
      zero: 'Ninguna contraseña débil',
    );
    return '$_temp0';
  }

  @override
  String duplicatePasswords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contraseñas duplicadas',
      one: '1 contraseña duplicada',
      zero: 'Ningún duplicado',
    );
    return '$_temp0';
  }

  @override
  String oldPasswords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contraseñas antiguas',
      one: '1 contraseña antigua',
      zero: 'Ninguna contraseña antigua',
    );
    return '$_temp0';
  }

  @override
  String get issuesFound => 'Problemas Encontrados';

  @override
  String get weakPassword => 'Contraseña Débil';

  @override
  String get duplicatePassword => 'Contraseña Duplicada';

  @override
  String get oldPassword => 'Contraseña Antigua';

  @override
  String get alsoUsedIn => 'También usado en';

  @override
  String get recommendations => 'Recomendaciones';

  @override
  String get recommendUseStrongPasswords =>
      'Usa contraseñas más complejas para mayor seguridad';

  @override
  String get recommendUseUniquePasswords =>
      'Evita reutilizar las mismas contraseñas';

  @override
  String get recommendUpdateOldPasswords =>
      'Actualiza las contraseñas antiguas al menos una vez al año';

  @override
  String get recommendUse12PlusChars =>
      'Usa al menos 12 caracteres para tus contraseñas';

  @override
  String get recommendUseSymbols =>
      'Incluye símbolos para fortalecer la seguridad';

  @override
  String get help => 'Ayuda';

  @override
  String get securityAnalysisHelp =>
      'El Análisis de Seguridad examina todas tus contraseñas y detecta:\n\n• Contraseñas débiles (demasiado cortas o simples)\n• Contraseñas duplicadas (usadas varias veces)\n• Contraseñas antiguas (sin cambiar por >1 año)\n\nLa puntuación de seguridad se calcula según:\n• Longitud de la contraseña\n• Variedad de caracteres (mayúsculas, minúsculas, números, símbolos)\n• Complejidad general';

  @override
  String errorDuringAnalysis(String error) {
    return 'Error durante el análisis: $error';
  }

  @override
  String get unableToPerformAnalysis => 'No se puede realizar el análisis';

  @override
  String get retry => 'Reintentar';

  @override
  String passwordNotUpdatedYears(int years) {
    return 'No actualizada en $years año(s)';
  }

  @override
  String get passwordTooShort => 'Demasiado corta (< 8 caracteres)';

  @override
  String get passwordShouldBe12Plus => 'Debería tener 12+ caracteres';

  @override
  String get passwordNoUppercase => 'Sin mayúsculas';

  @override
  String get passwordNoLowercase => 'Sin minúsculas';

  @override
  String get passwordNoNumbers => 'Sin números';

  @override
  String get passwordNoSymbols => 'Sin símbolos';

  @override
  String get weakPasswordGeneric => 'Contraseña débil';

  @override
  String usedInEntries(int count) {
    return 'Usado en $count entradas';
  }

  @override
  String get customIcon => 'Icono Personalizado';

  @override
  String get chooseIcon => 'Elegir un Icono';

  @override
  String get changeIcon => 'Cambiar Icono';

  @override
  String get iconSelected => 'Icono Seleccionado';

  @override
  String get chooseColor => 'Elegir un Color';

  @override
  String get customIconsPremiumFeature =>
      'Los iconos personalizados están reservados para usuarios Premium. ¡Actualiza a Premium para desbloquear esta función y mucho más!';

  @override
  String get categoryIconsTab => 'Iconos';

  @override
  String get categoryEmojisTab => 'Emojis';

  @override
  String get categoryEmojisPremium =>
      'Los emojis para categorías están reservados para usuarios Premium';

  @override
  String get categoryColorPicker => 'Paleta Completa';

  @override
  String get categoryPredefinedColors => 'Colores Predefinidos';

  @override
  String get theme => 'Tema';

  @override
  String get themeSubtitle => 'Modo claro, oscuro o sistema';

  @override
  String get selectTheme => 'Seleccionar un Tema';

  @override
  String get themeMode => 'Modo de Visualización';

  @override
  String get lightMode => 'Modo Claro';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get systemMode => 'Modo automático';

  @override
  String get systemModeSubtitle => 'Basado en la luz ambiente';

  @override
  String get darkVariant => 'Variante del Modo Oscuro';

  @override
  String get standardDark => 'Oscuro Estándar';

  @override
  String get standardDarkSubtitle => 'Modo oscuro clásico';

  @override
  String get amoledBlack => 'Negro AMOLED';

  @override
  String get amoledBlackSubtitle => 'Negro puro para pantallas OLED';

  @override
  String get darkGrey => 'Gris Oscuro';

  @override
  String get darkGreySubtitle => 'Gris personalizado elegante';

  @override
  String get darkThemePremiumFeature =>
      'Las variantes avanzadas del modo oscuro (Negro AMOLED y Gris oscuro) están reservadas para usuarios Premium. ¡Actualiza a Premium para desbloquear estos temas y mucho más!';

  @override
  String get colorPalette => 'Paleta de Colores';

  @override
  String get colorPaletteBlue => 'Azul (Clásica)';

  @override
  String get colorPaletteGreen => 'Verde';

  @override
  String get colorPaletteRedPink => 'Rojo/Rosa';

  @override
  String get colorPalettePurple => 'Violeta';

  @override
  String get colorPaletteOrange => 'Naranja';

  @override
  String get colorPalettePremiumFeature =>
      'Las paletas de colores personalizadas están reservadas para usuarios Premium. ¡Actualiza a Premium para desbloquear todas las paletas y mucho más!';

  @override
  String get fontFamily => 'Familia de Fuentes';

  @override
  String get fontRoboto => 'Roboto';

  @override
  String get fontLato => 'Lato';

  @override
  String get fontMontserrat => 'Montserrat';

  @override
  String get fontOpenSans => 'Open Sans';

  @override
  String get fontFamilyPremiumFeature =>
      'Las fuentes personalizadas están reservadas para usuarios Premium. ¡Actualiza a Premium para desbloquear todas las fuentes y mucho más!';

  @override
  String get cloudBackup => 'Copia de seguridad en la nube';

  @override
  String get cloudBackupSubtitle => 'Guardar en la nube';

  @override
  String get cloudBackupTitle => 'Copia de seguridad en la nube';

  @override
  String get cloudProviderSelectionDescription =>
      'Elija su servicio en la nube preferido para realizar copias de seguridad de sus contraseñas de forma segura. Puede cambiar de servicio en cualquier momento.';

  @override
  String get selectCloudProvider => 'Elegir servicio en la nube';

  @override
  String get switchProviderTitle => 'Cambiar servicio en la nube';

  @override
  String switchProviderMessage(Object currentProvider, Object newProvider) {
    return '¿Cerrar sesión de $currentProvider y cambiar a $newProvider?';
  }

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get uploadToCloud => 'Guardar en la nube';

  @override
  String get restoreFromCloud => 'Restaurar desde la nube';

  @override
  String get cloudBackupSuccess => 'Copia en la nube exitosa';

  @override
  String get cloudDisconnectTitle => '¿Desconectar la cuenta de Google?';

  @override
  String get cloudDisconnectMessage =>
      'La copia de seguridad de Google Drive y la sincronización Premium usan la misma cuenta de Google: la sincronización es la extensión Premium de la copia de Drive. Por lo tanto, desconectar detiene ambas. Tus datos locales y las copias ya guardadas en la nube se conservan. Puedes volver a conectarte y elegir otra cuenta en cualquier momento.';

  @override
  String get cloudDisconnectConfirm => 'Desconectar';

  @override
  String get cloudDisconnectGenericTitle =>
      '¿Desconectar la cuenta en la nube?';

  @override
  String get cloudDisconnectGenericMessage =>
      'Esta acción desactiva la copia de seguridad automática, desconecta tu cuenta en la nube y borra la configuración del proveedor. Las copias ya guardadas en la nube y tus datos locales se conservan.';

  @override
  String cloudBackupFailed(Object error) {
    return 'Error en copia de nube: $error';
  }

  @override
  String get noCloudBackups => 'No se encontraron copias en la nube';

  @override
  String lastCloudBackup(Object date) {
    return 'Última copia: $date';
  }

  @override
  String get cloudQuotaExceeded => 'Cuota de nube excedida';

  @override
  String get cloudProviderNotAvailable => 'Servicio en la nube no disponible';

  @override
  String authenticateWith(Object provider) {
    return 'Iniciar sesión en $provider';
  }

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get deleteBackup => 'Eliminar copia';

  @override
  String get downloadBackup => 'Descargar copia';

  @override
  String get restore => 'Restaurar';

  @override
  String cloudRestoreConfirmation(Object date) {
    return '¿Restaurar copia del $date? Esto reemplazará todos tus datos actuales.';
  }

  @override
  String cloudRestoreSuccess(Object count) {
    return 'Copia restaurada exitosamente ($count entradas)';
  }

  @override
  String cloudRestoreFailed(Object error) {
    return 'Error al restaurar: $error';
  }

  @override
  String get restoreSuccessAutoClose =>
      '¡Restauración exitosa!\n\nLa aplicación se cerrará automáticamente en 2 segundos para aplicar los cambios.';

  @override
  String cloudDeleteConfirmation(Object date) {
    return '¿Eliminar permanentemente la copia del $date?';
  }

  @override
  String get cloudBackupDeleted => 'Copia eliminada';

  @override
  String cloudDeleteFailed(Object error) {
    return 'Error al eliminar: $error';
  }

  @override
  String get cloudNoBackupsHint =>
      'Toca el botón de abajo para crear tu primera copia';

  @override
  String cloudRateLimitMessage(Object minutes) {
    return 'Por favor espera $minutes minuto(s) antes de la próxima copia';
  }

  @override
  String get cloudAuthenticationFailed => 'Error de autenticación';

  @override
  String get cloudNoAuthService => 'Servicio de autenticación no disponible';

  @override
  String get cloudSyncTitle => 'Sincronización en la nube';

  @override
  String get cloudSyncSubtitle =>
      'Sincronización automática en tiempo real entre dispositivos';

  @override
  String get cloudSyncSettings => 'Configuración de sincronización';

  @override
  String get cloudSyncAccount => 'Cuenta en la nube';

  @override
  String get cloudSyncNoAccount => 'Ninguna cuenta de Google conectada';

  @override
  String get cloudSyncSignIn => 'Iniciar sesión con Google';

  @override
  String get cloudSyncSignOut => 'Cerrar sesión';

  @override
  String get cloudSyncAutomatic => 'Sincronización automática';

  @override
  String get cloudSyncEnabled => 'Los cambios se sincronizan automáticamente';

  @override
  String get cloudSyncDisabled => 'Sincronización manual solamente';

  @override
  String get cloudSyncManualActions => 'Acciones manuales';

  @override
  String get cloudSyncUpload => 'Subir a la nube';

  @override
  String get cloudSyncDownload => 'Descargar desde la nube';

  @override
  String get cloudSyncPremiumFeature => 'Función Premium';

  @override
  String get cloudSyncPremiumMessage =>
      'La sincronización en tiempo real requiere PassKeyra Premium';

  @override
  String get syncStatusIdle => 'Inactivo';

  @override
  String get syncStatusSyncing => 'Sincronizando...';

  @override
  String get syncStatusSuccess => 'Sincronizado';

  @override
  String get syncStatusError => 'Error de sincronización';

  @override
  String get syncStatusConflict => 'Conflicto detectado';

  @override
  String get syncLastSyncNever => 'Nunca sincronizado';

  @override
  String get syncLastSyncJustNow => 'Ahora mismo';

  @override
  String syncLastSyncMinutes(Object minutes) {
    return 'Hace $minutes min';
  }

  @override
  String syncLastSyncHours(Object hours) {
    return 'Hace $hours h';
  }

  @override
  String syncLastSyncDays(Object days) {
    return 'Hace $days días';
  }

  @override
  String syncEntriesUploaded(Object count) {
    return '$count entradas sincronizadas';
  }

  @override
  String syncEntriesDownloaded(Object count) {
    return '$count entradas descargadas';
  }

  @override
  String syncMergeCompleted(Object count) {
    return 'Fusión completada ($count entradas)';
  }

  @override
  String get syncConflictResolved =>
      'Conflicto resuelto (versión más reciente conservada)';

  @override
  String get syncEnabled => 'Sincronización activada';

  @override
  String get syncDisabled => 'Sincronización desactivada';

  @override
  String get syncErrorOffline => 'Error: Sin conexión a internet';

  @override
  String get syncErrorAuth => 'Error: Autenticación expirada';

  @override
  String get syncErrorQuota => 'Error: Cuota de Firebase excedida';

  @override
  String get helpLogosTitle => 'Significado de los logos';

  @override
  String get helpLogoCloud => 'Logo Cloud (☁️)';

  @override
  String get helpLogoCloudSubtitle =>
      'Copia de seguridad automática de Google Drive';

  @override
  String get helpLogoSync => 'Logo Sync (⇄)';

  @override
  String get helpLogoSyncSubtitle => 'Sincronización Firebase en tiempo real';

  @override
  String get helpColorLegend => 'Código de colores (para ambos logos):';

  @override
  String get helpColorBlue => 'Azul';

  @override
  String get helpColorBlueMeaning => 'Activado y listo';

  @override
  String get helpColorPurple => 'Violeta';

  @override
  String get helpColorPurpleMeaning => 'Sincronización en curso';

  @override
  String get helpColorGreen => 'Verde';

  @override
  String get helpColorGreenMeaning => 'Operación exitosa';

  @override
  String get helpColorRed => 'Rojo';

  @override
  String get helpColorRedMeaning => 'Error';

  @override
  String get helpColorGrey => 'Gris';

  @override
  String get helpColorGreyMeaning => 'Desactivado';

  @override
  String syncConnectedAs(Object email) {
    return 'Conectado como $email';
  }

  @override
  String get syncDisconnected => 'Desconectado';

  @override
  String get syncAutoLabel => 'Sync auto';

  @override
  String get syncManualLabel => 'Sync manual';

  @override
  String get androidVersionWarningTitle => 'Funciones limitadas';

  @override
  String get androidVersionWarningMessage =>
      'Su versión de Android (< 8.0) no admite la restauración de copias de seguridad. Para una experiencia completa, use Android 8.0 o superior. La creación y visualización de copias de seguridad siguen disponibles.';

  @override
  String get onboardingFirstChoiceTitle => 'Tutorial de inicio';

  @override
  String get onboardingFirstChoiceMessage =>
      'Desea una guia rapida antes de crear su caja fuerte?';

  @override
  String get onboardingStartTutorial => 'Iniciar tutorial';

  @override
  String get onboardingSkipTutorial => 'Salir';

  @override
  String get onboardingQuitTitle => 'Tutorial cerrado';

  @override
  String get onboardingQuitMessage =>
      'Puede volver a verlo cuando quiera desde Configuración → Tutoriales.';

  @override
  String get onboardingMasterPasswordTitle => 'Aviso de clave maestra';

  @override
  String get onboardingMasterPasswordMessage =>
      'Su clave maestra es la unica llave. Si se pierde, no hay recuperacion.';

  @override
  String get onboardingSecurityRequirements => 'Requisitos de seguridad:';

  @override
  String get onboardingRuleLength => 'Minimo 12 caracteres (16+ recomendado)';

  @override
  String get onboardingRuleComplexity =>
      'Mayusculas, minusculas, numeros, simbolos';

  @override
  String get onboardingRuleDictionary => 'Evite palabras de diccionario';

  @override
  String get onboardingRuleUnique => 'Use una clave unica, nunca reutilizada';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingFinish => 'Finalizar';

  @override
  String get onboardingCreateFirstEntry => 'Crear mi primera entrada';

  @override
  String get onboardingStepSearchTitle => 'Búsqueda rápida';

  @override
  String get onboardingStepSearchBody =>
      'La búsqueda filtra entradas por nombre, usuario, URL o etiquetas.';

  @override
  String get onboardingStepSettingsTitle => 'Acceso a ajustes';

  @override
  String get onboardingStepSettingsBody =>
      'Este menú agrupa todos los ajustes de seguridad y otras opciones.';

  @override
  String get onboardingStepAddTitle => 'Creación de una entrada';

  @override
  String get onboardingStepAddBody =>
      'El botón + crea una nueva entrada en la caja fuerte.';

  @override
  String get onboardingStepCopyAllTitle => 'Copiar una entrada';

  @override
  String get onboardingStepCopyAllBody =>
      'Este botón copia toda la información útil de la entrada: usuario, contraseña, URL y notas si están presentes.';

  @override
  String get onboardingRestart => 'Reiniciar tutorial';

  @override
  String get onboardingRestartDescription =>
      'Volver a reproducir el tutorial completo de inicio';

  @override
  String get onboardingWillRestart =>
      'El tutorial se reiniciará en el próximo inicio de la aplicación.';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingFinishLater => 'Terminar más tarde';

  @override
  String get onboardingSecurityPauseTitle => 'Resumen de seguridad';

  @override
  String get onboardingSecurityPauseMessage =>
      '¿Continuar con una descripción de las funciones de seguridad? (3 pasos rápidos)';

  @override
  String get onboardingSecurityReportTitle => 'Análisis de seguridad';

  @override
  String get onboardingSecurityReportMessage =>
      'El informe de seguridad analiza las contraseñas y detecta problemas: contraseñas débiles, reutilizadas o comprometidas.';

  @override
  String get onboardingLockTimeoutTitle => 'Bloqueo automático';

  @override
  String get onboardingLockTimeoutMessage =>
      'La aplicación se bloquea automáticamente después de un período de inactividad para proteger los datos.';

  @override
  String get onboardingBiometryTitle => 'Autenticación biométrica';

  @override
  String get onboardingBiometryMessage =>
      'Desbloqueo rápido y seguro con huella digital o reconocimiento facial.';

  @override
  String get onboardingCompleteMessage =>
      '¡Ahora conoces todas las funciones esenciales de PassKeyra. ¡Disfrútalo!';

  @override
  String get discoveryModeTitle => 'Tutoriales';

  @override
  String get discoveryModeSubtitle =>
      'Aprenda a usar todas las funciones de PassKeyra a su ritmo';

  @override
  String get discoverySteps => 'pasos';

  @override
  String get discoveryCompleted => 'Completado';

  @override
  String get discoveryStart => 'Iniciar';

  @override
  String get discoveryReplay => 'Repetir';

  @override
  String get discoveryEntriesTitle => 'Gestión avanzada de entradas';

  @override
  String get discoveryEntriesDescription =>
      'Descubra cómo ver, editar y organizar sus entradas';

  @override
  String get discoveryEntriesViewTitle => 'Ver una entrada';

  @override
  String get discoveryEntriesViewMessage =>
      'Toque una entrada en la lista para mostrar todos sus detalles: contraseña, usuario, URL, notas y categoría.';

  @override
  String get discoveryEntriesCopyTitle => 'Copia rápida';

  @override
  String get discoveryEntriesCopyMessage =>
      'Toque la contraseña o el usuario para copiarlo instantáneamente al portapapeles.';

  @override
  String get discoveryEntriesGeneratorTitle => 'Generador de contraseñas';

  @override
  String get discoveryEntriesGeneratorMessage =>
      'Use el generador para crear contraseñas fuertes y únicas. Personalice la longitud y los caracteres incluidos.';

  @override
  String get discoveryEntriesAdditionalTitle => 'Contraseñas adicionales';

  @override
  String get discoveryEntriesAdditionalMessage =>
      'Agregue múltiples contraseñas a la misma entrada (ej: contraseña principal + código PIN).';

  @override
  String get discoveryEntriesCategoriesTitle => 'Categorías personalizadas';

  @override
  String get discoveryEntriesCategoriesMessage =>
      'Cree sus propias categorías para organizar sus entradas como desee.';

  @override
  String get discoveryBackupTitle => 'Copia de seguridad y sincronización';

  @override
  String get discoveryBackupDescription =>
      'Proteja sus datos y sincronice entre dispositivos';

  @override
  String get discoveryBackupLocalTitle => 'Copias de seguridad locales';

  @override
  String get discoveryBackupLocalMessage =>
      'Exporte sus datos a su dispositivo para respaldarlos o transferirlos. También puede importar desde un archivo de copia de seguridad.';

  @override
  String get discoveryBackupDriveTitle => 'Google Drive';

  @override
  String get discoveryBackupDriveMessage =>
      'Realice copias de seguridad automáticas de sus datos cifrados en Google Drive para recuperarlos en caso de problemas.';

  @override
  String get discoveryBackupSyncTitle => 'Sincronización Firebase';

  @override
  String get discoveryBackupSyncMessage =>
      'Sincronice automáticamente sus entradas en todos sus dispositivos en tiempo real (función Premium).';

  @override
  String get discoveryBackupConflictsTitle => 'Resolución de conflictos';

  @override
  String get discoveryBackupConflictsMessage =>
      'En caso de cambios simultáneos en múltiples dispositivos, elija qué versión conservar.';

  @override
  String get discoveryAppearanceTitle => 'Apariencia y Premium';

  @override
  String get discoveryAppearanceDescription =>
      'Personalice la interfaz y descubra las funciones Premium';

  @override
  String get discoveryAppearanceThemesTitle => 'Temas';

  @override
  String get discoveryAppearanceThemesMessage =>
      'Elija entre 4 temas: Claro, Oscuro, AMOLED Black o Gris oscuro. El modo adaptativo se ajusta automáticamente según la luz ambiente.';

  @override
  String get discoveryAppearancePalettesTitle => 'Paletas de colores';

  @override
  String get discoveryAppearancePalettesMessage =>
      'Personalice la interfaz con 5 paletas de colores diferentes (función Premium).';

  @override
  String get discoveryAppearanceFontsTitle => 'Fuentes personalizadas';

  @override
  String get discoveryAppearanceFontsMessage =>
      'Cambie la fuente de la aplicación entre 4 opciones disponibles (función Premium).';

  @override
  String get discoveryAppearancePremiumTitle => 'PassKeyra Premium';

  @override
  String get discoveryAppearancePremiumMessage =>
      'Desbloquee todas las funciones: paletas, fuentes, sincronización en tiempo real, análisis de seguridad avanzado, ¡y más!';

  @override
  String get discoveryPremiumTitle => 'Funciones Premium';

  @override
  String get discoveryPremiumDescription =>
      'Descubra todas las funciones exclusivas Premium';

  @override
  String get discoveryPremiumIntroMessage =>
      'Descubra todas las funciones exclusivas de PassKeyra Premium.';

  @override
  String get discoveryPremiumPalettesTitle => 'Paletas y Fuentes';

  @override
  String get discoveryPremiumPalettesMessage =>
      'Personalice la apariencia con paletas de colores y fuentes exclusivas Premium.';

  @override
  String get discoveryPremiumSecurityTitle => 'Análisis de seguridad';

  @override
  String get discoveryPremiumSecurityMessage =>
      'El análisis de seguridad verifica la fuerza de sus contraseñas y detecta problemas (contraseñas débiles, reutilizadas o comprometidas).';

  @override
  String get discoveryPremiumCompleteMessage =>
      '¡Ahora conoce todas las funciones Premium de PassKeyra!';

  @override
  String get onboardingStepSortTitle => 'Ordenar y filtrar';

  @override
  String get onboardingStepSortBody =>
      'Ordene las entradas por nombre o fecha con este botón. Reorganice rápidamente su lista para encontrar lo que necesita.';

  @override
  String get onboardingStepCategoriesTitle => 'Filtros por categoría';

  @override
  String get onboardingStepCategoriesBody =>
      'Toque una categoría para filtrar sus entradas. Desplace horizontalmente para ver todas las categorías disponibles.';

  @override
  String get onboardingSettingsSecurityTitle => 'Configuración de seguridad';

  @override
  String get onboardingSettingsSecurityBody =>
      'Esta sección le permite configurar el bloqueo automático, la biometría y todas las opciones de seguridad de su caja fuerte.';

  @override
  String get onboardingSettingsBackupTitle =>
      'Copia de seguridad y sincronización';

  @override
  String get onboardingSettingsBackupBody =>
      'Gestione sus copias de seguridad locales y en la nube, y configure la sincronización entre sus dispositivos.';

  @override
  String get onboardingSettingsAppearanceTitle => 'Apariencia';

  @override
  String get onboardingSettingsAppearanceBody =>
      'Personalice el idioma, el tema y las categorías de su aplicación.';

  @override
  String get onboardingBackupLocalTitle => 'Copia de seguridad local';

  @override
  String get onboardingBackupLocalBody =>
      'Exporte su caja fuerte a este dispositivo o restáurela desde una copia de seguridad existente.';

  @override
  String get onboardingBackupCloudTitle => 'Copia de seguridad en la nube';

  @override
  String get onboardingBackupCloudBody =>
      'Guarde su caja fuerte en la nube para acceder a ella desde todos sus dispositivos.';

  @override
  String get onboardingChangeMasterPasswordTitle => 'Contraseña maestra';

  @override
  String get onboardingChangeMasterPasswordMessage =>
      'Su contraseña maestra es la única llave de su caja fuerte. Puede cambiarla aquí en cualquier momento.';

  @override
  String get onboardingAutoCloseTitle => 'Cierre automático';

  @override
  String get onboardingAutoCloseMessage =>
      'La aplicación puede cerrarse automáticamente después de un período de inactividad para mayor protección.';

  @override
  String get onboardingLoginAttemptsTitle => 'Intentos de conexión';

  @override
  String get onboardingLoginAttemptsMessage =>
      'Limite el número de intentos fallidos antes del bloqueo temporal del cofre.';

  @override
  String get premiumTutorialIntroTitle => '¡Bienvenido a PassKeyra Premium!';

  @override
  String get premiumTutorialIntroMessage =>
      'Exploremos tus nuevas funciones. Nota: la sincronización y la copia de seguridad requieren una cuenta de Google conectada a PassKeyra.';

  @override
  String get premiumTutorialNoAdsTitle => 'Sin publicidad';

  @override
  String get premiumTutorialNoAdsMessage =>
      'Como usuario Premium, disfruta de la aplicación sin publicidad ni interrupciones.';

  @override
  String get premiumTutorialCloudSyncTitle => 'Sincronización en la nube';

  @override
  String get premiumTutorialCloudSyncMessage =>
      'Activa la sincronización para mantener tu bóveda actualizada en todos tus dispositivos. Requiere una cuenta de Google conectada a PassKeyra.';

  @override
  String get premiumTutorialBackupTitle => 'Lista de copias de seguridad';

  @override
  String get premiumTutorialBackupMessage =>
      'Tus copias de seguridad aparecen aquí. Cada nueva copia reemplaza la anterior - tu bóveda siempre está protegida.';

  @override
  String get premiumTutorialAutoBackupTitle => 'Copia de seguridad automática';

  @override
  String get premiumTutorialAutoBackupMessage =>
      'Activa la copia de seguridad automática para que tu bóveda se guarde en la nube con cada cambio.';

  @override
  String get premiumTutorialManualBackupTitle => 'Copia de seguridad manual';

  @override
  String get premiumTutorialManualBackupMessage =>
      'Pulsa este botón para guardar tu bóveda en la nube de inmediato.';

  @override
  String get premiumTutorialProviderNameTitle => 'Tu proveedor actual';

  @override
  String get premiumTutorialProviderNameMessage =>
      'El nombre mostrado aquí indica tu proveedor de copia de seguridad en la nube. Puedes cambiarlo en cualquier momento usando el icono en la parte superior derecha.';

  @override
  String get premiumTutorialChangeProviderTitle => 'Cambiar proveedor';

  @override
  String get premiumTutorialChangeProviderMessage =>
      'Pulsa el icono de nube en la parte superior derecha para cambiar tu proveedor de almacenamiento en cualquier momento.';

  @override
  String get premiumTutorialIconsTitle => 'Iconos y contraseñas múltiples';

  @override
  String get premiumTutorialIconsMessage =>
      'Personaliza cada entrada con un emoji y añade varias contraseñas por entrada desde la página de edición.';

  @override
  String get premiumTutorialSecurityTitle => 'Seguridad y apariencia';

  @override
  String get premiumTutorialSecurityMessage =>
      'Consulta tu puntuación de seguridad en Ajustes › Seguridad. Personaliza fuentes y paletas en Ajustes › Apariencia.';

  @override
  String get premiumTutorialSecurityReportTitle =>
      '¡Análisis de seguridad desbloqueado!';

  @override
  String get premiumTutorialSecurityReportMessage =>
      'Aquí está tu informe de seguridad. Consulta tu puntuación global y las recomendaciones para fortalecer tus contraseñas. Accesible en cualquier momento desde Ajustes › Seguridad.';

  @override
  String get premiumTutorialCompleteMessage =>
      'Has descubierto todas tus funciones Premium. ¡Disfruta PassKeyra al máximo!';

  @override
  String get premiumLocalAutoBackupTitle =>
      'Copia de seguridad local automática';

  @override
  String get premiumLocalAutoBackupDescription =>
      'Copia de seguridad cifrada automática en tu dispositivo a cada modificación del cofre';

  @override
  String get premiumTutorialLocalBackupTitle =>
      'Copia de seguridad local automática';

  @override
  String get premiumTutorialLocalBackupMessage =>
      'Activa esta opción para que tu cofre se guarde automáticamente en tu dispositivo a cada modificación, independientemente de la nube.';

  @override
  String get cloudSyncRequiresGoogle =>
      'La sincronización requiere una cuenta de Google conectada a PassKeyra.';

  @override
  String get premiumTutorialEmojiTitle => 'Personalización';

  @override
  String get premiumTutorialEmojiMessage =>
      'Pulsa aquí para añadir un emoji a esta entrada. Cada cuenta puede tener su propio ícono.';

  @override
  String get premiumTutorialMultiPasswordTitle => 'Contraseñas múltiples';

  @override
  String get premiumTutorialMultiPasswordMessage =>
      'Añade varias contraseñas a una misma entrada: ideal si usas combinaciones distintas para un mismo servicio.';

  @override
  String get firstEntryTutorialNameTitle => 'Nombre de la entrada';

  @override
  String get firstEntryTutorialNameMessage =>
      'Ingresa un nombre reconocible para identificar esta cuenta fácilmente.';

  @override
  String get firstEntryTutorialCategoryTitle => 'Categoría';

  @override
  String get firstEntryTutorialCategoryMessage =>
      'Asigna una categoría a esta entrada para encontrar tus cuentas más rápido.';

  @override
  String get firstEntryTutorialUsernameTitle => 'Nombre de usuario';

  @override
  String get firstEntryTutorialUsernameMessage =>
      'Ingresa tu nombre de usuario o correo electrónico para esta cuenta.';

  @override
  String get firstEntryTutorialPasswordTitle => 'Contraseña';

  @override
  String get firstEntryTutorialPasswordMessage =>
      'Ingresa tu contraseña o abre el generador para crear una segura.';

  @override
  String get firstEntryTutorialOpenGenerator => 'Abrir generador';

  @override
  String get firstEntryTutorialGeneratorLengthTitle => 'Longitud';

  @override
  String get firstEntryTutorialGeneratorLengthMessage =>
      'Desliza para elegir la longitud (se recomiendan 16 caracteres o más).';

  @override
  String get firstEntryTutorialGeneratorLowerTitle => 'Minúsculas';

  @override
  String get firstEntryTutorialGeneratorLowerMessage =>
      'Incluye letras minúsculas (a-z) para reforzar tu contraseña.';

  @override
  String get firstEntryTutorialGeneratorUpperTitle => 'Mayúsculas';

  @override
  String get firstEntryTutorialGeneratorUpperMessage =>
      'Agrega mayúsculas (A-Z) para hacer la contraseña más compleja.';

  @override
  String get firstEntryTutorialGeneratorDigitsTitle => 'Números';

  @override
  String get firstEntryTutorialGeneratorDigitsMessage =>
      'Incluye números (0-9) para aumentar la seguridad.';

  @override
  String get firstEntryTutorialGeneratorSymbolsTitle => 'Símbolos';

  @override
  String get firstEntryTutorialGeneratorSymbolsMessage =>
      'Agrega símbolos (!@#\$…) para maximizar la resistencia a ataques.';

  @override
  String get firstEntryTutorialUrlTitle => 'URL';

  @override
  String get firstEntryTutorialUrlMessage =>
      'Añade la URL del sitio web asociado a esta cuenta (opcional).';

  @override
  String get firstEntryTutorialNotesTitle => 'Notas';

  @override
  String get firstEntryTutorialNotesMessage =>
      'Agrega información adicional: preguntas de seguridad, códigos, etc.';

  @override
  String get firstEntryTutorialTagsTitle => 'Etiquetas';

  @override
  String get firstEntryTutorialTagsMessage =>
      'Agrega etiquetas separadas por comas para facilitar la búsqueda.';

  @override
  String get firstEntryTutorialEmojiTitle => 'Ícono personalizado';

  @override
  String get firstEntryTutorialEmojiMessage =>
      'Asocia un emoji a esta entrada para reconocerla de un vistazo.';

  @override
  String get firstEntryTutorialAdditionalPasswordsTitle =>
      'Contraseñas adicionales';

  @override
  String get firstEntryTutorialAdditionalPasswordsMessage =>
      'Añade varias contraseñas a una misma entrada (PIN, perfiles múltiples…).';

  @override
  String get firstEntryTutorialSaveTitle => 'Guardar entrada';

  @override
  String get firstEntryTutorialSaveMessage =>
      '¡Todo listo! Pulsa el botón ✓ para guardar esta entrada en tu caja fuerte.';

  @override
  String get firstEntryTutorialSaveAction => 'Entendido';

  @override
  String get firstEntryTutorialCardTitle => '¡Tu primera entrada!';

  @override
  String get firstEntryTutorialCardMessage =>
      'Tu entrada está guardada. Exploremos las acciones disponibles en cada tarjeta.';

  @override
  String get firstEntryTutorialCopyPasswordTitle => 'Copiar contraseña';

  @override
  String get firstEntryTutorialCopyPasswordMessage =>
      'Este botón copia solo la contraseña (se borra automáticamente después de 30 s).';

  @override
  String get firstEntryTutorialCopyAllTitle => 'Copiar toda la información';

  @override
  String get firstEntryTutorialCopyAllMessage =>
      'Este botón copia de una vez el nombre, usuario, contraseña, URL y notas.';

  @override
  String get firstEntryTutorialTapCardTitle => 'Ver la entrada';

  @override
  String get firstEntryTutorialTapCardMessage =>
      'Toca la tarjeta para ver el detalle completo y editar la entrada.';

  @override
  String get discoveryFirstEntryTitle => 'Crear una entrada';

  @override
  String get discoveryFirstEntryDescription =>
      'Aprende a crear, rellenar y gestionar tu primera entrada de principio a fin.';

  @override
  String get discoveryFirstEntrySteps => '14 pasos';
}
