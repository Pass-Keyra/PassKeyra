// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PassKeyra';

  @override
  String get settings => 'Settings';

  @override
  String get security => 'Security';

  @override
  String get premium => 'Premium';

  @override
  String get organization => 'Organization';

  @override
  String get data => 'Data';

  @override
  String get application => 'Application';

  @override
  String get changeMasterPassword => 'Change Master Password';

  @override
  String get changeMasterPasswordSubtitle => 'Modify your security code';

  @override
  String get biometricAuth => 'Biometric Authentication';

  @override
  String get biometricAuthSubtitle => 'Use fingerprint or Face ID';

  @override
  String get biometricAuthNotAvailable => 'Not available on this device';

  @override
  String get lockTimeout => 'Lock Timeout';

  @override
  String get autoClose => 'Auto Close';

  @override
  String get blurScreen => 'Hide Content in Background';

  @override
  String get blurScreenSubtitle => 'Hide content in app switcher';

  @override
  String get premiumTitle => 'PassKeyra Premium';

  @override
  String get premiumSubtitle => 'Discover upcoming features';

  @override
  String get premiumOnlyTooltip => 'Premium only';

  @override
  String get customCategories => 'Custom Categories';

  @override
  String get customCategoriesSubtitle => 'Manage your categories';

  @override
  String get export => 'Export';

  @override
  String get exportSubtitle => 'Backup your data';

  @override
  String get localBackupTitle => 'Local Backup';

  @override
  String get localBackupExportSubtitle => 'Export your local backup';

  @override
  String get about => 'About';

  @override
  String get aboutPremium => 'PassKeyra v1.1.0 (Premium activated)';

  @override
  String get aboutFree => 'PassKeyra v1.1.0';

  @override
  String get biometricMigrationTitle => 'Enhanced security';

  @override
  String get biometricMigrationMessage =>
      'PassKeyra has strengthened the biometric protection of your vault. To enable this new protection on your device, you need to enter your master password once. Fingerprint or face unlock will work normally afterwards.';

  @override
  String get biometricMigrationButton => 'Enter my master password';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get deleteCloudAccount => 'Delete my cloud account';

  @override
  String get deleteCloudAccountDescription =>
      'Permanently deletes your Firebase account and stops synchronization across your devices. Your local data and your Drive/OneDrive backups are NOT affected.';

  @override
  String get deleteCloudAccountWarning =>
      'This action is irreversible. Your Firebase account and all synchronized cloud data will be deleted. You may create a new cloud account later if you wish.';

  @override
  String get deleteCloudAccountConfirm => 'Delete permanently';

  @override
  String get deleteCloudAccountSuccess => 'Cloud account deleted';

  @override
  String get deleteCloudAccountReauthRequired =>
      'For security reasons, reconnect to Google then try again.';

  @override
  String get havePromoCode => 'I have a promo code';

  @override
  String get redeemPromoCodeError =>
      'Could not open Google Play Store. Check that the app is installed.';

  @override
  String get rateApp => 'Rate This App';

  @override
  String get rateAppSubtitle => 'Leave a review on the App Store or Play Store';

  @override
  String get thankYouSupport => 'Thank you for your support!';

  @override
  String get unlockVault => 'Unlock Vault';

  @override
  String get secureSetup => 'Secure Setup';

  @override
  String get createMasterPassword =>
      'Create your master password to protect your passwords.';

  @override
  String get newMasterPassword => 'New Master Password';

  @override
  String get masterPassword => 'Master Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get unlock => 'Unlock';

  @override
  String get createAccount => 'Create';

  @override
  String get passwordsDontMatch => 'Passwords don\'t match';

  @override
  String get passwordNoSpaces => 'Space detected (not allowed)';

  @override
  String get passwordMinLength => 'At least 8 characters';

  @override
  String get passwordNeedsUppercase => 'At least 1 uppercase required (A-Z)';

  @override
  String get passwordNeedsLowercase => 'At least 1 lowercase required (a-z)';

  @override
  String get passwordNeedsDigit => 'At least 1 digit required (0-9)';

  @override
  String get passwordNeedsSpecial =>
      'At least 1 special character required (!@#\$%...)';

  @override
  String get masterPasswordCreatedSuccess =>
      'Master password created successfully!';

  @override
  String get incorrectMasterPassword => 'Incorrect master password.';

  @override
  String loginAttemptsRemainingWarning(int n) {
    return '$n attempts remaining before your vault is locked for 24 hours.';
  }

  @override
  String get loginAttemptsLastChance =>
      'Warning: one more failed attempt will lock your vault for 24 hours.';

  @override
  String get masterPasswordChangeIntroTitle => 'Change master password';

  @override
  String get masterPasswordChangeIntroBody =>
      'You are about to change your master password. A security backup of your data will be created automatically.\n\nIf you encounter an issue in the next 30 days, you can revert to the current state using your old master password.\n\nContinue?';

  @override
  String get masterPasswordChangeCloudUpdateTitle =>
      'Updating your online vault';

  @override
  String get masterPasswordChangeCloudUpdateBody =>
      'Your data is being updated with your new master password.\n\nDo not close the application.';

  @override
  String masterPasswordChangeCloudProgress(int done, int total) {
    return '$done / $total entries synchronized';
  }

  @override
  String get masterPasswordChangeSuccessTitle => 'Master password changed';

  @override
  String get masterPasswordChangeSuccessBody =>
      'Your master password has been changed successfully.\n\nTwo backups were created automatically:\n• A security backup kept for 30 days, allowing you to revert to the previous state if needed (using your old master password).\n• A new up-to-date backup with your new master password.\n\nYour data is protected in any case.';

  @override
  String get masterPasswordChangeSeeBackups => 'View my backups';

  @override
  String get masterPasswordChangeFinish => 'Finish';

  @override
  String get securityBackupBadge => 'Security backup';

  @override
  String securityBackupSubtitle(String date, String expiry) {
    return 'Created on $date. Available until $expiry.';
  }

  @override
  String get securityBackupRestoreWarningTitle => 'Restore a previous state';

  @override
  String get securityBackupRestoreWarningBody =>
      'This backup was created before your last master password change.\n\nTo restore it, you\'ll need to enter your old master password. Your current data will be replaced by the data from this backup.\n\nContinue?';

  @override
  String get biometryDesktopComingSoon => 'Windows Hello — coming soon';

  @override
  String get lockTimeoutDisabled => 'Disabled';

  @override
  String get crossDeviceKeyChangedTitle =>
      'Master password changed on another device';

  @override
  String get crossDeviceKeyChangedBody =>
      'Your master password was changed on another device. Your online data is no longer accessible from this device with your current password.\n\nTo keep using PassKeyra here, import your latest backup from the device where you made the change, then enter your new master password.';

  @override
  String get crossDeviceKeyChangedLater => 'Later';

  @override
  String get onboardingBiometryDesktopMessage =>
      'This feature will be available in an upcoming update.';

  @override
  String get incorrectMasterPasswordBiometryDisabledAfter3Failures =>
      'Incorrect master password. Biometry disabled after 3 failed attempts.';

  @override
  String get biometryNotActivated => 'Biometry could not be activated.';

  @override
  String get connectionProblem => 'Connection Problem?';

  @override
  String get helpAndSettings => 'Help & Settings';

  @override
  String get connectionIssues => 'Connection Issues';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get resetApp => 'Reset Application';

  @override
  String get importBackupDescription => 'Restore a previous backup';

  @override
  String get resetAppDescription => 'Erase all data and start over';

  @override
  String get searchPlaceholder => 'Search... (name, username, URL, tag)';

  @override
  String get all => 'All';

  @override
  String get entry => 'entry';

  @override
  String get entries => 'entries';

  @override
  String get noEntries => 'No entries';

  @override
  String get noResults => 'No results';

  @override
  String get addFirstPassword => 'Tap + to add your first password';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get copyPassword => 'Copy Password';

  @override
  String get copyAllInfo => 'Copy all info';

  @override
  String get allInfoCopied => 'Info copied to clipboard';

  @override
  String get copyUsername => 'Copy Username';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get passwordCopied => 'Password copied (auto-cleared in 30s)';

  @override
  String get usernameCopied => 'Username copied';

  @override
  String get urlCopied => 'URL copied';

  @override
  String get sortByDateDesc => 'Most recent first';

  @override
  String get sortByDateAsc => 'Oldest first';

  @override
  String get sortByNameAsc => 'Name (A-Z)';

  @override
  String get sortByNameDesc => 'Name (Z-A)';

  @override
  String get name => 'Name';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get passwords => 'Passwords';

  @override
  String get additionalPasswordsShort => 'Additional';

  @override
  String get url => 'URL';

  @override
  String get notes => 'Notes';

  @override
  String get tags => 'Tags';

  @override
  String get category => 'Category';

  @override
  String get additionalPasswords => 'Additional Passwords';

  @override
  String get additionalPasswordLabel => 'Additional password';

  @override
  String get required => 'Required';

  @override
  String get optional => 'Optional';

  @override
  String get generatePassword => 'Generate Password';

  @override
  String get passwordLength => 'Length';

  @override
  String get includeUppercase => 'Uppercase (A-Z)';

  @override
  String get includeLowercase => 'Lowercase (a-z)';

  @override
  String get includeNumbers => 'Numbers (0-9)';

  @override
  String get includeSymbols => 'Symbols (!@#\$...)';

  @override
  String get deleteEntryTitle => 'Delete Entry';

  @override
  String get deleteEntryMessage =>
      'Are you sure you want to delete this entry?';

  @override
  String get deleteEntryConfirm => 'Type \"DELETE\" to confirm';

  @override
  String get deleteKeyword => 'DELETE';

  @override
  String get deleteSuccess => 'Entry deleted';

  @override
  String get lockTimeoutImmediate => 'Immediately';

  @override
  String get lockTimeout30s => '30 seconds';

  @override
  String get lockTimeout1m => '1 minute';

  @override
  String get lockTimeout2m => '2 minutes';

  @override
  String get lockTimeout5m => '5 minutes';

  @override
  String get lockTimeout10m => '10 minutes';

  @override
  String get lockTimeout30m => '30 minutes';

  @override
  String get autoCloseDisabled => 'Disabled';

  @override
  String get autoClose30s => '30 seconds';

  @override
  String get autoClose1m => '1 minute';

  @override
  String get autoClose2m => '2 minutes';

  @override
  String get autoClose5m => '5 minutes';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Change app language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get french => 'French';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get languageChanged => 'Language changed successfully';

  @override
  String get blurEnabled => 'Screen blur activated';

  @override
  String get blurDisabled => 'Screen blur deactivated';

  @override
  String get biometryEnabled => 'Biometry activated';

  @override
  String get biometryDisabled => 'Biometry deactivated';

  @override
  String get biometryError =>
      'You must first reconnect with your master password';

  @override
  String get mustReconnect =>
      'Error: You must first reconnect with your master password';

  @override
  String importSuccess(int count) {
    return '$count entries imported successfully.\nBiometry has been disabled for security reasons.\nThe application will close.';
  }

  @override
  String get exportSuccess => 'Export successful';

  @override
  String get importError => 'Import error';

  @override
  String get error => 'Error';

  @override
  String get createdAt => 'Created';

  @override
  String get updatedAt => 'Updated';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get viewEntry => 'View Entry';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get newEntry => 'New Entry';

  @override
  String get errorCreatingMasterPassword => 'Error creating master password';

  @override
  String get checkMasterPasswordOrBiometry =>
      '1. Check your master password or use biometry.';

  @override
  String get restoreFromBackup => '2. Restore from backup:';

  @override
  String get myLocalBackups => 'My local backup:';

  @override
  String get noLocalBackup => 'No local backup.';

  @override
  String get backupEntry => 'entry';

  @override
  String get backupEntries => 'entries';

  @override
  String get restoreFromBackupButton => 'Restore from backup';

  @override
  String get importSourceTitle => 'Choose import source';

  @override
  String get importFromLocalFile => 'Local file';

  @override
  String get importFromCloud => 'Cloud backup';

  @override
  String get resetApplication => 'Reset application';

  @override
  String get resetApplicationConfirm =>
      'Are you sure you want to reset the application?\n\nAll your data (passwords, settings, backups) will be permanently deleted.\n\nType RESET to confirm:';

  @override
  String get resetConfirmWord => 'RESET';

  @override
  String get typeResetToConfirm => 'Type RESET to confirm';

  @override
  String get applicationResetSuccess => 'Application reset successfully';

  @override
  String get biometryNotConfigured =>
      'Biometry not configured. Use your master password.';

  @override
  String get biometricUnlockError => 'Error during biometric unlock';

  @override
  String biometricError(String error) {
    return 'Biometric error: $error';
  }

  @override
  String get biometryTemporarilyBlocked =>
      'Biometry temporarily blocked. Use your master password.';

  @override
  String get importError2 => 'Error during import';

  @override
  String get vaultAlreadyExists => 'Vault already exists';

  @override
  String get vaultExistsMessage =>
      'A vault already exists.\n\nImporting will ERASE all current data and replace them with the backup.\n\nType IMPORT to confirm:';

  @override
  String get understood => 'Understood';

  @override
  String get importConfirmWord => 'IMPORT';

  @override
  String invalidBackup(String error) {
    return 'Invalid backup: $error';
  }

  @override
  String get backupMasterPassword => 'Confirm Master Password';

  @override
  String get backupPasswordInstructions =>
      'Enter the master password from the backup to decrypt it:';

  @override
  String get import => 'Import';

  @override
  String get importInProgress => 'Import in progress...';

  @override
  String get pleaseWait => 'Please wait';

  @override
  String get decryptionInProgress => 'Decryption in progress...';

  @override
  String get decryptionError => 'Decryption error';

  @override
  String get incorrectBackupPassword =>
      'Incorrect password or corrupted backup.';

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get other => 'Other';

  @override
  String get personalCategory => 'Personal';

  @override
  String get workCategory => 'Work';

  @override
  String get bankCategory => 'Bank';

  @override
  String get socialCategory => 'Social';

  @override
  String get emailCategory => 'Email';

  @override
  String get shoppingCategory => 'Shopping';

  @override
  String get entertainmentCategory => 'Entertainment';

  @override
  String get sortBy => 'Sort by';

  @override
  String get filterByCategory => 'Filter by category';

  @override
  String get premiumFeatures => 'Premium Features';

  @override
  String get premiumDescription =>
      'Upcoming features for PassKeyra Premium subscribers';

  @override
  String get cloudSync => 'Cloud Sync';

  @override
  String get cloudSyncDescription => 'Automatic sync across all your devices';

  @override
  String get biometricVault => 'Biometric Vault';

  @override
  String get biometricVaultDescription =>
      'Enhanced security with biometric authentication';

  @override
  String get prioritySupport => 'Priority Support';

  @override
  String get prioritySupportDescription =>
      'Get help faster with priority support';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get manageCategoriesTitle => 'Manage Categories';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryColor => 'Category Color';

  @override
  String get categoryIcon => 'Category Icon';

  @override
  String get selectColor => 'Select Color';

  @override
  String get deleteCategoryConfirm => 'Delete this category?';

  @override
  String get categorySaved => 'Category saved';

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String get import2 => 'Import';

  @override
  String get importFromFile => 'Import from File';

  @override
  String get importInstructions =>
      'Select a PassKeyra backup file (.json) to import';

  @override
  String get selectFile => 'Select File';

  @override
  String get noFileSelected => 'No file selected';

  @override
  String get importWarning =>
      'Warning: This will replace all your current data!';

  @override
  String get exportToFile => 'Export to File';

  @override
  String get exportInstructions =>
      'Export all your passwords to a secure backup file';

  @override
  String get exportButton => 'Export Now';

  @override
  String get exportWarning => 'Keep this file in a safe place!';

  @override
  String get fileExported => 'File exported successfully';

  @override
  String get autoClose45s => '45 seconds';

  @override
  String get securityAnalysis => 'Security Analysis';

  @override
  String get securityScore => 'Security Score';

  @override
  String get securityAnalysisPremiumMessage =>
      'Security Analysis is a Premium feature. Upgrade to Premium to scan your passwords and detect weaknesses.';

  @override
  String get viewPremium => 'View Premium';

  @override
  String get score => 'Score';

  @override
  String get veryWeak => 'Very Weak';

  @override
  String get weak => 'Weak';

  @override
  String get medium => 'Medium';

  @override
  String get strong => 'Strong';

  @override
  String get veryStrong => 'Very Strong';

  @override
  String get analysisSummary => 'Analysis Summary';

  @override
  String strongPasswords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count strong passwords',
      one: '1 strong password',
      zero: 'No strong passwords',
    );
    return '$_temp0';
  }

  @override
  String weakPasswords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weak passwords',
      one: '1 weak password',
      zero: 'No weak passwords',
    );
    return '$_temp0';
  }

  @override
  String duplicatePasswords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicate passwords',
      one: '1 duplicate password',
      zero: 'No duplicates',
    );
    return '$_temp0';
  }

  @override
  String oldPasswords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count old passwords',
      one: '1 old password',
      zero: 'No old passwords',
    );
    return '$_temp0';
  }

  @override
  String get issuesFound => 'Issues Found';

  @override
  String get weakPassword => 'Weak Password';

  @override
  String get duplicatePassword => 'Duplicate Password';

  @override
  String get oldPassword => 'Old Password';

  @override
  String get alsoUsedIn => 'Also used in';

  @override
  String get recommendations => 'Recommendations';

  @override
  String get recommendUseStrongPasswords =>
      'Use more complex passwords for better security';

  @override
  String get recommendUseUniquePasswords => 'Avoid reusing the same passwords';

  @override
  String get recommendUpdateOldPasswords =>
      'Update old passwords at least once a year';

  @override
  String get recommendUse12PlusChars =>
      'Use at least 12 characters for your passwords';

  @override
  String get recommendUseSymbols => 'Include symbols to strengthen security';

  @override
  String get help => 'Help';

  @override
  String get securityAnalysisHelp =>
      'Security Analysis examines all your passwords and detects:\n\n• Weak passwords (too short or simple)\n• Duplicate passwords (used multiple times)\n• Old passwords (not changed for >1 year)\n\nThe security score is calculated based on:\n• Password length\n• Character variety (uppercase, lowercase, numbers, symbols)\n• Overall complexity';

  @override
  String errorDuringAnalysis(String error) {
    return 'Error during analysis: $error';
  }

  @override
  String get unableToPerformAnalysis => 'Unable to perform analysis';

  @override
  String get retry => 'Retry';

  @override
  String passwordNotUpdatedYears(int years) {
    return 'Not updated in $years year(s)';
  }

  @override
  String get passwordTooShort => 'Too short (< 8 chars)';

  @override
  String get passwordShouldBe12Plus => 'Should be 12+ characters';

  @override
  String get passwordNoUppercase => 'No uppercase';

  @override
  String get passwordNoLowercase => 'No lowercase';

  @override
  String get passwordNoNumbers => 'No numbers';

  @override
  String get passwordNoSymbols => 'No symbols';

  @override
  String get weakPasswordGeneric => 'Weak password';

  @override
  String usedInEntries(int count) {
    return 'Used in $count entries';
  }

  @override
  String get customIcon => 'Custom Icon';

  @override
  String get chooseIcon => 'Choose an Icon';

  @override
  String get changeIcon => 'Change Icon';

  @override
  String get iconSelected => 'Icon Selected';

  @override
  String get chooseColor => 'Choose a Color';

  @override
  String get customIconsPremiumFeature =>
      'Custom icons are reserved for Premium users. Upgrade to Premium to unlock this feature and much more!';

  @override
  String get categoryIconsTab => 'Icons';

  @override
  String get categoryEmojisTab => 'Emojis';

  @override
  String get categoryEmojisPremium =>
      'Emojis for categories are reserved for Premium users';

  @override
  String get categoryColorPicker => 'Full Palette';

  @override
  String get categoryPredefinedColors => 'Predefined Colors';

  @override
  String get theme => 'Theme';

  @override
  String get themeSubtitle => 'Light, dark or system mode';

  @override
  String get selectTheme => 'Select a Theme';

  @override
  String get themeMode => 'Display Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get systemMode => 'Automatic mode';

  @override
  String get systemModeSubtitle => 'Based on ambient light';

  @override
  String get darkVariant => 'Dark Mode Variant';

  @override
  String get standardDark => 'Standard Dark';

  @override
  String get standardDarkSubtitle => 'Classic dark mode';

  @override
  String get amoledBlack => 'AMOLED Black';

  @override
  String get amoledBlackSubtitle => 'Pure black for OLED screens';

  @override
  String get darkGrey => 'Dark Grey';

  @override
  String get darkGreySubtitle => 'Elegant custom grey';

  @override
  String get darkThemePremiumFeature =>
      'Advanced dark mode variants (AMOLED Black and Dark Grey) are reserved for Premium users. Upgrade to Premium to unlock these themes and much more!';

  @override
  String get colorPalette => 'Color Palette';

  @override
  String get colorPaletteBlue => 'Blue (Classic)';

  @override
  String get colorPaletteGreen => 'Green';

  @override
  String get colorPaletteRedPink => 'Red/Pink';

  @override
  String get colorPalettePurple => 'Purple';

  @override
  String get colorPaletteOrange => 'Orange';

  @override
  String get colorPalettePremiumFeature =>
      'Custom color palettes are reserved for Premium users. Upgrade to Premium to unlock all palettes and much more!';

  @override
  String get fontFamily => 'Font Family';

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
      'Custom fonts are reserved for Premium users. Upgrade to Premium to unlock all fonts and much more!';

  @override
  String get cloudBackup => 'Cloud Backup';

  @override
  String get cloudBackupSubtitle => 'Backup to cloud';

  @override
  String get cloudBackupTitle => 'Cloud Backup';

  @override
  String get cloudProviderSelectionDescription =>
      'Choose your preferred cloud service to securely backup your passwords. You can change service at any time.';

  @override
  String get selectCloudProvider => 'Choose cloud service';

  @override
  String get switchProviderTitle => 'Switch cloud service';

  @override
  String switchProviderMessage(Object currentProvider, Object newProvider) {
    return 'Sign out from $currentProvider and switch to $newProvider?';
  }

  @override
  String get googleDrive => 'Google Drive';

  @override
  String get uploadToCloud => 'Backup to cloud';

  @override
  String get restoreFromCloud => 'Restore from cloud';

  @override
  String get cloudBackupSuccess => 'Cloud backup successful';

  @override
  String get cloudDisconnectTitle => 'Disconnect Google account?';

  @override
  String get cloudDisconnectMessage =>
      'Google Drive backup and Premium sync use the same Google account: sync is the Premium extension of Drive backup. Disconnecting therefore stops both. Your local data and the backups already stored in the cloud are kept. You can reconnect and choose another account at any time.';

  @override
  String get cloudDisconnectConfirm => 'Disconnect';

  @override
  String get cloudDisconnectGenericTitle => 'Disconnect cloud account?';

  @override
  String get cloudDisconnectGenericMessage =>
      'This disables automatic backup, disconnects your cloud account and clears the provider configuration. The backups already stored in the cloud and your local data are kept.';

  @override
  String cloudBackupFailed(Object error) {
    return 'Cloud backup failed: $error';
  }

  @override
  String get noCloudBackups => 'No cloud backups found';

  @override
  String lastCloudBackup(Object date) {
    return 'Last backup: $date';
  }

  @override
  String get cloudQuotaExceeded => 'Cloud quota exceeded';

  @override
  String get cloudProviderNotAvailable => 'Cloud service unavailable';

  @override
  String authenticateWith(Object provider) {
    return 'Sign in to $provider';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get deleteBackup => 'Delete backup';

  @override
  String get downloadBackup => 'Download backup';

  @override
  String get restore => 'Restore';

  @override
  String cloudRestoreConfirmation(Object date) {
    return 'Restore backup from $date? This will replace all your current data.';
  }

  @override
  String cloudRestoreSuccess(Object count) {
    return 'Backup restored successfully ($count entries)';
  }

  @override
  String cloudRestoreFailed(Object error) {
    return 'Restore failed: $error';
  }

  @override
  String get restoreSuccessAutoClose =>
      'Restore successful!\n\nThe app will close automatically in 2 seconds to apply changes.';

  @override
  String cloudDeleteConfirmation(Object date) {
    return 'Permanently delete backup from $date?';
  }

  @override
  String get cloudBackupDeleted => 'Backup deleted';

  @override
  String cloudDeleteFailed(Object error) {
    return 'Delete failed: $error';
  }

  @override
  String get cloudNoBackupsHint =>
      'Tap the button below to create your first backup';

  @override
  String cloudRateLimitMessage(Object minutes) {
    return 'Please wait $minutes minute(s) before next backup';
  }

  @override
  String get cloudAuthenticationFailed => 'Authentication failed';

  @override
  String get cloudNoAuthService => 'Authentication service not available';

  @override
  String get cloudSyncTitle => 'Cloud sync';

  @override
  String get cloudSyncSubtitle => 'Automatic real-time sync between devices';

  @override
  String get cloudSyncSettings => 'Sync settings';

  @override
  String get cloudSyncAccount => 'Cloud account';

  @override
  String get cloudSyncNoAccount => 'No Google account connected';

  @override
  String get cloudSyncSignIn => 'Sign in with Google';

  @override
  String get cloudSyncSignOut => 'Sign out';

  @override
  String get cloudSyncAutomatic => 'Automatic synchronization';

  @override
  String get cloudSyncEnabled => 'Changes are automatically synchronized';

  @override
  String get cloudSyncDisabled => 'Manual synchronization only';

  @override
  String get cloudSyncManualActions => 'Manual actions';

  @override
  String get cloudSyncUpload => 'Upload to cloud';

  @override
  String get cloudSyncDownload => 'Download from cloud';

  @override
  String get cloudSyncPremiumFeature => 'Premium Feature';

  @override
  String get cloudSyncPremiumMessage =>
      'Real-time cloud sync requires PassKeyra Premium';

  @override
  String get syncStatusIdle => 'Idle';

  @override
  String get syncStatusSyncing => 'Syncing...';

  @override
  String get syncStatusSuccess => 'Synced';

  @override
  String get syncStatusError => 'Sync error';

  @override
  String get syncStatusConflict => 'Conflict detected';

  @override
  String get syncLastSyncNever => 'Never synced';

  @override
  String get syncLastSyncJustNow => 'Just now';

  @override
  String syncLastSyncMinutes(Object minutes) {
    return '$minutes min ago';
  }

  @override
  String syncLastSyncHours(Object hours) {
    return '$hours h ago';
  }

  @override
  String syncLastSyncDays(Object days) {
    return '$days days ago';
  }

  @override
  String syncEntriesUploaded(Object count) {
    return '$count entries synced';
  }

  @override
  String syncEntriesDownloaded(Object count) {
    return '$count entries downloaded';
  }

  @override
  String syncMergeCompleted(Object count) {
    return 'Merge completed ($count entries)';
  }

  @override
  String get syncConflictResolved =>
      'Conflict resolved (most recent version kept)';

  @override
  String get syncEnabled => 'Sync enabled';

  @override
  String get syncDisabled => 'Sync disabled';

  @override
  String get syncErrorOffline => 'Error: No internet connection';

  @override
  String get syncErrorAuth => 'Error: Authentication expired';

  @override
  String get syncErrorQuota => 'Error: Firebase quota exceeded';

  @override
  String get helpLogosTitle => 'Logo meanings';

  @override
  String get helpLogoCloud => 'Cloud Logo (☁️)';

  @override
  String get helpLogoCloudSubtitle => 'Automatic Google Drive backup';

  @override
  String get helpLogoSync => 'Sync Logo (⇄)';

  @override
  String get helpLogoSyncSubtitle => 'Real-time Firebase sync';

  @override
  String get helpColorLegend => 'Color code (for both logos):';

  @override
  String get helpColorBlue => 'Blue';

  @override
  String get helpColorBlueMeaning => 'Enabled and ready';

  @override
  String get helpColorPurple => 'Purple';

  @override
  String get helpColorPurpleMeaning => 'Sync in progress';

  @override
  String get helpColorGreen => 'Green';

  @override
  String get helpColorGreenMeaning => 'Operation successful';

  @override
  String get helpColorRed => 'Red';

  @override
  String get helpColorRedMeaning => 'Error';

  @override
  String get helpColorGrey => 'Grey';

  @override
  String get helpColorGreyMeaning => 'Disabled';

  @override
  String syncConnectedAs(Object email) {
    return 'Connected as $email';
  }

  @override
  String get syncDisconnected => 'Disconnected';

  @override
  String get syncAutoLabel => 'Auto sync';

  @override
  String get syncManualLabel => 'Manual sync';

  @override
  String get androidVersionWarningTitle => 'Limited features';

  @override
  String get androidVersionWarningMessage =>
      'Your Android version (< 8.0) does not support backup restoration. For a complete experience, please use Android 8.0 or higher. Backup creation and viewing remain available.';

  @override
  String get onboardingFirstChoiceTitle => 'Getting started tutorial';

  @override
  String get onboardingFirstChoiceMessage =>
      'Do you want a quick guided setup before creating your vault?';

  @override
  String get onboardingStartTutorial => 'Start tutorial';

  @override
  String get onboardingSkipTutorial => 'Quit';

  @override
  String get onboardingQuitTitle => 'Tutorial exited';

  @override
  String get onboardingQuitMessage =>
      'You can replay it at any time from Settings → Tutorials.';

  @override
  String get onboardingMasterPasswordTitle => 'Master password warning';

  @override
  String get onboardingMasterPasswordMessage =>
      'Your master password is the only key. If lost, there is no recovery.';

  @override
  String get onboardingSecurityRequirements => 'Security requirements:';

  @override
  String get onboardingRuleLength => 'Minimum 12 characters (16+ recommended)';

  @override
  String get onboardingRuleComplexity =>
      'Uppercase, lowercase, numbers, symbols';

  @override
  String get onboardingRuleDictionary => 'Avoid dictionary words';

  @override
  String get onboardingRuleUnique => 'Use a unique password, never reused';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingFinish => 'Finish';

  @override
  String get onboardingCreateFirstEntry => 'Create my first entry';

  @override
  String get onboardingStepSearchTitle => 'Quick search';

  @override
  String get onboardingStepSearchBody =>
      'The search function filters entries by name, username, URL, or tags.';

  @override
  String get onboardingStepSettingsTitle => 'Settings access';

  @override
  String get onboardingStepSettingsBody =>
      'This menu groups all security settings and other options.';

  @override
  String get onboardingStepAddTitle => 'Creating an entry';

  @override
  String get onboardingStepAddBody =>
      'The + button creates a new entry in the vault.';

  @override
  String get onboardingStepCopyAllTitle => 'Copy an entry';

  @override
  String get onboardingStepCopyAllBody =>
      'This button copies all useful info from the entry: username, password, URL and notes if present.';

  @override
  String get onboardingRestart => 'Restart tutorial';

  @override
  String get onboardingRestartDescription =>
      'Replay the complete getting-started tutorial';

  @override
  String get onboardingWillRestart =>
      'The tutorial will restart on the next app launch.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingFinishLater => 'Finish later';

  @override
  String get onboardingSecurityPauseTitle => 'Security overview';

  @override
  String get onboardingSecurityPauseMessage =>
      'Continue with an overview of security features? (3 quick steps)';

  @override
  String get onboardingSecurityReportTitle => 'Security analysis';

  @override
  String get onboardingSecurityReportMessage =>
      'The security report analyzes passwords and detects issues: weak, reused, or compromised passwords.';

  @override
  String get onboardingLockTimeoutTitle => 'Auto-lock';

  @override
  String get onboardingLockTimeoutMessage =>
      'The app automatically locks after a period of inactivity to protect data.';

  @override
  String get onboardingBiometryTitle => 'Biometric authentication';

  @override
  String get onboardingBiometryMessage =>
      'Quick and secure unlocking with fingerprint or face recognition.';

  @override
  String get onboardingClickHere => 'Please click on the highlighted element';

  @override
  String get onboardingCompleteMessage =>
      'You now know all the essential features of PassKeyra. Enjoy using it!';

  @override
  String get discoveryModeTitle => 'Tutorials';

  @override
  String get discoveryModeSubtitle =>
      'Learn how to use all PassKeyra features at your own pace';

  @override
  String get discoverySteps => 'steps';

  @override
  String get discoveryCompleted => 'Completed';

  @override
  String get discoveryStart => 'Start';

  @override
  String get discoveryReplay => 'Replay';

  @override
  String get discoveryEntriesTitle => 'Advanced entry management';

  @override
  String get discoveryEntriesDescription =>
      'Learn how to view, edit, and organize your entries';

  @override
  String get discoveryEntriesViewTitle => 'View an entry';

  @override
  String get discoveryEntriesViewMessage =>
      'Tap an entry in the list to display all its details: password, username, URL, notes, and category.';

  @override
  String get discoveryEntriesCopyTitle => 'Quick copy';

  @override
  String get discoveryEntriesCopyMessage =>
      'Tap the password or username to instantly copy it to your clipboard.';

  @override
  String get discoveryEntriesGeneratorTitle => 'Password generator';

  @override
  String get discoveryEntriesGeneratorMessage =>
      'Use the generator to create strong and unique passwords. Customize the length and included characters.';

  @override
  String get discoveryEntriesAdditionalTitle => 'Additional passwords';

  @override
  String get discoveryEntriesAdditionalMessage =>
      'Add multiple passwords to the same entry (e.g., main password + PIN code).';

  @override
  String get discoveryEntriesCategoriesTitle => 'Custom categories';

  @override
  String get discoveryEntriesCategoriesMessage =>
      'Create your own categories to organize your entries as you wish.';

  @override
  String get discoveryBackupTitle => 'Backup & Synchronization';

  @override
  String get discoveryBackupDescription =>
      'Protect your data and sync across devices';

  @override
  String get discoveryBackupLocalTitle => 'Local backups';

  @override
  String get discoveryBackupLocalMessage =>
      'Export your data to your device to back it up or transfer it. You can also import from a backup file.';

  @override
  String get discoveryBackupDriveTitle => 'Google Drive';

  @override
  String get discoveryBackupDriveMessage =>
      'Automatically back up your encrypted data to Google Drive to recover it in case of problems.';

  @override
  String get discoveryBackupSyncTitle => 'Firebase Sync';

  @override
  String get discoveryBackupSyncMessage =>
      'Automatically sync your entries across all your devices in real-time (Premium feature).';

  @override
  String get discoveryBackupConflictsTitle => 'Conflict resolution';

  @override
  String get discoveryBackupConflictsMessage =>
      'In case of simultaneous changes on multiple devices, choose which version to keep.';

  @override
  String get discoveryAppearanceTitle => 'Appearance & Premium';

  @override
  String get discoveryAppearanceDescription =>
      'Customize the interface and discover Premium features';

  @override
  String get discoveryAppearanceThemesTitle => 'Themes';

  @override
  String get discoveryAppearanceThemesMessage =>
      'Choose from 4 themes: Light, Dark, AMOLED Black, or Dark Gray. Adaptive mode automatically adjusts according to ambient light.';

  @override
  String get discoveryAppearancePalettesTitle => 'Color palettes';

  @override
  String get discoveryAppearancePalettesMessage =>
      'Customize the interface with 5 different color palettes (Premium feature).';

  @override
  String get discoveryAppearanceFontsTitle => 'Custom fonts';

  @override
  String get discoveryAppearanceFontsMessage =>
      'Change the app\'s font from 4 available choices (Premium feature).';

  @override
  String get discoveryAppearancePremiumTitle => 'PassKeyra Premium';

  @override
  String get discoveryAppearancePremiumMessage =>
      'Unlock all features: palettes, fonts, real-time sync, advanced security analysis, and more!';

  @override
  String get discoveryPremiumTitle => 'Premium Features';

  @override
  String get discoveryPremiumDescription =>
      'Discover all exclusive Premium features';

  @override
  String get discoveryPremiumIntroMessage =>
      'Discover all exclusive features of PassKeyra Premium.';

  @override
  String get discoveryPremiumPalettesTitle => 'Palettes & Fonts';

  @override
  String get discoveryPremiumPalettesMessage =>
      'Customize the appearance with exclusive Premium color palettes and fonts.';

  @override
  String get discoveryPremiumSecurityTitle => 'Security analysis';

  @override
  String get discoveryPremiumSecurityMessage =>
      'Security analysis checks the strength of your passwords and detects issues (weak, reused, or compromised passwords).';

  @override
  String get discoveryPremiumCompleteMessage =>
      'You now know all the Premium features of PassKeyra!';

  @override
  String get onboardingStepSortTitle => 'Sort & filter';

  @override
  String get onboardingStepSortBody =>
      'Sort entries by name or date using this button. Quickly reorder your list to find what you need.';

  @override
  String get onboardingStepCategoriesTitle => 'Category filters';

  @override
  String get onboardingStepCategoriesBody =>
      'Tap a category chip to filter your entries. Scroll horizontally to see all available categories.';

  @override
  String get onboardingSettingsSecurityTitle => 'Security settings';

  @override
  String get onboardingSettingsSecurityBody =>
      'This section lets you configure auto-lock, biometric authentication, and all security options for your vault.';

  @override
  String get onboardingSettingsBackupTitle => 'Backup & Sync';

  @override
  String get onboardingSettingsBackupBody =>
      'Manage your local and cloud backups, and configure sync between your devices.';

  @override
  String get onboardingSettingsAppearanceTitle => 'Appearance';

  @override
  String get onboardingSettingsAppearanceBody =>
      'Customize the language, theme and categories of your app.';

  @override
  String get onboardingBackupLocalTitle => 'Local backup';

  @override
  String get onboardingBackupLocalBody =>
      'Export your vault to this device or restore it from an existing backup.';

  @override
  String get onboardingBackupCloudTitle => 'Cloud backup';

  @override
  String get onboardingBackupCloudBody =>
      'Save your vault to the cloud to access it across all your devices.';

  @override
  String get onboardingChangeMasterPasswordTitle => 'Master password';

  @override
  String get onboardingChangeMasterPasswordMessage =>
      'Your master password is the only key to your vault. You can change it here at any time.';

  @override
  String get onboardingAutoCloseTitle => 'Auto close';

  @override
  String get onboardingAutoCloseMessage =>
      'The app can close itself automatically after a period of inactivity for added protection.';

  @override
  String get onboardingLoginAttemptsTitle => 'Login attempts';

  @override
  String get onboardingLoginAttemptsMessage =>
      'Limit the number of failed attempts before the vault is temporarily locked.';

  @override
  String get premiumTutorialIntroTitle => 'Welcome to PassKeyra Premium!';

  @override
  String get premiumTutorialIntroMessage => 'Let\'s explore your new features.';

  @override
  String get premiumTutorialNoAdsTitle => 'No Ads';

  @override
  String get premiumTutorialNoAdsMessage =>
      'As a Premium user, enjoy the app without any advertisements or interruptions.';

  @override
  String get premiumTutorialCloudSyncTitle => 'Cloud Sync';

  @override
  String get premiumTutorialCloudSyncMessage =>
      'Enable sync to keep your vault up to date across all your connected devices. Requires a Google account connected to PassKeyra.';

  @override
  String get premiumTutorialBackupTitle => 'Cloud Backup List';

  @override
  String get premiumTutorialBackupMessage =>
      'Your backups appear here. Each new backup replaces the previous one - your vault is always protected.';

  @override
  String get premiumTutorialAutoBackupTitle => 'Automatic Backup';

  @override
  String get premiumTutorialAutoBackupMessage =>
      'Enable automatic backup so your vault is saved to the cloud every time you make a change.';

  @override
  String get premiumTutorialManualBackupTitle => 'Manual Backup';

  @override
  String get premiumTutorialManualBackupMessage =>
      'Tap this button to immediately save your vault to the cloud.';

  @override
  String get premiumTutorialProviderNameTitle => 'Your current provider';

  @override
  String get premiumTutorialProviderNameMessage =>
      'The name shown here indicates your cloud backup provider. You can change it at any time using the icon at the top right.';

  @override
  String get premiumTutorialChangeProviderTitle => 'Change Provider';

  @override
  String get premiumTutorialChangeProviderMessage =>
      'Tap the cloud icon at the top right to switch your cloud storage provider at any time.';

  @override
  String get premiumTutorialIconsTitle => 'Icons & Multiple Passwords';

  @override
  String get premiumTutorialIconsMessage =>
      'Customize each entry with an emoji and add multiple passwords per entry from the edit page.';

  @override
  String get premiumTutorialSecurityTitle => 'Security & Appearance';

  @override
  String get premiumTutorialSecurityMessage =>
      'Check your security score in Settings › Security. Customize fonts and palettes from Settings › Appearance.';

  @override
  String get premiumTutorialSecurityReportTitle =>
      'Security Analysis Unlocked!';

  @override
  String get premiumTutorialSecurityReportMessage =>
      'Here is your security report. Check your overall score and recommendations to strengthen your passwords. Accessible anytime from Settings › Security.';

  @override
  String get premiumTutorialCompleteMessage =>
      'You\'ve discovered all your Premium features. Enjoy PassKeyra to the fullest!';

  @override
  String get premiumLocalAutoBackupTitle => 'Automatic local backup';

  @override
  String get premiumLocalAutoBackupDescription =>
      'Automatic encrypted backup on your device each time your vault is modified';

  @override
  String get premiumTutorialLocalBackupTitle => 'Automatic local backup';

  @override
  String get premiumTutorialLocalBackupMessage =>
      'Enable this option to automatically back up your vault on your device each time it is modified, independently of cloud backup.';

  @override
  String get cloudSyncRequiresGoogle =>
      'Sync requires a Google account connected to PassKeyra.';

  @override
  String get premiumTutorialEmojiTitle => 'Customization';

  @override
  String get premiumTutorialEmojiMessage =>
      'Tap here to add an emoji to this entry. Each entry can have its own icon.';

  @override
  String get premiumTutorialMultiPasswordTitle => 'Multiple Passwords';

  @override
  String get premiumTutorialMultiPasswordMessage =>
      'Add multiple passwords to one entry, perfect when you use different credentials for the same service.';

  @override
  String get firstEntryTutorialNameTitle => 'Entry Name';

  @override
  String get firstEntryTutorialNameMessage =>
      'Enter a recognizable name to identify this account easily.';

  @override
  String get firstEntryTutorialCategoryTitle => 'Category';

  @override
  String get firstEntryTutorialCategoryMessage =>
      'Assign a category to this entry to find your accounts more quickly.';

  @override
  String get firstEntryTutorialUsernameTitle => 'Username';

  @override
  String get firstEntryTutorialUsernameMessage =>
      'Enter your username or email address for this account.';

  @override
  String get firstEntryTutorialPasswordTitle => 'Password';

  @override
  String get firstEntryTutorialPasswordMessage =>
      'Enter your password, or open the generator to create a secure one.';

  @override
  String get firstEntryTutorialOpenGenerator => 'Open Generator';

  @override
  String get firstEntryTutorialGeneratorLengthTitle => 'Length';

  @override
  String get firstEntryTutorialGeneratorLengthMessage =>
      'Slide to choose the length (16 characters or more recommended).';

  @override
  String get firstEntryTutorialGeneratorLowerTitle => 'Lowercase';

  @override
  String get firstEntryTutorialGeneratorLowerMessage =>
      'Include lowercase letters (a-z) to strengthen your password.';

  @override
  String get firstEntryTutorialGeneratorUpperTitle => 'Uppercase';

  @override
  String get firstEntryTutorialGeneratorUpperMessage =>
      'Add uppercase letters (A-Z) to make the password more complex.';

  @override
  String get firstEntryTutorialGeneratorDigitsTitle => 'Digits';

  @override
  String get firstEntryTutorialGeneratorDigitsMessage =>
      'Include digits (0-9) to increase security.';

  @override
  String get firstEntryTutorialGeneratorSymbolsTitle => 'Symbols';

  @override
  String get firstEntryTutorialGeneratorSymbolsMessage =>
      'Add symbols (!@#\$…) to maximize resistance to attacks.';

  @override
  String get firstEntryTutorialUrlTitle => 'URL';

  @override
  String get firstEntryTutorialUrlMessage =>
      'Add the website URL associated with this account (optional).';

  @override
  String get firstEntryTutorialNotesTitle => 'Notes';

  @override
  String get firstEntryTutorialNotesMessage =>
      'Add extra information: security questions, codes, etc.';

  @override
  String get firstEntryTutorialTagsTitle => 'Tags';

  @override
  String get firstEntryTutorialTagsMessage =>
      'Add comma-separated tags to make this entry easier to find.';

  @override
  String get firstEntryTutorialEmojiTitle => 'Custom Icon';

  @override
  String get firstEntryTutorialEmojiMessage =>
      'Associate an emoji with this entry to recognize it at a glance.';

  @override
  String get firstEntryTutorialAdditionalPasswordsTitle =>
      'Additional Passwords';

  @override
  String get firstEntryTutorialAdditionalPasswordsMessage =>
      'Add multiple passwords to one entry (PIN, multiple profiles…).';

  @override
  String get firstEntryTutorialSaveTitle => 'Save Entry';

  @override
  String get firstEntryTutorialSaveMessage =>
      'All set! Tap the ✓ button to save this entry to your vault.';

  @override
  String get firstEntryTutorialSaveAction => 'Got it';

  @override
  String get firstEntryTutorialCardTitle => 'Your first entry!';

  @override
  String get firstEntryTutorialCardMessage =>
      'Your entry is saved. Let\'s explore the available actions on each card.';

  @override
  String get firstEntryTutorialCopyPasswordTitle => 'Copy Password';

  @override
  String get firstEntryTutorialCopyPasswordMessage =>
      'This button copies only the password (automatically cleared after 30 s).';

  @override
  String get firstEntryTutorialCopyAllTitle => 'Copy All Info';

  @override
  String get firstEntryTutorialCopyAllMessage =>
      'This button copies the name, username, password, URL and notes all at once.';

  @override
  String get firstEntryTutorialTapCardTitle => 'View Entry';

  @override
  String get firstEntryTutorialTapCardMessage =>
      'Tap the card to view full details and edit the entry.';

  @override
  String get discoveryFirstEntryTitle => 'Create an Entry';

  @override
  String get discoveryFirstEntryDescription =>
      'Learn to create, fill in and manage your first entry from start to finish.';

  @override
  String get discoveryFirstEntrySteps => '14 steps';
}
