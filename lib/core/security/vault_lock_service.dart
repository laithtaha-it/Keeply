import 'package:flutter/foundation.dart';

import 'biometric_service.dart';
import 'secure_storage_service.dart';

/// Represents the current state of the Keeply lock.
enum VaultLockState {
  locked,
  unlocked,
}

/// Controls the authentication state of Keeply.
///
/// Responsibilities:
/// - Determine whether the vault is locked or unlocked.
/// - Authenticate using biometrics.
/// - Authenticate using PIN through the PIN service later.
/// - Lock the vault when the app goes to background.
/// - Notify listeners when the lock state changes.
///
/// This service does NOT contain UI or navigation logic.
class VaultLockService extends ChangeNotifier {
  VaultLockService({
    required SecureStorageService secureStorage,
    required BiometricService biometricService,
  })  : _secureStorage = secureStorage,
        _biometricService = biometricService;

  final SecureStorageService _secureStorage;
  final BiometricService _biometricService;

  VaultLockState _state = VaultLockState.locked;

  bool _initialized = false;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Current vault lock state.
  VaultLockState get state => _state;

  /// Returns true when the vault is currently unlocked.
  bool get isUnlocked => _state == VaultLockState.unlocked;

  /// Returns true when the vault is currently locked.
  bool get isLocked => _state == VaultLockState.locked;

  /// Returns true after initialization has completed.
  bool get isInitialized => _initialized;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the lock service.
  ///
  /// Keeply starts locked every time the application launches.
  Future<void> initialize() async {
    _state = VaultLockState.locked;
    _initialized = true;

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Unlock
  // ---------------------------------------------------------------------------

  /// Attempts to unlock the vault using device authentication.
  ///
  /// Depending on the platform and configuration, this can use:
  /// - Fingerprint
  /// - Face authentication
  /// - Device PIN/password/pattern
  ///
  /// Returns true only when authentication succeeds.
  Future<bool> unlockWithDeviceAuthentication() async {
    if (!_initialized) {
      throw StateError(
        'VaultLockService has not been initialized.',
      );
    }

    if (isUnlocked) {
      return true;
    }

    final authenticated = await _biometricService.authenticate();

    if (!authenticated) {
      return false;
    }

    _unlock();

    return true;
  }

  /// Attempts to unlock using biometrics only.
  ///
  /// Unlike [unlockWithDeviceAuthentication], this does not allow
  /// the operating system's PIN/password fallback.
  Future<bool> unlockWithBiometrics() async {
    if (!_initialized) {
      throw StateError(
        'VaultLockService has not been initialized.',
      );
    }

    if (isUnlocked) {
      return true;
    }

    final authenticated = await _biometricService.authenticateWithBiometrics();

    if (!authenticated) {
      return false;
    }

    _unlock();

    return true;
  }

  // ---------------------------------------------------------------------------
  // PIN Placeholder
  // ---------------------------------------------------------------------------

  /// Unlocks the vault after a PIN has been verified.
  ///
  /// PIN verification itself will be implemented in PinService.
  ///
  /// This method intentionally accepts a verification result rather than
  /// the plaintext PIN. This prevents VaultLockService from becoming
  /// responsible for PIN cryptography.
  Future<bool> unlockWithVerifiedPin(
    bool verified,
  ) async {
    if (!_initialized) {
      throw StateError(
        'VaultLockService has not been initialized.',
      );
    }

    if (!verified) {
      return false;
    }

    _unlock();

    return true;
  }

  // ---------------------------------------------------------------------------
  // Lock
  // ---------------------------------------------------------------------------

  /// Locks the vault immediately.
  ///
  /// Any sensitive in-memory state should be cleared by the responsible
  /// service when the vault becomes locked.
  void lock() {
    if (isLocked) {
      return;
    }

    _state = VaultLockState.locked;

    notifyListeners();
  }

  /// Locks the vault and clears authentication-related state.
  void forceLock() {
    _state = VaultLockState.locked;

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private State Management
  // ---------------------------------------------------------------------------

  void _unlock() {
    _state = VaultLockState.unlocked;

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Security Configuration
  // ---------------------------------------------------------------------------

  /// Returns whether biometric authentication is enabled.
  Future<bool> isBiometricEnabled() async {
    return _secureStorage.isBiometricEnabled();
  }

  /// Enables or disables biometric authentication.
  Future<void> setBiometricEnabled(
    bool enabled,
  ) async {
    await _secureStorage.setBiometricEnabled(
      enabled,
    );

    notifyListeners();
  }

  /// Returns whether the user has configured a PIN.
  Future<bool> isPinConfigured() async {
    return _secureStorage.isPinConfigured();
  }

  // ---------------------------------------------------------------------------
  // Authentication Availability
  // ---------------------------------------------------------------------------

  /// Returns true when biometric authentication is available.
  Future<bool> canUseBiometrics() async {
    return _biometricService.hasAvailableBiometrics();
  }

  /// Returns true when the device supports biometric authentication.
  Future<bool> isBiometricDeviceSupported() async {
    return _biometricService.isDeviceSupported();
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _initialized = false;

    super.dispose();
  }
}
