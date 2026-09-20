import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized secure storage service for Keeply.
///
/// This class is the ONLY layer that should directly communicate
/// with FlutterSecureStorage.
///
/// Sensitive values such as:
/// - Master encryption key
/// - PIN-related secrets
/// - Authentication state
/// - Security configuration
/// should be stored through this service.
class SecureStorageService {
  SecureStorageService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? _createStorage();

  final FlutterSecureStorage _storage;

  // ---------------------------------------------------------------------------
  // Storage Configuration
  // ---------------------------------------------------------------------------

  static FlutterSecureStorage _createStorage() {
    return const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Generic Operations
  // ---------------------------------------------------------------------------

  /// Stores a sensitive value securely.
  Future<void> write({
    required String key,
    required String value,
  }) async {
    if (key.trim().isEmpty) {
      throw ArgumentError('Storage key cannot be empty.');
    }

    await _storage.write(
      key: key,
      value: value,
    );
  }

  /// Reads a sensitive value.
  ///
  /// Returns null when the key does not exist.
  Future<String?> read({
    required String key,
  }) async {
    if (key.trim().isEmpty) {
      throw ArgumentError('Storage key cannot be empty.');
    }

    return _storage.read(
      key: key,
    );
  }

  /// Checks whether a key exists.
  Future<bool> containsKey({
    required String key,
  }) async {
    if (key.trim().isEmpty) {
      throw ArgumentError('Storage key cannot be empty.');
    }

    return _storage.containsKey(
      key: key,
    );
  }

  /// Deletes one stored value.
  Future<void> delete({
    required String key,
  }) async {
    if (key.trim().isEmpty) {
      throw ArgumentError('Storage key cannot be empty.');
    }

    await _storage.delete(
      key: key,
    );
  }

  /// Deletes all values stored by Keeply.
  ///
  /// WARNING:
  /// This can make encrypted data permanently unrecoverable
  /// if the encryption master key is also removed.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Returns all stored key/value pairs.
  ///
  /// This should be used very carefully and preferably only
  /// for internal security/debugging operations.
  Future<Map<String, String>> readAll() async {
    return _storage.readAll();
  }

  // ---------------------------------------------------------------------------
  // Keeply Keys
  // ---------------------------------------------------------------------------

  /// Master encryption key.
  ///
  /// This key protects all encrypted Keeply data.
  static const String masterKey = 'secure_vault_master_key';

  /// Indicates whether the initial security setup has completed.
  static const String securitySetupCompleted =
      'secure_vault_security_setup_completed';

  /// Indicates whether biometric authentication is enabled.
  static const String biometricEnabled = 'secure_vault_biometric_enabled';

  /// Stores a cryptographic PIN hash.
  ///
  /// Never store the user's plaintext PIN.
  static const String pinHash = 'secure_vault_pin_hash';

  /// Random salt used for PIN hashing.
  static const String pinSalt = 'secure_vault_pin_salt';

  /// Indicates whether a PIN has been configured.
  static const String pinConfigured = 'secure_vault_pin_configured';

  /// Stores the selected application locale.
  static const String locale = 'secure_vault_locale';

  /// Stores the selected theme mode.
  static const String themeMode = 'secure_vault_theme_mode';

  // ---------------------------------------------------------------------------
  // Master Key
  // ---------------------------------------------------------------------------

  Future<void> saveMasterKey(String value) async {
    await write(
      key: masterKey,
      value: value,
    );
  }

  Future<String?> getMasterKey() async {
    return read(
      key: masterKey,
    );
  }

  Future<bool> hasMasterKey() async {
    return containsKey(
      key: masterKey,
    );
  }

  Future<void> deleteMasterKey() async {
    await delete(
      key: masterKey,
    );
  }

  // ---------------------------------------------------------------------------
  // Security Setup
  // ---------------------------------------------------------------------------

  Future<void> setSecuritySetupCompleted(
    bool value,
  ) async {
    await write(
      key: securitySetupCompleted,
      value: value.toString(),
    );
  }

  Future<bool> isSecuritySetupCompleted() async {
    final value = await read(
      key: securitySetupCompleted,
    );

    return value == 'true';
  }

  // ---------------------------------------------------------------------------
  // Biometrics
  // ---------------------------------------------------------------------------

  Future<void> setBiometricEnabled(
    bool enabled,
  ) async {
    await write(
      key: biometricEnabled,
      value: enabled.toString(),
    );
  }

  Future<bool> isBiometricEnabled() async {
    final value = await read(
      key: biometricEnabled,
    );

    return value == 'true';
  }

  // ---------------------------------------------------------------------------
  // PIN Configuration
  // ---------------------------------------------------------------------------

  /// Stores the hashed PIN.
  ///
  /// The plaintext PIN must NEVER reach this method.
  Future<void> savePinHash(String hash) async {
    await write(
      key: pinHash,
      value: hash,
    );
  }

  Future<String?> getPinHash() async {
    return read(
      key: pinHash,
    );
  }

  Future<bool> hasPin() async {
    return containsKey(
      key: pinHash,
    );
  }

  Future<void> deletePinHash() async {
    await delete(
      key: pinHash,
    );
  }

  // ---------------------------------------------------------------------------
  // PIN Salt
  // ---------------------------------------------------------------------------

  Future<void> savePinSalt(String salt) async {
    await write(
      key: pinSalt,
      value: salt,
    );
  }

  Future<String?> getPinSalt() async {
    return read(
      key: pinSalt,
    );
  }

  Future<bool> hasPinSalt() async {
    return containsKey(
      key: pinSalt,
    );
  }

  Future<void> deletePinSalt() async {
    await delete(
      key: pinSalt,
    );
  }

  // ---------------------------------------------------------------------------
  // PIN State
  // ---------------------------------------------------------------------------

  Future<void> setPinConfigured(
    bool configured,
  ) async {
    await write(
      key: pinConfigured,
      value: configured.toString(),
    );
  }

  Future<bool> isPinConfigured() async {
    final value = await read(
      key: pinConfigured,
    );

    return value == 'true';
  }

  // ---------------------------------------------------------------------------
  // Locale
  // ---------------------------------------------------------------------------

  Future<void> saveLocale(String languageCode) async {
    await write(
      key: locale,
      value: languageCode,
    );
  }

  Future<String?> getLocale() async {
    return read(
      key: locale,
    );
  }

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  Future<void> saveThemeMode(String mode) async {
    await write(
      key: themeMode,
      value: mode,
    );
  }

  Future<String?> getThemeMode() async {
    return read(
      key: themeMode,
    );
  }
}
