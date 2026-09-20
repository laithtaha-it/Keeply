import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'secure_storage_service.dart';

/// Secure PIN management service for Keeply.
///
/// Security design:
/// - The plaintext PIN is NEVER stored.
/// - A random 128-bit salt is generated for every PIN.
/// - PBKDF2-HMAC-SHA256 is used instead of a fast hash.
/// - 120,000 PBKDF2 iterations are performed.
/// - The derived value is 256-bit.
/// - PIN verification uses constant-time comparison.
///
/// PIN policy:
/// - Exactly 6 numeric digits.
///
/// Storage:
/// - PIN salt -> FlutterSecureStorage
/// - PIN hash -> FlutterSecureStorage
/// - PIN state -> FlutterSecureStorage
class PinService {
  PinService({
    required SecureStorageService secureStorage,
  }) : _secureStorage = secureStorage;

  final SecureStorageService _secureStorage;

  // ---------------------------------------------------------------------------
  // Security Configuration
  // ---------------------------------------------------------------------------

  /// PBKDF2 iteration count.
  ///
  /// This makes PIN verification more expensive than a normal SHA-256 hash,
  /// reducing the effectiveness of brute-force attacks against a stolen
  /// database.
  static const int _iterations = 120000;

  /// Length of the generated salt in bytes.
  static const int _saltLength = 16;

  /// Length of the derived key in bytes.
  static const int _derivedKeyLength = 32;

  /// Keeply uses exactly 6 digits for all PIN operations.
  static const int pinLength = 6;

  /// Minimum allowed PIN length.
  ///
  /// Kept as a public constant for compatibility with existing UI/code.
  static const int minPinLength = pinLength;

  /// Maximum allowed PIN length.
  ///
  /// Kept as a public constant for compatibility with existing UI/code.
  static const int maxPinLength = pinLength;

  // ---------------------------------------------------------------------------
  // PIN Creation
  // ---------------------------------------------------------------------------

  /// Creates and securely stores a new PIN.
  ///
  /// Returns true when the PIN is successfully created.
  ///
  /// Throws [ArgumentError] when the PIN format is invalid.
  /// Throws [StateError] when a PIN already exists.
  Future<bool> createPin(String pin) async {
    _validatePin(pin);

    final alreadyConfigured = await _secureStorage.isPinConfigured();

    if (alreadyConfigured) {
      throw StateError(
        'A PIN is already configured.',
      );
    }

    final salt = _generateSalt();

    final derivedKey = _deriveKey(
      pin: pin,
      salt: salt,
    );

    await _secureStorage.savePinSalt(
      base64Encode(salt),
    );

    await _secureStorage.savePinHash(
      base64Encode(derivedKey),
    );

    await _secureStorage.setPinConfigured(
      true,
    );

    return true;
  }

  // ---------------------------------------------------------------------------
  // PIN Verification
  // ---------------------------------------------------------------------------

  /// Verifies a PIN against the securely stored credentials.
  ///
  /// Returns:
  /// - true  -> PIN is correct.
  /// - false -> PIN is incorrect.
  ///
  /// No plaintext PIN is stored.
  Future<bool> verifyPin(String pin) async {
    if (!_isValidPinFormat(pin)) {
      return false;
    }

    final configured = await _secureStorage.isPinConfigured();

    if (!configured) {
      return false;
    }

    final storedSalt = await _secureStorage.getPinSalt();

    final storedHash = await _secureStorage.getPinHash();

    if (storedSalt == null ||
        storedSalt.isEmpty ||
        storedHash == null ||
        storedHash.isEmpty) {
      return false;
    }

    try {
      final salt = base64Decode(storedSalt);
      final expectedHash = base64Decode(storedHash);

      if (salt.length != _saltLength) {
        return false;
      }

      if (expectedHash.length != _derivedKeyLength) {
        return false;
      }

      final calculatedHash = _deriveKey(
        pin: pin,
        salt: salt,
      );

      return _constantTimeEquals(
        calculatedHash,
        expectedHash,
      );
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // PIN Change
  // ---------------------------------------------------------------------------

  /// Changes the existing PIN.
  ///
  /// The current PIN must be verified before the new PIN is stored.
  ///
  /// Returns true when the PIN was successfully changed.
  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    _validatePin(newPin);

    final currentPinValid = await verifyPin(currentPin);

    if (!currentPinValid) {
      return false;
    }

    final newSalt = _generateSalt();

    final newDerivedKey = _deriveKey(
      pin: newPin,
      salt: newSalt,
    );

    await _secureStorage.savePinSalt(
      base64Encode(newSalt),
    );

    await _secureStorage.savePinHash(
      base64Encode(newDerivedKey),
    );

    await _secureStorage.setPinConfigured(
      true,
    );

    return true;
  }

  // ---------------------------------------------------------------------------
  // PIN Removal
  // ---------------------------------------------------------------------------

  /// Deletes the configured PIN.
  ///
  /// This method requires the current PIN for verification.
  ///
  /// Returns false when the current PIN is incorrect.
  Future<bool> removePin(String currentPin) async {
    final valid = await verifyPin(currentPin);

    if (!valid) {
      return false;
    }

    await _secureStorage.deletePinHash();
    await _secureStorage.deletePinSalt();

    await _secureStorage.setPinConfigured(
      false,
    );

    return true;
  }

  // ---------------------------------------------------------------------------
  // PIN State
  // ---------------------------------------------------------------------------

  /// Returns true when a PIN is configured.
  Future<bool> hasPin() async {
    return _secureStorage.isPinConfigured();
  }

  /// Returns true when a complete and valid PIN configuration exists.
  ///
  /// This checks:
  /// - PIN configured state
  /// - Salt exists and has the correct length
  /// - Hash exists and has the correct length
  Future<bool> isPinConfigurationValid() async {
    final configured = await _secureStorage.isPinConfigured();

    if (!configured) {
      return false;
    }

    final salt = await _secureStorage.getPinSalt();

    final hash = await _secureStorage.getPinHash();

    if (salt == null || salt.isEmpty || hash == null || hash.isEmpty) {
      return false;
    }

    try {
      final saltBytes = base64Decode(salt);
      final hashBytes = base64Decode(hash);

      return saltBytes.length == _saltLength &&
          hashBytes.length == _derivedKeyLength;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // PIN Validation
  // ---------------------------------------------------------------------------

  /// Returns true when the PIN contains exactly 6 numeric digits.
  bool isValidPin(String pin) {
    return _isValidPinFormat(pin);
  }

  /// Throws [ArgumentError] when the PIN is invalid.
  void _validatePin(String pin) {
    if (!_isValidPinFormat(pin)) {
      throw ArgumentError(
        'PIN must contain exactly $pinLength digits.',
      );
    }
  }

  /// Validates that the PIN contains exactly 6 ASCII digits.
  bool _isValidPinFormat(String pin) {
    if (pin.length != pinLength) {
      return false;
    }

    for (final codeUnit in pin.codeUnits) {
      if (codeUnit < 48 || codeUnit > 57) {
        return false;
      }
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Salt Generation
  // ---------------------------------------------------------------------------

  /// Generates a cryptographically secure random salt.
  Uint8List _generateSalt() {
    final random = Random.secure();

    return Uint8List.fromList(
      List<int>.generate(
        _saltLength,
        (_) => random.nextInt(256),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PBKDF2
  // ---------------------------------------------------------------------------

  /// Derives a 256-bit key from the PIN using
  /// PBKDF2-HMAC-SHA256.
  ///
  /// PBKDF2 formula:
  ///
  /// DK = T1 || T2 || ...
  ///
  /// Each block is calculated using:
  ///
  /// U1 = PRF(P, S || INT_32_BE(i))
  /// U2 = PRF(P, U1)
  /// ...
  ///
  /// T_i = U1 XOR U2 XOR ... XOR Uc
  Uint8List _deriveKey({
    required String pin,
    required List<int> salt,
  }) {
    final passwordBytes = Uint8List.fromList(
      utf8.encode(pin),
    );

    final blockCount = (_derivedKeyLength / sha256.blockSize).ceil();

    final derived = <int>[];

    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      derived.addAll(
        _pbkdf2Block(
          password: passwordBytes,
          salt: salt,
          blockIndex: blockIndex,
        ),
      );
    }

    return Uint8List.fromList(
      derived.take(_derivedKeyLength).toList(),
    );
  }

  /// Calculates one PBKDF2 block.
  List<int> _pbkdf2Block({
    required List<int> password,
    required List<int> salt,
    required int blockIndex,
  }) {
    final hmac = Hmac(
      sha256,
      password,
    );

    final blockIndexBytes = Uint8List(4)
      ..[0] = (blockIndex >> 24) & 0xff
      ..[1] = (blockIndex >> 16) & 0xff
      ..[2] = (blockIndex >> 8) & 0xff
      ..[3] = blockIndex & 0xff;

    final firstInput = <int>[
      ...salt,
      ...blockIndexBytes,
    ];

    var u = hmac.convert(firstInput).bytes;

    final result = List<int>.from(u);

    for (var iteration = 1; iteration < _iterations; iteration++) {
      u = hmac.convert(u).bytes;

      for (var i = 0; i < result.length; i++) {
        result[i] ^= u[i];
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Constant-Time Comparison
  // ---------------------------------------------------------------------------

  /// Compares two byte arrays without early exit based
  /// on the first mismatching byte.
  ///
  /// This reduces timing information that could otherwise
  /// leak comparison results.
  bool _constantTimeEquals(
    List<int> first,
    List<int> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    var difference = 0;

    for (var i = 0; i < first.length; i++) {
      difference |= first[i] ^ second[i];
    }

    return difference == 0;
  }
}
