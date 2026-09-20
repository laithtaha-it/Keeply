import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'create_pin_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? Directionality.of(context) : TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            const _Background(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 520,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // ======================================================
                        // Logo
                        // ======================================================

                        const _MainLogo(),

                        const SizedBox(height: 28),

                        // ======================================================
                        // Title
                        // ======================================================

                        Text(
                          l10n.keeplyTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontFamily: isArabic ? 'Tajawal' : null,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: isArabic ? 0 : -1.2,
                            height: 1.1,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ======================================================
                        // Subtitle
                        // ======================================================

                        Text(
                          l10n.welcomeSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontFamily: isArabic ? 'Tajawal' : null,
                            color: AppColors.textSecondary,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w400,
                            height: 1.55,
                            letterSpacing: isArabic ? 0 : -0.1,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ======================================================
                        // Security Feature 01
                        // ======================================================

                        _SecurityCard(
                          icon: AppIcons.folder,
                          title: l10n.offlineFirst,
                          description: l10n.offlineFirstDescription,
                          number: '03',
                          isArabic: isArabic,
                        ),

                        const SizedBox(height: 14),

                        // ======================================================
                        // Security Feature 02
                        // ======================================================

                        _SecurityCard(
                          icon: AppIcons.backup,
                          title: l10n.secureAccess,
                          description: l10n.secureAccessDescription,
                          number: '02',
                          isArabic: isArabic,
                        ),

                        const SizedBox(height: 14),

                        // ======================================================
                        // Security Feature 03
                        // ======================================================
                        _SecurityCard(
                          icon: AppIcons.security,
                          title: l10n.privateByDesign,
                          description: l10n.privateByDesignDescription,
                          number: '01',
                          isArabic: isArabic,
                        ),

                        const SizedBox(height: 34),

                        // ======================================================
                        // Get Started
                        // ======================================================

                        _GetStartedButton(
                          label: l10n.getStarted,
                          isArabic: isArabic,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CreatePinPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // ======================================================
                        // Encryption Badge
                        // ======================================================

                        _EncryptionBadge(
                          localEncryption: l10n.localEncryption,
                          isArabic: isArabic,
                        ),

                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Background
// ============================================================================

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _BackgroundPainter(),
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final mainCenter = Offset(
      size.width * 0.5,
      size.height * 0.04,
    );

    final mainRadius = size.width * 0.9;

    final mainPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.cyberEmerald.withValues(alpha: 0.13),
          AppColors.cyberEmerald.withValues(alpha: 0.035),
          Colors.transparent,
        ],
        stops: const [
          0,
          0.42,
          1,
        ],
      ).createShader(
        Rect.fromCircle(
          center: mainCenter,
          radius: mainRadius,
        ),
      );

    canvas.drawCircle(
      mainCenter,
      mainRadius,
      mainPaint,
    );

    final lowerCenter = Offset(
      size.width * 0.88,
      size.height * 0.78,
    );

    final lowerRadius = size.width * 0.45;

    final lowerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.cyberEmerald.withValues(alpha: 0.035),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: lowerCenter,
          radius: lowerRadius,
        ),
      );

    canvas.drawCircle(
      lowerCenter,
      lowerRadius,
      lowerPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ============================================================================
// Main Logo
// ============================================================================

class _MainLogo extends StatelessWidget {
  const _MainLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.cyberEmerald.withValues(
                  alpha: 0.10,
                ),
              ),
            ),
          ),
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyberEmerald.withValues(
                alpha: 0.035,
              ),
              border: Border.all(
                color: AppColors.cyberEmerald.withValues(
                  alpha: 0.16,
                ),
              ),
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyberEmerald.withValues(
                alpha: 0.095,
              ),
              border: Border.all(
                color: AppColors.cyberEmerald.withValues(
                  alpha: 0.30,
                ),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyberEmerald.withValues(
                    alpha: 0.20,
                  ),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              AppIcons.vault,
              color: AppColors.cyberEmerald,
              size: 40,
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyberEmerald,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyberEmerald.withValues(
                      alpha: 0.55,
                    ),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Security Card
// ============================================================================

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.number,
    required this.isArabic,
  });

  final IconData icon;
  final String title;
  final String description;
  final String number;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.glassStrong,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1,
            ),
          ),
          child: Row(
            textDirection:
                isArabic ? Directionality.of(context) : TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ==============================================================
              // Icon
              // ==============================================================

              _IconContainer(
                icon: icon,
              ),

              const SizedBox(width: 16),

              // ==============================================================
              // Content
              // ==============================================================

              Expanded(
                child: Column(
                  crossAxisAlignment: isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Row(
                      textDirection: isArabic
                          ? Directionality.of(context)
                          : TextDirection.ltr,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            textAlign:
                                isArabic ? TextAlign.end : TextAlign.start,
                            style: TextStyle(
                              fontFamily: isArabic ? 'Tajawal' : null,
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          number,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      textAlign: isArabic ? TextAlign.end : TextAlign.start,
                      style: TextStyle(
                        fontFamily: isArabic ? 'Tajawal' : null,
                        color: AppColors.textMuted,
                        fontSize: 12.3,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Icon Container
// ============================================================================

class _IconContainer extends StatelessWidget {
  const _IconContainer({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.cyberEmerald.withValues(
          alpha: 0.08,
        ),
        border: Border.all(
          color: AppColors.cyberEmerald.withValues(
            alpha: 0.18,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyberEmerald.withValues(
              alpha: 0.08,
            ),
            blurRadius: 18,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 28,
        color: AppColors.cyberEmerald,
      ),
    );
  }
}

// ============================================================================
// Get Started Button
// ============================================================================

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({
    required this.label,
    required this.isArabic,
    required this.onPressed,
  });

  final String label;
  final bool isArabic;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyberEmerald.withValues(
                alpha: 0.20,
              ),
              blurRadius: 26,
              spreadRadius: -5,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: AppColors.cyberEmerald,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection:
                isArabic ? Directionality.of(context) : TextDirection.ltr,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: isArabic ? 'Tajawal' : null,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 11),
              Icon(
                isArabic ? AppIcons.forward : AppIcons.forward,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Encryption Badge
// ============================================================================

class _EncryptionBadge extends StatelessWidget {
  const _EncryptionBadge({
    required this.localEncryption,
    required this.isArabic,
  });

  final String localEncryption;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: AppColors.glass,
        border: Border.all(
          color: AppColors.glassBorder.withValues(
            alpha: 0.7,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection:
            isArabic ? Directionality.of(context) : TextDirection.ltr,
        children: [
          Icon(
            AppIcons.lock,
            size: 13,
            color: AppColors.cyberEmerald.withValues(
              alpha: 0.85,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'AES-256',
            style: TextStyle(
              fontFamily: isArabic ? 'Tajawal' : null,
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: isArabic ? 0 : 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textMuted.withValues(
                alpha: 0.55,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            localEncryption,
            style: TextStyle(
              fontFamily: isArabic ? 'Tajawal' : null,
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
