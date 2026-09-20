import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../l10n/app_localizations.dart';

class LockPage extends StatefulWidget {
  const LockPage({
    super.key,
  });

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  static const int _pinLength = 6;

  final List<String> _digits = [];

  bool _isSubmitting = false;

  String get _pin => _digits.join();

  bool get _isComplete => _digits.length == _pinLength;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: _handleAuthState,
      child: Scaffold(
        body: Stack(
          children: [
            const _BackgroundGlow(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildLockHeader(),
                  const SizedBox(height: 28),
                  _buildPinIndicator(),
                  const Spacer(),
                  _buildKeypad(),
                  const SizedBox(height: 35),
                  _buildUnlockButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  void _handleAuthState(
    BuildContext context,
    AuthState state,
  ) {
    if (!mounted) {
      return;
    }

    if (state.status == AuthStatus.locked &&
        state.errorMessage == 'invalid_pin') {
      setState(() {
        _isSubmitting = false;
        _digits.clear();
      });

      HapticFeedback.heavyImpact();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).incorrectPin,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      return;
    }

    if (state.status == AuthStatus.locked &&
        state.errorMessage != null &&
        state.errorMessage != 'invalid_pin') {
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _friendlyError(state.errorMessage),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      return;
    }

    if (state.status == AuthStatus.authenticated) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _friendlyError(String? error) {
    switch (error) {
      case 'invalid_pin':
        return AppLocalizations.of(context).incorrectPin;

      case 'unlock_failed':
        return AppLocalizations.of(context).vaultUnlockError;

      case 'biometrics_not_enabled':
        return AppLocalizations.of(context).biometricDisabled;

      case 'biometrics_unavailable':
        return AppLocalizations.of(context).biometricUnavailable;

      case 'biometric_authentication_failed':
        return AppLocalizations.of(context).biometricFailed;

      default:
        return AppLocalizations.of(context).keeplyOpenError;
    }
  }

  Future<void> _unlock() async {
    if (!_isComplete || _isSubmitting) {
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isSubmitting = true;
    });

    await context.read<AuthCubit>().unlockWithPin(_pin);
  }

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------

  void _addDigit(String digit) {
    if (_digits.length >= _pinLength || _isSubmitting) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _digits.add(digit);
    });
  }

  void _removeDigit() {
    if (_digits.isEmpty || _isSubmitting) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _digits.removeLast();
    });
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        0,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cyberEmerald.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.cyberEmerald.withValues(
                  alpha: 0.20,
                ),
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.cyberEmerald,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).keeply,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(
            Icons.lock_rounded,
            color: AppColors.cyberEmerald,
            size: 21,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lock Header
  // ---------------------------------------------------------------------------

  Widget _buildLockHeader() {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyberEmerald.withValues(
              alpha: 0.10,
            ),
            border: Border.all(
              color: AppColors.cyberEmerald.withValues(
                alpha: 0.20,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyberEmerald.withValues(
                  alpha: 0.12,
                ),
                blurRadius: 30,
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: AppColors.cyberEmerald,
            size: 32,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context).unlockVault,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          AppLocalizations.of(context).pinAccessDescription,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PIN Indicator
  // ---------------------------------------------------------------------------

  Widget _buildPinIndicator() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _pinLength,
          (index) {
            final filled = index < _digits.length;

            return AnimatedContainer(
              duration: const Duration(
                milliseconds: 160,
              ),
              width: filled ? 18 : 16,
              height: filled ? 18 : 16,
              margin: const EdgeInsets.symmetric(
                horizontal: 7,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.cyberEmerald : AppColors.glassStrong,
                border: Border.all(
                  color:
                      filled ? AppColors.cyberEmerald : AppColors.glassBorder,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: AppColors.cyberEmerald.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Keypad
  // ---------------------------------------------------------------------------

  Widget _buildKeypad() {
    const keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '',
      '0',
      'delete',
    ];

    // لوحة الأرقام دائمًا LTR حتى في الواجهة العربية.
    //
    // النتيجة:
    //
    // 1   2   3
    // 4   5   6
    // 7   8   9
    //     0   ⌫
    //
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: keys.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final key = keys[index];

            if (key.isEmpty) {
              return const SizedBox.shrink();
            }

            if (key == 'delete') {
              return _KeyButton(
                icon: Icons.backspace_outlined,
                onPressed:
                    _digits.isEmpty || _isSubmitting ? null : _removeDigit,
              );
            }

            return _KeyButton(
              label: key,
              onPressed: _isSubmitting ? null : () => _addDigit(key),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Unlock Button
  // ---------------------------------------------------------------------------

  Widget _buildUnlockButton() {
    final enabled = _isComplete && !_isSubmitting;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: enabled ? _unlock : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  AppLocalizations.of(context).unlockVault,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Key Button
// -----------------------------------------------------------------------------

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    this.label,
    this.icon,
    required this.onPressed,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.glassBorder,
            ),
          ),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Icon(
                    icon,
                    color: onPressed == null
                        ? AppColors.textPrimary.withValues(
                            alpha: 0.35,
                          )
                        : AppColors.textPrimary,
                    size: 23,
                  ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Background
// -----------------------------------------------------------------------------

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GlowPainter(),
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width * 0.5,
      size.height * 0.08,
    );

    final radius = size.width * 0.85;

    final gradient = RadialGradient(
      colors: [
        AppColors.cyberEmerald.withValues(
          alpha: 0.08,
        ),
        Colors.transparent,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
      );

    canvas.drawCircle(
      center,
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
