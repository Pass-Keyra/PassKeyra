import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'PassKeyra'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a section to easily manage your application.'**
  String get settingsSubtitle;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @backupAndSync.
  ///
  /// In en, this message translates to:
  /// **'Backup & Synchronization'**
  String get backupAndSync;

  /// No description provided for @keyboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get keyboardShortcuts;

  /// No description provided for @aboutAndSupport.
  ///
  /// In en, this message translates to:
  /// **'About & Support'**
  String get aboutAndSupport;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @application.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get application;

  /// Change master password button
  ///
  /// In en, this message translates to:
  /// **'Change Master Password'**
  String get changeMasterPassword;

  /// No description provided for @changeMasterPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Modify your security code'**
  String get changeMasterPasswordSubtitle;

  /// No description provided for @biometricAuth.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuth;

  /// No description provided for @biometricAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or Face ID'**
  String get biometricAuthSubtitle;

  /// No description provided for @biometricAuthNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device'**
  String get biometricAuthNotAvailable;

  /// No description provided for @lockTimeout.
  ///
  /// In en, this message translates to:
  /// **'Lock Timeout'**
  String get lockTimeout;

  /// No description provided for @autoClose.
  ///
  /// In en, this message translates to:
  /// **'Auto Close'**
  String get autoClose;

  /// No description provided for @blurScreen.
  ///
  /// In en, this message translates to:
  /// **'Hide Content in Background'**
  String get blurScreen;

  /// No description provided for @blurScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide content in app switcher'**
  String get blurScreenSubtitle;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'PassKeyra Premium'**
  String get premiumTitle;

  /// No description provided for @premiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover upcoming features'**
  String get premiumSubtitle;

  /// No description provided for @premiumOnlyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Premium only'**
  String get premiumOnlyTooltip;

  /// No description provided for @customCategories.
  ///
  /// In en, this message translates to:
  /// **'Custom Categories'**
  String get customCategories;

  /// No description provided for @customCategoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your categories'**
  String get customCategoriesSubtitle;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backup your data'**
  String get exportSubtitle;

  /// No description provided for @localBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Backup'**
  String get localBackupTitle;

  /// No description provided for @localBackupExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export your local backup'**
  String get localBackupExportSubtitle;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutPremium.
  ///
  /// In en, this message translates to:
  /// **'PassKeyra v1.1.11 (Premium activated)'**
  String get aboutPremium;

  /// No description provided for @aboutFree.
  ///
  /// In en, this message translates to:
  /// **'PassKeyra v1.1.11'**
  String get aboutFree;

  /// No description provided for @biometricMigrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enhanced security'**
  String get biometricMigrationTitle;

  /// No description provided for @biometricMigrationMessage.
  ///
  /// In en, this message translates to:
  /// **'PassKeyra has strengthened the biometric protection of your vault. To enable this new protection on your device, you need to enter your master password once. Fingerprint or face unlock will work normally afterwards.'**
  String get biometricMigrationMessage;

  /// No description provided for @biometricMigrationButton.
  ///
  /// In en, this message translates to:
  /// **'Enter my master password'**
  String get biometricMigrationButton;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @deleteCloudAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my cloud account'**
  String get deleteCloudAccount;

  /// No description provided for @deleteCloudAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently deletes your Firebase account and stops synchronization across your devices. Your local data and your Drive/OneDrive backups are NOT affected.'**
  String get deleteCloudAccountDescription;

  /// No description provided for @deleteCloudAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. Your Firebase account and all synchronized cloud data will be deleted. You may create a new cloud account later if you wish.'**
  String get deleteCloudAccountWarning;

  /// No description provided for @deleteCloudAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteCloudAccountConfirm;

  /// No description provided for @deleteCloudAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cloud account deleted'**
  String get deleteCloudAccountSuccess;

  /// No description provided for @deleteCloudAccountReauthRequired.
  ///
  /// In en, this message translates to:
  /// **'For security reasons, reconnect to Google then try again.'**
  String get deleteCloudAccountReauthRequired;

  /// No description provided for @havePromoCode.
  ///
  /// In en, this message translates to:
  /// **'I have a promo code'**
  String get havePromoCode;

  /// No description provided for @redeemPromoCodeError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Play Store. Check that the app is installed.'**
  String get redeemPromoCodeError;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate This App'**
  String get rateApp;

  /// No description provided for @rateAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Leave a review on the App Store or Play Store'**
  String get rateAppSubtitle;

  /// No description provided for @thankYouSupport.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your support!'**
  String get thankYouSupport;

  /// No description provided for @unlockVault.
  ///
  /// In en, this message translates to:
  /// **'Unlock Vault'**
  String get unlockVault;

  /// No description provided for @secureSetup.
  ///
  /// In en, this message translates to:
  /// **'Secure Setup'**
  String get secureSetup;

  /// No description provided for @createMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Create your master password to protect your passwords.'**
  String get createMasterPassword;

  /// No description provided for @newMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'New Master Password'**
  String get newMasterPassword;

  /// No description provided for @masterPassword.
  ///
  /// In en, this message translates to:
  /// **'Master Password'**
  String get masterPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAccount;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordsDontMatch;

  /// No description provided for @passwordNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Space detected (not allowed)'**
  String get passwordNoSpaces;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordNeedsUppercase.
  ///
  /// In en, this message translates to:
  /// **'At least 1 uppercase required (A-Z)'**
  String get passwordNeedsUppercase;

  /// No description provided for @passwordNeedsLowercase.
  ///
  /// In en, this message translates to:
  /// **'At least 1 lowercase required (a-z)'**
  String get passwordNeedsLowercase;

  /// No description provided for @passwordNeedsDigit.
  ///
  /// In en, this message translates to:
  /// **'At least 1 digit required (0-9)'**
  String get passwordNeedsDigit;

  /// No description provided for @passwordNeedsSpecial.
  ///
  /// In en, this message translates to:
  /// **'At least 1 special character required (!@#\$%...)'**
  String get passwordNeedsSpecial;

  /// No description provided for @masterPasswordCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Master password created successfully!'**
  String get masterPasswordCreatedSuccess;

  /// No description provided for @incorrectMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect master password.'**
  String get incorrectMasterPassword;

  /// No description provided for @loginAttemptsRemainingWarning.
  ///
  /// In en, this message translates to:
  /// **'{n} attempts remaining before your vault is locked for 24 hours.'**
  String loginAttemptsRemainingWarning(int n);

  /// No description provided for @loginAttemptsLastChance.
  ///
  /// In en, this message translates to:
  /// **'Warning: one more failed attempt will lock your vault for 24 hours.'**
  String get loginAttemptsLastChance;

  /// No description provided for @masterPasswordChangeIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Change master password'**
  String get masterPasswordChangeIntroTitle;

  /// No description provided for @masterPasswordChangeIntroBody.
  ///
  /// In en, this message translates to:
  /// **'You are about to change your master password. A security backup of your data will be created automatically.\n\nIf you encounter an issue in the next 30 days, you can revert to the current state using your old master password.\n\nContinue?'**
  String get masterPasswordChangeIntroBody;

  /// No description provided for @masterPasswordChangeCloudUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Updating your online vault'**
  String get masterPasswordChangeCloudUpdateTitle;

  /// No description provided for @masterPasswordChangeCloudUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is being updated with your new master password.\n\nDo not close the application.'**
  String get masterPasswordChangeCloudUpdateBody;

  /// No description provided for @masterPasswordChangeCloudProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} entries synchronized'**
  String masterPasswordChangeCloudProgress(int done, int total);

  /// No description provided for @masterPasswordChangeSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Master password changed'**
  String get masterPasswordChangeSuccessTitle;

  /// No description provided for @masterPasswordChangeSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your master password has been changed successfully.\n\nTwo backups were created automatically:\n• A security backup kept for 30 days, allowing you to revert to the previous state if needed (using your old master password).\n• A new up-to-date backup with your new master password.\n\nYour data is protected in any case.'**
  String get masterPasswordChangeSuccessBody;

  /// No description provided for @masterPasswordChangeSeeBackups.
  ///
  /// In en, this message translates to:
  /// **'View my backups'**
  String get masterPasswordChangeSeeBackups;

  /// No description provided for @masterPasswordChangeFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get masterPasswordChangeFinish;

  /// No description provided for @securityBackupBadge.
  ///
  /// In en, this message translates to:
  /// **'Security backup'**
  String get securityBackupBadge;

  /// No description provided for @securityBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Created on {date}. Available until {expiry}.'**
  String securityBackupSubtitle(String date, String expiry);

  /// No description provided for @securityBackupRestoreWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore a previous state'**
  String get securityBackupRestoreWarningTitle;

  /// No description provided for @securityBackupRestoreWarningBody.
  ///
  /// In en, this message translates to:
  /// **'This backup was created before your last master password change.\n\nTo restore it, you\'ll need to enter your old master password. Your current data will be replaced by the data from this backup.\n\nContinue?'**
  String get securityBackupRestoreWarningBody;

  /// No description provided for @biometryDesktopComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Windows Hello — coming soon'**
  String get biometryDesktopComingSoon;

  /// No description provided for @lockTimeoutDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get lockTimeoutDisabled;

  /// No description provided for @crossDeviceKeyChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Master password changed on another device'**
  String get crossDeviceKeyChangedTitle;

  /// No description provided for @crossDeviceKeyChangedBody.
  ///
  /// In en, this message translates to:
  /// **'Your master password was changed on another device. Your online data is no longer accessible from this device with your current password.\n\nTo keep using PassKeyra here, import your latest backup from the device where you made the change, then enter your new master password.'**
  String get crossDeviceKeyChangedBody;

  /// No description provided for @crossDeviceKeyChangedLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get crossDeviceKeyChangedLater;

  /// No description provided for @onboardingBiometryDesktopMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature will be available in an upcoming update.'**
  String get onboardingBiometryDesktopMessage;

  /// No description provided for @incorrectMasterPasswordBiometryDisabledAfter3Failures.
  ///
  /// In en, this message translates to:
  /// **'Incorrect master password. Biometry disabled after 3 failed attempts.'**
  String get incorrectMasterPasswordBiometryDisabledAfter3Failures;

  /// No description provided for @biometryNotActivated.
  ///
  /// In en, this message translates to:
  /// **'Biometry could not be activated.'**
  String get biometryNotActivated;

  /// No description provided for @weakBiometricWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Limited biometric protection on this device'**
  String get weakBiometricWarningTitle;

  /// No description provided for @weakBiometricWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'This device does not support strong biometrics. Biometric unlock is more convenient, but less secure than your master password: someone with access to your phone could potentially bypass it.\n\nYour vault remains encrypted with your master password.\n\nEnable biometric unlock anyway?'**
  String get weakBiometricWarningMessage;

  /// No description provided for @weakBiometricWarningActivateAnyway.
  ///
  /// In en, this message translates to:
  /// **'Enable anyway'**
  String get weakBiometricWarningActivateAnyway;

  /// No description provided for @weakBiometricWarningKeepPassword.
  ///
  /// In en, this message translates to:
  /// **'Keep master password'**
  String get weakBiometricWarningKeepPassword;

  /// No description provided for @biometricReEnrollmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint changed'**
  String get biometricReEnrollmentTitle;

  /// No description provided for @biometricReEnrollmentMessage.
  ///
  /// In en, this message translates to:
  /// **'For your security, changes to your fingerprints have disabled biometric unlock. Enter your master password once to re-enable it.'**
  String get biometricReEnrollmentMessage;

  /// No description provided for @biometricReEnrollmentButton.
  ///
  /// In en, this message translates to:
  /// **'Enter my master password'**
  String get biometricReEnrollmentButton;

  /// No description provided for @biometricUpgraded.
  ///
  /// In en, this message translates to:
  /// **'Biometric protection upgraded'**
  String get biometricUpgraded;

  /// No description provided for @biometricAuthSubtitleStrong.
  ///
  /// In en, this message translates to:
  /// **'Enhanced protection (hardware-bound)'**
  String get biometricAuthSubtitleStrong;

  /// No description provided for @biometricAuthSubtitleWeak.
  ///
  /// In en, this message translates to:
  /// **'Standard protection'**
  String get biometricAuthSubtitleWeak;

  /// No description provided for @selectAnEntry.
  ///
  /// In en, this message translates to:
  /// **'Select an entry'**
  String get selectAnEntry;

  /// No description provided for @selectAnEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Click an entry to view its details'**
  String get selectAnEntryHint;

  /// No description provided for @connectionProblem.
  ///
  /// In en, this message translates to:
  /// **'Connection Problem?'**
  String get connectionProblem;

  /// No description provided for @helpAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Help & Settings'**
  String get helpAndSettings;

  /// No description provided for @connectionIssues.
  ///
  /// In en, this message translates to:
  /// **'Connection Issues'**
  String get connectionIssues;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @resetApp.
  ///
  /// In en, this message translates to:
  /// **'Reset Application'**
  String get resetApp;

  /// No description provided for @importBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Restore a previous backup'**
  String get importBackupDescription;

  /// No description provided for @resetAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Erase all data and start over'**
  String get resetAppDescription;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search... (name, username, URL, tag)'**
  String get searchPlaceholder;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @entry.
  ///
  /// In en, this message translates to:
  /// **'entry'**
  String get entry;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'entries'**
  String get entries;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get noEntries;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @addFirstPassword.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first password'**
  String get addFirstPassword;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @copyPassword.
  ///
  /// In en, this message translates to:
  /// **'Copy Password'**
  String get copyPassword;

  /// No description provided for @copyAllInfo.
  ///
  /// In en, this message translates to:
  /// **'Copy all info'**
  String get copyAllInfo;

  /// No description provided for @allInfoCopied.
  ///
  /// In en, this message translates to:
  /// **'Info copied to clipboard'**
  String get allInfoCopied;

  /// No description provided for @copyUsername.
  ///
  /// In en, this message translates to:
  /// **'Copy Username'**
  String get copyUsername;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @passwordCopied.
  ///
  /// In en, this message translates to:
  /// **'Password copied (auto-cleared in 30s)'**
  String get passwordCopied;

  /// No description provided for @usernameCopied.
  ///
  /// In en, this message translates to:
  /// **'Username copied'**
  String get usernameCopied;

  /// No description provided for @urlCopied.
  ///
  /// In en, this message translates to:
  /// **'URL copied'**
  String get urlCopied;

  /// No description provided for @sortByDateDesc.
  ///
  /// In en, this message translates to:
  /// **'Most recent first'**
  String get sortByDateDesc;

  /// No description provided for @sortByDateAsc.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortByDateAsc;

  /// No description provided for @sortByNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get sortByNameAsc;

  /// No description provided for @sortByNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get sortByNameDesc;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwords.
  ///
  /// In en, this message translates to:
  /// **'Passwords'**
  String get passwords;

  /// No description provided for @additionalPasswordsShort.
  ///
  /// In en, this message translates to:
  /// **'Additional'**
  String get additionalPasswordsShort;

  /// No description provided for @url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @additionalPasswords.
  ///
  /// In en, this message translates to:
  /// **'Additional Passwords'**
  String get additionalPasswords;

  /// No description provided for @additionalPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional password'**
  String get additionalPasswordLabel;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @generatePassword.
  ///
  /// In en, this message translates to:
  /// **'Generate Password'**
  String get generatePassword;

  /// No description provided for @passwordLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get passwordLength;

  /// No description provided for @includeUppercase.
  ///
  /// In en, this message translates to:
  /// **'Uppercase (A-Z)'**
  String get includeUppercase;

  /// No description provided for @includeLowercase.
  ///
  /// In en, this message translates to:
  /// **'Lowercase (a-z)'**
  String get includeLowercase;

  /// No description provided for @includeNumbers.
  ///
  /// In en, this message translates to:
  /// **'Numbers (0-9)'**
  String get includeNumbers;

  /// No description provided for @includeSymbols.
  ///
  /// In en, this message translates to:
  /// **'Symbols (!@#\$...)'**
  String get includeSymbols;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteEntryTitle;

  /// No description provided for @deleteEntryMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entry?'**
  String get deleteEntryMessage;

  /// No description provided for @deleteEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \"DELETE\" to confirm'**
  String get deleteEntryConfirm;

  /// No description provided for @deleteKeyword.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteKeyword;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get deleteSuccess;

  /// No description provided for @lockTimeoutImmediate.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get lockTimeoutImmediate;

  /// No description provided for @lockTimeout30s.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get lockTimeout30s;

  /// No description provided for @lockTimeout1m.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get lockTimeout1m;

  /// No description provided for @lockTimeout2m.
  ///
  /// In en, this message translates to:
  /// **'2 minutes'**
  String get lockTimeout2m;

  /// No description provided for @lockTimeout5m.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get lockTimeout5m;

  /// No description provided for @lockTimeout10m.
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get lockTimeout10m;

  /// No description provided for @lockTimeout30m.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get lockTimeout30m;

  /// No description provided for @autoCloseDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get autoCloseDisabled;

  /// No description provided for @autoClose30s.
  ///
  /// In en, this message translates to:
  /// **'30 seconds'**
  String get autoClose30s;

  /// No description provided for @autoClose1m.
  ///
  /// In en, this message translates to:
  /// **'1 minute'**
  String get autoClose1m;

  /// No description provided for @autoClose2m.
  ///
  /// In en, this message translates to:
  /// **'2 minutes'**
  String get autoClose2m;

  /// No description provided for @autoClose5m.
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get autoClose5m;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get languageSubtitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @blurEnabled.
  ///
  /// In en, this message translates to:
  /// **'Screen blur activated'**
  String get blurEnabled;

  /// No description provided for @blurDisabled.
  ///
  /// In en, this message translates to:
  /// **'Screen blur deactivated'**
  String get blurDisabled;

  /// No description provided for @biometryEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometry activated'**
  String get biometryEnabled;

  /// No description provided for @biometryDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometry deactivated'**
  String get biometryDisabled;

  /// No description provided for @biometryError.
  ///
  /// In en, this message translates to:
  /// **'You must first reconnect with your master password'**
  String get biometryError;

  /// No description provided for @mustReconnect.
  ///
  /// In en, this message translates to:
  /// **'Error: You must first reconnect with your master password'**
  String get mustReconnect;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} entries imported successfully.\nBiometry has been disabled for security reasons.\nThe application will close.'**
  String importSuccess(int count);

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get exportSuccess;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import error'**
  String get importError;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedAt;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @viewEntry.
  ///
  /// In en, this message translates to:
  /// **'View Entry'**
  String get viewEntry;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New Entry'**
  String get newEntry;

  /// No description provided for @errorCreatingMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Error creating master password'**
  String get errorCreatingMasterPassword;

  /// No description provided for @checkMasterPasswordOrBiometry.
  ///
  /// In en, this message translates to:
  /// **'1. Check your master password or use biometry.'**
  String get checkMasterPasswordOrBiometry;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'2. Restore from backup:'**
  String get restoreFromBackup;

  /// No description provided for @myLocalBackups.
  ///
  /// In en, this message translates to:
  /// **'My local backup:'**
  String get myLocalBackups;

  /// No description provided for @noLocalBackup.
  ///
  /// In en, this message translates to:
  /// **'No local backup.'**
  String get noLocalBackup;

  /// No description provided for @backupEntry.
  ///
  /// In en, this message translates to:
  /// **'entry'**
  String get backupEntry;

  /// No description provided for @backupEntries.
  ///
  /// In en, this message translates to:
  /// **'entries'**
  String get backupEntries;

  /// No description provided for @restoreFromBackupButton.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restoreFromBackupButton;

  /// No description provided for @importSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose import source'**
  String get importSourceTitle;

  /// No description provided for @importFromLocalFile.
  ///
  /// In en, this message translates to:
  /// **'Local file'**
  String get importFromLocalFile;

  /// No description provided for @importFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup'**
  String get importFromCloud;

  /// No description provided for @resetApplication.
  ///
  /// In en, this message translates to:
  /// **'Reset application'**
  String get resetApplication;

  /// No description provided for @resetApplicationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset the application?\n\nAll your data (passwords, settings, backups) will be permanently deleted.\n\nType RESET to confirm:'**
  String get resetApplicationConfirm;

  /// No description provided for @resetConfirmWord.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get resetConfirmWord;

  /// No description provided for @typeResetToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type RESET to confirm'**
  String get typeResetToConfirm;

  /// No description provided for @applicationResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Application reset successfully'**
  String get applicationResetSuccess;

  /// No description provided for @biometryNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Biometry not configured. Use your master password.'**
  String get biometryNotConfigured;

  /// No description provided for @biometricUnlockError.
  ///
  /// In en, this message translates to:
  /// **'Error during biometric unlock'**
  String get biometricUnlockError;

  /// No description provided for @biometricError.
  ///
  /// In en, this message translates to:
  /// **'Biometric error: {error}'**
  String biometricError(String error);

  /// No description provided for @biometryTemporarilyBlocked.
  ///
  /// In en, this message translates to:
  /// **'Biometry temporarily blocked. Use your master password.'**
  String get biometryTemporarilyBlocked;

  /// No description provided for @importError2.
  ///
  /// In en, this message translates to:
  /// **'Error during import'**
  String get importError2;

  /// No description provided for @vaultAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Vault already exists'**
  String get vaultAlreadyExists;

  /// No description provided for @vaultExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'A vault already exists.\n\nImporting will ERASE all current data and replace them with the backup.\n\nType IMPORT to confirm:'**
  String get vaultExistsMessage;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @importConfirmWord.
  ///
  /// In en, this message translates to:
  /// **'IMPORT'**
  String get importConfirmWord;

  /// No description provided for @invalidBackup.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup: {error}'**
  String invalidBackup(String error);

  /// No description provided for @backupMasterPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Master Password'**
  String get backupMasterPassword;

  /// No description provided for @backupPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter the master password from the backup to decrypt it:'**
  String get backupPasswordInstructions;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @importInProgress.
  ///
  /// In en, this message translates to:
  /// **'Import in progress...'**
  String get importInProgress;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get pleaseWait;

  /// No description provided for @decryptionInProgress.
  ///
  /// In en, this message translates to:
  /// **'Decryption in progress...'**
  String get decryptionInProgress;

  /// No description provided for @decryptionError.
  ///
  /// In en, this message translates to:
  /// **'Decryption error'**
  String get decryptionError;

  /// No description provided for @incorrectBackupPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password or corrupted backup.'**
  String get incorrectBackupPassword;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @personalCategory.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personalCategory;

  /// No description provided for @workCategory.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workCategory;

  /// No description provided for @bankCategory.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankCategory;

  /// No description provided for @socialCategory.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get socialCategory;

  /// No description provided for @emailCategory.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailCategory;

  /// No description provided for @shoppingCategory.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shoppingCategory;

  /// No description provided for @entertainmentCategory.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainmentCategory;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterByCategory;

  /// No description provided for @premiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get premiumFeatures;

  /// No description provided for @premiumDescription.
  ///
  /// In en, this message translates to:
  /// **'Upcoming features for PassKeyra Premium subscribers'**
  String get premiumDescription;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get cloudSync;

  /// No description provided for @cloudSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatic sync across all your devices'**
  String get cloudSyncDescription;

  /// No description provided for @biometricVault.
  ///
  /// In en, this message translates to:
  /// **'Biometric Vault'**
  String get biometricVault;

  /// No description provided for @biometricVaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Enhanced security with biometric authentication'**
  String get biometricVaultDescription;

  /// No description provided for @prioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority Support'**
  String get prioritySupport;

  /// No description provided for @prioritySupportDescription.
  ///
  /// In en, this message translates to:
  /// **'Get help faster with priority support'**
  String get prioritySupportDescription;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @manageCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategoriesTitle;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryColor.
  ///
  /// In en, this message translates to:
  /// **'Category Color'**
  String get categoryColor;

  /// No description provided for @categoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Category Icon'**
  String get categoryIcon;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColor;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this category?'**
  String get deleteCategoryConfirm;

  /// No description provided for @categorySaved.
  ///
  /// In en, this message translates to:
  /// **'Category saved'**
  String get categorySaved;

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoryDeleted;

  /// No description provided for @import2.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import2;

  /// No description provided for @importFromFile.
  ///
  /// In en, this message translates to:
  /// **'Import from File'**
  String get importFromFile;

  /// No description provided for @importInstructions.
  ///
  /// In en, this message translates to:
  /// **'Select a PassKeyra backup file (.json) to import'**
  String get importInstructions;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noFileSelected;

  /// No description provided for @importWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: This will replace all your current data!'**
  String get importWarning;

  /// No description provided for @exportToFile.
  ///
  /// In en, this message translates to:
  /// **'Export to File'**
  String get exportToFile;

  /// No description provided for @exportInstructions.
  ///
  /// In en, this message translates to:
  /// **'Export all your passwords to a secure backup file'**
  String get exportInstructions;

  /// No description provided for @exportButton.
  ///
  /// In en, this message translates to:
  /// **'Export Now'**
  String get exportButton;

  /// No description provided for @exportWarning.
  ///
  /// In en, this message translates to:
  /// **'Keep this file in a safe place!'**
  String get exportWarning;

  /// No description provided for @fileExported.
  ///
  /// In en, this message translates to:
  /// **'File exported successfully'**
  String get fileExported;

  /// No description provided for @autoClose45s.
  ///
  /// In en, this message translates to:
  /// **'45 seconds'**
  String get autoClose45s;

  /// No description provided for @securityAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Security Analysis'**
  String get securityAnalysis;

  /// No description provided for @securityScore.
  ///
  /// In en, this message translates to:
  /// **'Security Score'**
  String get securityScore;

  /// No description provided for @securityAnalysisPremiumMessage.
  ///
  /// In en, this message translates to:
  /// **'Security Analysis is a Premium feature. Upgrade to Premium to scan your passwords and detect weaknesses.'**
  String get securityAnalysisPremiumMessage;

  /// No description provided for @viewPremium.
  ///
  /// In en, this message translates to:
  /// **'View Premium'**
  String get viewPremium;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @veryWeak.
  ///
  /// In en, this message translates to:
  /// **'Very Weak'**
  String get veryWeak;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weak;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @veryStrong.
  ///
  /// In en, this message translates to:
  /// **'Very Strong'**
  String get veryStrong;

  /// No description provided for @analysisSummary.
  ///
  /// In en, this message translates to:
  /// **'Analysis Summary'**
  String get analysisSummary;

  /// No description provided for @strongPasswords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No strong passwords} =1{1 strong password} other{{count} strong passwords}}'**
  String strongPasswords(int count);

  /// No description provided for @weakPasswords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No weak passwords} =1{1 weak password} other{{count} weak passwords}}'**
  String weakPasswords(int count);

  /// No description provided for @duplicatePasswords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No duplicates} =1{1 duplicate password} other{{count} duplicate passwords}}'**
  String duplicatePasswords(int count);

  /// No description provided for @oldPasswords.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No old passwords} =1{1 old password} other{{count} old passwords}}'**
  String oldPasswords(int count);

  /// No description provided for @issuesFound.
  ///
  /// In en, this message translates to:
  /// **'Issues Found'**
  String get issuesFound;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Weak Password'**
  String get weakPassword;

  /// No description provided for @duplicatePassword.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Password'**
  String get duplicatePassword;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @alsoUsedIn.
  ///
  /// In en, this message translates to:
  /// **'Also used in'**
  String get alsoUsedIn;

  /// No description provided for @recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// No description provided for @recommendUseStrongPasswords.
  ///
  /// In en, this message translates to:
  /// **'Use more complex passwords for better security'**
  String get recommendUseStrongPasswords;

  /// No description provided for @recommendUseUniquePasswords.
  ///
  /// In en, this message translates to:
  /// **'Avoid reusing the same passwords'**
  String get recommendUseUniquePasswords;

  /// No description provided for @recommendUpdateOldPasswords.
  ///
  /// In en, this message translates to:
  /// **'Update old passwords at least once a year'**
  String get recommendUpdateOldPasswords;

  /// No description provided for @recommendUse12PlusChars.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters for your passwords'**
  String get recommendUse12PlusChars;

  /// No description provided for @recommendUseSymbols.
  ///
  /// In en, this message translates to:
  /// **'Include symbols to strengthen security'**
  String get recommendUseSymbols;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @securityAnalysisHelp.
  ///
  /// In en, this message translates to:
  /// **'Security Analysis examines all your passwords and detects:\n\n• Weak passwords (too short or simple)\n• Duplicate passwords (used multiple times)\n• Old passwords (not changed for >1 year)\n\nThe security score is calculated based on:\n• Password length\n• Character variety (uppercase, lowercase, numbers, symbols)\n• Overall complexity'**
  String get securityAnalysisHelp;

  /// No description provided for @errorDuringAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Error during analysis: {error}'**
  String errorDuringAnalysis(String error);

  /// No description provided for @unableToPerformAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Unable to perform analysis'**
  String get unableToPerformAnalysis;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @passwordNotUpdatedYears.
  ///
  /// In en, this message translates to:
  /// **'Not updated in {years} year(s)'**
  String passwordNotUpdatedYears(int years);

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Too short (< 8 chars)'**
  String get passwordTooShort;

  /// No description provided for @passwordShouldBe12Plus.
  ///
  /// In en, this message translates to:
  /// **'Should be 12+ characters'**
  String get passwordShouldBe12Plus;

  /// No description provided for @passwordNoUppercase.
  ///
  /// In en, this message translates to:
  /// **'No uppercase'**
  String get passwordNoUppercase;

  /// No description provided for @passwordNoLowercase.
  ///
  /// In en, this message translates to:
  /// **'No lowercase'**
  String get passwordNoLowercase;

  /// No description provided for @passwordNoNumbers.
  ///
  /// In en, this message translates to:
  /// **'No numbers'**
  String get passwordNoNumbers;

  /// No description provided for @passwordNoSymbols.
  ///
  /// In en, this message translates to:
  /// **'No symbols'**
  String get passwordNoSymbols;

  /// No description provided for @weakPasswordGeneric.
  ///
  /// In en, this message translates to:
  /// **'Weak password'**
  String get weakPasswordGeneric;

  /// No description provided for @usedInEntries.
  ///
  /// In en, this message translates to:
  /// **'Used in {count} entries'**
  String usedInEntries(int count);

  /// No description provided for @customIcon.
  ///
  /// In en, this message translates to:
  /// **'Custom Icon'**
  String get customIcon;

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose an Icon'**
  String get chooseIcon;

  /// No description provided for @changeIcon.
  ///
  /// In en, this message translates to:
  /// **'Change Icon'**
  String get changeIcon;

  /// No description provided for @iconSelected.
  ///
  /// In en, this message translates to:
  /// **'Icon Selected'**
  String get iconSelected;

  /// No description provided for @chooseColor.
  ///
  /// In en, this message translates to:
  /// **'Choose a Color'**
  String get chooseColor;

  /// No description provided for @customIconsPremiumFeature.
  ///
  /// In en, this message translates to:
  /// **'Custom icons are reserved for Premium users. Upgrade to Premium to unlock this feature and much more!'**
  String get customIconsPremiumFeature;

  /// No description provided for @categoryIconsTab.
  ///
  /// In en, this message translates to:
  /// **'Icons'**
  String get categoryIconsTab;

  /// No description provided for @categoryEmojisTab.
  ///
  /// In en, this message translates to:
  /// **'Emojis'**
  String get categoryEmojisTab;

  /// No description provided for @categoryEmojisPremium.
  ///
  /// In en, this message translates to:
  /// **'Emojis for categories are reserved for Premium users'**
  String get categoryEmojisPremium;

  /// No description provided for @categoryColorPicker.
  ///
  /// In en, this message translates to:
  /// **'Full Palette'**
  String get categoryColorPicker;

  /// No description provided for @categoryPredefinedColors.
  ///
  /// In en, this message translates to:
  /// **'Predefined Colors'**
  String get categoryPredefinedColors;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Light, dark or system mode'**
  String get themeSubtitle;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select a Theme'**
  String get selectTheme;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Display Mode'**
  String get themeMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'Automatic mode'**
  String get systemMode;

  /// No description provided for @systemModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Based on ambient light'**
  String get systemModeSubtitle;

  /// No description provided for @darkVariant.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode Variant'**
  String get darkVariant;

  /// No description provided for @standardDark.
  ///
  /// In en, this message translates to:
  /// **'Standard Dark'**
  String get standardDark;

  /// No description provided for @standardDarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Classic dark mode'**
  String get standardDarkSubtitle;

  /// No description provided for @amoledBlack.
  ///
  /// In en, this message translates to:
  /// **'AMOLED Black'**
  String get amoledBlack;

  /// No description provided for @amoledBlackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pure black for OLED screens'**
  String get amoledBlackSubtitle;

  /// No description provided for @darkGrey.
  ///
  /// In en, this message translates to:
  /// **'Dark Grey'**
  String get darkGrey;

  /// No description provided for @darkGreySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Elegant custom grey'**
  String get darkGreySubtitle;

  /// No description provided for @darkThemePremiumFeature.
  ///
  /// In en, this message translates to:
  /// **'Advanced dark mode variants (AMOLED Black and Dark Grey) are reserved for Premium users. Upgrade to Premium to unlock these themes and much more!'**
  String get darkThemePremiumFeature;

  /// No description provided for @colorPalette.
  ///
  /// In en, this message translates to:
  /// **'Color Palette'**
  String get colorPalette;

  /// No description provided for @colorPaletteBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue (Classic)'**
  String get colorPaletteBlue;

  /// No description provided for @colorPaletteGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorPaletteGreen;

  /// No description provided for @colorPaletteRedPink.
  ///
  /// In en, this message translates to:
  /// **'Red/Pink'**
  String get colorPaletteRedPink;

  /// No description provided for @colorPalettePurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPalettePurple;

  /// No description provided for @colorPaletteOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorPaletteOrange;

  /// No description provided for @colorPalettePremiumFeature.
  ///
  /// In en, this message translates to:
  /// **'Custom color palettes are reserved for Premium users. Upgrade to Premium to unlock all palettes and much more!'**
  String get colorPalettePremiumFeature;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamily;

  /// No description provided for @fontRoboto.
  ///
  /// In en, this message translates to:
  /// **'Roboto'**
  String get fontRoboto;

  /// No description provided for @fontLato.
  ///
  /// In en, this message translates to:
  /// **'Lato'**
  String get fontLato;

  /// No description provided for @fontMontserrat.
  ///
  /// In en, this message translates to:
  /// **'Montserrat'**
  String get fontMontserrat;

  /// No description provided for @fontOpenSans.
  ///
  /// In en, this message translates to:
  /// **'Open Sans'**
  String get fontOpenSans;

  /// No description provided for @fontFamilyPremiumFeature.
  ///
  /// In en, this message translates to:
  /// **'Custom fonts are reserved for Premium users. Upgrade to Premium to unlock all fonts and much more!'**
  String get fontFamilyPremiumFeature;

  /// No description provided for @cloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get cloudBackup;

  /// No description provided for @cloudBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backup to cloud'**
  String get cloudBackupSubtitle;

  /// No description provided for @cloudBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get cloudBackupTitle;

  /// No description provided for @cloudProviderSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred cloud service to securely backup your passwords. You can change service at any time.'**
  String get cloudProviderSelectionDescription;

  /// No description provided for @selectCloudProvider.
  ///
  /// In en, this message translates to:
  /// **'Choose cloud service'**
  String get selectCloudProvider;

  /// No description provided for @switchProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch cloud service'**
  String get switchProviderTitle;

  /// No description provided for @switchProviderMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign out from {currentProvider} and switch to {newProvider}?'**
  String switchProviderMessage(Object currentProvider, Object newProvider);

  /// No description provided for @googleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get googleDrive;

  /// No description provided for @uploadToCloud.
  ///
  /// In en, this message translates to:
  /// **'Backup to cloud'**
  String get uploadToCloud;

  /// No description provided for @restoreFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Restore from cloud'**
  String get restoreFromCloud;

  /// No description provided for @cloudBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup successful'**
  String get cloudBackupSuccess;

  /// No description provided for @cloudDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Google account?'**
  String get cloudDisconnectTitle;

  /// No description provided for @cloudDisconnectMessage.
  ///
  /// In en, this message translates to:
  /// **'Google Drive backup and Premium sync use the same Google account: sync is the Premium extension of Drive backup. Disconnecting therefore stops both. Your local data and the backups already stored in the cloud are kept. You can reconnect and choose another account at any time.'**
  String get cloudDisconnectMessage;

  /// No description provided for @cloudDisconnectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get cloudDisconnectConfirm;

  /// No description provided for @cloudDisconnectGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect cloud account?'**
  String get cloudDisconnectGenericTitle;

  /// No description provided for @cloudDisconnectGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'This disables automatic backup, disconnects your cloud account and clears the provider configuration. The backups already stored in the cloud and your local data are kept.'**
  String get cloudDisconnectGenericMessage;

  /// No description provided for @cloudBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup failed: {error}'**
  String cloudBackupFailed(Object error);

  /// No description provided for @noCloudBackups.
  ///
  /// In en, this message translates to:
  /// **'No cloud backups found'**
  String get noCloudBackups;

  /// No description provided for @lastCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String lastCloudBackup(Object date);

  /// No description provided for @cloudQuotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'Cloud quota exceeded'**
  String get cloudQuotaExceeded;

  /// No description provided for @cloudProviderNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud service unavailable'**
  String get cloudProviderNotAvailable;

  /// No description provided for @authenticateWith.
  ///
  /// In en, this message translates to:
  /// **'Sign in to {provider}'**
  String authenticateWith(Object provider);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @deleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Delete backup'**
  String get deleteBackup;

  /// No description provided for @downloadBackup.
  ///
  /// In en, this message translates to:
  /// **'Download backup'**
  String get downloadBackup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @cloudRestoreConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Restore backup from {date}? This will replace all your current data.'**
  String cloudRestoreConfirmation(Object date);

  /// No description provided for @cloudRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully ({count} entries)'**
  String cloudRestoreSuccess(Object count);

  /// No description provided for @cloudRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String cloudRestoreFailed(Object error);

  /// No description provided for @restoreSuccessAutoClose.
  ///
  /// In en, this message translates to:
  /// **'Restore successful!\n\nThe app will close automatically in 2 seconds to apply changes.'**
  String get restoreSuccessAutoClose;

  /// No description provided for @cloudDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete backup from {date}?'**
  String cloudDeleteConfirmation(Object date);

  /// No description provided for @cloudBackupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Backup deleted'**
  String get cloudBackupDeleted;

  /// No description provided for @cloudDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String cloudDeleteFailed(Object error);

  /// No description provided for @cloudNoBackupsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to create your first backup'**
  String get cloudNoBackupsHint;

  /// No description provided for @cloudRateLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'Please wait {minutes} minute(s) before next backup'**
  String cloudRateLimitMessage(Object minutes);

  /// No description provided for @cloudAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get cloudAuthenticationFailed;

  /// No description provided for @cloudNoAuthService.
  ///
  /// In en, this message translates to:
  /// **'Authentication service not available'**
  String get cloudNoAuthService;

  /// No description provided for @cloudSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get cloudSyncTitle;

  /// No description provided for @cloudSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic real-time sync between devices'**
  String get cloudSyncSubtitle;

  /// No description provided for @cloudSyncSettings.
  ///
  /// In en, this message translates to:
  /// **'Sync settings'**
  String get cloudSyncSettings;

  /// No description provided for @cloudSyncAccount.
  ///
  /// In en, this message translates to:
  /// **'Cloud account'**
  String get cloudSyncAccount;

  /// No description provided for @cloudSyncNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No Google account connected'**
  String get cloudSyncNoAccount;

  /// No description provided for @cloudSyncSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get cloudSyncSignIn;

  /// No description provided for @cloudSyncSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get cloudSyncSignOut;

  /// No description provided for @cloudSyncAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic synchronization'**
  String get cloudSyncAutomatic;

  /// No description provided for @cloudSyncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Changes are automatically synchronized'**
  String get cloudSyncEnabled;

  /// No description provided for @cloudSyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Manual synchronization only'**
  String get cloudSyncDisabled;

  /// No description provided for @cloudSyncManualActions.
  ///
  /// In en, this message translates to:
  /// **'Manual actions'**
  String get cloudSyncManualActions;

  /// No description provided for @cloudSyncUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload to cloud'**
  String get cloudSyncUpload;

  /// No description provided for @cloudSyncDownload.
  ///
  /// In en, this message translates to:
  /// **'Download from cloud'**
  String get cloudSyncDownload;

  /// No description provided for @cloudSyncPremiumFeature.
  ///
  /// In en, this message translates to:
  /// **'Premium Feature'**
  String get cloudSyncPremiumFeature;

  /// No description provided for @cloudSyncPremiumMessage.
  ///
  /// In en, this message translates to:
  /// **'Real-time cloud sync requires PassKeyra Premium'**
  String get cloudSyncPremiumMessage;

  /// No description provided for @syncStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get syncStatusIdle;

  /// No description provided for @syncStatusSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncStatusSyncing;

  /// No description provided for @syncStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSuccess;

  /// No description provided for @syncStatusError.
  ///
  /// In en, this message translates to:
  /// **'Sync error'**
  String get syncStatusError;

  /// No description provided for @syncStatusConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict detected'**
  String get syncStatusConflict;

  /// No description provided for @syncLastSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get syncLastSyncNever;

  /// No description provided for @syncLastSyncJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get syncLastSyncJustNow;

  /// No description provided for @syncLastSyncMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String syncLastSyncMinutes(Object minutes);

  /// No description provided for @syncLastSyncHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String syncLastSyncHours(Object hours);

  /// No description provided for @syncLastSyncDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String syncLastSyncDays(Object days);

  /// No description provided for @syncEntriesUploaded.
  ///
  /// In en, this message translates to:
  /// **'{count} entries synced'**
  String syncEntriesUploaded(Object count);

  /// No description provided for @syncEntriesDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{count} entries downloaded'**
  String syncEntriesDownloaded(Object count);

  /// No description provided for @syncMergeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Merge completed ({count} entries)'**
  String syncMergeCompleted(Object count);

  /// No description provided for @syncConflictResolved.
  ///
  /// In en, this message translates to:
  /// **'Conflict resolved (most recent version kept)'**
  String get syncConflictResolved;

  /// No description provided for @syncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Sync enabled'**
  String get syncEnabled;

  /// No description provided for @syncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Sync disabled'**
  String get syncDisabled;

  /// No description provided for @syncErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'Error: No internet connection'**
  String get syncErrorOffline;

  /// No description provided for @syncErrorAuth.
  ///
  /// In en, this message translates to:
  /// **'Error: Authentication expired'**
  String get syncErrorAuth;

  /// No description provided for @syncErrorQuota.
  ///
  /// In en, this message translates to:
  /// **'Error: Firebase quota exceeded'**
  String get syncErrorQuota;

  /// No description provided for @helpLogosTitle.
  ///
  /// In en, this message translates to:
  /// **'Logo meanings'**
  String get helpLogosTitle;

  /// No description provided for @helpLogoCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud Logo (☁️)'**
  String get helpLogoCloud;

  /// No description provided for @helpLogoCloudSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic Google Drive backup'**
  String get helpLogoCloudSubtitle;

  /// No description provided for @helpLogoSync.
  ///
  /// In en, this message translates to:
  /// **'Sync Logo (⇄)'**
  String get helpLogoSync;

  /// No description provided for @helpLogoSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time Firebase sync'**
  String get helpLogoSyncSubtitle;

  /// No description provided for @helpColorLegend.
  ///
  /// In en, this message translates to:
  /// **'Color code (for both logos):'**
  String get helpColorLegend;

  /// No description provided for @helpColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get helpColorBlue;

  /// No description provided for @helpColorBlueMeaning.
  ///
  /// In en, this message translates to:
  /// **'Enabled and ready'**
  String get helpColorBlueMeaning;

  /// No description provided for @helpColorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get helpColorPurple;

  /// No description provided for @helpColorPurpleMeaning.
  ///
  /// In en, this message translates to:
  /// **'Sync in progress'**
  String get helpColorPurpleMeaning;

  /// No description provided for @helpColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get helpColorGreen;

  /// No description provided for @helpColorGreenMeaning.
  ///
  /// In en, this message translates to:
  /// **'Operation successful'**
  String get helpColorGreenMeaning;

  /// No description provided for @helpColorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get helpColorRed;

  /// No description provided for @helpColorRedMeaning.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get helpColorRedMeaning;

  /// No description provided for @helpColorGrey.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get helpColorGrey;

  /// No description provided for @helpColorGreyMeaning.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get helpColorGreyMeaning;

  /// No description provided for @syncConnectedAs.
  ///
  /// In en, this message translates to:
  /// **'Connected as {email}'**
  String syncConnectedAs(Object email);

  /// No description provided for @syncDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get syncDisconnected;

  /// No description provided for @syncAutoLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto sync'**
  String get syncAutoLabel;

  /// No description provided for @syncManualLabel.
  ///
  /// In en, this message translates to:
  /// **'Manual sync'**
  String get syncManualLabel;

  /// No description provided for @androidVersionWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Limited features'**
  String get androidVersionWarningTitle;

  /// No description provided for @androidVersionWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Android version (< 8.0) does not support backup restoration. For a complete experience, please use Android 8.0 or higher. Backup creation and viewing remain available.'**
  String get androidVersionWarningMessage;

  /// No description provided for @onboardingFirstChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting started tutorial'**
  String get onboardingFirstChoiceTitle;

  /// No description provided for @onboardingFirstChoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want a quick guided setup before creating your vault?'**
  String get onboardingFirstChoiceMessage;

  /// No description provided for @onboardingStartTutorial.
  ///
  /// In en, this message translates to:
  /// **'Start tutorial'**
  String get onboardingStartTutorial;

  /// No description provided for @onboardingSkipTutorial.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get onboardingSkipTutorial;

  /// No description provided for @onboardingQuitTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutorial exited'**
  String get onboardingQuitTitle;

  /// No description provided for @onboardingQuitMessage.
  ///
  /// In en, this message translates to:
  /// **'You can replay it at any time from Settings → Tutorials.'**
  String get onboardingQuitMessage;

  /// No description provided for @onboardingMasterPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Master password warning'**
  String get onboardingMasterPasswordTitle;

  /// No description provided for @onboardingMasterPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Your master password is the only key. If lost, there is no recovery.'**
  String get onboardingMasterPasswordMessage;

  /// No description provided for @onboardingSecurityRequirements.
  ///
  /// In en, this message translates to:
  /// **'Security requirements:'**
  String get onboardingSecurityRequirements;

  /// No description provided for @onboardingRuleLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum 12 characters (16+ recommended)'**
  String get onboardingRuleLength;

  /// No description provided for @onboardingRuleComplexity.
  ///
  /// In en, this message translates to:
  /// **'Uppercase, lowercase, numbers, symbols'**
  String get onboardingRuleComplexity;

  /// No description provided for @onboardingRuleDictionary.
  ///
  /// In en, this message translates to:
  /// **'Avoid dictionary words'**
  String get onboardingRuleDictionary;

  /// No description provided for @onboardingRuleUnique.
  ///
  /// In en, this message translates to:
  /// **'Use a unique password, never reused'**
  String get onboardingRuleUnique;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get onboardingFinish;

  /// No description provided for @onboardingCreateFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Create my first entry'**
  String get onboardingCreateFirstEntry;

  /// No description provided for @onboardingStepSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick search'**
  String get onboardingStepSearchTitle;

  /// No description provided for @onboardingStepSearchBody.
  ///
  /// In en, this message translates to:
  /// **'The search function filters entries by name, username, URL, or tags.'**
  String get onboardingStepSearchBody;

  /// No description provided for @onboardingStepSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings access'**
  String get onboardingStepSettingsTitle;

  /// No description provided for @onboardingStepSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'This menu groups all security settings and other options.'**
  String get onboardingStepSettingsBody;

  /// No description provided for @onboardingStepAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Creating an entry'**
  String get onboardingStepAddTitle;

  /// No description provided for @onboardingStepAddBody.
  ///
  /// In en, this message translates to:
  /// **'The + button creates a new entry in the vault.'**
  String get onboardingStepAddBody;

  /// No description provided for @onboardingStepCopyAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy an entry'**
  String get onboardingStepCopyAllTitle;

  /// No description provided for @onboardingStepCopyAllBody.
  ///
  /// In en, this message translates to:
  /// **'This button copies all useful info from the entry: username, password, URL and notes if present.'**
  String get onboardingStepCopyAllBody;

  /// No description provided for @onboardingRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart tutorial'**
  String get onboardingRestart;

  /// No description provided for @onboardingRestartDescription.
  ///
  /// In en, this message translates to:
  /// **'Replay the complete getting-started tutorial'**
  String get onboardingRestartDescription;

  /// No description provided for @onboardingWillRestart.
  ///
  /// In en, this message translates to:
  /// **'The tutorial will restart on the next app launch.'**
  String get onboardingWillRestart;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingFinishLater.
  ///
  /// In en, this message translates to:
  /// **'Finish later'**
  String get onboardingFinishLater;

  /// No description provided for @onboardingSecurityPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Security overview'**
  String get onboardingSecurityPauseTitle;

  /// No description provided for @onboardingSecurityPauseMessage.
  ///
  /// In en, this message translates to:
  /// **'Continue with an overview of security features? (3 quick steps)'**
  String get onboardingSecurityPauseMessage;

  /// No description provided for @onboardingSecurityReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Security analysis'**
  String get onboardingSecurityReportTitle;

  /// No description provided for @onboardingSecurityReportMessage.
  ///
  /// In en, this message translates to:
  /// **'The security report analyzes passwords and detects issues: weak, reused, or compromised passwords.'**
  String get onboardingSecurityReportMessage;

  /// No description provided for @onboardingLockTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get onboardingLockTimeoutTitle;

  /// No description provided for @onboardingLockTimeoutMessage.
  ///
  /// In en, this message translates to:
  /// **'The app automatically locks after a period of inactivity to protect data.'**
  String get onboardingLockTimeoutMessage;

  /// No description provided for @onboardingBiometryTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication'**
  String get onboardingBiometryTitle;

  /// No description provided for @onboardingBiometryMessage.
  ///
  /// In en, this message translates to:
  /// **'Quick and secure unlocking with fingerprint or face recognition.'**
  String get onboardingBiometryMessage;

  /// No description provided for @onboardingCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'You now know all the essential features of PassKeyra. Enjoy using it!'**
  String get onboardingCompleteMessage;

  /// No description provided for @discoveryModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutorials'**
  String get discoveryModeTitle;

  /// No description provided for @discoveryModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn how to use all PassKeyra features at your own pace'**
  String get discoveryModeSubtitle;

  /// No description provided for @discoverySteps.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get discoverySteps;

  /// No description provided for @discoveryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get discoveryCompleted;

  /// No description provided for @discoveryStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get discoveryStart;

  /// No description provided for @discoveryReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get discoveryReplay;

  /// No description provided for @discoveryEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced entry management'**
  String get discoveryEntriesTitle;

  /// No description provided for @discoveryEntriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Learn how to view, edit, and organize your entries'**
  String get discoveryEntriesDescription;

  /// No description provided for @discoveryEntriesViewTitle.
  ///
  /// In en, this message translates to:
  /// **'View an entry'**
  String get discoveryEntriesViewTitle;

  /// No description provided for @discoveryEntriesViewMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap an entry in the list to display all its details: password, username, URL, notes, and category.'**
  String get discoveryEntriesViewMessage;

  /// No description provided for @discoveryEntriesCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick copy'**
  String get discoveryEntriesCopyTitle;

  /// No description provided for @discoveryEntriesCopyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the password or username to instantly copy it to your clipboard.'**
  String get discoveryEntriesCopyMessage;

  /// No description provided for @discoveryEntriesGeneratorTitle.
  ///
  /// In en, this message translates to:
  /// **'Password generator'**
  String get discoveryEntriesGeneratorTitle;

  /// No description provided for @discoveryEntriesGeneratorMessage.
  ///
  /// In en, this message translates to:
  /// **'Use the generator to create strong and unique passwords. Customize the length and included characters.'**
  String get discoveryEntriesGeneratorMessage;

  /// No description provided for @discoveryEntriesAdditionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional passwords'**
  String get discoveryEntriesAdditionalTitle;

  /// No description provided for @discoveryEntriesAdditionalMessage.
  ///
  /// In en, this message translates to:
  /// **'Add multiple passwords to the same entry (e.g., main password + PIN code).'**
  String get discoveryEntriesAdditionalMessage;

  /// No description provided for @discoveryEntriesCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom categories'**
  String get discoveryEntriesCategoriesTitle;

  /// No description provided for @discoveryEntriesCategoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your own categories to organize your entries as you wish.'**
  String get discoveryEntriesCategoriesMessage;

  /// No description provided for @discoveryBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Synchronization'**
  String get discoveryBackupTitle;

  /// No description provided for @discoveryBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Protect your data and sync across devices'**
  String get discoveryBackupDescription;

  /// No description provided for @discoveryBackupLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Local backups'**
  String get discoveryBackupLocalTitle;

  /// No description provided for @discoveryBackupLocalMessage.
  ///
  /// In en, this message translates to:
  /// **'Export your data to your device to back it up or transfer it. You can also import from a backup file.'**
  String get discoveryBackupLocalMessage;

  /// No description provided for @discoveryBackupDriveTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get discoveryBackupDriveTitle;

  /// No description provided for @discoveryBackupDriveMessage.
  ///
  /// In en, this message translates to:
  /// **'Automatically back up your encrypted data to Google Drive to recover it in case of problems.'**
  String get discoveryBackupDriveMessage;

  /// No description provided for @discoveryBackupSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Firebase Sync'**
  String get discoveryBackupSyncTitle;

  /// No description provided for @discoveryBackupSyncMessage.
  ///
  /// In en, this message translates to:
  /// **'Automatically sync your entries across all your devices in real-time (Premium feature).'**
  String get discoveryBackupSyncMessage;

  /// No description provided for @discoveryBackupConflictsTitle.
  ///
  /// In en, this message translates to:
  /// **'Conflict resolution'**
  String get discoveryBackupConflictsTitle;

  /// No description provided for @discoveryBackupConflictsMessage.
  ///
  /// In en, this message translates to:
  /// **'In case of simultaneous changes on multiple devices, choose which version to keep.'**
  String get discoveryBackupConflictsMessage;

  /// No description provided for @discoveryAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Premium'**
  String get discoveryAppearanceTitle;

  /// No description provided for @discoveryAppearanceDescription.
  ///
  /// In en, this message translates to:
  /// **'Customize the interface and discover Premium features'**
  String get discoveryAppearanceDescription;

  /// No description provided for @discoveryAppearanceThemesTitle.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get discoveryAppearanceThemesTitle;

  /// No description provided for @discoveryAppearanceThemesMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose from 4 themes: Light, Dark, AMOLED Black, or Dark Gray. Adaptive mode automatically adjusts according to ambient light.'**
  String get discoveryAppearanceThemesMessage;

  /// No description provided for @discoveryAppearancePalettesTitle.
  ///
  /// In en, this message translates to:
  /// **'Color palettes'**
  String get discoveryAppearancePalettesTitle;

  /// No description provided for @discoveryAppearancePalettesMessage.
  ///
  /// In en, this message translates to:
  /// **'Customize the interface with 5 different color palettes (Premium feature).'**
  String get discoveryAppearancePalettesMessage;

  /// No description provided for @discoveryAppearanceFontsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom fonts'**
  String get discoveryAppearanceFontsTitle;

  /// No description provided for @discoveryAppearanceFontsMessage.
  ///
  /// In en, this message translates to:
  /// **'Change the app\'s font from 4 available choices (Premium feature).'**
  String get discoveryAppearanceFontsMessage;

  /// No description provided for @discoveryAppearancePremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'PassKeyra Premium'**
  String get discoveryAppearancePremiumTitle;

  /// No description provided for @discoveryAppearancePremiumMessage.
  ///
  /// In en, this message translates to:
  /// **'Unlock all features: palettes, fonts, real-time sync, advanced security analysis, and more!'**
  String get discoveryAppearancePremiumMessage;

  /// No description provided for @discoveryPremiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium Features'**
  String get discoveryPremiumTitle;

  /// No description provided for @discoveryPremiumDescription.
  ///
  /// In en, this message translates to:
  /// **'Discover all exclusive Premium features'**
  String get discoveryPremiumDescription;

  /// No description provided for @discoveryPremiumIntroMessage.
  ///
  /// In en, this message translates to:
  /// **'Discover all exclusive features of PassKeyra Premium.'**
  String get discoveryPremiumIntroMessage;

  /// No description provided for @discoveryPremiumPalettesTitle.
  ///
  /// In en, this message translates to:
  /// **'Palettes & Fonts'**
  String get discoveryPremiumPalettesTitle;

  /// No description provided for @discoveryPremiumPalettesMessage.
  ///
  /// In en, this message translates to:
  /// **'Customize the appearance with exclusive Premium color palettes and fonts.'**
  String get discoveryPremiumPalettesMessage;

  /// No description provided for @discoveryPremiumSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security analysis'**
  String get discoveryPremiumSecurityTitle;

  /// No description provided for @discoveryPremiumSecurityMessage.
  ///
  /// In en, this message translates to:
  /// **'Security analysis checks the strength of your passwords and detects issues (weak, reused, or compromised passwords).'**
  String get discoveryPremiumSecurityMessage;

  /// No description provided for @discoveryPremiumCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'You now know all the Premium features of PassKeyra!'**
  String get discoveryPremiumCompleteMessage;

  /// No description provided for @onboardingStepSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort & filter'**
  String get onboardingStepSortTitle;

  /// No description provided for @onboardingStepSortBody.
  ///
  /// In en, this message translates to:
  /// **'Sort entries by name or date using this button. Quickly reorder your list to find what you need.'**
  String get onboardingStepSortBody;

  /// No description provided for @onboardingStepCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Category filters'**
  String get onboardingStepCategoriesTitle;

  /// No description provided for @onboardingStepCategoriesBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a category chip to filter your entries. Scroll horizontally to see all available categories.'**
  String get onboardingStepCategoriesBody;

  /// No description provided for @onboardingSettingsSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security settings'**
  String get onboardingSettingsSecurityTitle;

  /// No description provided for @onboardingSettingsSecurityBody.
  ///
  /// In en, this message translates to:
  /// **'This section lets you configure auto-lock, biometric authentication, and all security options for your vault.'**
  String get onboardingSettingsSecurityBody;

  /// No description provided for @onboardingSettingsBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Sync'**
  String get onboardingSettingsBackupTitle;

  /// No description provided for @onboardingSettingsBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Manage your local and cloud backups, and configure sync between your devices.'**
  String get onboardingSettingsBackupBody;

  /// No description provided for @onboardingSettingsAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get onboardingSettingsAppearanceTitle;

  /// No description provided for @onboardingSettingsAppearanceBody.
  ///
  /// In en, this message translates to:
  /// **'Customize the language, theme and categories of your app.'**
  String get onboardingSettingsAppearanceBody;

  /// No description provided for @onboardingBackupLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Local backup'**
  String get onboardingBackupLocalTitle;

  /// No description provided for @onboardingBackupLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Export your vault to this device or restore it from an existing backup.'**
  String get onboardingBackupLocalBody;

  /// No description provided for @onboardingBackupCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup'**
  String get onboardingBackupCloudTitle;

  /// No description provided for @onboardingBackupCloudBody.
  ///
  /// In en, this message translates to:
  /// **'Save your vault to the cloud to access it across all your devices.'**
  String get onboardingBackupCloudBody;

  /// No description provided for @onboardingChangeMasterPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Master password'**
  String get onboardingChangeMasterPasswordTitle;

  /// No description provided for @onboardingChangeMasterPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Your master password is the only key to your vault. You can change it here at any time.'**
  String get onboardingChangeMasterPasswordMessage;

  /// No description provided for @onboardingAutoCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto close'**
  String get onboardingAutoCloseTitle;

  /// No description provided for @onboardingAutoCloseMessage.
  ///
  /// In en, this message translates to:
  /// **'The app can close itself automatically after a period of inactivity for added protection.'**
  String get onboardingAutoCloseMessage;

  /// No description provided for @onboardingLoginAttemptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Login attempts'**
  String get onboardingLoginAttemptsTitle;

  /// No description provided for @onboardingLoginAttemptsMessage.
  ///
  /// In en, this message translates to:
  /// **'Limit the number of failed attempts before the vault is temporarily locked.'**
  String get onboardingLoginAttemptsMessage;

  /// No description provided for @premiumTutorialIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to PassKeyra Premium!'**
  String get premiumTutorialIntroTitle;

  /// No description provided for @premiumTutorialIntroMessage.
  ///
  /// In en, this message translates to:
  /// **'Let\'s explore your new features.'**
  String get premiumTutorialIntroMessage;

  /// No description provided for @premiumTutorialNoAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Ads'**
  String get premiumTutorialNoAdsTitle;

  /// No description provided for @premiumTutorialNoAdsMessage.
  ///
  /// In en, this message translates to:
  /// **'As a Premium user, enjoy the app without any advertisements or interruptions.'**
  String get premiumTutorialNoAdsMessage;

  /// No description provided for @premiumTutorialCloudSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get premiumTutorialCloudSyncTitle;

  /// No description provided for @premiumTutorialCloudSyncMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable sync to keep your vault up to date across all your connected devices. Requires a Google account connected to PassKeyra.'**
  String get premiumTutorialCloudSyncMessage;

  /// No description provided for @premiumTutorialBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup List'**
  String get premiumTutorialBackupTitle;

  /// No description provided for @premiumTutorialBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Your backups appear here. Each new backup replaces the previous one - your vault is always protected.'**
  String get premiumTutorialBackupMessage;

  /// No description provided for @premiumTutorialAutoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic Backup'**
  String get premiumTutorialAutoBackupTitle;

  /// No description provided for @premiumTutorialAutoBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable automatic backup so your vault is saved to the cloud every time you make a change.'**
  String get premiumTutorialAutoBackupMessage;

  /// No description provided for @premiumTutorialManualBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual Backup'**
  String get premiumTutorialManualBackupTitle;

  /// No description provided for @premiumTutorialManualBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap this button to immediately save your vault to the cloud.'**
  String get premiumTutorialManualBackupMessage;

  /// No description provided for @premiumTutorialProviderNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Your current provider'**
  String get premiumTutorialProviderNameTitle;

  /// No description provided for @premiumTutorialProviderNameMessage.
  ///
  /// In en, this message translates to:
  /// **'The name shown here indicates your cloud backup provider. You can change it at any time using the icon at the top right.'**
  String get premiumTutorialProviderNameMessage;

  /// No description provided for @premiumTutorialChangeProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Provider'**
  String get premiumTutorialChangeProviderTitle;

  /// No description provided for @premiumTutorialChangeProviderMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the cloud icon at the top right to switch your cloud storage provider at any time.'**
  String get premiumTutorialChangeProviderMessage;

  /// No description provided for @premiumTutorialIconsTitle.
  ///
  /// In en, this message translates to:
  /// **'Icons & Multiple Passwords'**
  String get premiumTutorialIconsTitle;

  /// No description provided for @premiumTutorialIconsMessage.
  ///
  /// In en, this message translates to:
  /// **'Customize each entry with an emoji and add multiple passwords per entry from the edit page.'**
  String get premiumTutorialIconsMessage;

  /// No description provided for @premiumTutorialSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security & Appearance'**
  String get premiumTutorialSecurityTitle;

  /// No description provided for @premiumTutorialSecurityMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your security score in Settings › Security. Customize fonts and palettes from Settings › Appearance.'**
  String get premiumTutorialSecurityMessage;

  /// No description provided for @premiumTutorialSecurityReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Analysis Unlocked!'**
  String get premiumTutorialSecurityReportTitle;

  /// No description provided for @premiumTutorialSecurityReportMessage.
  ///
  /// In en, this message translates to:
  /// **'Here is your security report. Check your overall score and recommendations to strengthen your passwords. Accessible anytime from Settings › Security.'**
  String get premiumTutorialSecurityReportMessage;

  /// No description provided for @premiumTutorialCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve discovered all your Premium features. Enjoy PassKeyra to the fullest!'**
  String get premiumTutorialCompleteMessage;

  /// No description provided for @premiumLocalAutoBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic local backup'**
  String get premiumLocalAutoBackupTitle;

  /// No description provided for @premiumLocalAutoBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatic encrypted backup on your device each time your vault is modified'**
  String get premiumLocalAutoBackupDescription;

  /// No description provided for @premiumTutorialLocalBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic local backup'**
  String get premiumTutorialLocalBackupTitle;

  /// No description provided for @premiumTutorialLocalBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable this option to automatically back up your vault on your device each time it is modified, independently of cloud backup.'**
  String get premiumTutorialLocalBackupMessage;

  /// No description provided for @cloudSyncRequiresGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sync requires a Google account connected to PassKeyra.'**
  String get cloudSyncRequiresGoogle;

  /// No description provided for @premiumTutorialEmojiTitle.
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get premiumTutorialEmojiTitle;

  /// No description provided for @premiumTutorialEmojiMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap here to add an emoji to this entry. Each entry can have its own icon.'**
  String get premiumTutorialEmojiMessage;

  /// No description provided for @premiumTutorialMultiPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple Passwords'**
  String get premiumTutorialMultiPasswordTitle;

  /// No description provided for @premiumTutorialMultiPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Add multiple passwords to one entry, perfect when you use different credentials for the same service.'**
  String get premiumTutorialMultiPasswordMessage;

  /// No description provided for @firstEntryTutorialNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Entry Name'**
  String get firstEntryTutorialNameTitle;

  /// No description provided for @firstEntryTutorialNameMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a recognizable name to identify this account easily.'**
  String get firstEntryTutorialNameMessage;

  /// No description provided for @firstEntryTutorialCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get firstEntryTutorialCategoryTitle;

  /// No description provided for @firstEntryTutorialCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Assign a category to this entry to find your accounts more quickly.'**
  String get firstEntryTutorialCategoryMessage;

  /// No description provided for @firstEntryTutorialUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get firstEntryTutorialUsernameTitle;

  /// No description provided for @firstEntryTutorialUsernameMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your username or email address for this account.'**
  String get firstEntryTutorialUsernameMessage;

  /// No description provided for @firstEntryTutorialPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get firstEntryTutorialPasswordTitle;

  /// No description provided for @firstEntryTutorialPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your password, or open the generator to create a secure one.'**
  String get firstEntryTutorialPasswordMessage;

  /// No description provided for @firstEntryTutorialOpenGenerator.
  ///
  /// In en, this message translates to:
  /// **'Open Generator'**
  String get firstEntryTutorialOpenGenerator;

  /// No description provided for @firstEntryTutorialGeneratorLengthTitle.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get firstEntryTutorialGeneratorLengthTitle;

  /// No description provided for @firstEntryTutorialGeneratorLengthMessage.
  ///
  /// In en, this message translates to:
  /// **'Slide to choose the length (16 characters or more recommended).'**
  String get firstEntryTutorialGeneratorLengthMessage;

  /// No description provided for @firstEntryTutorialGeneratorLowerTitle.
  ///
  /// In en, this message translates to:
  /// **'Lowercase'**
  String get firstEntryTutorialGeneratorLowerTitle;

  /// No description provided for @firstEntryTutorialGeneratorLowerMessage.
  ///
  /// In en, this message translates to:
  /// **'Include lowercase letters (a-z) to strengthen your password.'**
  String get firstEntryTutorialGeneratorLowerMessage;

  /// No description provided for @firstEntryTutorialGeneratorUpperTitle.
  ///
  /// In en, this message translates to:
  /// **'Uppercase'**
  String get firstEntryTutorialGeneratorUpperTitle;

  /// No description provided for @firstEntryTutorialGeneratorUpperMessage.
  ///
  /// In en, this message translates to:
  /// **'Add uppercase letters (A-Z) to make the password more complex.'**
  String get firstEntryTutorialGeneratorUpperMessage;

  /// No description provided for @firstEntryTutorialGeneratorDigitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Digits'**
  String get firstEntryTutorialGeneratorDigitsTitle;

  /// No description provided for @firstEntryTutorialGeneratorDigitsMessage.
  ///
  /// In en, this message translates to:
  /// **'Include digits (0-9) to increase security.'**
  String get firstEntryTutorialGeneratorDigitsMessage;

  /// No description provided for @firstEntryTutorialGeneratorSymbolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get firstEntryTutorialGeneratorSymbolsTitle;

  /// No description provided for @firstEntryTutorialGeneratorSymbolsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add symbols (!@#\$…) to maximize resistance to attacks.'**
  String get firstEntryTutorialGeneratorSymbolsMessage;

  /// No description provided for @firstEntryTutorialUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get firstEntryTutorialUrlTitle;

  /// No description provided for @firstEntryTutorialUrlMessage.
  ///
  /// In en, this message translates to:
  /// **'Add the website URL associated with this account (optional).'**
  String get firstEntryTutorialUrlMessage;

  /// No description provided for @firstEntryTutorialNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get firstEntryTutorialNotesTitle;

  /// No description provided for @firstEntryTutorialNotesMessage.
  ///
  /// In en, this message translates to:
  /// **'Add extra information: security questions, codes, etc.'**
  String get firstEntryTutorialNotesMessage;

  /// No description provided for @firstEntryTutorialTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get firstEntryTutorialTagsTitle;

  /// No description provided for @firstEntryTutorialTagsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add comma-separated tags to make this entry easier to find.'**
  String get firstEntryTutorialTagsMessage;

  /// No description provided for @firstEntryTutorialEmojiTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Icon'**
  String get firstEntryTutorialEmojiTitle;

  /// No description provided for @firstEntryTutorialEmojiMessage.
  ///
  /// In en, this message translates to:
  /// **'Associate an emoji with this entry to recognize it at a glance.'**
  String get firstEntryTutorialEmojiMessage;

  /// No description provided for @firstEntryTutorialAdditionalPasswordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional Passwords'**
  String get firstEntryTutorialAdditionalPasswordsTitle;

  /// No description provided for @firstEntryTutorialAdditionalPasswordsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add multiple passwords to one entry (PIN, multiple profiles…).'**
  String get firstEntryTutorialAdditionalPasswordsMessage;

  /// No description provided for @firstEntryTutorialSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get firstEntryTutorialSaveTitle;

  /// No description provided for @firstEntryTutorialSaveMessage.
  ///
  /// In en, this message translates to:
  /// **'All set! Tap the ✓ button to save this entry to your vault.'**
  String get firstEntryTutorialSaveMessage;

  /// No description provided for @firstEntryTutorialSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get firstEntryTutorialSaveAction;

  /// No description provided for @firstEntryTutorialCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first entry!'**
  String get firstEntryTutorialCardTitle;

  /// No description provided for @firstEntryTutorialCardMessage.
  ///
  /// In en, this message translates to:
  /// **'Your entry is saved. Let\'s explore the available actions on each card.'**
  String get firstEntryTutorialCardMessage;

  /// No description provided for @firstEntryTutorialCopyPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy Password'**
  String get firstEntryTutorialCopyPasswordTitle;

  /// No description provided for @firstEntryTutorialCopyPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'This button copies only the password (automatically cleared after 30 s).'**
  String get firstEntryTutorialCopyPasswordMessage;

  /// No description provided for @firstEntryTutorialCopyAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy All Info'**
  String get firstEntryTutorialCopyAllTitle;

  /// No description provided for @firstEntryTutorialCopyAllMessage.
  ///
  /// In en, this message translates to:
  /// **'This button copies the name, username, password, URL and notes all at once.'**
  String get firstEntryTutorialCopyAllMessage;

  /// No description provided for @firstEntryTutorialTapCardTitle.
  ///
  /// In en, this message translates to:
  /// **'View Entry'**
  String get firstEntryTutorialTapCardTitle;

  /// No description provided for @firstEntryTutorialTapCardMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the card to view full details and edit the entry.'**
  String get firstEntryTutorialTapCardMessage;

  /// No description provided for @discoveryFirstEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an Entry'**
  String get discoveryFirstEntryTitle;

  /// No description provided for @discoveryFirstEntryDescription.
  ///
  /// In en, this message translates to:
  /// **'Learn to create, fill in and manage your first entry from start to finish.'**
  String get discoveryFirstEntryDescription;

  /// No description provided for @discoveryFirstEntrySteps.
  ///
  /// In en, this message translates to:
  /// **'14 steps'**
  String get discoveryFirstEntrySteps;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
