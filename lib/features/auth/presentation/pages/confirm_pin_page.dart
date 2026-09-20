import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'vault_home_page.dart';
import '../../../../l10n/app_localizations.dart';

class ConfirmPinPage extends StatefulWidget {
  const ConfirmPinPage({
    super.key,
    required this.pin,
  });

  final String pin;

  @override
  State<ConfirmPinPage> createState() => _ConfirmPinPageState();
}

class _ConfirmPinPageState extends State<ConfirmPinPage> {
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
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: height,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 16,
                    ),
                    child: Column(
                      children: [
                        _buildHeader(),
                        SizedBox(
                          height: _responsiveSpacing(
                            height,
                            0.025,
                            min: 55,
                            max: 55,
                          ),
                        ),
                        _buildPinIndicator(),
                        SizedBox(
                          height: _responsiveSpacing(
                            height,
                            0.035,
                            min: 55,
                            max: 55,
                          ),
                        ),
                        _buildKeypad(),
                        SizedBox(
                          height: _responsiveSpacing(
                            height,
                            0.025,
                            min: 55,
                            max: 55,
                          ),
                        ),
                        _buildConfirmButton(),
                        const SizedBox(
                          height: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Responsive Spacing
  // ===========================================================================

  double _responsiveSpacing(
    double height,
    double factor, {
    required double min,
    required double max,
  }) {
    return (height * factor).clamp(min, max).toDouble();
  }

  // ===========================================================================
  // Auth State
  // ===========================================================================

  void _handleAuthState(
    BuildContext context,
    AuthState state,
  ) {
    if (!mounted) {
      return;
    }

    if (state.status == AuthStatus.failure) {
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

    if (state.status == AuthStatus.authenticated && state.isPinConfigured) {
      setState(() {
        _isSubmitting = false;
      });

      HapticFeedback.heavyImpact();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const VaultHomePage(),
        ),
        (route) => false,
      );
    }
  }

  // ===========================================================================
  // Errors
  // ===========================================================================

  String _friendlyError(String? error) {
    switch (error) {
      case 'pin_too_short':
        return AppLocalizations.of(context).pinMinimumDigits;

      case 'pin_too_long':
        return AppLocalizations.of(context).pinMaximumDigits;

      case 'invalid_pin':
        return AppLocalizations.of(context).invalidPin;

      case 'pin_too_weak':
        return AppLocalizations.of(context).strongerPin;

      case 'unlock_failed':
        return AppLocalizations.of(context).vaultUnlockError;

      default:
        return AppLocalizations.of(context).pinCreationErrorRetry;
    }
  }

  // ===========================================================================
  // Confirm
  // ===========================================================================

  Future<void> _confirm() async {
    if (!_isComplete || _isSubmitting) {
      return;
    }

    HapticFeedback.mediumImpact();

    if (_pin != widget.pin) {
      HapticFeedback.heavyImpact();

      setState(() {
        _digits.clear();
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).pinMismatchRetry,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await context.read<AuthCubit>().createPin(widget.pin);

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // ===========================================================================
  // Header
  // ===========================================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            tooltip: AppLocalizations.of(context).back,
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),
          const Spacer(),
          Text(
            '2 / 2',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PIN Indicator
  // ===========================================================================

  Widget _buildPinIndicator() {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context).confirmPin,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: Text(
            AppLocalizations.of(context).pinRememberDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(
          height: 28,
        ),
        _buildPinDots(),
      ],
    );
  }

  // ===========================================================================
  // PIN Dots
  // ===========================================================================

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: TextDirection.ltr,
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
                color: filled ? AppColors.cyberEmerald : AppColors.glassBorder,
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
    );
  }

  // ===========================================================================
  // Keypad
  // ===========================================================================

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

    return Directionality(
      // مهم جدًا:
      // لوحة الأرقام دائمًا LTR حتى لو كانت الصفحة عربية RTL.
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
              onPressed: _isSubmitting
                  ? null
                  : () {
                      _addDigit(key);
                    },
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // Add Digit
  // ===========================================================================

  void _addDigit(String digit) {
    if (_digits.length >= _pinLength || _isSubmitting) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _digits.add(digit);
    });
  }

  // ===========================================================================
  // Remove Digit
  // ===========================================================================

  void _removeDigit() {
    if (_digits.isEmpty || _isSubmitting) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _digits.removeLast();
    });
  }

  // ===========================================================================
  // Confirm Button
  // ===========================================================================

  Widget _buildConfirmButton() {
    final enabled = _isComplete && !_isSubmitting;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: enabled ? _confirm : null,
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
                  AppLocalizations.of(context).confirmPin,
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

// =============================================================================
// Key Button
// =============================================================================

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
                    // الأرقام نفسها إنجليزية واتجاهها LTR.
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
                        ? AppColors.textMuted.withValues(
                            alpha: 0.35,
                          )
                        : AppColors.textSecondary,
                    size: 23,
                  ),
          ),
        ),
      ),
    );
  }
}
