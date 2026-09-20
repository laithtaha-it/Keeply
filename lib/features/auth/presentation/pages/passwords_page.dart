import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../vault/domain/models/vault_item.dart';
import '../../../../l10n/app_localizations.dart';

class PasswordsPage extends StatefulWidget {
  const PasswordsPage({
    super.key,
    required this.hiveService,
  });

  final HiveService hiveService;

  @override
  State<PasswordsPage> createState() => _PasswordsPageState();
}

class _PasswordsPageState extends State<PasswordsPage> {
  List<VaultItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  // ---------------------------------------------------------------------------
  // تحميل البيانات
  // ---------------------------------------------------------------------------

  Future<void> _loadItems() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // البيانات الآن تُقرأ مباشرة من Hive.
      // لا يوجد فك تشفير.
      final storedItems = widget.hiveService.getAllItems();

      if (!mounted) {
        return;
      }

      setState(() {
        _items = List<VaultItem>.from(storedItems);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        AppLocalizations.of(context).passwordsLoadError,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // الحفظ
  // ---------------------------------------------------------------------------

  Future<void> _saveItem(
    VaultItem item,
  ) async {
    if (!item.hasData) {
      _showMessage(
        AppLocalizations.of(context).passwordValidationBeforeSave,
      );
      return;
    }

    try {
      // حفظ مباشر في Hive.
      // لا يوجد تشفير.
      await widget.hiveService.putItem(
        item,
      );

      await _loadItems();

      if (!mounted) {
        return;
      }

      _showMessage(
        AppLocalizations.of(context).passwordSaved,
      );
    } catch (e) {
      debugPrint(
        'PASSWORD SAVE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        AppLocalizations.of(context).passwordSaveError,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // الحذف
  // ---------------------------------------------------------------------------

  Future<void> _deleteItem(
    VaultItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: Directionality.of(context),
          child: AlertDialog(
            backgroundColor: AppColors.glass,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(
                color: AppColors.glassBorder,
              ),
            ),
            title: Text(
              AppLocalizations.of(context).deletePasswordConfirm,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              AppLocalizations.of(context).deletePasswordMessage,
              textAlign: TextAlign.end,
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
                      fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.hiveService.deleteItem(
        item.id,
      );

      await _loadItems();

      if (!mounted) {
        return;
      }

      _showMessage(
        AppLocalizations.of(context).passwordDeleted,
      );
    } catch (e) {
      debugPrint(
        'PASSWORD DELETE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        AppLocalizations.of(context).passwordDeleteError,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // الإضافة / التعديل
  // ---------------------------------------------------------------------------

  Future<void> _openEditor({
    VaultItem? item,
  }) async {
    final result = await showModalBottomSheet<VaultItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: Directionality.of(context),
          child: _PasswordEditorSheet(
            item: item,
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    await _saveItem(result);
  }

  // ---------------------------------------------------------------------------
  // الأدوات المساعدة
  // ---------------------------------------------------------------------------

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
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // بناء الصفحة
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            AppLocalizations.of(context).passwords,
            textAlign: TextAlign.end,
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
            AppLocalizations.of(context).addPassword,
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        body: _buildBody(),
      ),
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

    if (_items.isEmpty) {
      return _EmptyState(
        onAdd: () {
          _openEditor();
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.cyberEmerald,
      backgroundColor: AppColors.glass,
      onRefresh: _loadItems,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          110,
        ),
        itemCount: _items.length,
        separatorBuilder: (_, __) {
          return const SizedBox(
            height: 12,
          );
        },
        itemBuilder: (context, index) {
          final item = _items[index];

          return _PasswordCard(
            item: item,
            onEdit: () {
              _openEditor(
                item: item,
              );
            },
            onDelete: () {
              _deleteItem(item);
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// بطاقة كلمة المرور
// -----------------------------------------------------------------------------

class _PasswordCard extends StatelessWidget {
  const _PasswordCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final VaultItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = item.emailOrUsername.isNotEmpty
        ? item.emailOrUsername
        : item.description.isNotEmpty
            ? item.description
            : AppLocalizations.of(context).enterPassword;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.cyberEmerald.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.key_rounded,
                  color: AppColors.cyberEmerald,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  textDirection: Directionality.of(context),
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
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text(
                        AppLocalizations.of(context).edit,
                        textAlign: TextAlign.end,
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
                        textAlign: TextAlign.end,
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
          if (item.emailOrUsername.isNotEmpty)
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: AppLocalizations.of(context).emailOrUsername,
              value: item.emailOrUsername,
              copyable: true,
            ),
          if (item.password.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            _InfoRow(
              icon: Icons.lock_outline_rounded,
              label: AppLocalizations.of(context).passwordLabel,
              value: item.password,
              copyable: true,
            ),
          ],
          if (item.description.isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            _InfoRow(
              icon: Icons.notes_rounded,
              label: AppLocalizations.of(context).description,
              value: item.description,
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// صف المعلومات
// -----------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copyable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool copyable;

  Future<void> _copyValue(
    BuildContext context,
  ) async {
    await Clipboard.setData(
      ClipboardData(
        text: value,
      ),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.glass,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(
            seconds: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(
              color: AppColors.glassBorder,
            ),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.cyberEmerald,
                size: 20,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).copiedLabel(label: label),
                  textAlign: TextAlign.end,
                  textDirection: Directionality.of(context),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: AppColors.textMuted,
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.end,
                      textDirection: Directionality.of(context),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (copyable)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _copyValue(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Tooltip(
                            message: AppLocalizations.of(context).copy,
                            child: Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(
                height: 3,
              ),
              SelectableText(
                value,
                textAlign: TextAlign.end,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// محرر كلمة المرور
// -----------------------------------------------------------------------------

class _PasswordEditorSheet extends StatefulWidget {
  const _PasswordEditorSheet({
    this.item,
  });

  final VaultItem? item;

  @override
  State<_PasswordEditorSheet> createState() => _PasswordEditorSheetState();
}

class _PasswordEditorSheetState extends State<_PasswordEditorSheet> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController(
      text: widget.item?.emailOrUsername ?? '',
    );

    _passwordController = TextEditingController(
      text: widget.item?.password ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.item?.description ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  void _save() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final description = _descriptionController.text.trim();

    if (email.isEmpty && password.isEmpty && description.isEmpty) {
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
              AppLocalizations.of(context).passwordValidation,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );

      return;
    }

    final now = DateTime.now();

    final item = VaultItem(
      id: widget.item?.id ?? now.microsecondsSinceEpoch.toString(),
      emailOrUsername: email,
      password: password,
      description: description,
      createdAt: widget.item?.createdAt ?? now,
      updatedAt: now,
    );

    Navigator.of(context).pop(item);
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
        color: AppColors.cyberEmerald,
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
    final isEditing = widget.item != null;

    return SafeArea(
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
                      ? AppLocalizations.of(context).editPassword
                      : AppLocalizations.of(context).addKeeplyPassword,
                  textAlign: TextAlign.end,
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
                  AppLocalizations.of(context).passwordFormDescription,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                  ),
                  cursorColor: AppColors.cyberEmerald,
                  decoration: _inputDecoration(
                    label: AppLocalizations.of(context).emailOrUsername,
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: false,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                  ),
                  cursorColor: AppColors.cyberEmerald,
                  decoration: _inputDecoration(
                    label: AppLocalizations.of(context).passwordLabel,
                    icon: Icons.lock_outline_rounded,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  textDirection: Directionality.of(context),
                  textAlign: TextAlign.end,
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
                              fontWeight: FontWeight.w700, color: Colors.white),
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
    );
  }
}

// -----------------------------------------------------------------------------
// الحالة الفارغة
// -----------------------------------------------------------------------------

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
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.cyberEmerald.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cyberEmerald.withValues(
                    alpha: 0.16,
                  ),
                ),
              ),
              child: const Icon(
                Icons.key_rounded,
                color: AppColors.cyberEmerald,
                size: 34,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              AppLocalizations.of(context).noPasswordsYet,
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
              AppLocalizations.of(context).passwordsEmptyDescription,
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
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
              ),
              label: Text(
                AppLocalizations.of(context).addPassword,
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
