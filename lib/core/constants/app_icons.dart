import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Central icon system for Keeply.
///
/// Keeply uses Lucide as its single visual icon language.
///
/// Do not use Material Icons directly inside feature pages.
class AppIcons {
  AppIcons._();

  // ===========================================================================
  // Brand
  // ===========================================================================

  static const IconData vault = LucideIcons.shieldCheck;
  static const IconData security = LucideIcons.shieldCheck;
  static const IconData protectedVault = LucideIcons.shieldCheck;

  // ===========================================================================
  // Authentication
  // ===========================================================================
  static const IconData laith = LucideIcons.folder;
  static const IconData lock = LucideIcons.lockKeyhole;
  static const IconData unlock = LucideIcons.lockKeyholeOpen;
  static const IconData fingerprint = LucideIcons.fingerprint;
  static const IconData pin = LucideIcons.keyRound;
  static const IconData password = LucideIcons.keyRound;
  static const IconData visibility = LucideIcons.eye;
  static const IconData visibilityOff = LucideIcons.eyeOff;
  static const IconData login = LucideIcons.logIn;
  static const IconData logout = LucideIcons.logOut;

  // ===========================================================================
  // Vault Modules
  // ===========================================================================

  static const IconData passwords = LucideIcons.keyRound;
  static const IconData accounts = LucideIcons.userRound;
  static const IconData bookmarks = LucideIcons.bookmark;
  static const IconData media = LucideIcons.image;
  static const IconData photo = LucideIcons.image;
  static const IconData documents = LucideIcons.fileText;
  static const IconData folder = LucideIcons.folder;
  static const IconData folderSecure = LucideIcons.folderLock;
  static const IconData file = LucideIcons.file;

  // ===========================================================================
  // Backup & Restore
  // ===========================================================================

  static const IconData backup = LucideIcons.cloudUpload;
  static const IconData restore = LucideIcons.cloudDownload;
  static const IconData cloud = LucideIcons.cloud;
  static const IconData cloudOffline = LucideIcons.cloudOff;
  static const IconData sync = LucideIcons.refreshCw;
  static const IconData syncSuccess = LucideIcons.cloudCheck;
  static const IconData backupHistory = LucideIcons.history;

  // ===========================================================================
  // Actions
  // ===========================================================================

  static const IconData add = LucideIcons.plus;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData search = LucideIcons.search;
  static const IconData more = LucideIcons.ellipsis;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData cancel = LucideIcons.circleX;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData download = LucideIcons.download;
  static const IconData upload = LucideIcons.upload;
  static const IconData share = LucideIcons.share2;
  static const IconData copy = LucideIcons.copy;
  static const IconData openExternal = LucideIcons.externalLink;

  // ===========================================================================
  // Navigation
  // ===========================================================================

  static const IconData home = LucideIcons.house;

  static const IconData back = LucideIcons.arrowLeft;
  static const IconData forward = LucideIcons.arrowRight;

  static const IconData previous = LucideIcons.chevronLeft;
  static const IconData next = LucideIcons.chevronRight;

  static const IconData expand = LucideIcons.chevronDown;
  static const IconData collapse = LucideIcons.chevronUp;

  // ===========================================================================
  // Settings
  // ===========================================================================

  static const IconData settings = LucideIcons.settings;
  static const IconData language = LucideIcons.languages;
  static const IconData appearance = LucideIcons.palette;
  static const IconData darkMode = LucideIcons.moon;
  static const IconData lightMode = LucideIcons.sun;
  static const IconData notifications = LucideIcons.bell;
  static const IconData privacy = LucideIcons.shield;

  // ===========================================================================
  // Password Tools
  // ===========================================================================

  static const IconData generatePassword = LucideIcons.sparkles;
  static const IconData passwordStrength = LucideIcons.shieldCheck;
  static const IconData username = LucideIcons.userRound;
  static const IconData email = LucideIcons.mail;
  static const IconData website = LucideIcons.globe;

  // ===========================================================================
  // Media
  // ===========================================================================

  static const IconData camera = LucideIcons.camera;
  static const IconData gallery = LucideIcons.images;
  static const IconData image = LucideIcons.image;
  static const IconData video = LucideIcons.video;

  // ===========================================================================
  // Documents
  // ===========================================================================

  static const IconData addDocument = LucideIcons.filePlus2;
  static const IconData addFolder = LucideIcons.folderPlus;
  static const IconData archive = LucideIcons.archive;
  static const IconData extract = LucideIcons.archiveRestore;
  static const IconData fileUpload = LucideIcons.fileUp;
  static const IconData fileDownload = LucideIcons.fileDown;

  // ===========================================================================
  // Status
  // ===========================================================================

  static const IconData success = LucideIcons.circleCheck;
  static const IconData error = LucideIcons.circleAlert;
  static const IconData warning = LucideIcons.triangleAlert;
  static const IconData information = LucideIcons.info;
  static const IconData loading = LucideIcons.loaderCircle;
  static const IconData offline = LucideIcons.wifiOff;
  static const IconData online = LucideIcons.wifi;
}
