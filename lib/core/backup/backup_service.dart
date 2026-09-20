import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../features/bookmarks/domain/models/bookmark.dart';
import '../../features/files/domain/models/file_item.dart';
import '../../features/files/domain/models/folder_item.dart';
import '../../features/media/domain/models/media_item.dart';
import '../../features/vault/domain/models/vault_item.dart';
import '../cloud/google_drive_service.dart';
import '../security/encryption_service.dart';
import '../security/secure_storage_service.dart';
import '../storage/hive_service.dart';

enum BackupSection {
  passwords,
  bookmarks,
  media,
  documents,
}

enum BackupOperation {
  upload,
  download,
}

class BackupProgress {
  const BackupProgress({
    required this.operation,
    required this.currentItem,
    required this.currentItemIndex,
    required this.totalItems,
    required this.currentBytes,
    required this.currentItemTotalBytes,
    required this.transferredBytes,
    required this.totalBytes,
    required this.speedBytesPerSecond,
  });

  final BackupOperation operation;
  final String currentItem;
  final int currentItemIndex;
  final int totalItems;
  final int currentBytes;
  final int currentItemTotalBytes;
  final int transferredBytes;
  final int totalBytes;
  final double speedBytesPerSecond;

  double get fraction {
    if (totalBytes <= 0) return 0;
    return (transferredBytes / totalBytes).clamp(0.0, 1.0);
  }

  int get remainingBytes {
    final remaining = totalBytes - transferredBytes;
    return remaining < 0 ? 0 : remaining;
  }

  Duration? get eta {
    if (speedBytesPerSecond <= 0 || remainingBytes <= 0) return null;
    return Duration(
      seconds: (remainingBytes / speedBytesPerSecond).ceil(),
    );
  }
}

typedef BackupProgressCallback = void Function(BackupProgress progress);

class NoInternetConnectionException implements Exception {
  const NoInternetConnectionException();

  @override
  String toString() => 'NO_INTERNET_CONNECTION';
}

class BackupService {
  BackupService({
    required HiveService hiveService,
    required EncryptionService encryptionService,
    required GoogleDriveService googleDriveService,
    required SecureStorageService secureStorage,
  })  : _hiveService = hiveService,
        _encryptionService = encryptionService,
        _googleDriveService = googleDriveService,
        _secureStorage = secureStorage;

  final HiveService _hiveService;

  // Kept for compatibility with the existing dependency injection setup.
  //
  // Incremental Google Drive backup does NOT use EncryptionService.
  final EncryptionService _encryptionService;

  final GoogleDriveService _googleDriveService;

  // Kept for compatibility with the existing dependency injection setup.
  //
  // Incremental cloud backup does NOT store or restore a master key.
  final SecureStorageService _secureStorage;

  // ===========================================================================
  // INCREMENTAL OBJECT PREFIXES
  // ===========================================================================

  static const String _vaultPrefix = 'Keeply_Vault_';

  static const String _bookmarkPrefix = 'Keeply_Bookmark_';

  static const String _folderPrefix = 'Keeply_Folder_';

  static const String _mediaMetaPrefix = 'Keeply_MediaMeta_';

  static const String _mediaDataPrefix = 'Keeply_MediaData_';

  static const String _fileMetaPrefix = 'Keeply_FileMeta_';

  static const String _fileDataPrefix = 'Keeply_FileData_';

  // ===========================================================================
  // DESCRIPTION KEYS
  // ===========================================================================

  static const String _descriptionHeader = 'KeeplyIncremental';

  static const String _hashKey = 'sha256';

  static const String _kindKey = 'kind';

  static const String _idKey = 'id';

  static const String _versionKey = 'version';

  static const String _version = '1';

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  bool get isGoogleConnected {
    return _googleDriveService.isConnected;
  }

  GoogleDriveService get googleDriveService {
    return _googleDriveService;
  }

  // ===========================================================================
  // MAIN CLOUD BACKUP
  // ===========================================================================

  Future<void> ensureInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );

      if (result.isEmpty) {
        throw const NoInternetConnectionException();
      }
    } on NoInternetConnectionException {
      rethrow;
    } on SocketException catch (_) {
      throw const NoInternetConnectionException();
    } on TimeoutException catch (_) {
      throw const NoInternetConnectionException();
    }
  }

  Future<IncrementalBackupResult> syncToGoogleDrive({
    Set<BackupSection>? sections,
    BackupProgressCallback? onProgress,
  }) async {
    await ensureInternetConnection();
    _ensureGoogleConnected();

    final selectedSections = sections == null || sections.isEmpty
        ? BackupSection.values.toSet()
        : sections;

    final localObjects = <String, _IncrementalObject>{};

    // -------------------------------------------------------------------------
    // VAULT / PASSWORDS
    // -------------------------------------------------------------------------

    if (selectedSections.contains(BackupSection.passwords)) {
      final vaultItems = _hiveService.getAllItems();

      for (final item in vaultItems) {
        final json = _vaultItemToJson(item);

        final bytes = Uint8List.fromList(
          utf8.encode(
            jsonEncode(json),
          ),
        );

        final name = '$_vaultPrefix${item.id}.svm';

        localObjects[name] = _IncrementalObject(
          name: name,
          kind: 'vault',
          id: item.id,
          content: bytes,
          mimeType: 'application/octet-stream',
        );
      }
    }

    // -------------------------------------------------------------------------
    // BOOKMARKS
    // -------------------------------------------------------------------------

    if (selectedSections.contains(BackupSection.bookmarks)) {
      final bookmarks = _hiveService.getAllBookmarks();

      for (final bookmark in bookmarks) {
        final json = _bookmarkToJson(bookmark);

        final bytes = Uint8List.fromList(
          utf8.encode(
            jsonEncode(json),
          ),
        );

        final name = '$_bookmarkPrefix${bookmark.id}.svm';

        localObjects[name] = _IncrementalObject(
          name: name,
          kind: 'bookmark',
          id: bookmark.id,
          content: bytes,
          mimeType: 'application/octet-stream',
        );
      }
    }

    // -------------------------------------------------------------------------
    // FOLDERS
    // -------------------------------------------------------------------------

    if (selectedSections.contains(BackupSection.documents)) {
      final folders = _hiveService.getAllFolders();

      for (final folder in folders) {
        final json = _folderItemToJson(folder);

        final bytes = Uint8List.fromList(
          utf8.encode(
            jsonEncode(json),
          ),
        );

        final name = '$_folderPrefix${folder.id}.svm';

        localObjects[name] = _IncrementalObject(
          name: name,
          kind: 'folder',
          id: folder.id,
          content: bytes,
          mimeType: 'application/octet-stream',
        );
      }
    }

    // -------------------------------------------------------------------------
    // MEDIA
    // -------------------------------------------------------------------------

    if (selectedSections.contains(BackupSection.media)) {
      final mediaItems = _hiveService.getAllMedia();

      for (final media in mediaItems) {
        final metadataJson = _mediaItemToJson(media);

        final metadataBytes = Uint8List.fromList(
          utf8.encode(
            jsonEncode(metadataJson),
          ),
        );

        final metadataName = '$_mediaMetaPrefix${media.id}.svm';

        localObjects[metadataName] = _IncrementalObject(
          name: metadataName,
          kind: 'media_meta',
          id: media.id,
          content: metadataBytes,
          mimeType: 'application/octet-stream',
        );

        final sourceFile = File(media.filePath);

        if (await sourceFile.exists()) {
          final dataName = '$_mediaDataPrefix${media.id}.svm';

          localObjects[dataName] = _IncrementalObject(
            name: dataName,
            kind: 'media_data',
            id: media.id,
            file: sourceFile,
            mimeType: 'application/octet-stream',
          );
        }
      }
    }

    // -------------------------------------------------------------------------
    // FILES
    // -------------------------------------------------------------------------

    if (selectedSections.contains(BackupSection.documents)) {
      final fileItems = _hiveService.getAllFiles();

      for (final file in fileItems) {
        final metadataJson = _fileItemToJson(file);

        final metadataBytes = Uint8List.fromList(
          utf8.encode(
            jsonEncode(metadataJson),
          ),
        );

        final metadataName = '$_fileMetaPrefix${file.id}.svm';

        localObjects[metadataName] = _IncrementalObject(
          name: metadataName,
          kind: 'file_meta',
          id: file.id,
          content: metadataBytes,
          mimeType: 'application/octet-stream',
        );

        final sourceFile = File(file.filePath);

        if (await sourceFile.exists()) {
          final dataName = '$_fileDataPrefix${file.id}.svm';

          localObjects[dataName] = _IncrementalObject(
            name: dataName,
            kind: 'file_data',
            id: file.id,
            file: sourceFile,
            mimeType: 'application/octet-stream',
          );
        }
      }
    }

    // -------------------------------------------------------------------------
    // READ CURRENT CLOUD STATE
    // -------------------------------------------------------------------------

    final cloudFiles = await _listIncrementalCloudObjects(
      sections: selectedSections,
    );
    final cloudObjects = cloudFiles;

    var created = 0;
    var updated = 0;
    var skipped = 0;
    var deleted = 0;
    var uploadedBytes = 0;

    drive.File? representativeFile;

    // -------------------------------------------------------------------------
    // BUILD TRANSFER PLAN
    // -------------------------------------------------------------------------

    final pendingUploads = <_PendingUpload>[];
    final pendingDeletes = <drive.File>[];

    for (final localObject in localObjects.values) {
      final cloudFile = cloudObjects[localObject.name];
      final localHash = await _sha256IncrementalObject(localObject);

      if (cloudFile != null &&
          cloudFile.id != null &&
          cloudFile.id!.isNotEmpty) {
        final cloudHash = _extractHashFromDescription(
          cloudFile.description,
        );

        if (cloudHash == localHash &&
            _isValidIncrementalDescription(
              cloudFile.description,
              expectedKind: localObject.kind,
              expectedId: localObject.id,
            )) {
          skipped++;
          representativeFile ??= cloudFile;
          continue;
        }

        pendingUploads.add(
          _PendingUpload(
            localObject: localObject,
            fileId: cloudFile.id,
            isUpdate: true,
            hash: localHash,
          ),
        );
        continue;
      }

      pendingUploads.add(
        _PendingUpload(
          localObject: localObject,
          isUpdate: false,
          hash: localHash,
        ),
      );
    }

    for (final entry in cloudObjects.entries) {
      if (localObjects.containsKey(entry.key)) {
        continue;
      }

      final fileId = entry.value.id;
      if (fileId != null && fileId.isNotEmpty) {
        pendingDeletes.add(entry.value);
      }
    }

    final totalTransferBytes = await _sumPendingUploadBytes(pendingUploads);
    var transferredOverall = 0;
    final stopwatch = Stopwatch()..start();

    void emitProgress({
      required BackupOperation operation,
      required String item,
      required int itemIndex,
      required int totalItems,
      required int currentBytes,
      required int currentTotalBytes,
    }) {
      if (onProgress == null) return;

      final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000.0;
      final speed =
          elapsedSeconds <= 0 ? 0.0 : transferredOverall / elapsedSeconds;

      onProgress(
        BackupProgress(
          operation: operation,
          currentItem: item,
          currentItemIndex: itemIndex,
          totalItems: totalItems,
          currentBytes: currentBytes,
          currentItemTotalBytes: currentTotalBytes,
          transferredBytes: transferredOverall,
          totalBytes: totalTransferBytes,
          speedBytesPerSecond: speed,
        ),
      );
    }

    // -------------------------------------------------------------------------
    // UPLOAD / UPDATE
    //
    // A small bounded concurrency keeps several tiny Drive requests from
    // becoming a long serial queue, while avoiding an unbounded request burst.
    // -------------------------------------------------------------------------

    var completedUploads = 0;

    await _runConcurrent<_PendingUpload>(
      pendingUploads,
      maxConcurrency: 3,
      task: (pending) async {
        var lastReported = 0;
        final itemTotalBytes = await pending.localObject.length;

        void progress(int current) {
          final delta = current - lastReported;
          if (delta <= 0) return;
          lastReported = current;
          transferredOverall += delta;

          emitProgress(
            operation: BackupOperation.upload,
            item: pending.localObject.name,
            itemIndex: completedUploads + 1,
            totalItems: pendingUploads.length,
            currentBytes: current,
            currentTotalBytes: itemTotalBytes,
          );
        }

        final description = _buildDescription(
          kind: pending.localObject.kind,
          id: pending.localObject.id,
          hash: pending.hash,
        );

        final uploadedFile = await _uploadPendingObject(
          pending,
          description: description,
          onProgress: progress,
        );

        if (pending.isUpdate) {
          updated++;
        } else {
          created++;
        }

        uploadedBytes += await pending.localObject.length;
        representativeFile ??= uploadedFile;
        completedUploads++;
      },
    );

    // -------------------------------------------------------------------------
    // DELETE OBSOLETE OBJECTS
    // -------------------------------------------------------------------------

    await _runConcurrent<drive.File>(
      pendingDeletes,
      maxConcurrency: 3,
      task: (file) async {
        final fileId = file.id;
        if (fileId == null || fileId.isEmpty) return;
        await _googleDriveService.deleteAppDataFile(fileId);
        deleted++;
      },
    );

    stopwatch.stop();

    return IncrementalBackupResult(
      created: created,
      updated: updated,
      skipped: skipped,
      deleted: deleted,
      uploadedBytes: uploadedBytes,
      representativeFile: representativeFile,
    );
  }

  // ===========================================================================
  // BACKWARDS-COMPATIBLE BACKUP METHOD
  // ===========================================================================

  Future<drive.File> backupAndUpload() async {
    final result = await syncToGoogleDrive();

    if (result.representativeFile != null) {
      return result.representativeFile!;
    }

    return drive.File()..name = 'Keeply_Cloud_Sync';
  }

  // ===========================================================================
  // LIST KEEPLY CLOUD OBJECTS
  // ===========================================================================

  Future<List<drive.File>> listCloudBackupObjects() async {
    _ensureGoogleConnected();

    final objects = await _listIncrementalCloudObjects();

    final result = objects.values.toList(
      growable: false,
    );

    result.sort(
      (a, b) {
        final aTime = a.modifiedTime ?? a.createdTime;
        final bTime = b.modifiedTime ?? b.createdTime;

        if (aTime == null && bTime == null) {
          return 0;
        }

        if (aTime == null) {
          return 1;
        }

        if (bTime == null) {
          return -1;
        }

        return bTime.compareTo(aTime);
      },
    );

    return result;
  }

  // ===========================================================================
  // LIST ALL APP DATA FILES
  // ===========================================================================

  Future<List<drive.File>> listAllAppDataFiles() async {
    _ensureGoogleConnected();

    return _googleDriveService.listAllAppDataFiles();
  }

  // ===========================================================================
  // DELETE ONE CLOUD OBJECT
  // ===========================================================================

  Future<void> deleteIncrementalObject(
    String fileId,
  ) async {
    _ensureGoogleConnected();

    await _googleDriveService.deleteAppDataFile(
      fileId,
    );
  }

  // ===========================================================================
  // DELETE ALL KEEPLY CLOUD OBJECTS
  // ===========================================================================

  Future<int> deleteAllIncrementalCloudObjects() async {
    _ensureGoogleConnected();

    final cloudObjects = await _listIncrementalCloudObjects();

    var deleted = 0;

    for (final file in cloudObjects.values) {
      final fileId = file.id;

      if (fileId == null || fileId.isEmpty) {
        continue;
      }

      await _googleDriveService.deleteAppDataFile(
        fileId,
      );

      deleted++;
    }

    return deleted;
  }

  // ===========================================================================
  // RESTORE FROM GOOGLE DRIVE
  // ===========================================================================

  /// Restores missing Keeply data from Google Drive.
  ///
  /// Restore is additive: local data is never cleared or replaced.
  /// Records whose stable IDs already exist locally are skipped.
  ///
  /// Restore is performed in two phases:
  /// 1. Download and validate the missing cloud data.
  /// 2. Write only the missing records and their binary files.
  Future<void> restoreFromGoogleDrive({
    Set<BackupSection>? sections,
    BackupProgressCallback? onProgress,
  }) async {
    await ensureInternetConnection();
    _ensureGoogleConnected();

    final selectedSections = sections == null || sections.isEmpty
        ? BackupSection.values.toSet()
        : sections;

    final cloudObjects = await _listIncrementalCloudObjects(
      sections: selectedSections,
    );

    if (cloudObjects.isEmpty) {
      throw StateError(
        'No Keeply cloud backup was found in Google Drive.',
      );
    }

    // =========================================================================
    // EXISTING LOCAL DATA
    // =========================================================================

    final existingVaultIds =
        _hiveService.getAllItems().map((item) => item.id).toSet();

    final existingBookmarkIds =
        _hiveService.getAllBookmarks().map((item) => item.id).toSet();

    final existingFolderIds =
        _hiveService.getAllFolders().map((item) => item.id).toSet();

    final existingMediaIds =
        _hiveService.getAllMedia().map((item) => item.id).toSet();

    final existingFileIds =
        _hiveService.getAllFiles().map((item) => item.id).toSet();

    // =========================================================================
    // TEMPORARY RESTORE DATA
    // =========================================================================

    final vaultItems = <VaultItem>[];

    final bookmarks = <Bookmark>[];

    final folders = <FolderItem>[];

    final mediaItems = <String, MediaItem>{};

    final fileItems = <String, FileItem>{};

    final mediaBinary = <String, File>{};

    final fileBinary = <String, File>{};

    // =========================================================================
    // PREFETCH MISSING CLOUD OBJECTS
    // =========================================================================
    //
    // Downloads are independent, so a small concurrent pool removes the
    // artificial one-request-at-a-time delay of the previous implementation.
    // The actual decoding/validation below remains sequential and unchanged.
    // =========================================================================

    final downloadEntries = <MapEntry<String, drive.File>>[];

    for (final entry in cloudObjects.entries) {
      final cloudFile = entry.value;
      final description = _parseIncrementalDescription(
        cloudFile.description,
      );
      final objectId = description[_idKey];

      if (objectId == null || objectId.isEmpty) {
        continue;
      }

      final kind = description[_kindKey];
      final alreadyExistsLocally =
          (kind == 'vault' && existingVaultIds.contains(objectId)) ||
              (kind == 'bookmark' && existingBookmarkIds.contains(objectId)) ||
              (kind == 'folder' && existingFolderIds.contains(objectId)) ||
              ((kind == 'media_meta' || kind == 'media_data') &&
                  existingMediaIds.contains(objectId)) ||
              ((kind == 'file_meta' || kind == 'file_data') &&
                  existingFileIds.contains(objectId));

      if (!alreadyExistsLocally) {
        downloadEntries.add(entry);
      }
    }

    final totalDownloadBytes = downloadEntries.fold<int>(
      0,
      (sum, entry) => sum + (int.tryParse(entry.value.size ?? '0') ?? 0),
    );

    final transferTempDirectory = await Directory(
      path.join(
        (await getTemporaryDirectory()).path,
        'Keeply',
        'cloud_restore_${DateTime.now().microsecondsSinceEpoch}',
      ),
    ).create(recursive: true);
    var downloadedOverall = 0;
    final downloadStopwatch = Stopwatch()..start();
    final downloadedBytes = <String, Uint8List>{};
    final downloadProgressByObject = <String, int>{};
    var completedDownloads = 0;

    void emitDownloadProgress(
      String item,
      int itemIndex,
      int currentBytes,
      int currentTotalBytes,
    ) {
      if (onProgress == null) return;

      final elapsedSeconds = downloadStopwatch.elapsedMilliseconds / 1000.0;
      final speed =
          elapsedSeconds <= 0 ? 0.0 : downloadedOverall / elapsedSeconds;

      onProgress(
        BackupProgress(
          operation: BackupOperation.download,
          currentItem: item,
          currentItemIndex: itemIndex,
          totalItems: downloadEntries.length,
          currentBytes: currentBytes,
          currentItemTotalBytes: currentTotalBytes,
          transferredBytes: downloadedOverall,
          totalBytes: totalDownloadBytes,
          speedBytesPerSecond: speed,
        ),
      );
    }

    await _runConcurrent<MapEntry<String, drive.File>>(
      downloadEntries,
      maxConcurrency: 3,
      task: (entry) async {
        final cloudFile = entry.value;
        final fileId = cloudFile.id;

        if (fileId == null || fileId.isEmpty) {
          throw StateError(
            'Cloud object has no Google Drive ID: ${entry.key}',
          );
        }

        final expectedSize = int.tryParse(cloudFile.size ?? '0') ?? 0;
        final kind =
            _parseIncrementalDescription(cloudFile.description)[_kindKey];
        final isBinary = kind == 'media_data' || kind == 'file_data';

        if (isBinary) {
          final destination = File(
            path.join(
              transferTempDirectory.path,
              _safeTransferFileName(entry.key),
            ),
          );

          final downloadedFile =
              await _googleDriveService.downloadAppDataFileToFile(
            fileId,
            destination,
            onProgress: (current) {
              final previous = downloadProgressByObject[entry.key] ?? 0;
              final delta = current - previous;
              if (delta <= 0) return;
              downloadProgressByObject[entry.key] = current;
              downloadedOverall += delta;
              emitDownloadProgress(
                entry.key,
                completedDownloads + 1,
                current,
                expectedSize,
              );
            },
          );

          if (kind == 'media_data') {
            mediaBinary[_parseIncrementalDescription(
                cloudFile.description)[_idKey]!] = downloadedFile;
          } else {
            fileBinary[_parseIncrementalDescription(
                cloudFile.description)[_idKey]!] = downloadedFile;
          }
        } else {
          final bytes = await _googleDriveService.downloadAppDataFile(
            fileId,
            onProgress: (current) {
              final previous = downloadProgressByObject[entry.key] ?? 0;
              final delta = current - previous;
              if (delta <= 0) return;
              downloadProgressByObject[entry.key] = current;
              downloadedOverall += delta;
              emitDownloadProgress(
                entry.key,
                completedDownloads + 1,
                current,
                expectedSize,
              );
            },
          );
          downloadedBytes[entry.key] = bytes;
        }

        completedDownloads++;
      },
    );

    downloadStopwatch.stop();

    // =========================================================================
    // DOWNLOAD + VALIDATE EVERYTHING
    // =========================================================================

    for (final entry in cloudObjects.entries) {
      final cloudName = entry.key;

      final cloudFile = entry.value;

      final fileId = cloudFile.id;

      if (fileId == null || fileId.isEmpty) {
        throw StateError(
          'Cloud object has no Google Drive ID: $cloudName',
        );
      }

      final description = _parseIncrementalDescription(
        cloudFile.description,
      );

      final expectedHash = description[_hashKey];

      final kind = description[_kindKey];

      final objectId = description[_idKey];

      if (expectedHash == null ||
          expectedHash.length != 64 ||
          !_isValidSha256(expectedHash)) {
        throw FormatException(
          'Invalid SHA-256 for cloud object: $cloudName',
        );
      }

      if (kind == null || kind.isEmpty) {
        throw FormatException(
          'Cloud object kind is missing: $cloudName',
        );
      }

      if (objectId == null || objectId.isEmpty) {
        throw FormatException(
          'Cloud object ID is missing: $cloudName',
        );
      }

      // -----------------------------------------------------------------------
      // Validate filename
      // -----------------------------------------------------------------------

      final expectedKind = _incrementalKindForName(
        cloudName,
      );

      if (expectedKind == null) {
        throw FormatException(
          'Unknown Keeply cloud object: $cloudName',
        );
      }

      if (kind != expectedKind) {
        throw StateError(
          'Cloud object kind mismatch: $cloudName',
        );
      }

      _validateIncrementalIdentity(
        cloudName: cloudName,
        kind: kind,
        objectId: objectId,
      );

      // -----------------------------------------------------------------------
      // Existing local record
      // -----------------------------------------------------------------------

      final alreadyExistsLocally =
          (kind == 'vault' && existingVaultIds.contains(objectId)) ||
              (kind == 'bookmark' && existingBookmarkIds.contains(objectId)) ||
              (kind == 'folder' && existingFolderIds.contains(objectId)) ||
              ((kind == 'media_meta' || kind == 'media_data') &&
                  existingMediaIds.contains(objectId)) ||
              ((kind == 'file_meta' || kind == 'file_data') &&
                  existingFileIds.contains(objectId));

      if (alreadyExistsLocally) {
        continue;
      }

      // -----------------------------------------------------------------------
      // Download
      // -----------------------------------------------------------------------

      final bytes = downloadedBytes[cloudName];
      final binaryFile = mediaBinary[objectId] ?? fileBinary[objectId];

      if (bytes == null && binaryFile == null) {
        continue;
      }

      final actualHash =
          bytes != null ? _sha256(bytes) : await _sha256File(binaryFile!);

      if (actualHash != expectedHash) {
        throw StateError(
          'SHA-256 verification failed: $cloudName',
        );
      }

      // -----------------------------------------------------------------------
      // VAULT
      // -----------------------------------------------------------------------

      if (cloudName.startsWith(_vaultPrefix)) {
        final item = _decodeVaultIncrementalObject(
          bytes!,
          cloudName,
          objectId,
        );

        _ensureUniqueId(
          [
            ...existingVaultIds,
            ...vaultItems.map((e) => e.id),
          ],
          item.id,
          cloudName,
        );

        vaultItems.add(item);

        continue;
      }

      // -----------------------------------------------------------------------
      // BOOKMARK
      // -----------------------------------------------------------------------

      if (cloudName.startsWith(_bookmarkPrefix)) {
        final bookmark = _decodeBookmarkIncrementalObject(
          bytes!,
          cloudName,
          objectId,
        );

        _ensureUniqueId(
          [
            ...existingBookmarkIds,
            ...bookmarks.map((e) => e.id),
          ],
          bookmark.id,
          cloudName,
        );

        bookmarks.add(bookmark);

        continue;
      }

      // -----------------------------------------------------------------------
      // FOLDER
      // -----------------------------------------------------------------------

      if (cloudName.startsWith(_folderPrefix)) {
        final folder = _decodeFolderIncrementalObject(
          bytes!,
          cloudName,
          objectId,
        );

        _ensureUniqueId(
          [
            ...existingFolderIds,
            ...folders.map((e) => e.id),
          ],
          folder.id,
          cloudName,
        );

        folders.add(folder);

        continue;
      }

      // -----------------------------------------------------------------------
      // MEDIA META
      // -----------------------------------------------------------------------

      if (cloudName.startsWith(_mediaMetaPrefix)) {
        final media = _decodeMediaIncrementalObject(
          bytes!,
          cloudName,
          objectId,
        );

        if (mediaItems.containsKey(media.id)) {
          throw StateError(
            'Duplicate media metadata ID: ${media.id}',
          );
        }

        mediaItems[media.id] = media;

        continue;
      }

      // -----------------------------------------------------------------------
      // MEDIA DATA
      // -----------------------------------------------------------------------

      if (cloudName.startsWith(_mediaDataPrefix)) {
        // The binary object was already downloaded and registered in
        // mediaBinary during the download phase.
        //
        // Do NOT treat containsKey(objectId) as a duplicate here.
        // This validation loop visits the same object that was intentionally
        // inserted into mediaBinary during download.
        continue;
      }

      // -----------------------------------------------------------------------
      // FILE META
      // -----------------------------------------------------------------------

      if (cloudName.startsWith(_fileMetaPrefix)) {
        final file = _decodeFileIncrementalObject(
          bytes!,
          cloudName,
          objectId,
        );

        if (fileItems.containsKey(file.id)) {
          throw StateError(
            'Duplicate file metadata ID: ${file.id}',
          );
        }

        fileItems[file.id] = file;

        continue;
      }

      // -----------------------------------------------------------------------
      // FILE DATA
      // -----------------------------------------------------------------------

      if (cloudName.startsWith(_fileDataPrefix)) {
        // The binary object was already downloaded and registered in
        // fileBinary during the download phase.
        //
        // Do NOT treat containsKey(objectId) as a duplicate here.
        // This validation loop visits the same object that was intentionally
        // inserted into fileBinary during download.
        continue;
      }

      throw FormatException(
        'Unknown Keeply cloud object: $cloudName',
      );
    }

    // =========================================================================
    // VALIDATE MEDIA RELATIONSHIPS
    // =========================================================================

    for (final mediaId in mediaItems.keys) {
      if (!mediaBinary.containsKey(mediaId)) {
        throw StateError(
          'Media metadata has no matching binary data: $mediaId',
        );
      }
    }

    for (final mediaId in mediaBinary.keys) {
      if (!mediaItems.containsKey(mediaId)) {
        throw StateError(
          'Media data has no matching metadata: $mediaId',
        );
      }
    }

    // =========================================================================
    // VALIDATE FILE RELATIONSHIPS
    // =========================================================================

    for (final fileId in fileItems.keys) {
      if (!fileBinary.containsKey(fileId)) {
        throw StateError(
          'File metadata has no matching binary data: $fileId',
        );
      }
    }

    for (final fileId in fileBinary.keys) {
      if (!fileItems.containsKey(fileId)) {
        throw StateError(
          'File data has no matching metadata: $fileId',
        );
      }
    }

    // =========================================================================
    // VALIDATE FOLDER RELATIONSHIPS
    // =========================================================================

    final folderIds = <String>{
      ...existingFolderIds,
      ...folders.map((folder) => folder.id),
    };

    for (final folder in folders) {
      if (folder.parentId.isNotEmpty && !folderIds.contains(folder.parentId)) {
        throw StateError(
          'Folder "${folder.id}" references missing parent '
          '"${folder.parentId}".',
        );
      }
    }

    for (final file in fileItems.values) {
      if (file.folderId.isNotEmpty && !folderIds.contains(file.folderId)) {
        throw StateError(
          'File "${file.id}" references missing folder '
          '"${file.folderId}".',
        );
      }
    }

    // =========================================================================
    // CREATE PERMANENT RESTORE DIRECTORY
    // =========================================================================

    final restoreDirectory = await _createRestoreDirectory();

    // =========================================================================
    // RESTORE MEDIA FILES
    // =========================================================================

    final restoredMedia = <MediaItem>[];

    for (final media in mediaItems.values) {
      final sourceFile = mediaBinary[media.id];

      if (sourceFile == null) {
        throw StateError(
          'Missing media data for: ${media.id}',
        );
      }

      final outputPath = path.join(
        restoreDirectory.path,
        'media',
        _safeFileName(
          media.id,
          media.fileName,
        ),
      );

      final outputFile = File(outputPath);

      await outputFile.parent.create(
        recursive: true,
      );

      await sourceFile.copy(outputFile.path);

      final writtenLength = await outputFile.length();
      final sourceLength = await sourceFile.length();

      if (writtenLength != sourceLength) {
        throw StateError(
          'Restored media file size mismatch: ${media.id}',
        );
      }

      restoredMedia.add(
        media.copyWith(
          filePath: outputFile.path,
        ),
      );
    }

    // =========================================================================
    // RESTORE FILES
    // =========================================================================

    final restoredFiles = <FileItem>[];

    for (final file in fileItems.values) {
      final sourceFile = fileBinary[file.id];

      if (sourceFile == null) {
        throw StateError(
          'Missing file data for: ${file.id}',
        );
      }

      final outputPath = path.join(
        restoreDirectory.path,
        'files',
        _safeFileName(
          file.id,
          file.fileName,
        ),
      );

      final outputFile = File(outputPath);

      await outputFile.parent.create(
        recursive: true,
      );

      await sourceFile.copy(outputFile.path);

      final writtenLength = await outputFile.length();
      final sourceLength = await sourceFile.length();

      if (writtenLength != sourceLength) {
        throw StateError(
          'Restored file size mismatch: ${file.id}',
        );
      }

      restoredFiles.add(
        file.copyWith(
          filePath: outputFile.path,
        ),
      );
    }

    // =========================================================================
    // FINAL VALIDATION BEFORE TOUCHING HIVE
    // =========================================================================

    for (final media in restoredMedia) {
      final file = File(media.filePath);

      if (!await file.exists()) {
        throw StateError(
          'Restored media file does not exist: ${media.id}',
        );
      }
    }

    for (final fileItem in restoredFiles) {
      final file = File(fileItem.filePath);

      if (!await file.exists()) {
        throw StateError(
          'Restored file does not exist: ${fileItem.id}',
        );
      }
    }

    // =========================================================================
    // ADD ONLY NEW DATA TO HIVE
    // =========================================================================
    //
    // IMPORTANT:
    // No Hive box is cleared.
    // Existing records are never replaced or deleted.

    // -------------------------------------------------------------------------
    // RESTORE VAULT
    // -------------------------------------------------------------------------

    for (final item in vaultItems) {
      await _hiveService.putItem(item);
    }

    // -------------------------------------------------------------------------
    // RESTORE BOOKMARKS
    // -------------------------------------------------------------------------

    for (final bookmark in bookmarks) {
      await _hiveService.putBookmark(bookmark);
    }

    // -------------------------------------------------------------------------
    // RESTORE FOLDERS
    // -------------------------------------------------------------------------

    for (final folder in folders) {
      await _hiveService.putFolder(folder);
    }

    // -------------------------------------------------------------------------
    // RESTORE MEDIA
    // -------------------------------------------------------------------------

    for (final media in restoredMedia) {
      await _hiveService.putMedia(media);
    }

    // -------------------------------------------------------------------------
    // RESTORE FILES
    // -------------------------------------------------------------------------

    for (final file in restoredFiles) {
      await _hiveService.putFile(file);
    }

    await transferTempDirectory.delete(recursive: true);
  }

  // ===========================================================================
  // RESTORE ALIASES
  // ===========================================================================

  Future<void> restoreIncrementalFromGoogleDrive() async {
    await restoreFromGoogleDrive();
  }

  Future<void> restoreIncrementalBackup() async {
    await restoreFromGoogleDrive();
  }

  // ===========================================================================
  // LIST CLOUD OBJECTS INTERNALLY
  // ===========================================================================
  //
  // IMPORTANT:
  //
  // Google Drive appDataFolder can contain multiple files with exactly the
  // same name.
  //
  // Older versions of the backup logic may have created duplicates instead
  // of updating the existing object.
  //
  // The previous implementation threw:
  //
  //   Duplicate Keeply cloud object name
  //
  // which caused the entire Restore operation to fail.
  //
  // We now handle duplicates safely:
  //
  // 1. Keep the first object.
  // 2. If another object has the same name, compare timestamps.
  // 3. Keep the newest object.
  // 4. Never fail merely because duplicate names exist.
  //
  // We intentionally do NOT delete the older duplicate here.
  // This prevents accidental destruction of cloud data.
  //
  // The selected object is then used by both Backup and Restore.
  // ===========================================================================

  Future<void> _runConcurrent<T>(
    Iterable<T> items, {
    required int maxConcurrency,
    required Future<void> Function(T item) task,
  }) async {
    final queue = items.toList(growable: false);
    if (queue.isEmpty) return;

    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        if (nextIndex >= queue.length) return;
        final index = nextIndex++;
        await task(queue[index]);
      }
    }

    final workerCount =
        maxConcurrency < queue.length ? maxConcurrency : queue.length;

    await Future.wait(
      List<Future<void>>.generate(
        workerCount,
        (_) => worker(),
      ),
    );
  }

  Future<Map<String, drive.File>> _listIncrementalCloudObjects({
    Set<BackupSection>? sections,
  }) async {
    final prefixes = <String>[];

    final selected = sections ?? BackupSection.values.toSet();

    if (selected.contains(BackupSection.passwords)) {
      prefixes.add(_vaultPrefix);
    }
    if (selected.contains(BackupSection.bookmarks)) {
      prefixes.add(_bookmarkPrefix);
    }
    if (selected.contains(BackupSection.media)) {
      prefixes.add(_mediaMetaPrefix);
      prefixes.add(_mediaDataPrefix);
    }
    if (selected.contains(BackupSection.documents)) {
      prefixes.add(_folderPrefix);
      prefixes.add(_fileMetaPrefix);
      prefixes.add(_fileDataPrefix);
    }

    final allFiles = await _googleDriveService.listIncrementalFilesByPrefixes(
      prefixes,
    );

    final result = <String, drive.File>{};

    for (final file in allFiles) {
      final name = file.name;

      if (name == null || name.isEmpty) {
        continue;
      }

      if (!_isIncrementalObjectName(name)) {
        continue;
      }

      if (!name.toLowerCase().endsWith('.svm')) {
        continue;
      }

      final existing = result[name];

      // -----------------------------------------------------------------------
      // FIRST OBJECT WITH THIS NAME
      // -----------------------------------------------------------------------

      if (existing == null) {
        result[name] = file;
        continue;
      }

      // -----------------------------------------------------------------------
      // DUPLICATE OBJECT NAME
      // -----------------------------------------------------------------------
      //
      // Do not throw.
      //
      // Choose the newest object.
      // modifiedTime is preferred because an object can be updated after
      // creation. createdTime is used as fallback.
      // -----------------------------------------------------------------------

      final existingTime = existing.modifiedTime ?? existing.createdTime;

      final currentTime = file.modifiedTime ?? file.createdTime;

      // If neither object has a timestamp, keep the first object returned
      // by Google Drive rather than making an arbitrary destructive choice.
      if (existingTime == null && currentTime == null) {
        continue;
      }

      // Existing object has no timestamp but current object does.
      if (existingTime == null && currentTime != null) {
        result[name] = file;
        continue;
      }

      // Current object has no timestamp but existing object does.
      if (existingTime != null && currentTime == null) {
        continue;
      }

      // Both have timestamps.
      if (existingTime != null &&
          currentTime != null &&
          currentTime.isAfter(existingTime)) {
        result[name] = file;
      }
    }

    return result;
  }

  // ===========================================================================
  // OBJECT NAME VALIDATION
  // ===========================================================================

  bool _isIncrementalObjectName(
    String name,
  ) {
    return name.startsWith(_vaultPrefix) ||
        name.startsWith(_bookmarkPrefix) ||
        name.startsWith(_folderPrefix) ||
        name.startsWith(_mediaMetaPrefix) ||
        name.startsWith(_mediaDataPrefix) ||
        name.startsWith(_fileMetaPrefix) ||
        name.startsWith(_fileDataPrefix);
  }

  String? _incrementalKindForName(
    String name,
  ) {
    if (name.startsWith(_vaultPrefix)) {
      return 'vault';
    }

    if (name.startsWith(_bookmarkPrefix)) {
      return 'bookmark';
    }

    if (name.startsWith(_folderPrefix)) {
      return 'folder';
    }

    if (name.startsWith(_mediaMetaPrefix)) {
      return 'media_meta';
    }

    if (name.startsWith(_mediaDataPrefix)) {
      return 'media_data';
    }

    if (name.startsWith(_fileMetaPrefix)) {
      return 'file_meta';
    }

    if (name.startsWith(_fileDataPrefix)) {
      return 'file_data';
    }

    return null;
  }

  // ===========================================================================
  // DESCRIPTION
  // ===========================================================================

  String _buildDescription({
    required String kind,
    required String id,
    required String hash,
  }) {
    return '$_descriptionHeader'
        '|$_versionKey=$_version'
        '|$_kindKey=$kind'
        '|$_idKey=$id'
        '|$_hashKey=$hash'
        '|encrypted=false';
  }

  Map<String, String> _parseIncrementalDescription(
    String? description,
  ) {
    if (description == null || description.isEmpty) {
      throw const FormatException(
        'Incremental cloud object description is missing.',
      );
    }

    final parts = description.split('|');

    if (parts.isEmpty || parts.first != _descriptionHeader) {
      throw const FormatException(
        'Invalid Keeply incremental description.',
      );
    }

    final result = <String, String>{};

    for (final part in parts.skip(1)) {
      final separator = part.indexOf('=');

      if (separator <= 0 || separator >= part.length - 1) {
        continue;
      }

      final key = part.substring(
        0,
        separator,
      );

      final value = part.substring(
        separator + 1,
      );

      result[key] = value;
    }

    if (result[_versionKey] != _version) {
      throw FormatException(
        'Unsupported incremental cloud version: '
        '${result[_versionKey]}',
      );
    }

    final hash = result[_hashKey];

    if (hash == null || hash.length != 64 || !_isValidSha256(hash)) {
      throw const FormatException(
        'Invalid incremental SHA-256.',
      );
    }

    return result;
  }

  bool _isValidIncrementalDescription(
    String? description, {
    required String expectedKind,
    required String expectedId,
  }) {
    try {
      final parsed = _parseIncrementalDescription(
        description,
      );

      return parsed[_kindKey] == expectedKind &&
          parsed[_idKey] == expectedId &&
          parsed[_hashKey] != null;
    } catch (_) {
      return false;
    }
  }

  String? _extractHashFromDescription(
    String? description,
  ) {
    try {
      final parsed = _parseIncrementalDescription(
        description,
      );

      return parsed[_hashKey];
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // SHA-256
  // ===========================================================================

  Future<String> _sha256File(File file) async {
    final sink = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(sink);

    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();

    return sink.events.single.toString();
  }

  String _safeTransferFileName(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  String _sha256(
    List<int> bytes,
  ) {
    return sha256.convert(bytes).toString();
  }

  bool _isValidSha256(
    String value,
  ) {
    return RegExp(
      r'^[a-fA-F0-9]{64}$',
    ).hasMatch(value);
  }

  // ===========================================================================
  // INCREMENTAL ID VALIDATION
  // ===========================================================================

  void _validateIncrementalIdentity({
    required String cloudName,
    required String kind,
    required String objectId,
  }) {
    if (objectId.isEmpty) {
      throw StateError(
        'Cloud object ID is empty: $cloudName',
      );
    }

    String expectedPrefix;

    switch (kind) {
      case 'vault':
        expectedPrefix = _vaultPrefix;
        break;

      case 'bookmark':
        expectedPrefix = _bookmarkPrefix;
        break;

      case 'folder':
        expectedPrefix = _folderPrefix;
        break;

      case 'media_meta':
        expectedPrefix = _mediaMetaPrefix;
        break;

      case 'media_data':
        expectedPrefix = _mediaDataPrefix;
        break;

      case 'file_meta':
        expectedPrefix = _fileMetaPrefix;
        break;

      case 'file_data':
        expectedPrefix = _fileDataPrefix;
        break;

      default:
        throw StateError(
          'Unknown incremental kind: $kind',
        );
    }

    final expectedName = '$expectedPrefix$objectId.svm';

    if (cloudName != expectedName) {
      throw StateError(
        'Cloud object name/ID mismatch: $cloudName',
      );
    }
  }

  // ===========================================================================
  // RESTORE DIRECTORY
  // ===========================================================================

  /// Creates a persistent restore directory inside the application's
  /// documents directory.
  ///
  /// We intentionally do NOT use systemTemp because the operating system
  /// may delete temporary files.
  Future<Directory> _createRestoreDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final restoreDirectory = Directory(
      path.join(
        appDirectory.path,
        'Keeply',
        'RestoredBackup',
      ),
    );

    await restoreDirectory.create(
      recursive: true,
    );

    return restoreDirectory;
  }

  String _safeFileName(
    String id,
    String originalName,
  ) {
    var sanitized = originalName
        .replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '_',
        )
        .trim();

    if (sanitized.isEmpty) {
      sanitized = 'file';
    }

    // Prevent pathological file names.
    if (sanitized.length > 180) {
      sanitized = sanitized.substring(
        0,
        180,
      );
    }

    return '${id}_$sanitized';
  }

  // ===========================================================================
  // UNIQUE ID VALIDATION
  // ===========================================================================

  void _ensureUniqueId(
    Iterable<String> existingIds,
    String id,
    String cloudName,
  ) {
    if (existingIds.contains(id)) {
      throw StateError(
        'Duplicate object ID "$id" in cloud object: $cloudName',
      );
    }
  }

  // ===========================================================================
  // JSON SERIALIZATION
  // ===========================================================================

  Map<String, dynamic> _vaultItemToJson(
    VaultItem item,
  ) {
    return <String, dynamic>{
      'id': item.id,
      'emailOrUsername': item.emailOrUsername,
      'password': item.password,
      'description': item.description,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'updatedAt': item.updatedAt.toUtc().toIso8601String(),
    };
  }

  VaultItem _vaultItemFromJson(
    Map<String, dynamic> json,
  ) {
    return VaultItem(
      id: _requiredString(
        json,
        'id',
      ),
      emailOrUsername: _requiredString(
        json,
        'emailOrUsername',
      ),
      password: _requiredString(
        json,
        'password',
      ),
      description: _requiredString(
        json,
        'description',
      ),
      createdAt: _parseDate(
        json,
        'createdAt',
      ),
      updatedAt: _parseDate(
        json,
        'updatedAt',
      ),
    );
  }

  Map<String, dynamic> _bookmarkToJson(
    Bookmark item,
  ) {
    return <String, dynamic>{
      'id': item.id,
      'description': item.description,
      'url': item.url,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'updatedAt': item.updatedAt.toUtc().toIso8601String(),
    };
  }

  Bookmark _bookmarkFromJson(
    Map<String, dynamic> json,
  ) {
    return Bookmark(
      id: _requiredString(
        json,
        'id',
      ),
      description: _requiredString(
        json,
        'description',
      ),
      url: _requiredString(
        json,
        'url',
      ),
      createdAt: _parseDate(
        json,
        'createdAt',
      ),
      updatedAt: _parseDate(
        json,
        'updatedAt',
      ),
    );
  }

  Map<String, dynamic> _mediaItemToJson(
    MediaItem item,
  ) {
    return <String, dynamic>{
      'id': item.id,
      'filePath': item.filePath,
      'fileName': item.fileName,
      'fileType': item.fileType,
      'description': item.description,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'updatedAt': item.updatedAt.toUtc().toIso8601String(),
    };
  }

  MediaItem _mediaItemFromJson(
    Map<String, dynamic> json,
  ) {
    return MediaItem(
      id: _requiredString(
        json,
        'id',
      ),
      filePath: _requiredString(
        json,
        'filePath',
      ),
      fileName: _requiredString(
        json,
        'fileName',
      ),
      fileType: _requiredString(
        json,
        'fileType',
      ),
      description: _requiredString(
        json,
        'description',
      ),
      createdAt: _parseDate(
        json,
        'createdAt',
      ),
      updatedAt: _parseDate(
        json,
        'updatedAt',
      ),
    );
  }

  Map<String, dynamic> _fileItemToJson(
    FileItem item,
  ) {
    return <String, dynamic>{
      'id': item.id,
      'filePath': item.filePath,
      'fileName': item.fileName,
      'fileType': item.fileType,
      'folderId': item.folderId,
      'description': item.description,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'updatedAt': item.updatedAt.toUtc().toIso8601String(),
    };
  }

  FileItem _fileItemFromJson(
    Map<String, dynamic> json,
  ) {
    return FileItem(
      id: _requiredString(
        json,
        'id',
      ),
      filePath: _requiredString(
        json,
        'filePath',
      ),
      fileName: _requiredString(
        json,
        'fileName',
      ),
      fileType: _requiredString(
        json,
        'fileType',
      ),
      folderId: _requiredString(
        json,
        'folderId',
      ),
      description: _requiredString(
        json,
        'description',
      ),
      createdAt: _parseDate(
        json,
        'createdAt',
      ),
      updatedAt: _parseDate(
        json,
        'updatedAt',
      ),
    );
  }

  Map<String, dynamic> _folderItemToJson(
    FolderItem item,
  ) {
    return <String, dynamic>{
      'id': item.id,
      'name': item.name,
      'parentId': item.parentId,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'updatedAt': item.updatedAt.toUtc().toIso8601String(),
    };
  }

  FolderItem _folderItemFromJson(
    Map<String, dynamic> json,
  ) {
    return FolderItem(
      id: _requiredString(
        json,
        'id',
      ),
      name: _requiredString(
        json,
        'name',
      ),
      parentId: _requiredString(
        json,
        'parentId',
      ),
      createdAt: _parseDate(
        json,
        'createdAt',
      ),
      updatedAt: _parseDate(
        json,
        'updatedAt',
      ),
    );
  }

  // ===========================================================================
  // INCREMENTAL JSON DECODING
  // ===========================================================================

  Map<String, dynamic> _decodeIncrementalJson(
    Uint8List bytes,
    String cloudName,
  ) {
    try {
      final decoded = jsonDecode(
        utf8.decode(bytes),
      );

      if (decoded is! Map) {
        throw const FormatException(
          'Incremental object must be a JSON object.',
        );
      }

      return Map<String, dynamic>.from(
        decoded,
      );
    } catch (e) {
      throw FormatException(
        'Invalid incremental JSON object "$cloudName": $e',
      );
    }
  }

  VaultItem _decodeVaultIncrementalObject(
    Uint8List bytes,
    String cloudName,
    String expectedId,
  ) {
    final json = _decodeIncrementalJson(
      bytes,
      cloudName,
    );

    final item = _vaultItemFromJson(json);

    if (item.id != expectedId) {
      throw StateError(
        'Vault object ID mismatch: $cloudName',
      );
    }

    return item;
  }

  Bookmark _decodeBookmarkIncrementalObject(
    Uint8List bytes,
    String cloudName,
    String expectedId,
  ) {
    final json = _decodeIncrementalJson(
      bytes,
      cloudName,
    );

    final item = _bookmarkFromJson(json);

    if (item.id != expectedId) {
      throw StateError(
        'Bookmark object ID mismatch: $cloudName',
      );
    }

    return item;
  }

  FolderItem _decodeFolderIncrementalObject(
    Uint8List bytes,
    String cloudName,
    String expectedId,
  ) {
    final json = _decodeIncrementalJson(
      bytes,
      cloudName,
    );

    final item = _folderItemFromJson(json);

    if (item.id != expectedId) {
      throw StateError(
        'Folder object ID mismatch: $cloudName',
      );
    }

    return item;
  }

  MediaItem _decodeMediaIncrementalObject(
    Uint8List bytes,
    String cloudName,
    String expectedId,
  ) {
    final json = _decodeIncrementalJson(
      bytes,
      cloudName,
    );

    final item = _mediaItemFromJson(json);

    if (item.id != expectedId) {
      throw StateError(
        'Media object ID mismatch: $cloudName',
      );
    }

    return item;
  }

  FileItem _decodeFileIncrementalObject(
    Uint8List bytes,
    String cloudName,
    String expectedId,
  ) {
    final json = _decodeIncrementalJson(
      bytes,
      cloudName,
    );

    final item = _fileItemFromJson(json);

    if (item.id != expectedId) {
      throw StateError(
        'File object ID mismatch: $cloudName',
      );
    }

    return item;
  }

  // ===========================================================================
  // PRIMITIVE HELPERS
  // ===========================================================================

  String _requiredString(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];

    if (value is! String) {
      throw FormatException(
        'Missing or invalid "$key".',
      );
    }

    return value;
  }

  DateTime _parseDate(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = _requiredString(
      json,
      key,
    );

    try {
      return DateTime.parse(value);
    } catch (e) {
      throw FormatException(
        'Invalid date in "$key": $e',
      );
    }
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  Future<String> _sha256IncrementalObject(
    _IncrementalObject object,
  ) async {
    final bytes = object.content;
    if (bytes != null) return _sha256(bytes);

    final file = object.file;
    if (file == null) throw StateError('Incremental object has no source.');

    final sink = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(sink);

    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();

    final digest = sink.events.single;
    return digest.toString();
  }

  Future<int> _sumPendingUploadBytes(
    List<_PendingUpload> uploads,
  ) async {
    var total = 0;
    for (final upload in uploads) {
      total += await upload.localObject.length;
    }
    return total;
  }

  Future<drive.File> _uploadPendingObject(
    _PendingUpload pending, {
    required String description,
    required CloudTransferProgress onProgress,
  }) async {
    final object = pending.localObject;
    final file = object.file;

    if (file != null) {
      if (pending.isUpdate) {
        return _googleDriveService.updateAppDataFileFromFile(
          fileId: pending.fileId!,
          file: file,
          description: description,
          mimeType: object.mimeType,
          name: object.name,
          onProgress: onProgress,
        );
      }

      return _googleDriveService.uploadAppDataFileFromFile(
        name: object.name,
        file: file,
        mimeType: object.mimeType,
        description: description,
        onProgress: onProgress,
      );
    }

    final bytes = object.content;
    if (bytes == null) {
      throw StateError('Incremental object has no content.');
    }

    if (pending.isUpdate) {
      return _googleDriveService.updateAppDataFile(
        fileId: pending.fileId!,
        bytes: bytes,
        description: description,
        mimeType: object.mimeType,
        name: object.name,
        onProgress: onProgress,
      );
    }

    return _googleDriveService.uploadAppDataFile(
      name: object.name,
      bytes: bytes,
      mimeType: object.mimeType,
      description: description,
      onProgress: onProgress,
    );
  }

  void _ensureGoogleConnected() {
    if (!_googleDriveService.isConnected ||
        _googleDriveService.driveApi == null) {
      throw StateError(
        'Google Drive is not connected.',
      );
    }
  }

  // ===========================================================================
  // UNUSED DEPENDENCIES
  // ===========================================================================

  EncryptionService get encryptionService {
    return _encryptionService;
  }

  SecureStorageService get secureStorage {
    return _secureStorage;
  }
}

// =============================================================================
// INCREMENTAL OBJECT
// =============================================================================

class _PendingUpload {
  const _PendingUpload({
    required this.localObject,
    required this.isUpdate,
    required this.hash,
    this.fileId,
  });

  final _IncrementalObject localObject;
  final bool isUpdate;
  final String hash;
  final String? fileId;
}

class _IncrementalObject {
  const _IncrementalObject({
    required this.name,
    required this.kind,
    required this.id,
    this.content,
    this.file,
    required this.mimeType,
  }) : assert(content != null || file != null);

  final String name;

  final String kind;

  final String id;

  final Uint8List? content;

  final File? file;

  final String mimeType;

  Future<int> get length async {
    final bytes = content;
    if (bytes != null) return bytes.length;
    final source = file;
    if (source == null) throw StateError('Incremental object has no source.');
    return source.length();
  }
}

// =============================================================================
// BACKUP RESULT
// =============================================================================

class IncrementalBackupResult {
  const IncrementalBackupResult({
    required this.created,
    required this.updated,
    required this.skipped,
    required this.deleted,
    required this.uploadedBytes,
    required this.representativeFile,
  });

  final int created;

  final int updated;

  final int skipped;

  final int deleted;

  final int uploadedBytes;

  final drive.File? representativeFile;

  int get examined {
    return created + updated + skipped;
  }

  bool get nothingUploaded {
    return created == 0 && updated == 0;
  }

  @override
  String toString() {
    return 'IncrementalBackupResult('
        'created: $created, '
        'updated: $updated, '
        'skipped: $skipped, '
        'deleted: $deleted, '
        'uploadedBytes: $uploadedBytes, '
        'examined: $examined'
        ')';
  }
}
