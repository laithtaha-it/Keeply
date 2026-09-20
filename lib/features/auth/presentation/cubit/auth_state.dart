import 'package:flutter/foundation.dart';

/// Represents the current authentication/setup phase.
enum AuthStatus {
  initial,
  loading,
  firstLaunch,
  locked,
  authenticated,
  failure,
}

/// Immutable authentication state.
///
/// The UI observes this state and never communicates directly
/// with the underlying security services.
@immutable
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.isPinConfigured = false,
    this.isBiometricEnabled = false,
    this.canUseBiometrics = false,
  });

  final AuthStatus status;

  /// Optional localized-independent error identifier/message.
  ///
  /// We will move user-facing text to localization later.
  final String? errorMessage;

  final bool isPinConfigured;

  final bool isBiometricEnabled;

  final bool canUseBiometrics;

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool? isPinConfigured,
    bool? isBiometricEnabled,
    bool? canUseBiometrics,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isPinConfigured: isPinConfigured ?? this.isPinConfigured,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
    );
  }

  @override
  String toString() {
    return 'AuthState('
        'status: $status, '
        'isPinConfigured: $isPinConfigured, '
        'isBiometricEnabled: $isBiometricEnabled, '
        'canUseBiometrics: $canUseBiometrics'
        ')';
  }
}
