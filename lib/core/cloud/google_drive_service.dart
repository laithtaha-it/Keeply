import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

typedef CloudTransferProgress = void Function(int transferredBytes);

/// Google Drive service for Keeply.
///
/// Keeply uses Google's private appDataFolder.
///
/// Incremental backup design:
/// - New local backup objects are uploaded as new Drive files.
/// - Unchanged objects are NOT uploaded again.
/// - Changed objects update the existing Drive file using its fileId.
/// - Deleted local objects can be deleted from Drive using their fileId.
/// - Restore reads the individual Keeply files from appDataFolder.
///
/// IMPORTANT:
/// This service does NOT create or use one monolithic .svb backup file.
class GoogleDriveService {
  GoogleDriveService();

  // ===========================================================================
  // GOOGLE SIGN-IN
  // ===========================================================================

  static const List<String> _scopes = <String>[
    drive.DriveApi.driveAppdataScope,
  ];

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  GoogleSignInAccount? _currentUser;

  drive.DriveApi? _driveApi;

  // ===========================================================================
  // GETTERS
  // ===========================================================================

  GoogleSignInAccount? get currentUser {
    return _currentUser;
  }

  drive.DriveApi? get driveApi {
    return _driveApi;
  }

  bool get isConnected {
    return _currentUser != null && _driveApi != null;
  }

  String? get email {
    return _currentUser?.email;
  }

  String? get displayName {
    return _currentUser?.displayName;
  }

  String? get photoUrl {
    return _currentUser?.photoUrl;
  }

  // ===========================================================================
  // SIGN IN
  // ===========================================================================

  Future<GoogleSignInAccount?> signIn() async {
    final account = await _googleSignIn.signIn();

    if (account == null) {
      return null;
    }

    await _initializeDriveApi(account);

    return account;
  }

  // ===========================================================================
  // SILENT SIGN IN
  // ===========================================================================

  Future<GoogleSignInAccount?> signInSilently() async {
    final account = await _googleSignIn.signInSilently();

    if (account == null) {
      return null;
    }

    await _initializeDriveApi(account);

    return account;
  }

  // ===========================================================================
  // INITIALIZE DRIVE API
  // ===========================================================================

  Future<void> _initializeDriveApi(
    GoogleSignInAccount account,
  ) async {
    final authHeaders = await account.authHeaders;

    if (authHeaders.isEmpty) {
      throw StateError(
        'Unable to obtain Google authentication headers.',
      );
    }

    final client = _GoogleAuthClient(
      authHeaders,
    );

    _currentUser = account;

    _driveApi = drive.DriveApi(
      client,
    );
  }

  // ===========================================================================
  // SIGN OUT
  // ===========================================================================

  Future<void> signOut() async {
    _driveApi = null;
    _currentUser = null;

    await _googleSignIn.signOut();
  }

  // ===========================================================================
  // DISCONNECT
  // ===========================================================================

  Future<void> disconnect() async {
    _driveApi = null;
    _currentUser = null;

    await _googleSignIn.disconnect();
  }

  // ===========================================================================
  // REQUEST DRIVE ACCESS
  // ===========================================================================

  Future<bool> requestDriveAccess() async {
    if (_currentUser == null) {
      return false;
    }

    final granted = await _googleSignIn.requestScopes(
      _scopes,
    );

    if (!granted) {
      return false;
    }

    await _initializeDriveApi(
      _currentUser!,
    );

    return true;
  }

  // ===========================================================================
  // UPLOAD NEW APP DATA FILE
  // ===========================================================================
  //
  // Use this ONLY for a file that does not already exist on Google Drive.
  //
  // For incremental backup:
  //   new object -> uploadAppDataFile()
  //
  // Existing object:
  //   changed object -> updateAppDataFile()
  //
  // Unchanged object:
  //   do nothing
  //
  // ===========================================================================

  Future<drive.File> uploadAppDataFile({
    required String name,
    required List<int> bytes,
    String mimeType = 'application/octet-stream',
    String? description,
    CloudTransferProgress? onProgress,
  }) async {
    final api = _requireDriveApi();

    _validateFileName(name);
    _validateBytes(bytes);

    final metadata = drive.File()
      ..name = name
      ..mimeType = mimeType
      ..parents = <String>[
        'appDataFolder',
      ];

    if (description != null) {
      metadata.description = description;
    }

    final data = Uint8List.fromList(
      bytes,
    );

    final media = drive.Media(
      _progressStream(
        data,
        onProgress,
      ),
      data.length,
    );

    final uploaded = await api.files.create(
      metadata,
      uploadMedia: media,
      uploadOptions: drive.ResumableUploadOptions(
        chunkSize: 4 * 1024 * 1024,
      ),
      $fields:
          'id,name,mimeType,size,description,createdTime,modifiedTime,parents',
    );

    _validateReturnedFile(
      uploaded,
      operation: 'upload',
    );

    return uploaded;
  }

  // ===========================================================================
  // STREAM FILE UPLOAD
  // ===========================================================================

  Future<drive.File> uploadAppDataFileFromFile({
    required String name,
    required File file,
    String mimeType = 'application/octet-stream',
    String? description,
    CloudTransferProgress? onProgress,
  }) async {
    final api = _requireDriveApi();
    _validateFileName(name);

    if (!await file.exists()) {
      throw FileSystemException('File does not exist.', file.path);
    }

    final length = await file.length();
    if (length <= 0) {
      throw const FormatException('Cannot upload an empty Google Drive file.');
    }

    final metadata = drive.File()
      ..name = name
      ..mimeType = mimeType
      ..parents = <String>['appDataFolder'];

    if (description != null) metadata.description = description;

    final media = drive.Media(
      _progressFileStream(file, onProgress),
      length,
    );

    final uploaded = await api.files.create(
      metadata,
      uploadMedia: media,
      uploadOptions: drive.ResumableUploadOptions(
        chunkSize: 4 * 1024 * 1024,
      ),
      $fields:
          'id,name,mimeType,size,description,createdTime,modifiedTime,parents',
    );

    _validateReturnedFile(uploaded, operation: 'upload');
    return uploaded;
  }

  Future<drive.File> updateAppDataFileFromFile({
    required String fileId,
    required File file,
    String? description,
    String? mimeType,
    String? name,
    CloudTransferProgress? onProgress,
  }) async {
    final api = _requireDriveApi();
    _validateFileId(fileId);

    if (!await file.exists()) {
      throw FileSystemException('File does not exist.', file.path);
    }

    final length = await file.length();
    if (length <= 0) {
      throw const FormatException('Cannot upload an empty Google Drive file.');
    }

    final metadata = drive.File();
    if (name != null && name.trim().isNotEmpty) metadata.name = name;
    if (description != null) metadata.description = description;
    if (mimeType != null) metadata.mimeType = mimeType;

    final media = drive.Media(
      _progressFileStream(file, onProgress),
      length,
    );

    final updated = await api.files.update(
      metadata,
      fileId,
      uploadMedia: media,
      uploadOptions: drive.ResumableUploadOptions(
        chunkSize: 4 * 1024 * 1024,
      ),
      $fields:
          'id,name,mimeType,size,description,createdTime,modifiedTime,parents',
    );

    _validateReturnedFile(updated, operation: 'update');
    return updated;
  }

  // ===========================================================================
  // UPDATE EXISTING APP DATA FILE
  // ===========================================================================
  //
  // IMPORTANT:
  // This updates the EXISTING Google Drive file using its fileId.
  //
  // It does NOT create another Drive file.
  //
  // This is the method that should be used when an incremental object
  // already exists remotely but its content has changed.
  //
  // ===========================================================================

  Future<drive.File> updateAppDataFile({
    required String fileId,
    required List<int> bytes,
    String? description,
    String? mimeType,
    String? name,
    CloudTransferProgress? onProgress,
  }) async {
    final api = _requireDriveApi();

    _validateFileId(fileId);
    _validateBytes(bytes);

    final metadata = drive.File();

    if (name != null && name.trim().isNotEmpty) {
      metadata.name = name;
    }

    if (description != null) {
      metadata.description = description;
    }

    if (mimeType != null) {
      metadata.mimeType = mimeType;
    }

    final data = Uint8List.fromList(
      bytes,
    );

    final media = drive.Media(
      _progressStream(
        data,
        onProgress,
      ),
      data.length,
    );

    final updated = await api.files.update(
      metadata,
      fileId,
      uploadMedia: media,
      uploadOptions: drive.ResumableUploadOptions(
        chunkSize: 4 * 1024 * 1024,
      ),
      $fields:
          'id,name,mimeType,size,description,createdTime,modifiedTime,parents',
    );

    _validateReturnedFile(
      updated,
      operation: 'update',
    );

    return updated;
  }

  // ===========================================================================
  // UPLOAD OR UPDATE
  // ===========================================================================
  //
  // Convenience method for Incremental Backup.
  //
  // If fileId is provided:
  //     update the existing Drive file.
  //
  // If fileId is null:
  //     create a new Drive file.
  //
  // This method does NOT determine whether the data changed.
  // The BackupService should compare the local object/version/hash first.
  //
  // ===========================================================================

  Future<drive.File> uploadOrUpdateAppDataFile({
    required String name,
    required List<int> bytes,
    String? fileId,
    String mimeType = 'application/octet-stream',
    String? description,
  }) async {
    if (fileId != null && fileId.trim().isNotEmpty) {
      return updateAppDataFile(
        fileId: fileId,
        bytes: bytes,
        description: description,
        mimeType: mimeType,
        name: name,
      );
    }

    return uploadAppDataFile(
      name: name,
      bytes: bytes,
      mimeType: mimeType,
      description: description,
    );
  }

  // ===========================================================================
  // LIST ALL APP DATA FILES
  // ===========================================================================
  //
  // Returns every non-trashed file belonging to Keeply's appDataFolder.
  //
  // This method handles pagination correctly.
  //
  // ===========================================================================

  Future<List<drive.File>> listAllAppDataFiles() async {
    final api = _requireDriveApi();

    final result = <drive.File>[];

    String? pageToken;

    do {
      final response = await api.files.list(
        spaces: 'appDataFolder',
        q: "'appDataFolder' in parents and trashed = false",
        $fields:
            'nextPageToken,files(id,name,mimeType,size,description,createdTime,modifiedTime,parents)',
        pageSize: 1000,
        pageToken: pageToken,
        orderBy: 'name',
      );

      final files = response.files;

      if (files != null && files.isNotEmpty) {
        result.addAll(
          files,
        );
      }

      pageToken = response.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);

    return result;
  }

  // ===========================================================================
  // LIST KEEPLY INCREMENTAL FILES BY PREFIX
  // ===========================================================================
  //
  // Query only the requested Keeply sections. This avoids retrieving unrelated
  // appDataFolder metadata during selective backup/restore.
  //
  Future<List<drive.File>> listIncrementalFilesByPrefixes(
    Iterable<String> prefixes,
  ) async {
    final api = _requireDriveApi();

    final uniquePrefixes = prefixes
        .where((prefix) => prefix.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (uniquePrefixes.isEmpty) {
      return <drive.File>[];
    }

    final prefixQuery = uniquePrefixes
        .map(
          (prefix) => "name contains '${_escapeDriveQueryValue(prefix)}'",
        )
        .join(' or ');

    final result = <drive.File>[];
    String? pageToken;

    do {
      final response = await api.files.list(
        spaces: 'appDataFolder',
        q: "'appDataFolder' in parents and trashed = false "
            "and ($prefixQuery)",
        $fields:
            'nextPageToken,files(id,name,mimeType,size,description,createdTime,modifiedTime,parents)',
        pageSize: 1000,
        pageToken: pageToken,
        orderBy: 'name',
      );

      final files = response.files;
      if (files != null && files.isNotEmpty) {
        result.addAll(files);
      }

      pageToken = response.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);

    return result;
  }

  // ===========================================================================
  // LIST KEEPLY INCREMENTAL FILES
  // ===========================================================================
  //
  // Returns only Keeply's incremental backup objects.
  //
  // Examples:
  //
  // Keeply_Vault_abc123.svm
  // Keeply_Vault_xyz456.svm
  // Keeply_Bookmark_abc123.svm
  //
  // Any unrelated appDataFolder files are ignored.
  //
  // ===========================================================================

  Future<List<drive.File>> listKeeplyFiles() async {
    final files = await listAllAppDataFiles();

    return files.where(
      (file) {
        final name = file.name;

        if (name == null || name.isEmpty) {
          return false;
        }

        return _isKeeplyBackupFileName(
          name,
        );
      },
    ).toList();
  }

  // ===========================================================================
  // LIST INCREMENTAL BACKUP FILES
  // ===========================================================================
  //
  // Alias specifically for BackupService.
  //
  // ===========================================================================

  Future<List<drive.File>> listIncrementalBackupFiles() async {
    return listKeeplyFiles();
  }

  // ===========================================================================
  // FIND FILE BY NAME
  // ===========================================================================
  //
  // Finds a single Keeply file by exact name.
  //
  // This is useful when BackupService has a stable object name but does not
  // yet have the remote fileId.
  //
  // ===========================================================================

  Future<drive.File?> findAppDataFileByName(
    String name,
  ) async {
    final api = _requireDriveApi();

    _validateFileName(name);

    final escapedName = _escapeDriveQueryValue(
      name,
    );

    final response = await api.files.list(
      spaces: 'appDataFolder',
      q: "'appDataFolder' in parents "
          "and name = '$escapedName' "
          'and trashed = false',
      $fields:
          'files(id,name,mimeType,size,description,createdTime,modifiedTime,parents)',
      pageSize: 100,
    );

    final files = response.files;

    if (files == null || files.isEmpty) {
      return null;
    }

    return files.first;
  }

  // ===========================================================================
  // FIND ALL FILES BY NAME
  // ===========================================================================
  //
  // Normally a stable Keeply object name should map to one remote file.
  //
  // This method exists to safely inspect duplicates if they ever occur.
  //
  // ===========================================================================

  Future<List<drive.File>> findAllAppDataFilesByName(
    String name,
  ) async {
    final api = _requireDriveApi();

    _validateFileName(name);

    final escapedName = _escapeDriveQueryValue(
      name,
    );

    final result = <drive.File>[];

    String? pageToken;

    do {
      final response = await api.files.list(
        spaces: 'appDataFolder',
        q: "'appDataFolder' in parents "
            "and name = '$escapedName' "
            'and trashed = false',
        $fields:
            'nextPageToken,files(id,name,mimeType,size,description,createdTime,modifiedTime,parents)',
        pageSize: 100,
        pageToken: pageToken,
      );

      final files = response.files;

      if (files != null && files.isNotEmpty) {
        result.addAll(
          files,
        );
      }

      pageToken = response.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);

    return result;
  }

  // ===========================================================================
  // FIND FILE BY ID
  // ===========================================================================
  //
  // Fetches metadata for a specific Drive file.
  //
  // Useful for verifying that a stored remote fileId still exists.
  //
  // ===========================================================================

  Future<drive.File?> getAppDataFile(
    String fileId,
  ) async {
    final api = _requireDriveApi();

    _validateFileId(fileId);

    try {
      final file = await api.files.get(
        fileId,
        $fields:
            'id,name,mimeType,size,description,createdTime,modifiedTime,parents,trashed',
      );

      if (file is! drive.File) {
        return null;
      }

      if (file.trashed == true) {
        return null;
      }

      return file;
    } on drive.DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        return null;
      }

      rethrow;
    }
  }

  // ===========================================================================
  // DOWNLOAD APP DATA FILE
  // ===========================================================================
  //
  // Downloads one incremental backup object.
  //
  // Restore should call this once for each Keeply remote object.
  //
  // ===========================================================================

  Future<Uint8List> downloadAppDataFile(
    String fileId, {
    CloudTransferProgress? onProgress,
  }) async {
    final api = _requireDriveApi();

    _validateFileId(fileId);

    final response = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (response is! drive.Media) {
      throw StateError(
        'Google Drive did not return media data.',
      );
    }

    final bytes = <int>[];
    var transferred = 0;

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      transferred += chunk.length;
      onProgress?.call(transferred);
    }

    if (bytes.isEmpty) {
      throw StateError(
        'Downloaded Google Drive file is empty.',
      );
    }

    return Uint8List.fromList(
      bytes,
    );
  }

  // ===========================================================================
  // STREAM DOWNLOAD TO FILE
  // ===========================================================================

  Future<File> downloadAppDataFileToFile(
    String fileId,
    File destination, {
    CloudTransferProgress? onProgress,
  }) async {
    final api = _requireDriveApi();
    _validateFileId(fileId);

    await destination.parent.create(recursive: true);

    final response = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (response is! drive.Media) {
      throw StateError('Google Drive did not return media data.');
    }

    final sink = destination.openWrite();
    var transferred = 0;

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        transferred += chunk.length;
        onProgress?.call(transferred);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    if (transferred == 0) {
      throw StateError('Downloaded Google Drive file is empty.');
    }

    return destination;
  }

  // ===========================================================================
  // DELETE APP DATA FILE
  // ===========================================================================
  //
  // Deletes the remote object by fileId.
  //
  // This is used when a local Keeply object was deleted.
  //
  // ===========================================================================

  Future<void> deleteAppDataFile(
    String fileId,
  ) async {
    final api = _requireDriveApi();

    _validateFileId(fileId);

    try {
      await api.files.delete(
        fileId,
      );
    } on drive.DetailedApiRequestError catch (e) {
      // If the file is already gone, the desired final state is already
      // achieved. Therefore a 404 is treated as success.
      if (e.status == 404) {
        return;
      }

      rethrow;
    }
  }

  // ===========================================================================
  // DELETE MULTIPLE APP DATA FILES
  // ===========================================================================
  //
  // Deletes multiple remote objects.
  //
  // Useful for the Incremental Backup cleanup phase.
  //
  // ===========================================================================

  Future<void> deleteAppDataFiles(
    Iterable<String> fileIds,
  ) async {
    for (final fileId in fileIds) {
      final normalizedId = fileId.trim();

      if (normalizedId.isEmpty) {
        continue;
      }

      await deleteAppDataFile(
        normalizedId,
      );
    }
  }

  // ===========================================================================
  // DELETE KEEPLY FILE BY NAME
  // ===========================================================================
  //
  // Deletes every active Keeply appDataFolder file having this exact name.
  //
  // Normally you should prefer deleteAppDataFile(fileId), because fileId is
  // the safest identity for an existing remote object.
  //
  // ===========================================================================

  Future<int> deleteAppDataFilesByName(
    String name,
  ) async {
    final files = await findAllAppDataFilesByName(
      name,
    );

    var deletedCount = 0;

    for (final file in files) {
      final fileId = file.id;

      if (fileId == null || fileId.isEmpty) {
        continue;
      }

      await deleteAppDataFile(
        fileId,
      );

      deletedCount++;
    }

    return deletedCount;
  }

  // ===========================================================================
  // GET DRIVE INFORMATION
  // ===========================================================================

  Future<drive.About?> getDriveAbout() async {
    final api = _requireDriveApi();

    return api.about.get(
      $fields:
          'user(displayName,emailAddress,photoLink),storageQuota(limit,usage)',
    );
  }

  // ===========================================================================
  // COUNT KEEPLY FILES
  // ===========================================================================

  Future<int> countKeeplyFiles() async {
    final files = await listKeeplyFiles();

    return files.length;
  }

  // ===========================================================================
  // CHECK WHETHER A FILE EXISTS
  // ===========================================================================

  Future<bool> appDataFileExists(
    String fileId,
  ) async {
    final file = await getAppDataFile(
      fileId,
    );

    return file != null;
  }

  // ===========================================================================
  // REQUIRE DRIVE API
  // ===========================================================================

  drive.DriveApi _requireDriveApi() {
    final api = _driveApi;

    if (api == null) {
      throw StateError(
        'Google Drive is not connected.',
      );
    }

    return api;
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  void _validateFileName(
    String name,
  ) {
    if (name.trim().isEmpty) {
      throw const FormatException(
        'Google Drive file name cannot be empty.',
      );
    }
  }

  void _validateFileId(
    String fileId,
  ) {
    if (fileId.trim().isEmpty) {
      throw const FormatException(
        'Google Drive file ID cannot be empty.',
      );
    }
  }

  Stream<List<int>> _progressStream(
    Uint8List data,
    CloudTransferProgress? onProgress,
  ) async* {
    const chunkSize = 256 * 1024;
    var transferred = 0;

    for (var offset = 0; offset < data.length; offset += chunkSize) {
      final end =
          (offset + chunkSize < data.length) ? offset + chunkSize : data.length;
      final chunk = data.sublist(offset, end);
      transferred += chunk.length;
      onProgress?.call(transferred);
      yield chunk;
    }
  }

  Stream<List<int>> _progressFileStream(
    File file,
    CloudTransferProgress? onProgress,
  ) async* {
    var transferred = 0;

    await for (final chunk in file.openRead()) {
      // openRead may emit chunks smaller than our preferred upload chunk;
      // Drive's resumable uploader handles the actual network chunking.
      transferred += chunk.length;
      onProgress?.call(transferred);
      yield chunk;
    }
  }

  void _validateBytes(
    List<int> bytes,
  ) {
    if (bytes.isEmpty) {
      throw const FormatException(
        'Cannot upload an empty Google Drive file.',
      );
    }
  }

  void _validateReturnedFile(
    drive.File file, {
    required String operation,
  }) {
    final id = file.id;

    if (id == null || id.isEmpty) {
      throw StateError(
        'Google Drive did not return a valid file ID after $operation.',
      );
    }
  }

  // ===========================================================================
  // KEEPLY FILE NAME CHECK
  // ===========================================================================

  bool _isKeeplyBackupFileName(
    String name,
  ) {
    final lower = name.toLowerCase();

    if (!lower.startsWith('keeply_') && !lower.startsWith('securevault_')) {
      return false;
    }

    // Incremental Keeply objects.
    //
    // Current expected format:
    //
    // Keeply_Vault_<id>.svm
    //
    // Keeply_Bookmark_<id>.svm
    //
    // Keeply_Media_<id>.svm
    //
    // Keeply_Doc_<id>.svm
    //
    // More object types can be added without changing this service because
    // the common requirement is Keeply_ + .svm.
    return lower.endsWith('.svm');
  }

  // ===========================================================================
  // GOOGLE DRIVE QUERY ESCAPING
  // ===========================================================================

  String _escapeDriveQueryValue(
    String value,
  ) {
    return value
        .replaceAll(
          r'\',
          r'\\',
        )
        .replaceAll(
          "'",
          r"\'",
        );
  }
}

// =============================================================================
// GOOGLE AUTH HTTP CLIENT
// =============================================================================

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(
    Map<String, String> headers,
  ) : _headers = Map<String, String>.from(
          headers,
        );

  final Map<String, String> _headers;

  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(
    http.BaseRequest request,
  ) {
    request.headers.addAll(
      _headers,
    );

    return _inner.send(
      request,
    );
  }

  @override
  void close() {
    _inner.close();
  }
}
