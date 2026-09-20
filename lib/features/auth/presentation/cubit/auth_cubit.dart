import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/security/biometric_service.dart';
import '../../../../core/security/encryption_service.dart';
import '../../../../core/security/pin_service.dart';
import '../../../../core/security/vault_lock_service.dart';
import 'auth_state.dart';

/// Coordinates the authentication and initial security setup flow.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required PinService pinService,
    required BiometricService biometricService,
    required VaultLockService vaultLockService,
    required EncryptionService encryptionService,
  })  : _pinService = pinService,
        _biometricService = biometricService,
        _vaultLockService = vaultLockService,
        _encryptionService = encryptionService,
        super(const AuthState());

  final PinService _pinService;
  final BiometricService _biometricService;
  final VaultLockService _vaultLockService;
  final EncryptionService _encryptionService;

  // ===========================================================================
  // Initialization
  // ===========================================================================

  Future<void> initialize() async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      ),
    );

    try {
      final hasPin = await _pinService.isPinConfigurationValid();

      final biometricEnabled = await _vaultLockService.isBiometricEnabled();

      final canUseBiometrics = await _biometricService.hasAvailableBiometrics();

      // -----------------------------------------------------------------------
      // First Launch
      // -----------------------------------------------------------------------

      if (!hasPin) {
        emit(
          state.copyWith(
            status: AuthStatus.firstLaunch,
            isPinConfigured: false,
            isBiometricEnabled: biometricEnabled,
            canUseBiometrics: canUseBiometrics,
          ),
        );

        return;
      }

      // -----------------------------------------------------------------------
      // Existing Vault
      // -----------------------------------------------------------------------

      _vaultLockService.forceLock();

      emit(
        state.copyWith(
          status: AuthStatus.locked,
          isPinConfigured: true,
          isBiometricEnabled: biometricEnabled,
          canUseBiometrics: canUseBiometrics,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // ===========================================================================
  // PIN Setup
  // ===========================================================================

  Future<bool> createPin(String pin) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      ),
    );

    try {
      await _pinService.createPin(pin);

      // The user has just successfully created and confirmed
      // the initial PIN, so the vault is immediately authenticated.
      final unlocked = await _vaultLockService.unlockWithVerifiedPin(true);

      if (!unlocked) {
        emit(
          state.copyWith(
            status: AuthStatus.locked,
            isPinConfigured: true,
            errorMessage: 'unlock_failed',
          ),
        );

        return false;
      }

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          isPinConfigured: true,
          clearError: true,
        ),
      );

      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: e.toString(),
        ),
      );

      return false;
    }
  }

  // ===========================================================================
  // PIN Authentication
  // ===========================================================================

  Future<bool> unlockWithPin(String pin) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      ),
    );

    try {
      final verified = await _pinService.verifyPin(pin);

      if (!verified) {
        emit(
          state.copyWith(
            status: AuthStatus.locked,
            errorMessage: 'invalid_pin',
          ),
        );

        return false;
      }

      final unlocked = await _vaultLockService.unlockWithVerifiedPin(true);

      if (!unlocked) {
        emit(
          state.copyWith(
            status: AuthStatus.locked,
            errorMessage: 'unlock_failed',
          ),
        );

        return false;
      }

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          clearError: true,
        ),
      );

      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.locked,
          errorMessage: e.toString(),
        ),
      );

      return false;
    }
  }

  // ===========================================================================
  // Biometric Authentication
  // ===========================================================================

  Future<bool> unlockWithBiometrics() async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        clearError: true,
      ),
    );

    try {
      final enabled = await _vaultLockService.isBiometricEnabled();

      if (!enabled) {
        emit(
          state.copyWith(
            status: AuthStatus.locked,
            errorMessage: 'biometrics_not_enabled',
          ),
        );

        return false;
      }

      final available = await _biometricService.hasAvailableBiometrics();

      if (!available) {
        emit(
          state.copyWith(
            status: AuthStatus.locked,
            errorMessage: 'biometrics_unavailable',
          ),
        );

        return false;
      }

      final authenticated = await _vaultLockService.unlockWithBiometrics();

      if (!authenticated) {
        emit(
          state.copyWith(
            status: AuthStatus.locked,
            errorMessage: 'biometric_authentication_failed',
          ),
        );

        return false;
      }

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          clearError: true,
        ),
      );

      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.locked,
          errorMessage: e.toString(),
        ),
      );

      return false;
    }
  }

  // ===========================================================================
  // Biometric Setup
  // ===========================================================================

  Future<bool> enableBiometrics() async {
    try {
      final available = await _biometricService.hasAvailableBiometrics();

      if (!available) {
        return false;
      }

      final authenticated =
          await _biometricService.authenticateWithBiometrics();

      if (!authenticated) {
        return false;
      }

      await _vaultLockService.setBiometricEnabled(true);

      emit(
        state.copyWith(
          isBiometricEnabled: true,
          canUseBiometrics: true,
          clearError: true,
        ),
      );

      return true;
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: e.toString(),
        ),
      );

      return false;
    }
  }

  // ===========================================================================
  // Disable Biometrics
  // ===========================================================================

  Future<void> disableBiometrics() async {
    await _vaultLockService.setBiometricEnabled(false);

    emit(
      state.copyWith(
        isBiometricEnabled: false,
        clearError: true,
      ),
    );
  }

  // ===========================================================================
  // Vault
  // ===========================================================================

  void lock() {
    _vaultLockService.lock();

    emit(
      state.copyWith(
        status: AuthStatus.locked,
        clearError: true,
      ),
    );
  }

  bool get encryptionReady {
    return _encryptionService.isInitialized;
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  void clearError() {
    emit(
      state.copyWith(
        clearError: true,
      ),
    );
  }
}
