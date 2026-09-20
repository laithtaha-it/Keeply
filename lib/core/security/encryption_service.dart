import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt;

import 'secure_storage_service.dart';

/// Central encryption service for Keeply.
///
/// Responsibilities:
/// - AES-256-CBC encryption.
/// - Generates a random 256-bit master key on first initialization.
/// - Stores the master key in FlutterSecureStorage.
/// - Supports restoring a master key from a Keeply backup.
/// - Supports strings, binary data and files.
/// - Supports streaming encryption/decryption for large files.
/// - Supports SHA-256 content hashing for true incremental backup.
///
/// IMPORTANT:
///
/// Hashing is performed on PLAINTEXT/source data.
///
/// Encryption still uses a random IV for every encryption operation.
/// Therefore the same plaintext can produce different encrypted bytes,
/// while the SHA-256 content hash remains identical.
///
/// This is exactly what BackupService needs for true incremental backup.
///
/// Streaming encryption format:
///
///   MAGIC
///   CHUNK:
///     4-byte plaintext length
///     16-byte IV
///     AES-256-CBC ciphertext
///
/// Old encryptBytes()/decryptBytes() data remains compatible.
class EncryptionService {
  EncryptionService({
    required SecureStorageService secureStorage,
  }) : _secureStorage = secureStorage;

  final SecureStorageService _secureStorage;

  encrypt.Key? _masterKey;

  // ===========================================================================
  // STREAMING FORMAT
  // ===========================================================================

  static const List<int> _streamMagic = <int>[
    0x53,
    0x56,
    0x53,
    0x31,
  ];

  static const int streamChunkSize = 4 * 1024 * 1024;

  static const int _maxAllowedChunkSize = 4 * 1024 * 1024;

  static const int _chunkLengthBytes = 4;

  static const int _ivLength = 16;

  static const int _aesBlockSize = 16;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  Future<void> initialize() async {
    final storedKey = await _secureStorage.getMasterKey();

    if (storedKey != null && storedKey.isNotEmpty) {
      _masterKey = _keyFromBase64(storedKey);
      return;
    }

    final newKey = _generateMasterKey();

    await _secureStorage.saveMasterKey(
      newKey.base64,
    );

    _masterKey = newKey;
  }

  // ===========================================================================
  // MASTER KEY
  // ===========================================================================

  encrypt.Key _generateMasterKey() {
    final random = Random.secure();

    final bytes = Uint8List.fromList(
      List<int>.generate(
        32,
        (_) => random.nextInt(256),
      ),
    );

    return encrypt.Key(bytes);
  }

  encrypt.Key _keyFromBase64(
    String value,
  ) {
    try {
      final key = encrypt.Key.fromBase64(value);

      if (key.bytes.length != 32) {
        throw const FormatException(
          'Master key is not 256-bit.',
        );
      }

      return key;
    } catch (e) {
      throw StateError(
        'Unable to load the Keeply master key: $e',
      );
    }
  }

  encrypt.Key get _key {
    final key = _masterKey;

    if (key == null) {
      throw StateError(
        'EncryptionService has not been initialized. '
        'Call initialize() before using encryption.',
      );
    }

    return key;
  }

  String exportMasterKey() {
    return _key.base64;
  }

  Future<void> restoreMasterKey(
    String base64Key,
  ) async {
    if (base64Key.trim().isEmpty) {
      throw const FormatException(
        'Backup master key is empty.',
      );
    }

    final restoredKey = _keyFromBase64(
      base64Key.trim(),
    );

    await _secureStorage.saveMasterKey(
      restoredKey.base64,
    );

    _masterKey = restoredKey;
  }

  Uint8List exportMasterKeyBytes() {
    return Uint8List.fromList(
      _key.bytes,
    );
  }

  Future<void> restoreMasterKeyBytes(
    List<int> bytes,
  ) async {
    if (bytes.length != 32) {
      throw const FormatException(
        'Master key must contain exactly 32 bytes.',
      );
    }

    final restoredKey = encrypt.Key(
      Uint8List.fromList(bytes),
    );

    await _secureStorage.saveMasterKey(
      restoredKey.base64,
    );

    _masterKey = restoredKey;
  }

  // ===========================================================================
  // AES ENGINE
  // ===========================================================================

  encrypt.Encrypter get _encrypter {
    return encrypt.Encrypter(
      encrypt.AES(
        _key,
        mode: encrypt.AESMode.cbc,
      ),
    );
  }

  // ===========================================================================
  // IV
  // ===========================================================================

  encrypt.IV _generateIV() {
    final random = Random.secure();

    final bytes = Uint8List.fromList(
      List<int>.generate(
        _ivLength,
        (_) => random.nextInt(256),
      ),
    );

    return encrypt.IV(bytes);
  }

  // ===========================================================================
  // SHA-256 CONTENT HASH
  // ===========================================================================

  /// Calculates SHA-256 for arbitrary data.
  ///
  /// This hashes the original/source data, not encrypted bytes.
  String sha256Bytes(
    List<int> data,
  ) {
    final digest = crypto.sha256.convert(data);

    return digest.toString();
  }

  /// Calculates SHA-256 for a UTF-8 string.
  String sha256String(
    String value,
  ) {
    return sha256Bytes(
      utf8.encode(value),
    );
  }

  /// Calculates SHA-256 for a file using a streaming read.
  ///
  /// The complete file is never loaded into memory.
  ///
  /// The [chunkSize] parameter is retained for API compatibility with
  /// BackupService. Dart's File.openRead() controls its own stream chunks,
  /// so it is not passed as a positional argument to openRead().
  Future<String> sha256File(
    String filePath, {
    int chunkSize = streamChunkSize,
  }) async {
    _validateStreamChunkSize(chunkSize);

    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException(
        'File does not exist.',
        filePath,
      );
    }

    final digestSink = _DigestSink();

    final converter = crypto.sha256.startChunkedConversion(
      digestSink,
    );

    try {
      await for (final chunk in file.openRead()) {
        if (chunk.isEmpty) {
          continue;
        }

        converter.add(chunk);

        await Future<void>.delayed(
          Duration.zero,
        );
      }

      converter.close();
    } catch (_) {
      rethrow;
    }

    final digest = digestSink.digest;

    if (digest == null) {
      throw StateError(
        'Unable to calculate file SHA-256.',
      );
    }

    return digest.toString();
  }

  /// Calculates SHA-256 for a file using a streaming read.
  ///
  /// This is kept as a compatibility API for existing BackupService code.
  Future<String> sha256FileStreaming(
    String filePath,
  ) async {
    return sha256File(filePath);
  }

  // ===========================================================================
  // STRING ENCRYPTION
  // ===========================================================================

  Future<String> encryptString(
    String plainText,
  ) async {
    if (plainText.isEmpty) {
      return '';
    }

    final iv = _generateIV();

    final encrypted = _encrypter.encrypt(
      plainText,
      iv: iv,
    );

    final result = Uint8List.fromList([
      ...iv.bytes,
      ...encrypted.bytes,
    ]);

    return base64Encode(result);
  }

  Future<String> decryptString(
    String encryptedText,
  ) async {
    if (encryptedText.isEmpty) {
      return '';
    }

    final combined = _decodeEncryptedPayload(
      encryptedText,
    );

    _validateEncryptedBytes(combined);

    final iv = _extractIV(combined);

    final cipherBytes = _extractCiphertext(combined);

    final encrypted = encrypt.Encrypted(
      Uint8List.fromList(cipherBytes),
    );

    try {
      return _encrypter.decrypt(
        encrypted,
        iv: iv,
      );
    } catch (_) {
      throw StateError(
        'Unable to decrypt string data.',
      );
    }
  }

  // ===========================================================================
  // SMALL BINARY ENCRYPTION
  // ===========================================================================

  Future<List<int>> encryptBytes(
    List<int> data,
  ) async {
    if (data.isEmpty) {
      return <int>[];
    }

    final iv = _generateIV();

    final encrypted = _encrypter.encryptBytes(
      data,
      iv: iv,
    );

    return <int>[
      ...iv.bytes,
      ...encrypted.bytes,
    ];
  }

  Future<List<int>> decryptBytes(
    List<int> encryptedData,
  ) async {
    if (encryptedData.isEmpty) {
      return <int>[];
    }

    _validateEncryptedBytes(encryptedData);

    final iv = _extractIV(encryptedData);

    final cipherBytes = _extractCiphertext(encryptedData);

    final encrypted = encrypt.Encrypted(
      Uint8List.fromList(cipherBytes),
    );

    try {
      return _encrypter.decryptBytes(
        encrypted,
        iv: iv,
      );
    } catch (_) {
      throw StateError(
        'Unable to decrypt binary data.',
      );
    }
  }

  // ===========================================================================
  // STREAMING ENCRYPTION
  // ===========================================================================

  Future<File> encryptFileStreaming({
    required String inputPath,
    required String outputPath,
    int chunkSize = streamChunkSize,
  }) async {
    _validateStreamChunkSize(chunkSize);

    if (!_isInitialized()) {
      throw StateError(
        'EncryptionService has not been initialized.',
      );
    }

    final inputFile = File(inputPath);

    if (!await inputFile.exists()) {
      throw FileSystemException(
        'Input file does not exist.',
        inputPath,
      );
    }

    final outputFile = File(outputPath);

    await outputFile.parent.create(
      recursive: true,
    );

    if (pathEquals(inputPath, outputPath)) {
      throw ArgumentError(
        'Input and output paths must be different.',
      );
    }

    final inputStream = inputFile.openRead();

    final outputSink = outputFile.openWrite();

    try {
      await _writeStreamMagic(outputSink);

      await _encryptInputStream(
        inputStream,
        outputSink,
        chunkSize,
      );

      await outputSink.flush();
    } finally {
      await outputSink.close();
    }

    return outputFile;
  }

  // ===========================================================================
  // STREAMING DECRYPTION
  // ===========================================================================

  Future<File> decryptFileStreaming({
    required String inputPath,
    required String outputPath,
  }) async {
    if (!_isInitialized()) {
      throw StateError(
        'EncryptionService has not been initialized.',
      );
    }

    final inputFile = File(inputPath);

    if (!await inputFile.exists()) {
      throw FileSystemException(
        'Encrypted file does not exist.',
        inputPath,
      );
    }

    final outputFile = File(outputPath);

    await outputFile.parent.create(
      recursive: true,
    );

    if (pathEquals(inputPath, outputPath)) {
      throw ArgumentError(
        'Input and output paths must be different.',
      );
    }

    final inputStream = inputFile.openRead();

    final reader = _ByteStreamReader(inputStream);

    final outputSink = outputFile.openWrite();

    try {
      await _readAndValidateStreamMagic(reader);

      while (true) {
        final lengthBytes = await reader.readUpTo(
          _chunkLengthBytes,
        );

        if (lengthBytes.isEmpty) {
          break;
        }

        if (lengthBytes.length != _chunkLengthBytes) {
          throw const FormatException(
            'Corrupted streaming encryption data.',
          );
        }

        final plaintextLength = _decodeUint32(
          lengthBytes,
        );

        if (plaintextLength <= 0 || plaintextLength > _maxAllowedChunkSize) {
          throw const FormatException(
            'Invalid streaming chunk size.',
          );
        }

        final ivBytes = await reader.readExact(
          _ivLength,
        );

        final encryptedLength = _encryptedLengthForPlaintext(
          plaintextLength,
        );

        final cipherBytes = await reader.readExact(
          encryptedLength,
        );

        final iv = encrypt.IV(
          Uint8List.fromList(ivBytes),
        );

        final encrypted = encrypt.Encrypted(
          Uint8List.fromList(cipherBytes),
        );

        late final List<int> decrypted;

        try {
          decrypted = _encrypter.decryptBytes(
            encrypted,
            iv: iv,
          );
        } catch (_) {
          throw StateError(
            'Unable to decrypt streaming file data.',
          );
        }

        if (decrypted.length != plaintextLength) {
          throw const FormatException(
            'Streaming chunk length mismatch.',
          );
        }

        outputSink.add(decrypted);

        await outputSink.flush();

        await Future<void>.delayed(
          Duration.zero,
        );
      }
    } finally {
      await outputSink.close();
    }

    return outputFile;
  }

  // ===========================================================================
  // STREAMING INTERNALS
  // ===========================================================================

  Future<void> _writeStreamMagic(
    IOSink sink,
  ) async {
    sink.add(_streamMagic);
  }

  Future<void> _readAndValidateStreamMagic(
    _ByteStreamReader reader,
  ) async {
    final magic = await reader.readExact(
      _streamMagic.length,
    );

    for (var i = 0; i < _streamMagic.length; i++) {
      if (magic[i] != _streamMagic[i]) {
        throw const FormatException(
          'Invalid Keeply streaming encryption format.',
        );
      }
    }
  }

  Future<void> _encryptInputStream(
    Stream<List<int>> inputStream,
    IOSink outputSink,
    int chunkSize,
  ) async {
    final buffer = BytesBuilder(
      copy: false,
    );

    await for (final incoming in inputStream) {
      if (incoming.isEmpty) {
        continue;
      }

      var offset = 0;

      while (offset < incoming.length) {
        final remaining = chunkSize - buffer.length;

        final available = incoming.length - offset;

        final take = min(
          remaining,
          available,
        );

        buffer.add(
          incoming.sublist(
            offset,
            offset + take,
          ),
        );

        offset += take;

        if (buffer.length == chunkSize) {
          await _encryptAndWriteChunk(
            buffer.takeBytes(),
            outputSink,
          );

          await Future<void>.delayed(
            Duration.zero,
          );
        }
      }
    }

    if (buffer.length > 0) {
      await _encryptAndWriteChunk(
        buffer.takeBytes(),
        outputSink,
      );
    }
  }

  Future<void> _encryptAndWriteChunk(
    Uint8List plaintext,
    IOSink outputSink,
  ) async {
    if (plaintext.isEmpty) {
      return;
    }

    if (plaintext.length > _maxAllowedChunkSize) {
      throw StateError(
        'Streaming encryption chunk is too large.',
      );
    }

    final iv = _generateIV();

    final encrypted = _encrypter.encryptBytes(
      plaintext,
      iv: iv,
    );

    final lengthBytes = _encodeUint32(
      plaintext.length,
    );

    outputSink.add(lengthBytes);

    outputSink.add(iv.bytes);

    outputSink.add(encrypted.bytes);

    await outputSink.flush();
  }

  int _encryptedLengthForPlaintext(
    int plaintextLength,
  ) {
    if (plaintextLength <= 0) {
      throw const FormatException(
        'Invalid plaintext length.',
      );
    }

    final blocks = (plaintextLength ~/ _aesBlockSize) + 1;

    return blocks * _aesBlockSize;
  }

  // ===========================================================================
  // LEGACY FILE ENCRYPTION
  // ===========================================================================

  Future<File> encryptFile({
    required String inputPath,
    required String outputPath,
  }) async {
    final inputFile = File(inputPath);

    if (!await inputFile.exists()) {
      throw FileSystemException(
        'Input file does not exist.',
        inputPath,
      );
    }

    final data = await inputFile.readAsBytes();

    final encryptedData = await encryptBytes(data);

    final outputFile = File(outputPath);

    await outputFile.parent.create(
      recursive: true,
    );

    await outputFile.writeAsBytes(
      encryptedData,
      flush: true,
    );

    return outputFile;
  }

  Future<File> decryptFile({
    required String inputPath,
    required String outputPath,
  }) async {
    final encryptedFile = File(inputPath);

    if (!await encryptedFile.exists()) {
      throw FileSystemException(
        'Encrypted file does not exist.',
        inputPath,
      );
    }

    final encryptedData = await encryptedFile.readAsBytes();

    final decryptedData = await decryptBytes(
      encryptedData,
    );

    final outputFile = File(outputPath);

    await outputFile.parent.create(
      recursive: true,
    );

    await outputFile.writeAsBytes(
      decryptedData,
      flush: true,
    );

    return outputFile;
  }

  // ===========================================================================
  // FILE BYTES HELPERS
  // ===========================================================================

  Future<List<int>> encryptFileBytes(
    String filePath,
  ) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException(
        'File does not exist.',
        filePath,
      );
    }

    final bytes = await file.readAsBytes();

    return encryptBytes(bytes);
  }

  Future<List<int>> decryptFileBytes(
    String filePath,
  ) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException(
        'Encrypted file does not exist.',
        filePath,
      );
    }

    final encryptedBytes = await file.readAsBytes();

    return decryptBytes(encryptedBytes);
  }

  // ===========================================================================
  // PATH HELPERS
  // ===========================================================================

  bool pathEquals(
    String first,
    String second,
  ) {
    final firstPath = File(first).absolute.path;

    final secondPath = File(second).absolute.path;

    return Platform.isWindows
        ? firstPath.toLowerCase() == secondPath.toLowerCase()
        : firstPath == secondPath;
  }

  void _validateStreamChunkSize(
    int chunkSize,
  ) {
    if (chunkSize <= 0) {
      throw ArgumentError(
        'Streaming chunk size must be greater than zero.',
      );
    }

    if (chunkSize > _maxAllowedChunkSize) {
      throw ArgumentError(
        'Streaming chunk size is too large.',
      );
    }
  }

  bool _isInitialized() {
    return _masterKey != null;
  }

  // ===========================================================================
  // PAYLOAD HELPERS
  // ===========================================================================

  Uint8List _decodeEncryptedPayload(
    String encryptedText,
  ) {
    try {
      return Uint8List.fromList(
        base64Decode(encryptedText),
      );
    } catch (_) {
      throw const FormatException(
        'Invalid encrypted payload.',
      );
    }
  }

  encrypt.IV _extractIV(
    List<int> encryptedData,
  ) {
    if (encryptedData.length < _ivLength) {
      throw const FormatException(
        'Encrypted payload is too short.',
      );
    }

    return encrypt.IV(
      Uint8List.fromList(
        encryptedData.sublist(
          0,
          _ivLength,
        ),
      ),
    );
  }

  List<int> _extractCiphertext(
    List<int> encryptedData,
  ) {
    if (encryptedData.length <= _ivLength) {
      throw const FormatException(
        'Encrypted payload does not contain ciphertext.',
      );
    }

    return encryptedData.sublist(_ivLength);
  }

  void _validateEncryptedBytes(
    List<int> encryptedData,
  ) {
    if (encryptedData.length <= _ivLength) {
      throw const FormatException(
        'Invalid encrypted data.',
      );
    }

    final ciphertextLength = encryptedData.length - _ivLength;

    if (ciphertextLength <= 0) {
      throw const FormatException(
        'Missing ciphertext.',
      );
    }

    if (ciphertextLength % _aesBlockSize != 0) {
      throw const FormatException(
        'Invalid AES ciphertext length.',
      );
    }
  }

  // ===========================================================================
  // UINT32
  // ===========================================================================

  Uint8List _encodeUint32(
    int value,
  ) {
    if (value < 0 || value > 0xFFFFFFFF) {
      throw ArgumentError(
        'Value does not fit into uint32.',
      );
    }

    return Uint8List.fromList([
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ]);
  }

  int _decodeUint32(
    List<int> bytes,
  ) {
    if (bytes.length != 4) {
      throw const FormatException(
        'Invalid uint32 data.',
      );
    }

    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  // ===========================================================================
  // SECURITY STATE
  // ===========================================================================

  bool get isInitialized {
    return _masterKey != null;
  }

  Future<bool> hasMasterKey() async {
    return _secureStorage.hasMasterKey();
  }

  void clearMemoryKey() {
    _masterKey = null;
  }

  Future<void> deleteMasterKey() async {
    _masterKey = null;

    await _secureStorage.deleteMasterKey();
  }
}

// =============================================================================
// DIGEST SINK
// =============================================================================

class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? digest;

  @override
  void add(
    crypto.Digest data,
  ) {
    digest = data;
  }

  @override
  void close() {}
}

// =============================================================================
// BYTE STREAM READER
// =============================================================================

class _ByteStreamReader {
  _ByteStreamReader(
    Stream<List<int>> source,
  ) : _iterator = StreamIterator<List<int>>(source);

  final StreamIterator<List<int>> _iterator;

  Uint8List _buffer = Uint8List(0);

  int _offset = 0;

  bool _finished = false;

  Future<List<int>> readExact(
    int length,
  ) async {
    if (length <= 0) {
      return <int>[];
    }

    final result = Uint8List(length);

    var written = 0;

    while (written < length) {
      final available = _buffer.length - _offset;

      if (available > 0) {
        final take = min(
          available,
          length - written,
        );

        result.setRange(
          written,
          written + take,
          _buffer,
          _offset,
        );

        written += take;
        _offset += take;

        continue;
      }

      if (_finished) {
        throw const FormatException(
          'Unexpected end of encrypted stream.',
        );
      }

      final hasNext = await _iterator.moveNext();

      if (!hasNext) {
        _finished = true;

        throw const FormatException(
          'Unexpected end of encrypted stream.',
        );
      }

      final next = _iterator.current;

      if (next.isEmpty) {
        continue;
      }

      _buffer = Uint8List.fromList(next);

      _offset = 0;
    }

    return result;
  }

  Future<List<int>> readUpTo(
    int length,
  ) async {
    if (length <= 0) {
      return <int>[];
    }

    while (_buffer.length - _offset < length) {
      if (_finished) {
        break;
      }

      final hasNext = await _iterator.moveNext();

      if (!hasNext) {
        _finished = true;
        break;
      }

      final next = _iterator.current;

      if (next.isEmpty) {
        continue;
      }

      if (_offset >= _buffer.length) {
        _buffer = Uint8List.fromList(next);

        _offset = 0;
      } else {
        final remaining = _buffer.sublist(_offset);

        final combined = Uint8List(
          remaining.length + next.length,
        );

        combined.setRange(
          0,
          remaining.length,
          remaining,
        );

        combined.setRange(
          remaining.length,
          combined.length,
          next,
        );

        _buffer = combined;

        _offset = 0;
      }
    }

    final available = _buffer.length - _offset;

    if (available <= 0) {
      return <int>[];
    }

    final take = min(
      available,
      length,
    );

    final result = Uint8List.fromList(
      _buffer.sublist(
        _offset,
        _offset + take,
      ),
    );

    _offset += take;

    return result;
  }
}
