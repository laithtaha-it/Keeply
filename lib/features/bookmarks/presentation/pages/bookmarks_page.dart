import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/bookmark.dart';
import '../../../../l10n/app_localizations.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({
    super.key,
    required this.hiveService,
  });

  final HiveService hiveService;

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  // ===========================================================================
  // Load
  // ===========================================================================

  Future<void> _loadBookmarks() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // No encryption/decryption.
      //
      // Bookmark data is stored directly in Hive and restored directly
      // from the backup.
      final storedBookmarks = widget.hiveService.getAllBookmarks();

      if (!mounted) {
        return;
      }

      setState(() {
        _bookmarks = storedBookmarks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(AppLocalizations.of(context).bookmarksLoadError);
    }
  }

  // ===========================================================================
  // Save
  // ===========================================================================

  Future<void> _saveBookmark(
    Bookmark bookmark,
  ) async {
    if (!bookmark.hasData) {
      _showMessage(
        AppLocalizations.of(context).bookmarkValidationBeforeSave,
      );
      return;
    }

    final normalizedUrl = _normalizeUrl(bookmark.url);

    if (normalizedUrl == null) {
      _showMessage(
        AppLocalizations.of(context).invalidWebsiteUrlInput,
      );
      return;
    }

    final normalizedBookmark = bookmark.copyWith(
      url: normalizedUrl,
    );

    try {
      // IMPORTANT:
      // Save the Bookmark directly.
      // No EncryptionService.
      await widget.hiveService.putBookmark(
        normalizedBookmark,
      );

      await _loadBookmarks();

      if (!mounted) {
        return;
      }

      _showMessage(AppLocalizations.of(context).bookmarkSaved);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(AppLocalizations.of(context).bookmarkSaveError);
    }
  }

  // ===========================================================================
  // Delete
  // ===========================================================================

  Future<void> _deleteBookmark(
    Bookmark bookmark,
  ) async {
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
            AppLocalizations.of(context).deleteBookmarkConfirm,
            textDirection: Directionality.of(context),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            AppLocalizations.of(context).deleteBookmarkMessage,
            textDirection: Directionality.of(context),
            style: TextStyle(
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
                textDirection: Directionality.of(context),
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
                textDirection: Directionality.of(context),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
      await widget.hiveService.deleteBookmark(
        bookmark.id,
      );

      await _loadBookmarks();

      if (!mounted) {
        return;
      }

      _showMessage(AppLocalizations.of(context).bookmarkDeleted);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(AppLocalizations.of(context).bookmarkDeleteError);
    }
  }

  // ===========================================================================
  // Add / Edit
  // ===========================================================================

  Future<void> _openEditor({
    Bookmark? bookmark,
  }) async {
    final result = await showModalBottomSheet<Bookmark>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BookmarkEditorSheet(
          bookmark: bookmark,
        );
      },
    );

    if (result == null) {
      return;
    }

    await _saveBookmark(result);
  }

  // ===========================================================================
  // Open Website
  // ===========================================================================

  Future<void> _openWebsite(
    String url,
  ) async {
    final normalizedUrl = _normalizeUrl(url);

    if (normalizedUrl == null) {
      _showMessage(AppLocalizations.of(context).invalidWebsiteUrl);
      return;
    }

    final uri = Uri.tryParse(normalizedUrl);

    if (uri == null) {
      _showMessage(AppLocalizations.of(context).invalidWebsiteUrl);
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage(AppLocalizations.of(context).websiteOpenError);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(AppLocalizations.of(context).websiteOpenError);
    }
  }

  // ===========================================================================
  // Copy URL
  // ===========================================================================

  Future<void> _copyUrl(
    String url,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: url),
    );

    if (!mounted) {
      return;
    }

    _showMessage(AppLocalizations.of(context).linkCopied);
  }

  // ===========================================================================
  // URL Helpers
  // ===========================================================================

  String? _normalizeUrl(
    String value,
  ) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    String normalized = trimmed;

    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }

    final uri = Uri.tryParse(normalized);

    if (uri == null || uri.host.isEmpty || !uri.hasScheme) {
      return null;
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }

    return normalized;
  }

  // ===========================================================================
  // Messages
  // ===========================================================================

  void _showMessage(
    String message,
  ) {
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
          AppLocalizations.of(context).bookmarksTitle,
          textDirection: Directionality.of(context),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSecondary,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.cyberEmerald,
        foregroundColor: Colors.black,
        elevation: 0,
        onPressed: () {
          _openEditor();
        },
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
        label: Text(
          AppLocalizations.of(context).addBookmark,
          textDirection: Directionality.of(context),
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
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

    if (_bookmarks.isEmpty) {
      return _EmptyState(
        onAdd: () {
          _openEditor();
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.cyberEmerald,
      backgroundColor: AppColors.glass,
      onRefresh: _loadBookmarks,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          110,
        ),
        itemCount: _bookmarks.length,
        separatorBuilder: (_, __) {
          return const SizedBox(
            height: 12,
          );
        },
        itemBuilder: (context, index) {
          final bookmark = _bookmarks[index];

          return _BookmarkCard(
            bookmark: bookmark,
            onOpen: () {
              _openWebsite(bookmark.url);
            },
            onCopy: () {
              _copyUrl(bookmark.url);
            },
            onEdit: () {
              _openEditor(
                bookmark: bookmark,
              );
            },
            onDelete: () {
              _deleteBookmark(bookmark);
            },
          );
        },
      ),
    );
  }
}

// =============================================================================
// Bookmark Card
// =============================================================================

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.bookmark,
    required this.onOpen,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
  });

  final Bookmark bookmark;
  final VoidCallback onOpen;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title =
        bookmark.description.isNotEmpty ? bookmark.description : bookmark.url;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.glassBorder,
        ),
      ),
      child: Directionality(
        textDirection: Directionality.of(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    Icons.link_rounded,
                    color: AppColors.cyberEmerald,
                    size: 23,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  color: AppColors.glass,
                  surfaceTintColor: Colors.transparent,
                  iconColor: AppColors.textSecondary,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(
                      color: AppColors.glassBorder,
                    ),
                  ),
                  onSelected: (value) {
                    if (value == 'open') {
                      onOpen();
                    } else if (value == 'copy') {
                      onCopy();
                    } else if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'open',
                        child: Text(
                          AppLocalizations.of(context).openWebsite,
                          textDirection: Directionality.of(context),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'copy',
                        child: Text(
                          AppLocalizations.of(context).copyLink,
                          textDirection: Directionality.of(context),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text(
                          AppLocalizations.of(context).edit,
                          textDirection: Directionality.of(context),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(
                          AppLocalizations.of(context).delete,
                          textDirection: Directionality.of(context),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(
              height: 18,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.language_rounded,
                  size: 19,
                  color: AppColors.textMuted,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: SelectableText(
                    bookmark.url,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (bookmark.description.trim().isNotEmpty) ...[
              const SizedBox(
                height: 12,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 19,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      bookmark.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(
              height: 16,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpen,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(
                        color: AppColors.glassBorder,
                      ),
                      backgroundColor: AppColors.glass,
                      overlayColor: AppColors.cyberEmerald.withValues(
                        alpha: 0.08,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                    ),
                    label: Text(
                      AppLocalizations.of(context).open,
                      textDirection: Directionality.of(context),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onCopy,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(
                        color: AppColors.glassBorder,
                      ),
                      backgroundColor: AppColors.glass,
                      overlayColor: AppColors.cyberEmerald.withValues(
                        alpha: 0.08,
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Editor
// =============================================================================

class _BookmarkEditorSheet extends StatefulWidget {
  const _BookmarkEditorSheet({
    this.bookmark,
  });

  final Bookmark? bookmark;

  @override
  State<_BookmarkEditorSheet> createState() => _BookmarkEditorSheetState();
}

class _BookmarkEditorSheetState extends State<_BookmarkEditorSheet> {
  late final TextEditingController _urlController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    _urlController = TextEditingController(
      text: widget.bookmark?.url ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.bookmark?.description ?? '',
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final url = _urlController.text.trim();
    final description = _descriptionController.text.trim();

    if (url.isEmpty && description.isEmpty) {
      _showEditorMessage(
        AppLocalizations.of(context).bookmarkValidation,
      );
      return;
    }

    if (url.isEmpty) {
      _showEditorMessage(
        AppLocalizations.of(context).websiteUrlRequired,
      );
      return;
    }

    final normalizedUrl = _normalizeUrl(url);

    if (normalizedUrl == null) {
      _showEditorMessage(
        AppLocalizations.of(context).invalidWebsiteUrlInput,
      );
      return;
    }

    final now = DateTime.now();

    final bookmark = Bookmark(
      id: widget.bookmark?.id ?? now.microsecondsSinceEpoch.toString(),
      description: description,
      url: normalizedUrl,
      createdAt: widget.bookmark?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(bookmark);
  }

  void _showEditorMessage(
    String message,
  ) {
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

  String? _normalizeUrl(
    String value,
  ) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    String normalized = trimmed;

    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      normalized = 'https://$normalized';
    }

    final uri = Uri.tryParse(normalized);

    if (uri == null || uri.host.isEmpty || !uri.hasScheme) {
      return null;
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }

    return normalized;
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppColors.textMuted,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.cyberEmerald,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.textMuted,
      ),
      filled: true,
      fillColor: AppColors.glass,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.glassBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.cyberEmerald,
          width: 1.2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.glassBorder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bookmark != null;

    return Directionality(
      textDirection: Directionality.of(context),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              20,
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.glassBorder,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Text(
                    isEditing
                        ? AppLocalizations.of(context).editBookmark
                        : AppLocalizations.of(context).addBookmark,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    AppLocalizations.of(context).bookmarkDescription,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    cursorColor: AppColors.cyberEmerald,
                    decoration: _inputDecoration(
                      label: AppLocalizations.of(context).websiteUrl,
                      icon: Icons.language_rounded,
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    cursorColor: AppColors.cyberEmerald,
                    decoration: _inputDecoration(
                      label: AppLocalizations.of(context).description,
                      icon: Icons.notes_rounded,
                    ).copyWith(
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(
                              color: AppColors.glassBorder,
                            ),
                            backgroundColor: AppColors.glass,
                            overlayColor: AppColors.cyberEmerald.withValues(
                              alpha: 0.08,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            AppLocalizations.of(context).cancel,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.cyberEmerald,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            overlayColor: Colors.black.withValues(
                              alpha: 0.08,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          onPressed: _save,
                          child: Text(
                            AppLocalizations.of(context).save,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
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
// Empty State
// =============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.neonBlue.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.neonBlue.withValues(
                      alpha: 0.16,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: AppColors.neonBlue,
                  size: 34,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                AppLocalizations.of(context).noBookmarksYet,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                AppLocalizations.of(context).bookmarksEmptyDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(
                height: 22,
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cyberEmerald,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  AppLocalizations.of(context).addBookmark,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
