import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/language_controller.dart';
import '../../../backup/presentation/pages/backup_page.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ---------------------------------------------------------------------------
  // Developer Links
  // ---------------------------------------------------------------------------

  static final Uri _githubUri = Uri.parse(
    'https://github.com/laithtahatech',
  );

  static final Uri _linkedinUri = Uri.parse(
    'https://www.linkedin.com/in/laith-taha-32633042',
  );

  static final Uri _instagramUri = Uri.parse(
    'https://www.instagram.com/0wlll_?igsi=eWZwYnJuemt0MTF5&utm_source=qr',
  );

  static final Uri _emailUri = Uri(
    scheme: 'mailto',
    path: 'laith.taha.tech@gmail.com',
  );

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _openBackupPage() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BackupPage(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // External Links
  // ---------------------------------------------------------------------------

  Future<void> _openExternalLink(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showLinkError();
      }
    } catch (_) {
      if (mounted) {
        _showLinkError();
      }
    }
  }

  void _showLinkError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).linkOpenError,
          style: const TextStyle(
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const _SettingsBackgroundGlow(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ----------------------------------------------------------------
                // Header
                // ----------------------------------------------------------------

                SliverToBoxAdapter(
                  child: _buildHeader(context),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    40,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        // -------------------------------------------------------
                        // Backup
                        // -------------------------------------------------------

                        _SectionTitle(
                          title: l10n.backup,
                          subtitle: l10n.backupSectionDescription,
                        ),

                        const SizedBox(height: 14),

                        _BackupEntryCard(
                          onTap: _openBackupPage,
                        ),

                        const SizedBox(height: 30),

                        // -------------------------------------------------------
                        // Language
                        // -------------------------------------------------------

                        const _LanguageCard(),

                        const SizedBox(height: 30),

                        // -------------------------------------------------------
                        // About
                        // -------------------------------------------------------

                        _SectionTitle(
                          title: l10n.about,
                          subtitle: l10n.aboutSectionDescription,
                        ),

                        const SizedBox(height: 14),

                        const _AboutKeeplyCard(),

                        const SizedBox(height: 16),

                        // -------------------------------------------------------
                        // Developer
                        // -------------------------------------------------------

                        const _DeveloperCard(),

                        const SizedBox(height: 12),

                        // -------------------------------------------------------
                        // Social Links
                        // -------------------------------------------------------

                        _SocialLinksCard(
                          onGithubTap: () => _openExternalLink(
                            _githubUri,
                          ),
                          onLinkedinTap: () => _openExternalLink(
                            _linkedinUri,
                          ),
                          onInstagramTap: () => _openExternalLink(
                            _instagramUri,
                          ),
                          onEmailTap: () => _openExternalLink(
                            _emailUri,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // -------------------------------------------------------
                        // Version
                        // -------------------------------------------------------

                        Center(
                          child: Text(
                            l10n.versionText,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10.5,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        0,
      ),
      child: Row(
        children: [
          _BackButton(
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 13),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.cyberEmerald.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.cyberEmerald.withValues(
                  alpha: 0.20,
                ),
              ),
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: AppColors.cyberEmerald,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settings,
                  textAlign: isRTL ? TextAlign.end : TextAlign.start,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.settingsManagement,
                  textAlign: isRTL ? TextAlign.end : TextAlign.start,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Language Card
// =============================================================================

class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<LanguageController>();
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cyberEmerald.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: AppColors.cyberEmerald,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.language,
                      textAlign: isRTL ? TextAlign.end : TextAlign.start,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.languageDescription,
                      textAlign: isRTL ? TextAlign.end : TextAlign.start,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'ar',
                label: Text(
                  l10n.arabic,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                  ),
                ),
                icon: const Icon(
                  Icons.translate_rounded,
                  size: 18,
                ),
              ),
              ButtonSegment<String>(
                value: 'en',
                label: Text(
                  l10n.english,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                  ),
                ),
                icon: const Icon(
                  Icons.translate_rounded,
                  size: 18,
                ),
              ),
            ],
            selected: {
              controller.locale.languageCode,
            },
            onSelectionChanged: (selection) {
              controller.setLanguage(
                selection.first,
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Backup Entry Card
// =============================================================================

class _BackupEntryCard extends StatelessWidget {
  const _BackupEntryCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.glassBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.cyberEmerald.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.backup_rounded,
                      color: AppColors.cyberEmerald,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: isRTL
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.backupRestore,
                          textAlign: isRTL ? TextAlign.end : TextAlign.start,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          l10n.backupEntryDescription,
                          textAlign: isRTL ? TextAlign.end : TextAlign.start,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.cyberEmerald.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.glass,
                      ),
                    ),
                    child: Icon(
                      isRTL
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: AppColors.cyberEmerald,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// About Keeply Card
// =============================================================================

class _AboutKeeplyCard extends StatelessWidget {
  const _AboutKeeplyCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cyberEmerald.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppColors.cyberEmerald,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  l10n.keeply,
                  textAlign: isRTL ? TextAlign.end : TextAlign.start,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.aboutDescriptionPart1 +
                l10n.aboutDescriptionPart2 +
                l10n.aboutDescriptionPart3,
            textAlign: isRTL ? TextAlign.end : TextAlign.start,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.65,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Developer Card
// =============================================================================

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.neonBlue.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.code_rounded,
              color: AppColors.neonBlue,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.developedBy,
                  textAlign: isRTL ? TextAlign.end : TextAlign.start,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.developerName,
                  textAlign: isRTL ? TextAlign.end : TextAlign.start,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Social Links Card
// =============================================================================

class _SocialLinksCard extends StatelessWidget {
  const _SocialLinksCard({
    required this.onGithubTap,
    required this.onLinkedinTap,
    required this.onInstagramTap,
    required this.onEmailTap,
  });

  final VoidCallback onGithubTap;
  final VoidCallback onLinkedinTap;
  final VoidCallback onInstagramTap;
  final VoidCallback onEmailTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.glassBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SocialButton(
            icon: Icons.code_rounded,
            label: 'GitHub',
            onTap: onGithubTap,
          ),
          const _SocialDivider(),
          _SocialButton(
            icon: Icons.work_outline_rounded,
            label: 'LinkedIn',
            onTap: onLinkedinTap,
          ),
          const _SocialDivider(),
          _SocialButton(
            icon: Icons.camera_alt_outlined,
            label: 'Instagram',
            onTap: onInstagramTap,
          ),
          const _SocialDivider(),
          _SocialButton(
            icon: Icons.email_outlined,
            label: 'Email',
            onTap: onEmailTap,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Social Button
// =============================================================================

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.neonBlue.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.neonBlue,
                    size: 21,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Social Divider
// =============================================================================

class _SocialDivider extends StatelessWidget {
  const _SocialDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      color: AppColors.glassBorder,
    );
  }
}

// =============================================================================
// Section Title
// =============================================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Column(
      crossAxisAlignment:
          isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: isRTL ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: 'Tajawal',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: isRTL ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11.5,
            height: 1.35,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Back Button
// =============================================================================

class _BackButton extends StatelessWidget {
  const _BackButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: AppColors.glass,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.glassBorder,
            ),
          ),
          child: Icon(
            isRTL ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Background Glow
// =============================================================================

class _SettingsBackgroundGlow extends StatelessWidget {
  const _SettingsBackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _SettingsGlowPainter(),
        ),
      ),
    );
  }
}

class _SettingsGlowPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width * 0.5,
      size.height * 0.05,
    );

    final radius = size.width * 0.85;

    final gradient = RadialGradient(
      colors: [
        AppColors.cyberEmerald.withValues(
          alpha: 0.07,
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
