import 'package:local_auth/local_auth.dart';

/// Handles biometric authentication for Keeply.
///
/// This service is responsible only for communicating with the
/// device authentication APIs. It does not manage application state
/// or UI navigation.
class BiometricService {
  BiometricService({
    LocalAuthentication? localAuthentication,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  // ---------------------------------------------------------------------------
  // Device Support
  // ---------------------------------------------------------------------------

  /// Returns true if the device can perform biometric authentication.
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuthentication.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Returns true if biometric authentication can currently be used.
  ///
  /// This checks whether the device has enrolled biometrics.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuthentication.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Returns the biometric types enrolled on the device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuthentication.getAvailableBiometrics();
    } catch (_) {
      return <BiometricType>[];
    }
  }

  /// Returns true if at least one biometric method is available.
  Future<bool> hasAvailableBiometrics() async {
    final supported = await isDeviceSupported();

    if (!supported) {
      return false;
    }

    final available = await getAvailableBiometrics();

    return available.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// Requests biometric/device authentication from the user.
  ///
  /// Returns:
  /// - true  → authentication succeeded.
  /// - false → authentication failed or was cancelled.
  Future<bool> authenticate() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'Authenticate to unlock your Keeply.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Performs biometric-only authentication.
  ///
  /// PIN/password fallback is disabled.
  Future<bool> authenticateWithBiometrics() async {
    try {
      final available = await hasAvailableBiometrics();

      if (!available) {
        return false;
      }

      return await _localAuthentication.authenticate(
        localizedReason: 'Use your biometric authentication to unlock Keeply.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Biometric Information
  // ---------------------------------------------------------------------------

  /// Returns true when fingerprint authentication is available.
  Future<bool> hasFingerprint() async {
    final biometrics = await getAvailableBiometrics();

    return biometrics.contains(
      BiometricType.fingerprint,
    );
  }

  /// Returns true when Face ID / face authentication is available.
  Future<bool> hasFaceAuthentication() async {
    final biometrics = await getAvailableBiometrics();

    return biometrics.contains(
          BiometricType.face,
        ) ||
        biometrics.contains(
          BiometricType.strong,
        );
  }

  /// Returns a human-readable authentication label.
  ///
  /// The UI can later replace these strings with localized values.
  Future<String> getBiometricLabel() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.contains(BiometricType.face)) {
      return 'Face Authentication';
    }

    if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }

    if (biometrics.contains(BiometricType.strong)) {
      return 'Biometric Authentication';
    }

    if (biometrics.contains(BiometricType.weak)) {
      return 'Biometric Authentication';
    }

    return 'Biometric Authentication';
  }

  // ---------------------------------------------------------------------------
  // Authentication Cancellation
  // ---------------------------------------------------------------------------

  /// Stops an ongoing authentication request if supported.
  Future<void> stopAuthentication() async {
    try {
      await _localAuthentication.stopAuthentication();
    } catch (_) {
      // Some platforms may not support stopping authentication.
    }
  }
}
