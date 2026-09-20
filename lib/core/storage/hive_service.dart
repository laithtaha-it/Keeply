import 'package:hive_flutter/hive_flutter.dart';

import '../../features/bookmarks/data/models/bookmark_adapter.dart';
import '../../features/bookmarks/domain/models/bookmark.dart';
import '../../features/files/data/models/file_item_adapter.dart';
import '../../features/files/data/models/folder_item_adapter.dart';
import '../../features/files/domain/models/file_item.dart';
import '../../features/files/domain/models/folder_item.dart';
import '../../features/media/data/models/media_item_adapter.dart';
import '../../features/media/domain/models/media_item.dart';
import '../../features/vault/data/models/vault_item_adapter.dart';
import '../../features/vault/domain/models/vault_item.dart';

/// Central Hive initialization and box management service.
class HiveService {
  HiveService();

  // ===========================================================================
  // Box Names
  // ===========================================================================

  static const String vaultBoxName = 'secure_vault_items';
  static const String bookmarksBoxName = 'secure_vault_bookmarks';
  static const String mediaBoxName = 'secure_vault_media';
  static const String filesBoxName = 'secure_vault_files';
  static const String foldersBoxName = 'secure_vault_folders';

  // ===========================================================================
  // Boxes
  // ===========================================================================

  Box<VaultItem>? _vaultBox;
  Box<Bookmark>? _bookmarksBox;
  Box<MediaItem>? _mediaBox;
  Box<FileItem>? _filesBox;
  Box<FolderItem>? _foldersBox;

  // ===========================================================================
  // Initialize
  // ===========================================================================

  /// Initializes Hive and registers all adapters.
  Future<void> initialize() async {
    await Hive.initFlutter();

    _registerAdapters();

    _vaultBox = await Hive.openBox<VaultItem>(
      vaultBoxName,
    );

    _bookmarksBox = await Hive.openBox<Bookmark>(
      bookmarksBoxName,
    );

    _mediaBox = await Hive.openBox<MediaItem>(
      mediaBoxName,
    );

    _filesBox = await Hive.openBox<FileItem>(
      filesBoxName,
    );

    _foldersBox = await Hive.openBox<FolderItem>(
      foldersBoxName,
    );
  }

  // ===========================================================================
  // Hive Adapters
  // ===========================================================================

  /// Registers application-specific Hive adapters.
  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(
        VaultItemAdapter(),
      );
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(
        BookmarkAdapter(),
      );
    }

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(
        MediaItemAdapter(),
      );
    }

    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(
        FileItemAdapter(),
      );
    }

    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(
        FolderItemAdapter(),
      );
    }
  }

  // ===========================================================================
  // Password Vault
  // ===========================================================================

  /// Returns the main Keeply password box.
  Box<VaultItem> get vaultBox {
    final box = _vaultBox;

    if (box == null || !box.isOpen) {
      throw StateError(
        'HiveService has not been initialized.',
      );
    }

    return box;
  }

  /// Stores or updates a vault item.
  Future<void> putItem(
    VaultItem item,
  ) async {
    await vaultBox.put(
      item.id,
      item,
    );
  }

  /// Reads a vault item by ID.
  VaultItem? getItem(
    String id,
  ) {
    return vaultBox.get(id);
  }

  /// Returns all stored vault items.
  List<VaultItem> getAllItems() {
    return vaultBox.values.toList();
  }

  /// Deletes one vault item.
  Future<void> deleteItem(
    String id,
  ) async {
    await vaultBox.delete(id);
  }

  /// Clears all vault items.
  Future<void> clearVault() async {
    await vaultBox.clear();
  }

  /// Number of stored vault items.
  int get itemCount {
    return vaultBox.length;
  }

  // ===========================================================================
  // Bookmarks
  // ===========================================================================

  /// Returns the Keeply bookmarks box.
  Box<Bookmark> get bookmarksBox {
    final box = _bookmarksBox;

    if (box == null || !box.isOpen) {
      throw StateError(
        'HiveService has not been initialized.',
      );
    }

    return box;
  }

  /// Stores or updates a bookmark.
  Future<void> putBookmark(
    Bookmark bookmark,
  ) async {
    await bookmarksBox.put(
      bookmark.id,
      bookmark,
    );
  }

  /// Reads a bookmark by ID.
  Bookmark? getBookmark(
    String id,
  ) {
    return bookmarksBox.get(id);
  }

  /// Returns all stored bookmarks.
  List<Bookmark> getAllBookmarks() {
    return bookmarksBox.values.toList();
  }

  /// Deletes one bookmark.
  Future<void> deleteBookmark(
    String id,
  ) async {
    await bookmarksBox.delete(id);
  }

  /// Clears all bookmarks.
  Future<void> clearBookmarks() async {
    await bookmarksBox.clear();
  }

  /// Number of stored bookmarks.
  int get bookmarkCount {
    return bookmarksBox.length;
  }

  // ===========================================================================
  // Media
  // ===========================================================================

  /// Returns the Keeply media box.
  Box<MediaItem> get mediaBox {
    final box = _mediaBox;

    if (box == null || !box.isOpen) {
      throw StateError(
        'HiveService has not been initialized.',
      );
    }

    return box;
  }

  /// Stores or updates a media item.
  Future<void> putMedia(
    MediaItem media,
  ) async {
    await mediaBox.put(
      media.id,
      media,
    );
  }

  /// Reads a media item by ID.
  MediaItem? getMedia(
    String id,
  ) {
    return mediaBox.get(id);
  }

  /// Returns all stored media items.
  List<MediaItem> getAllMedia() {
    return mediaBox.values.toList();
  }

  /// Deletes one media item.
  Future<void> deleteMedia(
    String id,
  ) async {
    await mediaBox.delete(id);
  }

  /// Clears all media items.
  Future<void> clearMedia() async {
    await mediaBox.clear();
  }

  /// Number of stored media items.
  int get mediaCount {
    return mediaBox.length;
  }

  // ===========================================================================
  // Files
  // ===========================================================================

  /// Returns the Keeply files box.
  Box<FileItem> get filesBox {
    final box = _filesBox;

    if (box == null || !box.isOpen) {
      throw StateError(
        'HiveService has not been initialized.',
      );
    }

    return box;
  }

  /// Stores or updates a file.
  Future<void> putFile(
    FileItem file,
  ) async {
    await filesBox.put(
      file.id,
      file,
    );
  }

  /// Reads a file by ID.
  FileItem? getFile(
    String id,
  ) {
    return filesBox.get(id);
  }

  /// Returns all stored files.
  List<FileItem> getAllFiles() {
    return filesBox.values.toList();
  }

  /// Returns files belonging to a specific folder.
  ///
  /// An empty folder ID means the root directory.
  List<FileItem> getFilesInFolder(
    String folderId,
  ) {
    return filesBox.values
        .where(
          (file) => file.folderId == folderId,
        )
        .toList();
  }

  /// Deletes one file record.
  Future<void> deleteFile(
    String id,
  ) async {
    await filesBox.delete(id);
  }

  /// Clears all file records.
  Future<void> clearFiles() async {
    await filesBox.clear();
  }

  /// Number of stored files.
  int get fileCount {
    return filesBox.length;
  }

  // ===========================================================================
  // Folders
  // ===========================================================================

  /// Returns the Keeply folders box.
  Box<FolderItem> get foldersBox {
    final box = _foldersBox;

    if (box == null || !box.isOpen) {
      throw StateError(
        'HiveService has not been initialized.',
      );
    }

    return box;
  }

  /// Stores or updates a folder.
  Future<void> putFolder(
    FolderItem folder,
  ) async {
    await foldersBox.put(
      folder.id,
      folder,
    );
  }

  /// Reads a folder by ID.
  FolderItem? getFolder(
    String id,
  ) {
    return foldersBox.get(id);
  }

  /// Returns all stored folders.
  List<FolderItem> getAllFolders() {
    return foldersBox.values.toList();
  }

  /// Returns folders belonging to a specific parent folder.
  ///
  /// An empty parent ID means the root directory.
  List<FolderItem> getFoldersInParent(
    String parentId,
  ) {
    return foldersBox.values
        .where(
          (folder) => folder.parentId == parentId,
        )
        .toList();
  }

  /// Deletes one folder record.
  Future<void> deleteFolder(
    String id,
  ) async {
    await foldersBox.delete(id);
  }

  /// Clears all folder records.
  Future<void> clearFolders() async {
    await foldersBox.clear();
  }

  /// Number of stored folders.
  int get folderCount {
    return foldersBox.length;
  }

  // ===========================================================================
  // Close
  // ===========================================================================

  /// Closes all Hive boxes.
  Future<void> close() async {
    if (_vaultBox?.isOpen ?? false) {
      await _vaultBox!.close();
    }

    if (_bookmarksBox?.isOpen ?? false) {
      await _bookmarksBox!.close();
    }

    if (_mediaBox?.isOpen ?? false) {
      await _mediaBox!.close();
    }

    if (_filesBox?.isOpen ?? false) {
      await _filesBox!.close();
    }

    if (_foldersBox?.isOpen ?? false) {
      await _foldersBox!.close();
    }

    _vaultBox = null;
    _bookmarksBox = null;
    _mediaBox = null;
    _filesBox = null;
    _foldersBox = null;
  }
}
