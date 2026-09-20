import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Keeply'**
  String get appName;

  /// No description provided for @secureAccess.
  ///
  /// In en, this message translates to:
  /// **'Secure access'**
  String get secureAccess;

  /// No description provided for @localEncryption.
  ///
  /// In en, this message translates to:
  /// **'Local encryption'**
  String get localEncryption;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @keeplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Keeply'**
  String get keeplyTitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @createPin.
  ///
  /// In en, this message translates to:
  /// **'Create PIN'**
  String get createPin;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPin;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN.'**
  String get incorrectPin;

  /// No description provided for @pinTooWeak.
  ///
  /// In en, this message translates to:
  /// **'PIN is too weak.'**
  String get pinTooWeak;

  /// No description provided for @unlockVault.
  ///
  /// In en, this message translates to:
  /// **'Unlock Vault'**
  String get unlockVault;

  /// No description provided for @vaultLocked.
  ///
  /// In en, this message translates to:
  /// **'Vault Locked'**
  String get vaultLocked;

  /// No description provided for @vaultUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Vault Unlocked'**
  String get vaultUnlocked;

  /// No description provided for @pinTooLong.
  ///
  /// In en, this message translates to:
  /// **'PIN is too long.'**
  String get pinTooLong;

  /// No description provided for @invalidPin.
  ///
  /// In en, this message translates to:
  /// **'Invalid PIN.'**
  String get invalidPin;

  /// No description provided for @createPinStep.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2'**
  String get createPinStep;

  /// No description provided for @confirmPinStep.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2'**
  String get confirmPinStep;

  /// No description provided for @confirmPinButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirmPinButton;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @vault.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get vault;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @keeply.
  ///
  /// In en, this message translates to:
  /// **'Keeply'**
  String get keeply;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @recentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get recentlyAdded;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @noItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get noItemsYet;

  /// No description provided for @passwords.
  ///
  /// In en, this message translates to:
  /// **'Passwords'**
  String get passwords;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @addPassword.
  ///
  /// In en, this message translates to:
  /// **'Add Password'**
  String get addPassword;

  /// No description provided for @editPassword.
  ///
  /// In en, this message translates to:
  /// **'Edit Password'**
  String get editPassword;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

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

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add Bookmark'**
  String get addBookmark;

  /// No description provided for @editBookmark.
  ///
  /// In en, this message translates to:
  /// **'Edit Bookmark'**
  String get editBookmark;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @launch.
  ///
  /// In en, this message translates to:
  /// **'Launch'**
  String get launch;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get openLink;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL.'**
  String get invalidUrl;

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @mediaVault.
  ///
  /// In en, this message translates to:
  /// **'Media Vault'**
  String get mediaVault;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// No description provided for @importPhoto.
  ///
  /// In en, this message translates to:
  /// **'Import Photo'**
  String get importPhoto;

  /// No description provided for @importPhotos.
  ///
  /// In en, this message translates to:
  /// **'Import Photos'**
  String get importPhotos;

  /// No description provided for @deletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get deletePhoto;

  /// No description provided for @noPhotosYet.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get noPhotosYet;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocument;

  /// No description provided for @addFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get addFolder;

  /// No description provided for @importDocument.
  ///
  /// In en, this message translates to:
  /// **'Import Document'**
  String get importDocument;

  /// No description provided for @importFolder.
  ///
  /// In en, this message translates to:
  /// **'Import Folder'**
  String get importFolder;

  /// No description provided for @noFoldersYet.
  ///
  /// In en, this message translates to:
  /// **'No folders yet'**
  String get noFoldersYet;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @folder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folder;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @selectFile.
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get selectFile;

  /// No description provided for @selectFolder.
  ///
  /// In en, this message translates to:
  /// **'Select Folder'**
  String get selectFolder;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @backups.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get backups;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// No description provided for @backupFile.
  ///
  /// In en, this message translates to:
  /// **'Backup File'**
  String get backupFile;

  /// No description provided for @googleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get googleDrive;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @synchronize.
  ///
  /// In en, this message translates to:
  /// **'Synchronize'**
  String get synchronize;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @signedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get signedOut;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @autoLock.
  ///
  /// In en, this message translates to:
  /// **'Auto Lock'**
  String get autoLock;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteItem;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found.'**
  String get fileNotFound;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @encryptedData.
  ///
  /// In en, this message translates to:
  /// **'Encrypted data'**
  String get encryptedData;

  /// No description provided for @mediaLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load media.'**
  String get mediaLoadError;

  /// No description provided for @mediaEmpty.
  ///
  /// In en, this message translates to:
  /// **'No media has been added.'**
  String get mediaEmpty;

  /// No description provided for @mediaAdded.
  ///
  /// In en, this message translates to:
  /// **'Media added successfully.'**
  String get mediaAdded;

  /// No description provided for @mediaAddedCount.
  ///
  /// In en, this message translates to:
  /// **'{savedCount} media items added successfully.'**
  String mediaAddedCount({required int savedCount});

  /// No description provided for @mediaAddError.
  ///
  /// In en, this message translates to:
  /// **'Unable to add media.'**
  String get mediaAddError;

  /// No description provided for @mediaNotFound.
  ///
  /// In en, this message translates to:
  /// **'Media file not found.'**
  String get mediaNotFound;

  /// No description provided for @mediaOpenError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open media.'**
  String get mediaOpenError;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to gallery'**
  String get saveToGallery;

  /// No description provided for @mediaFileMissing.
  ///
  /// In en, this message translates to:
  /// **'Media file does not exist.'**
  String get mediaFileMissing;

  /// No description provided for @galleryPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Gallery access permission was denied.'**
  String get galleryPermissionDenied;

  /// No description provided for @imageSavedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Image saved to gallery.'**
  String get imageSavedToGallery;

  /// No description provided for @videoSavedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Video saved to gallery.'**
  String get videoSavedToGallery;

  /// No description provided for @galleryUnsupportedType.
  ///
  /// In en, this message translates to:
  /// **'This file type cannot be saved to the gallery.'**
  String get galleryUnsupportedType;

  /// No description provided for @mediaSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save media to the gallery.'**
  String get mediaSaveError;

  /// No description provided for @mediaShareError.
  ///
  /// In en, this message translates to:
  /// **'Unable to share media.'**
  String get mediaShareError;

  /// No description provided for @deleteMediaConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete media?'**
  String get deleteMediaConfirm;

  /// No description provided for @deleteMediaMessage.
  ///
  /// In en, this message translates to:
  /// **'“{fileName}” will be permanently deleted from your vault.'**
  String deleteMediaMessage({required String fileName});

  /// No description provided for @mediaDeleted.
  ///
  /// In en, this message translates to:
  /// **'Media deleted.'**
  String get mediaDeleted;

  /// No description provided for @mediaDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete media.'**
  String get mediaDeleteError;

  /// No description provided for @addMedia.
  ///
  /// In en, this message translates to:
  /// **'Add media'**
  String get addMedia;

  /// No description provided for @noMediaYet.
  ///
  /// In en, this message translates to:
  /// **'No media yet'**
  String get noMediaYet;

  /// No description provided for @mediaEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Add photos and videos to keep them securely in your vault.'**
  String get mediaEmptyDescription;

  /// No description provided for @bookmarksLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load bookmarks.'**
  String get bookmarksLoadError;

  /// No description provided for @bookmarkValidationBeforeSave.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one field before saving.'**
  String get bookmarkValidationBeforeSave;

  /// No description provided for @invalidWebsiteUrlInput.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid website URL.'**
  String get invalidWebsiteUrlInput;

  /// No description provided for @bookmarkSaved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark saved.'**
  String get bookmarkSaved;

  /// No description provided for @bookmarkSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save bookmark.'**
  String get bookmarkSaveError;

  /// No description provided for @deleteBookmarkConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete bookmark?'**
  String get deleteBookmarkConfirm;

  /// No description provided for @deleteBookmarkMessage.
  ///
  /// In en, this message translates to:
  /// **'This bookmark will be permanently deleted.'**
  String get deleteBookmarkMessage;

  /// No description provided for @bookmarkDeleted.
  ///
  /// In en, this message translates to:
  /// **'Bookmark deleted.'**
  String get bookmarkDeleted;

  /// No description provided for @bookmarkDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete bookmark.'**
  String get bookmarkDeleteError;

  /// No description provided for @invalidWebsiteUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid website URL.'**
  String get invalidWebsiteUrl;

  /// No description provided for @websiteOpenError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open website.'**
  String get websiteOpenError;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied.'**
  String get linkCopied;

  /// No description provided for @bookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarksTitle;

  /// No description provided for @openWebsite.
  ///
  /// In en, this message translates to:
  /// **'Open website'**
  String get openWebsite;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLink;

  /// No description provided for @bookmarkValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one field.'**
  String get bookmarkValidation;

  /// No description provided for @websiteUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the website URL.'**
  String get websiteUrlRequired;

  /// No description provided for @bookmarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Save a website URL with an optional description.'**
  String get bookmarkDescription;

  /// No description provided for @websiteUrl.
  ///
  /// In en, this message translates to:
  /// **'Website URL'**
  String get websiteUrl;

  /// No description provided for @noBookmarksYet.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarksYet;

  /// No description provided for @bookmarksEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Save your important websites and links here.'**
  String get bookmarksEmptyDescription;

  /// No description provided for @googleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get googleSignInCancelled;

  /// No description provided for @googleDriveConnectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Connected to Google Drive successfully.\n'**
  String get googleDriveConnectedMessage;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed.\n{error}'**
  String googleSignInFailed({required String error});

  /// No description provided for @googleDriveDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Google Drive disconnected'**
  String get googleDriveDisconnected;

  /// No description provided for @googleSignOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-out failed.\n{error}'**
  String googleSignOutFailed({required String error});

  /// No description provided for @googleDriveBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Google Drive backup failed.\n{error}'**
  String googleDriveBackupFailed({required String error});

  /// No description provided for @googleDriveRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Keeply data restored from Google Drive successfully.'**
  String get googleDriveRestoreSuccess;

  /// No description provided for @googleDriveRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore from Google Drive failed.\n{error}'**
  String googleDriveRestoreFailed({required String error});

  /// No description provided for @googleDriveSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Google Drive synced successfully.'**
  String get googleDriveSyncSuccess;

  /// No description provided for @createdCount.
  ///
  /// In en, this message translates to:
  /// **'Created: {created}'**
  String createdCount({required int created});

  /// No description provided for @updatedCount.
  ///
  /// In en, this message translates to:
  /// **'Updated: {updated}'**
  String updatedCount({required int updated});

  /// No description provided for @skippedCount.
  ///
  /// In en, this message translates to:
  /// **'Skipped: {skipped}'**
  String skippedCount({required int skipped});

  /// No description provided for @deletedCount.
  ///
  /// In en, this message translates to:
  /// **'Deleted: {deleted}'**
  String deletedCount({required int deleted});

  /// No description provided for @examinedCount.
  ///
  /// In en, this message translates to:
  /// **'Examined: {examined}'**
  String examinedCount({required int examined});

  /// No description provided for @uploadedDataLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploaded data: '**
  String get uploadedDataLabel;

  /// No description provided for @connectGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Connect to Google Drive'**
  String get connectGoogleDrive;

  /// No description provided for @googleDriveBackupRequirement.
  ///
  /// In en, this message translates to:
  /// **'To use Google Drive backup and restore, '**
  String get googleDriveBackupRequirement;

  /// No description provided for @googleAccountRequirement.
  ///
  /// In en, this message translates to:
  /// **'you must connect your Google account.'**
  String get googleAccountRequirement;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @restoreBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore backup?'**
  String get restoreBackupConfirm;

  /// No description provided for @restoreOnlyMissingPart1.
  ///
  /// In en, this message translates to:
  /// **'Restore will only add data from the backup '**
  String get restoreOnlyMissingPart1;

  /// No description provided for @restoreOnlyMissingPart2.
  ///
  /// In en, this message translates to:
  /// **'that does not currently exist in Keeply.\n\n'**
  String get restoreOnlyMissingPart2;

  /// No description provided for @restoreNoDeletePart1.
  ///
  /// In en, this message translates to:
  /// **'No existing data on your device will be deleted or replaced, '**
  String get restoreNoDeletePart1;

  /// No description provided for @restoreNoDeletePart2.
  ///
  /// In en, this message translates to:
  /// **'Existing items will be skipped automatically.\n\n'**
  String get restoreNoDeletePart2;

  /// No description provided for @restoreMissingDataSafe.
  ///
  /// In en, this message translates to:
  /// **'You can safely continue to add missing data from the backup.'**
  String get restoreMissingDataSafe;

  /// No description provided for @backupReadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to read backup data from Google Drive.\n{error}'**
  String backupReadError({required String error});

  /// No description provided for @keeplyCloudData.
  ///
  /// In en, this message translates to:
  /// **'Keeply data on Google Drive'**
  String get keeplyCloudData;

  /// No description provided for @noBackupData.
  ///
  /// In en, this message translates to:
  /// **'No backup data.'**
  String get noBackupData;

  /// No description provided for @unnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get unnamed;

  /// No description provided for @unknownSize.
  ///
  /// In en, this message translates to:
  /// **'Unknown size'**
  String get unknownSize;

  /// No description provided for @cloudItemsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {deleted} item(s) from Google Drive.'**
  String cloudItemsDeleted({required int deleted});

  /// No description provided for @cloudDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete backup data.\n{error}'**
  String cloudDeleteError({required String error});

  /// No description provided for @deleteCloudBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete cloud backup?'**
  String get deleteCloudBackupConfirm;

  /// No description provided for @deleteIncrementalObjectsPart1.
  ///
  /// In en, this message translates to:
  /// **'All Keeply Incremental objects will be deleted '**
  String get deleteIncrementalObjectsPart1;

  /// No description provided for @deleteIncrementalObjectsPart2.
  ///
  /// In en, this message translates to:
  /// **'from Google Drive.\n\n'**
  String get deleteIncrementalObjectsPart2;

  /// No description provided for @irreversibleAction.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.\n\n'**
  String get irreversibleAction;

  /// No description provided for @localDataUnaffected.
  ///
  /// In en, this message translates to:
  /// **'Your local data will not be affected.'**
  String get localDataUnaffected;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @bytesLabel.
  ///
  /// In en, this message translates to:
  /// **'{bytes} bytes'**
  String bytesLabel({required int bytes});

  /// No description provided for @kilobytesLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} KB'**
  String kilobytesLabel({required String value});

  /// No description provided for @megabytesLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String megabytesLabel({required String value});

  /// No description provided for @gigabytesLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} GB'**
  String gigabytesLabel({required String value});

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @keeplyBackup.
  ///
  /// In en, this message translates to:
  /// **'Keeply Backup'**
  String get keeplyBackup;

  /// No description provided for @googleDriveConnected.
  ///
  /// In en, this message translates to:
  /// **'Google Drive connected'**
  String get googleDriveConnected;

  /// No description provided for @googleAccount.
  ///
  /// In en, this message translates to:
  /// **'Google Account'**
  String get googleAccount;

  /// No description provided for @connectGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Connect your Google account'**
  String get connectGoogleAccount;

  /// No description provided for @disconnectAccount.
  ///
  /// In en, this message translates to:
  /// **'Disconnect account'**
  String get disconnectAccount;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @incrementalSyncDescription1.
  ///
  /// In en, this message translates to:
  /// **'Only new items are uploaded, changed items are updated, '**
  String get incrementalSyncDescription1;

  /// No description provided for @incrementalSyncDescription2.
  ///
  /// In en, this message translates to:
  /// **'and unchanged items are skipped, '**
  String get incrementalSyncDescription2;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncBackup.
  ///
  /// In en, this message translates to:
  /// **'Sync backup'**
  String get syncBackup;

  /// No description provided for @readingData.
  ///
  /// In en, this message translates to:
  /// **'Reading data...'**
  String get readingData;

  /// No description provided for @viewCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'View cloud backup data'**
  String get viewCloudBackup;

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
  String get restoring;

  /// No description provided for @restoreFromGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Restore from Google Drive'**
  String get restoreFromGoogleDrive;

  /// No description provided for @lastSyncResult.
  ///
  /// In en, this message translates to:
  /// **'Last sync result'**
  String get lastSyncResult;

  /// No description provided for @manageCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Manage cloud backup'**
  String get manageCloudBackup;

  /// No description provided for @manageCloudBackupDescription.
  ///
  /// In en, this message translates to:
  /// **'You can delete all Keeply objects from '**
  String get manageCloudBackupDescription;

  /// No description provided for @deleteCloudBackupProgress.
  ///
  /// In en, this message translates to:
  /// **'Google Drive. This does not delete your local data.'**
  String get deleteCloudBackupProgress;

  /// No description provided for @deleteCloudBackupCompletely.
  ///
  /// In en, this message translates to:
  /// **'Deleting cloud backup...'**
  String get deleteCloudBackupCompletely;

  /// No description provided for @deleteCloudBackupAll.
  ///
  /// In en, this message translates to:
  /// **'Delete cloud backup completely'**
  String get deleteCloudBackupAll;

  /// No description provided for @backupSystem.
  ///
  /// In en, this message translates to:
  /// **'Backup system'**
  String get backupSystem;

  /// No description provided for @backupStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage: Google Drive appDataFolder'**
  String get backupStorage;

  /// No description provided for @backupSystemMode.
  ///
  /// In en, this message translates to:
  /// **'System: Incremental Sync'**
  String get backupSystemMode;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @examined.
  ///
  /// In en, this message translates to:
  /// **'Examined'**
  String get examined;

  /// No description provided for @uploadedData.
  ///
  /// In en, this message translates to:
  /// **'Uploaded data'**
  String get uploadedData;

  /// No description provided for @documentsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load documents.'**
  String get documentsLoadError;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @folderCreated.
  ///
  /// In en, this message translates to:
  /// **'Folder created.'**
  String get folderCreated;

  /// No description provided for @folderCreateError.
  ///
  /// In en, this message translates to:
  /// **'Unable to create folder.'**
  String get folderCreateError;

  /// No description provided for @noFilesAdded.
  ///
  /// In en, this message translates to:
  /// **'No files were added.'**
  String get noFilesAdded;

  /// No description provided for @documentAdded.
  ///
  /// In en, this message translates to:
  /// **'Document added successfully.'**
  String get documentAdded;

  /// No description provided for @documentsAddedCount.
  ///
  /// In en, this message translates to:
  /// **'{savedCount} documents added.'**
  String documentsAddedCount({required int savedCount});

  /// No description provided for @documentsAddError.
  ///
  /// In en, this message translates to:
  /// **'Unable to add documents.'**
  String get documentsAddError;

  /// No description provided for @documentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Document not found.'**
  String get documentNotFound;

  /// No description provided for @textFileReadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to read this text file.'**
  String get textFileReadError;

  /// No description provided for @noReadableText.
  ///
  /// In en, this message translates to:
  /// **'No readable text was found in this document.'**
  String get noReadableText;

  /// No description provided for @wordReadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to read this Word document.'**
  String get wordReadError;

  /// No description provided for @excelReadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to read this Excel document.'**
  String get excelReadError;

  /// No description provided for @emptySlide.
  ///
  /// In en, this message translates to:
  /// **'Empty slide'**
  String get emptySlide;

  /// No description provided for @powerpointReadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to read this PowerPoint document.'**
  String get powerpointReadError;

  /// No description provided for @documentOpenError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open this document.'**
  String get documentOpenError;

  /// No description provided for @noAppToOpenFile.
  ///
  /// In en, this message translates to:
  /// **'No app can open the file'**
  String get noAppToOpenFile;

  /// No description provided for @noAppForFile.
  ///
  /// In en, this message translates to:
  /// **'No installed app can open \"\$fileName\".'**
  String noAppForFile({required String fileName});

  /// No description provided for @documentMissing.
  ///
  /// In en, this message translates to:
  /// **'Document does not exist.'**
  String get documentMissing;

  /// No description provided for @documentShareError.
  ///
  /// In en, this message translates to:
  /// **'Unable to share document.'**
  String get documentShareError;

  /// No description provided for @deleteDocumentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete document?'**
  String get deleteDocumentConfirm;

  /// No description provided for @deleteDocumentMessage.
  ///
  /// In en, this message translates to:
  /// **'“{fileName}” will be permanently deleted from your vault.'**
  String deleteDocumentMessage({required String fileName});

  /// No description provided for @documentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted.'**
  String get documentDeleted;

  /// No description provided for @documentDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete document.'**
  String get documentDeleteError;

  /// No description provided for @folderNotEmpty.
  ///
  /// In en, this message translates to:
  /// **'This folder is not empty. Delete its contents first.'**
  String get folderNotEmpty;

  /// No description provided for @deleteFolderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete folder?'**
  String get deleteFolderConfirm;

  /// No description provided for @deleteFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'“{folderName}” will be deleted.'**
  String deleteFolderMessage({required String folderName});

  /// No description provided for @folderDeleted.
  ///
  /// In en, this message translates to:
  /// **'Folder deleted.'**
  String get folderDeleted;

  /// No description provided for @folderDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete folder.'**
  String get folderDeleteError;

  /// No description provided for @folderFileCount.
  ///
  /// In en, this message translates to:
  /// **'{folders} folders • {files} files'**
  String folderFileCount({required int folders, required int files});

  /// No description provided for @imageDisplayError.
  ///
  /// In en, this message translates to:
  /// **'Unable to display this image.'**
  String get imageDisplayError;

  /// No description provided for @readOnlyDocumentPreview.
  ///
  /// In en, this message translates to:
  /// **'Read-only document preview'**
  String get readOnlyDocumentPreview;

  /// No description provided for @noReadableWorksheets.
  ///
  /// In en, this message translates to:
  /// **'No readable worksheets were found.'**
  String get noReadableWorksheets;

  /// No description provided for @emptyWorksheet.
  ///
  /// In en, this message translates to:
  /// **'The worksheet is empty'**
  String get emptyWorksheet;

  /// No description provided for @noReadableSlides.
  ///
  /// In en, this message translates to:
  /// **'No readable slides were found.'**
  String get noReadableSlides;

  /// No description provided for @slideNumber.
  ///
  /// In en, this message translates to:
  /// **'Slide {index}'**
  String slideNumber({required int index});

  /// No description provided for @yourDocuments.
  ///
  /// In en, this message translates to:
  /// **'Your documents'**
  String get yourDocuments;

  /// No description provided for @documentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep your important documents organized\nand securely stored in your vault.'**
  String get documentsDescription;

  /// No description provided for @createFolder.
  ///
  /// In en, this message translates to:
  /// **'Create folder'**
  String get createFolder;

  /// No description provided for @secure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get secure;

  /// No description provided for @secureFile.
  ///
  /// In en, this message translates to:
  /// **'Secure file'**
  String get secureFile;

  /// No description provided for @shareDocument.
  ///
  /// In en, this message translates to:
  /// **'Share document'**
  String get shareDocument;

  /// No description provided for @deleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Delete document'**
  String get deleteDocument;

  /// No description provided for @linkOpenError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open link'**
  String get linkOpenError;

  /// No description provided for @backupSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage backups and restore your data easily'**
  String get backupSectionDescription;

  /// No description provided for @aboutSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Learn more about Keeply'**
  String get aboutSectionDescription;

  /// No description provided for @versionText.
  ///
  /// In en, this message translates to:
  /// **'Keeply • Version 1.0.0'**
  String get versionText;

  /// No description provided for @settingsManagement.
  ///
  /// In en, this message translates to:
  /// **'Manage Keeply'**
  String get settingsManagement;

  /// No description provided for @backupEntryDescription.
  ///
  /// In en, this message translates to:
  /// **'Create or restore a backup'**
  String get backupEntryDescription;

  /// No description provided for @aboutDescriptionPart1.
  ///
  /// In en, this message translates to:
  /// **'Keeply is a personal app that helps you organize and store passwords, '**
  String get aboutDescriptionPart1;

  /// No description provided for @aboutDescriptionPart2.
  ///
  /// In en, this message translates to:
  /// **'links, photos, and documents in one place, with the ability to create '**
  String get aboutDescriptionPart2;

  /// No description provided for @aboutDescriptionPart3.
  ///
  /// In en, this message translates to:
  /// **'backups and restore your data easily.'**
  String get aboutDescriptionPart3;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by'**
  String get developedBy;

  /// No description provided for @developerName.
  ///
  /// In en, this message translates to:
  /// **'Laith Taha'**
  String get developerName;

  /// No description provided for @passwordsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load passwords.'**
  String get passwordsLoadError;

  /// No description provided for @passwordValidationBeforeSave.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one value before saving.'**
  String get passwordValidationBeforeSave;

  /// No description provided for @passwordSaved.
  ///
  /// In en, this message translates to:
  /// **'Password saved.'**
  String get passwordSaved;

  /// No description provided for @passwordSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save password.'**
  String get passwordSaveError;

  /// No description provided for @deletePasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete password?'**
  String get deletePasswordConfirm;

  /// No description provided for @deletePasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'This item will be permanently deleted.'**
  String get deletePasswordMessage;

  /// No description provided for @passwordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Password deleted.'**
  String get passwordDeleted;

  /// No description provided for @passwordDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete password.'**
  String get passwordDeleteError;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get emailOrUsername;

  /// No description provided for @copiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Copied {label}'**
  String copiedLabel({required String label});

  /// No description provided for @passwordValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one value.'**
  String get passwordValidation;

  /// No description provided for @addKeeplyPassword.
  ///
  /// In en, this message translates to:
  /// **'Add keeply password'**
  String get addKeeplyPassword;

  /// No description provided for @passwordFormDescription.
  ///
  /// In en, this message translates to:
  /// **'All fields are optional. Enter at least one value.'**
  String get passwordFormDescription;

  /// No description provided for @noPasswordsYet.
  ///
  /// In en, this message translates to:
  /// **'No passwords yet'**
  String get noPasswordsYet;

  /// No description provided for @passwordsEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first email, password, or description.'**
  String get passwordsEmptyDescription;

  /// No description provided for @vaultUnlockError.
  ///
  /// In en, this message translates to:
  /// **'Unable to unlock the vault.'**
  String get vaultUnlockError;

  /// No description provided for @biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not enabled.'**
  String get biometricDisabled;

  /// No description provided for @biometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available.'**
  String get biometricUnavailable;

  /// No description provided for @biometricFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed.'**
  String get biometricFailed;

  /// No description provided for @keeplyOpenError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open Keeply.'**
  String get keeplyOpenError;

  /// No description provided for @pinAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to access Keeply.'**
  String get pinAccessDescription;

  /// No description provided for @pinMinimumDigits.
  ///
  /// In en, this message translates to:
  /// **'PIN must be at least 6 digits.'**
  String get pinMinimumDigits;

  /// No description provided for @pinMaximumDigits.
  ///
  /// In en, this message translates to:
  /// **'PIN cannot contain more than 12 digits.'**
  String get pinMaximumDigits;

  /// No description provided for @strongerPin.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger PIN.'**
  String get strongerPin;

  /// No description provided for @pinCreationErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Unable to create PIN. Please try again.'**
  String get pinCreationErrorRetry;

  /// No description provided for @pinMismatchRetry.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match. Please try again.'**
  String get pinMismatchRetry;

  /// No description provided for @pinRememberDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN again to make sure you remember it.'**
  String get pinRememberDescription;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get genericError;

  /// No description provided for @initializationError.
  ///
  /// In en, this message translates to:
  /// **'Unable to initialize Keeply.'**
  String get initializationError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the app language'**
  String get languageDescription;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'Keeply is a personal app that helps you organize and store passwords, links, photos, and documents in one place, with the ability to create backups and restore your data easily.'**
  String get aboutDescription;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your private vault, designed to protect your data.'**
  String get welcomeSubtitle;

  /// No description provided for @privateByDesign.
  ///
  /// In en, this message translates to:
  /// **'Private by design'**
  String get privateByDesign;

  /// No description provided for @privateByDesignDescription.
  ///
  /// In en, this message translates to:
  /// **'Your sensitive data stays encrypted on your device.'**
  String get privateByDesignDescription;

  /// No description provided for @secureAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Use your device authentication to access your vault.'**
  String get secureAccessDescription;

  /// No description provided for @offlineFirst.
  ///
  /// In en, this message translates to:
  /// **'Offline first'**
  String get offlineFirst;

  /// No description provided for @offlineFirstDescription.
  ///
  /// In en, this message translates to:
  /// **'Your vault is available locally without requiring internet.'**
  String get offlineFirstDescription;

  /// No description provided for @keeplySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your secure digital vault'**
  String get keeplySubtitle;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Secure your passwords, files, photos, and bookmarks in one place.'**
  String get welcomeDescription;

  /// No description provided for @yourDataYourControl.
  ///
  /// In en, this message translates to:
  /// **'Your data, your control'**
  String get yourDataYourControl;

  /// No description provided for @encryptedLocally.
  ///
  /// In en, this message translates to:
  /// **'Your local data is encrypted.'**
  String get encryptedLocally;

  /// No description provided for @createPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a PIN to protect your vault'**
  String get createPinTitle;

  /// No description provided for @createPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Use a 6-digit PIN that is easy for you to remember and hard for others to guess.'**
  String get createPinDescription;

  /// No description provided for @confirmPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your PIN'**
  String get confirmPinTitle;

  /// No description provided for @confirmPinDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN again to make sure it is correct.'**
  String get confirmPinDescription;

  /// No description provided for @pinDoesNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs do not match.'**
  String get pinDoesNotMatch;

  /// No description provided for @pinCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN created successfully.'**
  String get pinCreatedSuccessfully;

  /// No description provided for @pinCannotBeRepeated.
  ///
  /// In en, this message translates to:
  /// **'Do not use the same digit repeatedly.'**
  String get pinCannotBeRepeated;

  /// No description provided for @pinCannotBeSequential.
  ///
  /// In en, this message translates to:
  /// **'Do not use a simple sequence such as 123456.'**
  String get pinCannotBeSequential;

  /// No description provided for @useBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get useBiometrics;

  /// No description provided for @biometricAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication'**
  String get biometricAuthentication;

  /// No description provided for @fingerprintOrFace.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face recognition to unlock your vault.'**
  String get fingerprintOrFace;

  /// No description provided for @pinTooShort.
  ///
  /// In en, this message translates to:
  /// **'PIN is too short.'**
  String get pinTooShort;

  /// No description provided for @unlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unlock the vault.'**
  String get unlockFailed;

  /// No description provided for @createPinFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create PIN.'**
  String get createPinFailed;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs do not match.'**
  String get pinMismatch;

  /// No description provided for @createPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a 6-digit PIN to protect your vault.'**
  String get createPinSubtitle;

  /// No description provided for @confirmPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your PIN to make sure it is correct.'**
  String get confirmPinSubtitle;

  /// No description provided for @weakPinWarning.
  ///
  /// In en, this message translates to:
  /// **'This PIN is weak. Choose a stronger PIN.'**
  String get weakPinWarning;

  /// No description provided for @yourKeeply.
  ///
  /// In en, this message translates to:
  /// **'Your secure digital vault'**
  String get yourKeeply;

  /// No description provided for @addFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Add your first item to your vault.'**
  String get addFirstItem;

  /// No description provided for @passwordsAndEmails.
  ///
  /// In en, this message translates to:
  /// **'Passwords & Emails'**
  String get passwordsAndEmails;

  /// No description provided for @generatePassword.
  ///
  /// In en, this message translates to:
  /// **'Generate Strong Password'**
  String get generatePassword;

  /// No description provided for @passwordGenerated.
  ///
  /// In en, this message translates to:
  /// **'Strong password generated.'**
  String get passwordGenerated;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password strength'**
  String get passwordStrength;

  /// No description provided for @loginCredentials.
  ///
  /// In en, this message translates to:
  /// **'Login Credentials'**
  String get loginCredentials;

  /// No description provided for @docsAndFolders.
  ///
  /// In en, this message translates to:
  /// **'Docs & Folders'**
  String get docsAndFolders;

  /// No description provided for @noDocumentsYet.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get noDocumentsYet;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @backupCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully.'**
  String get backupCreatedSuccessfully;

  /// No description provided for @backupRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully.'**
  String get backupRestoredSuccessfully;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup creation failed.'**
  String get backupFailed;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup restoration failed.'**
  String get restoreFailed;

  /// No description provided for @selectBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Select Backup File'**
  String get selectBackupFile;

  /// No description provided for @invalidBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file.'**
  String get invalidBackupFile;

  /// No description provided for @backupFileExtension.
  ///
  /// In en, this message translates to:
  /// **'Keeply backup files must use the .svb extension.'**
  String get backupFileExtension;

  /// No description provided for @restoreWarning.
  ///
  /// In en, this message translates to:
  /// **'Restoring will replace the current data with the data contained in the backup.'**
  String get restoreWarning;

  /// No description provided for @confirmRestore.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore this backup?'**
  String get confirmRestore;

  /// No description provided for @backupToGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Backup to Google Drive'**
  String get backupToGoogleDrive;

  /// No description provided for @cloudActions.
  ///
  /// In en, this message translates to:
  /// **'Cloud actions'**
  String get cloudActions;

  /// No description provided for @uploadToCloud.
  ///
  /// In en, this message translates to:
  /// **'Upload to cloud'**
  String get uploadToCloud;

  /// No description provided for @downloadFromCloud.
  ///
  /// In en, this message translates to:
  /// **'Download from cloud'**
  String get downloadFromCloud;

  /// No description provided for @selectBackupSections.
  ///
  /// In en, this message translates to:
  /// **'Select sections'**
  String get selectBackupSections;

  /// No description provided for @selectRestoreSections.
  ///
  /// In en, this message translates to:
  /// **'Select sections to restore'**
  String get selectRestoreSections;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please connect to the internet and try again'**
  String get noInternetConnection;

  /// No description provided for @backupAllSections.
  ///
  /// In en, this message translates to:
  /// **'All sections'**
  String get backupAllSections;

  /// No description provided for @cloudActionConfirmRestore.
  ///
  /// In en, this message translates to:
  /// **'Download this section from Google Drive? Your existing local data will not be deleted or replaced.'**
  String get cloudActionConfirmRestore;

  /// No description provided for @sectionUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{section} uploaded successfully.'**
  String sectionUploadedSuccessfully({required String section});

  /// No description provided for @sectionDownloadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{section} downloaded successfully.'**
  String sectionDownloadedSuccessfully({required String section});

  /// No description provided for @noCloudSectionData.
  ///
  /// In en, this message translates to:
  /// **'No cloud data was found for {section}.'**
  String noCloudSectionData({required String section});

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @disconnectGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Google Drive'**
  String get disconnectGoogleDrive;

  /// No description provided for @syncSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Synchronization completed successfully.'**
  String get syncSuccessful;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Synchronization failed.'**
  String get syncFailed;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @deleteItemConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item? This action cannot be undone.'**
  String get deleteItemConfirmation;

  /// No description provided for @deletePasswordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this password?'**
  String get deletePasswordConfirmation;

  /// No description provided for @deleteBookmarkConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this bookmark?'**
  String get deleteBookmarkConfirmation;

  /// No description provided for @deletePhotoConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this photo?'**
  String get deletePhotoConfirmation;

  /// No description provided for @deleteDocumentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this document?'**
  String get deleteDocumentConfirmation;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get invalidEmail;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid password.'**
  String get invalidPassword;

  /// No description provided for @invalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input.'**
  String get invalidInput;

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFound;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @unableToSave.
  ///
  /// In en, this message translates to:
  /// **'Unable to save data.'**
  String get unableToSave;

  /// No description provided for @unableToDelete.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete data.'**
  String get unableToDelete;

  /// No description provided for @unableToOpen.
  ///
  /// In en, this message translates to:
  /// **'Unable to open item.'**
  String get unableToOpen;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied.'**
  String get permissionDenied;

  /// No description provided for @storageError.
  ///
  /// In en, this message translates to:
  /// **'Storage error.'**
  String get storageError;

  /// No description provided for @encryptionError.
  ///
  /// In en, this message translates to:
  /// **'Encryption error.'**
  String get encryptionError;

  /// No description provided for @decryptionError.
  ///
  /// In en, this message translates to:
  /// **'Decryption error.'**
  String get decryptionError;

  /// No description provided for @vaultDescription.
  ///
  /// In en, this message translates to:
  /// **'Store all your data in one place, from emails and passwords to files and photos.'**
  String get vaultDescription;

  /// No description provided for @googleDriveBackup.
  ///
  /// In en, this message translates to:
  /// **'Back up your data to Google Drive and restore it whenever you need.'**
  String get googleDriveBackup;

  /// No description provided for @privateVault.
  ///
  /// In en, this message translates to:
  /// **'Your private vault for securely storing your data, even without an internet connection.'**
  String get privateVault;

  /// No description provided for @secureOfflineStorage.
  ///
  /// In en, this message translates to:
  /// **'Secure offline storage'**
  String get secureOfflineStorage;

  /// No description provided for @protectedByEncryption.
  ///
  /// In en, this message translates to:
  /// **'Protected by encryption'**
  String get protectedByEncryption;

  /// No description provided for @allYourDataIsEncrypted.
  ///
  /// In en, this message translates to:
  /// **'All your data is stored encrypted.'**
  String get allYourDataIsEncrypted;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
