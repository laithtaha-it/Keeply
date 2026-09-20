import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/bookmarks/presentation/pages/bookmarks_page.dart';
import '../../../../features/files/presentation/pages/files_page.dart';
import '../../../../features/media/presentation/pages/media_page.dart';
import '../../../../features/settings/presentation/pages/settings_page.dart';
import 'passwords_page.dart';

class VaultHomePage extends StatelessWidget {
  const VaultHomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            const _BackgroundGlow(),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ==========================================================
                  // Header
                  // ==========================================================
                  SliverToBoxAdapter(
                    child: _buildHeader(
                      context,
                      l10n,
                      isArabic,
                    ),
                  ),

                  // ==========================================================
                  // Main Content
                  // ==========================================================
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      28,
                      20,
                      30,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          const _VaultStatusCard(),
                          const SizedBox(height: 30),
                          _VaultGrid(
                            isArabic: isArabic,
                          ),
                          const SizedBox(height: 32),
                          _DeveloperCard(
                            l10n: l10n,
                            isArabic: isArabic,
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        26,
        16,
        0,
      ),
      child: Row(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
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
              Icons.shield_rounded,
              color: AppColors.cyberEmerald,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.keeplyTitle,
                  textAlign: isArabic ? TextAlign.end : TextAlign.start,
                  style: TextStyle(
                    fontFamily: isArabic ? 'Tajawal' : null,
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: isArabic ? 0 : -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.yourKeeply,
                  textAlign: isArabic ? TextAlign.end : TextAlign.start,
                  style: TextStyle(
                    fontFamily: isArabic ? 'Tajawal' : null,
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _HeaderButton(
            icon: Icons.lock_outline_rounded,
            tooltip: l10n.vaultLocked,
            onPressed: () {
              context.read<AuthCubit>().lock();
            },
          ),
          const SizedBox(width: 6),
          _HeaderButton(
            icon: Icons.settings_outlined,
            tooltip: l10n.settings,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Vault Status Card
// ============================================================================

class _VaultStatusCard extends StatelessWidget {
  const _VaultStatusCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cyberEmerald.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.cyberEmerald.withValues(
                alpha: 0.18,
              ),
            ),
          ),
          child: Row(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cyberEmerald.withValues(
                    alpha: 0.12,
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.cyberEmerald,
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.vaultUnlocked,
                      textAlign: isArabic ? TextAlign.end : TextAlign.start,
                      style: TextStyle(
                        fontFamily: isArabic ? 'Tajawal' : null,
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      l10n.vaultDescription,
                      textAlign: isArabic ? TextAlign.end : TextAlign.start,
                      style: TextStyle(
                        fontFamily: isArabic ? 'Tajawal' : null,
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              const Icon(
                Icons.lock_rounded,
                color: AppColors.cyberEmerald,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Vault Grid
// ============================================================================

class _VaultGrid extends StatelessWidget {
  const _VaultGrid({
    required this.isArabic,
  });

  final bool isArabic;

  List<_VaultModule> _modules(AppLocalizations l10n) {
    return [
      _VaultModule(
        title: l10n.passwords,
        subtitle: l10n.passwordsAndEmails,
        icon: Icons.key_rounded,
        accent: AppColors.cyberEmerald,
        type: _VaultModuleType.passwords,
      ),
      _VaultModule(
        title: l10n.bookmarks,
        subtitle: l10n.description,
        icon: Icons.link_rounded,
        accent: AppColors.cyberEmerald,
        type: _VaultModuleType.bookmarks,
      ),
      _VaultModule(
        title: l10n.media,
        subtitle: l10n.photos,
        icon: Icons.photo_library_rounded,
        accent: AppColors.cyberEmerald,
        type: _VaultModuleType.media,
      ),
      _VaultModule(
        title: l10n.documents,
        subtitle: l10n.docsAndFolders,
        icon: Icons.folder_rounded,
        accent: AppColors.cyberEmerald,
        type: _VaultModuleType.documents,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final modules = _modules(l10n);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.12,
      ),
      itemBuilder: (context, index) {
        final module = modules[index];

        return _VaultModuleCard(
          module: module,
          isArabic: isArabic,
          onCloudAction: () => _showCloudActions(context, module),
          onTap: () {
            switch (module.type) {
              case _VaultModuleType.passwords:
                _openPasswordsPage(context);
                break;

              case _VaultModuleType.bookmarks:
                _openBookmarksPage(context);
                break;

              case _VaultModuleType.media:
                _openMediaPage(context);
                break;

              case _VaultModuleType.documents:
                _openFilesPage(context);
                break;
            }
          },
        );
      },
    );
  }

  Future<void> _showCloudActions(
    BuildContext context,
    _VaultModule module,
  ) async {
    final l10n = AppLocalizations.of(context);
    final backupService = context.read<BackupService>();
    final section = module.backupSection;

    final action = await showModalBottomSheet<_CloudAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isArabic = Directionality.of(sheetContext) == TextDirection.rtl;
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Theme.of(sheetContext).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${l10n.cloudActions} · ${module.title}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: Text(l10n.uploadToCloud),
                  onTap: () => Navigator.of(sheetContext).pop(
                    _CloudAction.upload,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: Text(l10n.downloadFromCloud),
                  onTap: () => Navigator.of(sheetContext).pop(
                    _CloudAction.download,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null || !context.mounted) {
      return;
    }

    try {
      await backupService.ensureInternetConnection();
    } on NoInternetConnectionException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noInternetConnection)),
        );
      }
      return;
    }

    if (!backupService.isGoogleConnected) {
      final account = await backupService.googleDriveService.signIn();
      if (account == null || !context.mounted) {
        return;
      }
    }

    if (action == _CloudAction.download) {
      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.downloadFromCloud),
            content: Text(l10n.cloudActionConfirmRestore),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.downloadFromCloud),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !context.mounted) return;
    }

    final isUpload = action == _CloudAction.upload;
    final progress = ValueNotifier<BackupProgress>(
      BackupProgress(
        operation: isUpload ? BackupOperation.upload : BackupOperation.download,
        currentItem: '',
        currentItemIndex: 0,
        totalItems: 0,
        currentBytes: 0,
        currentItemTotalBytes: 0,
        transferredBytes: 0,
        totalBytes: 0,
        speedBytesPerSecond: 0,
      ),
    );

    if (context.mounted) {
      _showCloudTransferProgress(
        context,
        progress,
        isUpload ? l10n.uploadToCloud : l10n.downloadFromCloud,
      );
    }

    try {
      if (isUpload) {
        await backupService.syncToGoogleDrive(
          sections: {section},
          onProgress: (value) => progress.value = value,
        );
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.sectionUploadedSuccessfully(section: module.title),
              ),
            ),
          );
        }
      } else {
        await backupService.restoreFromGoogleDrive(
          sections: {section},
          onProgress: (value) => progress.value = value,
        );
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.sectionDownloadedSuccessfully(section: module.title),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        final message = e is NoInternetConnectionException
            ? l10n.noInternetConnection
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      progress.dispose();
    }
  }

  void _showCloudTransferProgress(
    BuildContext context,
    ValueNotifier<BackupProgress> progress,
    String title,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ValueListenableBuilder<BackupProgress>(
          valueListenable: progress,
          builder: (_, value, __) {
            final hasTotal = value.totalBytes > 0;
            final percent = (value.fraction * 100).toStringAsFixed(0);

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: hasTotal ? value.fraction : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      hasTotal
                          ? '${_formatCloudBytes(value.transferredBytes)} / '
                              '${_formatCloudBytes(value.totalBytes)}  •  $percent%'
                          : _formatCloudBytes(value.transferredBytes),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatCloudBytes(value.speedBytesPerSecond.round())}/s',
                    ),
                    if (value.eta != null) ...[
                      const SizedBox(height: 4),
                      Text('ETA ${_formatCloudDuration(value.eta!)}'),
                    ],
                    if (value.totalItems > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${value.currentItemIndex} / ${value.totalItems}',
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatCloudBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatCloudDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h '
          '${duration.inMinutes.remainder(60)}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m '
          '${duration.inSeconds.remainder(60)}s';
    }
    return '${duration.inSeconds}s';
  }

  void _openPasswordsPage(BuildContext context) {
    final hiveService = RepositoryProvider.of<HiveService>(context);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return PasswordsPage(
            hiveService: hiveService,
          );
        },
      ),
    );
  }

  void _openBookmarksPage(BuildContext context) {
    final hiveService = RepositoryProvider.of<HiveService>(context);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return BookmarksPage(
            hiveService: hiveService,
          );
        },
      ),
    );
  }

  void _openMediaPage(BuildContext context) {
    final hiveService = RepositoryProvider.of<HiveService>(context);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return MediaPage(
            hiveService: hiveService,
          );
        },
      ),
    );
  }

  void _openFilesPage(BuildContext context) {
    final hiveService = RepositoryProvider.of<HiveService>(context);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return FilesPage(
            hiveService: hiveService,
          );
        },
      ),
    );
  }
}

// ============================================================================
// Vault Module
// ============================================================================

enum _VaultModuleType {
  passwords,
  bookmarks,
  media,
  documents,
}

enum _CloudAction {
  upload,
  download,
}

class _VaultModule {
  const _VaultModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.type,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final _VaultModuleType type;

  BackupSection get backupSection {
    switch (type) {
      case _VaultModuleType.passwords:
        return BackupSection.passwords;
      case _VaultModuleType.bookmarks:
        return BackupSection.bookmarks;
      case _VaultModuleType.media:
        return BackupSection.media;
      case _VaultModuleType.documents:
        return BackupSection.documents;
    }
  }
}

// ============================================================================
// Vault Module Card
// ============================================================================

class _VaultModuleCard extends StatelessWidget {
  const _VaultModuleCard({
    required this.module,
    required this.isArabic,
    required this.onTap,
    required this.onCloudAction,
  });

  final _VaultModule module;
  final bool isArabic;
  final VoidCallback onTap;
  final VoidCallback onCloudAction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.glassBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: module.accent.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: module.accent.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Icon(
                        module.icon,
                        color: module.accent,
                        size: 23,
                      ),
                    ),
                    const Spacer(),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: onCloudAction,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.glass,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.glassBorder,
                            ),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            color: AppColors.textSecondary,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    module.title,
                    textAlign: isArabic ? TextAlign.end : TextAlign.start,
                    style: TextStyle(
                      fontFamily: isArabic ? 'Tajawal' : null,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    module.subtitle,
                    textAlign: isArabic ? TextAlign.end : TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: isArabic ? 'Tajawal' : null,
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
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

// ============================================================================
// Developer Card
// ============================================================================

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({
    required this.l10n,
    required this.isArabic,
  });

  final AppLocalizations l10n;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 9,
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
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Icon(
              Icons.code_rounded,
              size: 14,
              color: AppColors.cyberEmerald.withValues(
                alpha: 0.85,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '${l10n.developer}:',
              style: TextStyle(
                fontFamily: isArabic ? 'Tajawal' : null,
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              l10n.developerName,
              style: TextStyle(
                fontFamily: isArabic ? 'Tajawal' : null,
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Header Button
// ============================================================================

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.glassBorder,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.textSecondary,
            size: 21,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Background Glow
// ============================================================================

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
      size.height * 0.05,
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
