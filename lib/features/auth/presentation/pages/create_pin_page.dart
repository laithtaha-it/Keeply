import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'confirm_pin_page.dart';

class CreatePinPage extends StatefulWidget {
  const CreatePinPage({
    super.key,
  });

  @override
  State<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
  static const int _pinLength = 6;

  final List<String> _digits = [];

  String get _pin => _digits.join();

  bool get _isComplete => _digits.length == _pinLength;

  bool get _isWeakPin {
    if (!_isComplete) {
      return false;
    }

    // Reject repeated digits:
    // 000000, 111111, 222222, etc.
    if (_digits.every((digit) => digit == _digits.first)) {
      return true;
    }

    // Reject ascending sequence.
    if (_pin == '123456') {
      return true;
    }

    // Reject descending sequence.
    if (_pin == '654321') {
      return true;
    }

    // Reject repeated pairs:
    // 121212, 343434, 565656, etc.
    if (_pin.substring(0, 2) == _pin.substring(2, 4) &&
        _pin.substring(2, 4) == _pin.substring(4, 6)) {
      return true;
    }

    return false;
  }

  void _addDigit(String digit) {
    if (_digits.length >= _pinLength) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _digits.add(digit);
    });
  }

  void _removeDigit() {
    if (_digits.isEmpty) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _digits.removeLast();
    });
  }

  void _continue() {
    if (!_isComplete || _isWeakPin) {
      return;
    }

    HapticFeedback.mediumImpact();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return ConfirmPinPage(
            pin: _pin,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
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
                      _buildHeader(
                        theme,
                        localizations,
                      ),

                      // Keep exactly the same spacing as ConfirmPinPage.
                      SizedBox(
                        height: _responsiveSpacing(
                          height,
                          0.025,
                        ),
                      ),

                      _buildPinIndicator(
                        localizations,
                      ),

                      if (_isWeakPin) ...[
                        SizedBox(
                          height: _responsiveSpacing(
                            height,
                            0.018,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          child: _WeakPinWarning(
                            message: localizations.weakPinWarning,
                          ),
                        ),
                      ],

                      SizedBox(
                        height: _responsiveSpacing(
                          height,
                          _isWeakPin ? 0.018 : 0.035,
                        ),
                      ),

                      _buildKeypad(),

                      SizedBox(
                        height: _responsiveSpacing(
                          height,
                          0.025,
                        ),
                      ),

                      _buildContinueButton(
                        localizations,
                      ),

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
    );
  }

  // ===========================================================================
  // Responsive Spacing
  // ===========================================================================

  double _responsiveSpacing(
    double height,
    double factor,
  ) {
    return (height * factor).clamp(55.0, 55.0).toDouble();
  }

  // ===========================================================================
  // Header
  // ===========================================================================

  Widget _buildHeader(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
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
            onPressed: () {
              Navigator.of(context).pop();
            },
            tooltip: localizations.back,
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),
          const Spacer(),
          Text(
            localizations.createPinStep,
            style: theme.textTheme.bodyMedium?.copyWith(
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

  Widget _buildPinIndicator(
    AppLocalizations localizations,
  ) {
    return Column(
      children: [
        Text(
          localizations.createPinTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: Text(
            localizations.createPinSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
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

  Widget _buildPinDots() {
    return Row(
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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
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
                onPressed: _digits.isEmpty ? null : _removeDigit,
              );
            }

            return _KeyButton(
              label: key,
              onPressed: () {
                _addDigit(key);
              },
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // Continue Button
  // ===========================================================================

  Widget _buildContinueButton(
    AppLocalizations localizations,
  ) {
    final enabled = _isComplete && !_isWeakPin;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: enabled ? _continue : null,
          child: Text(
            localizations.continueButton,
            style: const TextStyle(
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

// =============================================================================
// Weak PIN Warning
// =============================================================================

class _WeakPinWarning extends StatelessWidget {
  const _WeakPinWarning({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Row(
        textDirection: Directionality.of(context),
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
