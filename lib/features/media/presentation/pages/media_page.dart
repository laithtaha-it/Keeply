import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/media_item.dart';
import '../../../../l10n/app_localizations.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({
    super.key,
    required this.hiveService,
  });

  final HiveService hiveService;

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  List<MediaItem> _mediaItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  // ===========================================================================
  // تحميل الوسائط
  // ===========================================================================

  Future<void> _loadMedia() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final items = widget.hiveService.getAllMedia();
      final validItems = <MediaItem>[];

      for (final item in items) {
        final file = File(item.filePath);

        if (await file.exists()) {
          validItems.add(item);
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _mediaItems = validItems.reversed.toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(AppLocalizations.of(context).mediaLoadError);
    }
  }

  // ===========================================================================
  // اختيار الوسائط
  // ===========================================================================

  Future<void> _pickMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.media,
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final vaultDirectory = await _getVaultMediaDirectory();

      int savedCount = 0;

      for (final pickedFile in result.files) {
        final originalPath = pickedFile.path;

        if (originalPath == null || originalPath.trim().isEmpty) {
          continue;
        }

        final originalFile = File(originalPath);

        if (!await originalFile.exists()) {
          continue;
        }

        final fileName = pickedFile.name.trim().isNotEmpty
            ? pickedFile.name.trim()
            : p.basename(originalPath);

        final pickerExtension =
            pickedFile.extension?.trim().toLowerCase() ?? '';

        final nameExtension =
            p.extension(fileName).replaceFirst('.', '').toLowerCase();

        final fileType =
            pickerExtension.isNotEmpty ? pickerExtension : nameExtension;

        final timestamp = DateTime.now().microsecondsSinceEpoch;

        final safeFileName = _createSafeFileName(
          fileName,
          timestamp,
        );

        final destinationPath = p.join(
          vaultDirectory.path,
          safeFileName,
        );

        final copiedFile = await originalFile.copy(
          destinationPath,
        );

        final now = DateTime.now();

        final item = MediaItem(
          id: '${timestamp}_$savedCount',
          filePath: copiedFile.path,
          fileName: fileName,
          fileType: fileType,
          description: '',
          createdAt: now,
          updatedAt: now,
        );

        if (!item.hasData) {
          try {
            await copiedFile.delete();
          } catch (_) {}

          continue;
        }

        await widget.hiveService.putMedia(item);

        savedCount++;
      }

      await _loadMedia();

      if (!mounted) {
        return;
      }

      if (savedCount == 0) {
        _showMessage(AppLocalizations.of(context).mediaEmpty);
        return;
      }

      if (savedCount == 1) {
        _showMessage(AppLocalizations.of(context).mediaAdded);
      } else {
        _showMessage(
          AppLocalizations.of(context).mediaAddedCount(savedCount: savedCount),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(AppLocalizations.of(context).mediaAddError);
    }
  }

  // ===========================================================================
  // مجلد الوسائط
  // ===========================================================================

  Future<Directory> _getVaultMediaDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final vaultDirectory = Directory(
      p.join(
        appDirectory.path,
        'secure_vault_media',
      ),
    );

    if (!await vaultDirectory.exists()) {
      await vaultDirectory.create(
        recursive: true,
      );
    }

    return vaultDirectory;
  }

  String _createSafeFileName(
    String originalName,
    int timestamp,
  ) {
    final extension = p.extension(originalName);

    final baseName = p.basenameWithoutExtension(
      originalName,
    );

    final safeBaseName = baseName
        .replaceAll(
          RegExp(r'[^a-zA-Z0-9_\- ]'),
          '_',
        )
        .trim();

    final finalBaseName = safeBaseName.isEmpty ? 'media' : safeBaseName;

    return '${finalBaseName}_$timestamp$extension';
  }

  // ===========================================================================
  // فتح الوسائط
  // ===========================================================================

  Future<void> _openMedia(MediaItem item) async {
    final file = File(item.filePath);

    try {
      if (!await file.exists()) {
        if (!mounted) {
          return;
        }

        _showMessage(
          AppLocalizations.of(context).mediaNotFound,
        );

        return;
      }

      if (item.isImage) {
        await _showImagePreview(item);
        return;
      }

      await _showFileActions(item);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(AppLocalizations.of(context).mediaOpenError);
    }
  }

  // ===========================================================================
  // معاينة الصورة
  // ===========================================================================

  Future<void> _showImagePreview(MediaItem item) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(
        alpha: 0.92,
      ),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              File(item.filePath),
                              fit: BoxFit.contain,
                              errorBuilder: (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return const _PreviewError();
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _PreviewIconButton(
                          icon: Icons.close_rounded,
                          tooltip: AppLocalizations.of(context).close,
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ImageActionBar(
                  onSave: () async {
                    await _saveToGallery(item);
                  },
                  onShare: () async {
                    await _shareMedia(item);
                  },
                  onDelete: () async {
                    Navigator.of(dialogContext).pop();
                    await _deleteMedia(item);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // إجراءات الملف
  // ===========================================================================

  Future<void> _showFileActions(MediaItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: const Border(
                top: BorderSide(
                  color: AppColors.glassBorder,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.neonBlue.withValues(
                      alpha: 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.isVideo
                        ? Icons.movie_rounded
                        : Icons.insert_drive_file_rounded,
                    color: AppColors.neonBlue,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  item.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  icon: Icons.save_alt_rounded,
                  title: AppLocalizations.of(context).saveToGallery,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _saveToGallery(item);
                  },
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  icon: Icons.share_rounded,
                  title: AppLocalizations.of(context).share,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _shareMedia(item);
                  },
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  title: AppLocalizations.of(context).delete,
                  destructive: true,
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _deleteMedia(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // حفظ في المعرض
  // ===========================================================================

  Future<void> _saveToGallery(MediaItem item) async {
    final file = File(item.filePath);

    try {
      if (!await file.exists()) {
        if (!mounted) return;
        _showMessage(AppLocalizations.of(context).mediaFileMissing);
        return;
      }

      final hasAccess = await Gal.hasAccess();
      if (!mounted) return;

      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final accessGranted = await Gal.hasAccess();
      if (!mounted) return;

      if (!accessGranted) {
        _showMessage(
          AppLocalizations.of(context).galleryPermissionDenied,
        );
        return;
      }

      if (item.isImage) {
        await Gal.putImage(item.filePath);
        if (!mounted) return;

        _showMessage(
          AppLocalizations.of(context).imageSavedToGallery,
        );

        return;
      }

      if (item.isVideo) {
        await Gal.putVideo(item.filePath);
        if (!mounted) return;

        _showMessage(
          AppLocalizations.of(context).videoSavedToGallery,
        );

        return;
      }

      if (!mounted) return;
      _showMessage(
        AppLocalizations.of(context).galleryUnsupportedType,
      );
    } on GalException catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.type.message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        AppLocalizations.of(context).mediaSaveError,
      );
    }
  }

  // ===========================================================================
  // مشاركة
  // ===========================================================================

  Future<void> _shareMedia(MediaItem item) async {
    final file = File(item.filePath);

    try {
      if (!await file.exists()) {
        if (!mounted) return;
        _showMessage(
          AppLocalizations.of(context).mediaFileMissing,
        );

        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          title: item.fileName,
          files: [
            XFile(item.filePath),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        AppLocalizations.of(context).mediaShareError,
      );
    }
  }

  // ===========================================================================
  // حذف
  // ===========================================================================

  Future<void> _deleteMedia(MediaItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.glass,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(
              color: AppColors.glassBorder,
            ),
          ),
          title: Text(
            AppLocalizations.of(context).deleteMediaConfirm,
            textAlign: TextAlign.end,
            textDirection: Directionality.of(context),
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            AppLocalizations.of(context)
                .deleteMediaMessage(fileName: item.fileName),
            textAlign: TextAlign.end,
            textDirection: Directionality.of(context),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            18,
            4,
            18,
            18,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                overlayColor: AppColors.cyberEmerald.withValues(
                  alpha: 0.08,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                AppLocalizations.of(context).cancel,
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyberEmerald,
                foregroundColor: Colors.black,
                overlayColor: Colors.black.withValues(
                  alpha: 0.08,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(
                AppLocalizations.of(context).delete,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final file = File(item.filePath);

      if (await file.exists()) {
        await file.delete();
      }

      await widget.hiveService.deleteMedia(
        item.id,
      );

      await _loadMedia();

      if (!mounted) {
        return;
      }

      _showMessage(
        AppLocalizations.of(context).mediaDeleted,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        AppLocalizations.of(context).mediaDeleteError,
      );
    }
  }

  // ===========================================================================
  // الرسائل
  // ===========================================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.glass,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(
              color: AppColors.glassBorder,
            ),
          ),
          content: Text(
            message,
            textDirection: Directionality.of(context),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      );
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).media,
          textDirection: Directionality.of(context),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSecondary,
        ),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).addMedia,
            onPressed: _pickMedia,
            icon: const Icon(
              Icons.add_rounded,
              color: Color(0xFF1877F2),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.cyberEmerald,
        foregroundColor: Colors.black,
        elevation: 0,
        onPressed: _pickMedia,
        icon: const Icon(
          Icons.add_photo_alternate_rounded,
          color: Colors.white,
        ),
        label: Text(
          AppLocalizations.of(context).addMedia,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.cyberEmerald,
        ),
      );
    }

    if (_mediaItems.isEmpty) {
      return _EmptyState(
        onAdd: _pickMedia,
      );
    }

    return RefreshIndicator(
      color: AppColors.cyberEmerald,
      backgroundColor: AppColors.glass,
      onRefresh: _loadMedia,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          110,
        ),
        itemCount: _mediaItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (context, index) {
          final item = _mediaItems[index];

          return _MediaCard(
            item: item,
            onTap: () {
              _openMedia(item);
            },
            onDelete: () {
              _deleteMedia(item);
            },
            onSave: () {
              _saveToGallery(item);
            },
            onShare: () {
              _shareMedia(item);
            },
          );
        },
      ),
    );
  }
}

// =============================================================================
// الحالة الفارغة
// =============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.cyberEmerald.withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.perm_media_outlined,
                color: AppColors.cyberEmerald,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).noMediaYet,
              textAlign: TextAlign.center,
              textDirection: Directionality.of(context),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).mediaEmptyDescription,
              textAlign: TextAlign.center,
              textDirection: Directionality.of(context),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyberEmerald,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                AppLocalizations.of(context).addMedia,
                style:
                    TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// بطاقة الوسائط
// =============================================================================

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onSave,
    required this.onShare,
  });

  final MediaItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final file = File(item.filePath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.glassBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: item.isImage
                            ? Image.file(
                                file,
                                fit: BoxFit.cover,
                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return _FilePlaceholder(
                                    item: item,
                                  );
                                },
                              )
                            : _FilePlaceholder(
                                item: item,
                              ),
                      ),
                      if (item.isVideo)
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: 0.55,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: _MediaMenu(
                          onSave: onSave,
                          onShare: onShare,
                          onDelete: onDelete,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    13,
                    11,
                    13,
                    13,
                  ),
                  child: Text(
                    item.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

// =============================================================================
// قائمة إجراءات البطاقة
// =============================================================================

class _MediaMenu extends StatelessWidget {
  const _MediaMenu({
    required this.onSave,
    required this.onShare,
    required this.onDelete,
  });

  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(
        alpha: 0.50,
      ),
      shape: const CircleBorder(),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: const Icon(
          Icons.more_vert_rounded,
          color: Colors.white,
        ),
        color: AppColors.glass,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppColors.glassBorder,
          ),
        ),
        onSelected: (value) {
          if (value == 'save') {
            onSave();
          } else if (value == 'share') {
            onShare();
          } else if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (context) {
          return <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'save',
              child: Row(
                children: [
                  const Icon(
                    Icons.save_alt_rounded,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context).saveToGallery,
                    textDirection: Directionality.of(context),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'share',
              child: Row(
                children: [
                  const Icon(
                    Icons.share_rounded,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context).share,
                    textDirection: Directionality.of(context),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.cyberEmerald,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context).delete,
                    textDirection: Directionality.of(context),
                    style: TextStyle(
                      color: AppColors.cyberEmerald,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }
}

// =============================================================================
// عناصر مساعدة
// =============================================================================

class _FilePlaceholder extends StatelessWidget {
  const _FilePlaceholder({
    required this.item,
  });

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.glassBorder.withValues(
        alpha: 0.2,
      ),
      child: Center(
        child: Icon(
          item.isVideo
              ? Icons.movie_rounded
              : item.isImage
                  ? Icons.image_not_supported_rounded
                  : Icons.insert_drive_file_rounded,
          color: AppColors.textSecondary,
          size: 40,
        ),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.broken_image_rounded,
        color: AppColors.textSecondary,
        size: 48,
      ),
    );
  }
}

class _PreviewIconButton extends StatelessWidget {
  const _PreviewIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(
        alpha: 0.6,
      ),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(
          icon,
          color: Colors.white,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _ImageActionBar extends StatelessWidget {
  const _ImageActionBar({
    required this.onSave,
    required this.onShare,
    required this.onDelete,
  });

  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.glassBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: AppLocalizations.of(context).save,
            icon: const Icon(
              Icons.save_alt_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: onSave,
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).share,
            icon: const Icon(
              Icons.share_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: onShare,
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).delete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.cyberEmerald,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.cyberEmerald : AppColors.textPrimary;

    return ListTile(
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        textDirection: Directionality.of(context),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onPressed,
    );
  }
}
