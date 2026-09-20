import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/backup/backup_service.dart';
import '../../../../l10n/app_localizations.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({
    super.key,
  });

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _isBackingUpToGoogle = false;
  bool _isRestoringFromGoogle = false;
  bool _isSigningInGoogle = false;
  bool _isSigningOutGoogle = false;
  bool _isLoadingCloudObjects = false;
  bool _isDeletingCloudObjects = false;

  IncrementalBackupResult? _lastBackupResult;

  BackupService get _backupService {
    return context.read<BackupService>();
  }

  bool get _isBusy {
    return _isBackingUpToGoogle ||
        _isRestoringFromGoogle ||
        _isSigningInGoogle ||
        _isSigningOutGoogle ||
        _isLoadingCloudObjects ||
        _isDeletingCloudObjects;
  }

  bool get _isGoogleConnected {
    return _backupService.googleDriveService.isConnected;
  }

  bool get _isRTL {
    return Directionality.of(context) == TextDirection.rtl;
  }

  TextDirection get _textDirection {
    return _isRTL ? TextDirection.rtl : TextDirection.ltr;
  }

  TextAlign get _textAlign {
    return _isRTL ? TextAlign.right : TextAlign.left;
  }

  CrossAxisAlignment get _crossAxisAlignment {
    return _isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start;
  }

  // ===========================================================================
  // Google connection
  // ===========================================================================

  Future<bool> _ensureGoogleConnected() async {
    if (_isGoogleConnected) {
      return true;
    }

    final shouldSignIn = await _showGoogleSignInDialog();

    if (!shouldSignIn || !mounted) {
      return false;
    }

    await _signInToGoogle();

    if (!mounted) {
      return false;
    }

    return _isGoogleConnected;
  }

  Future<void> _signInToGoogle() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isSigningInGoogle = true;
    });

    try {
      final account = await _backupService.googleDriveService.signIn();

      if (!mounted) {
        return;
      }

      if (account == null) {
        _showError(
          AppLocalizations.of(context).googleSignInCancelled,
        );
        return;
      }

      setState(() {});

      _showSuccess(
        AppLocalizations.of(context).googleDriveConnectedMessage +
            account.email,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        AppLocalizations.of(context).googleSignInFailed(
          error: e.toString(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningInGoogle = false;
        });
      }
    }
  }

  // ===========================================================================
  // Google sign out
  // ===========================================================================

  Future<void> _signOutFromGoogle() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isSigningOutGoogle = true;
    });

    try {
      await _backupService.googleDriveService.signOut();

      if (!mounted) {
        return;
      }

      setState(() {
        _lastBackupResult = null;
      });

      _showSuccess(
        AppLocalizations.of(context).googleDriveDisconnected,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        AppLocalizations.of(context).googleSignOutFailed(
          error: e.toString(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOutGoogle = false;
        });
      }
    }
  }

  // ===========================================================================
  // Incremental backup
  // ===========================================================================

  Future<void> _backupToGoogle() async {
    if (_isBusy) {
      return;
    }

    try {
      await _backupService.ensureInternetConnection();
    } on NoInternetConnectionException {
      if (mounted) {
        _showError(AppLocalizations.of(context).noInternetConnection);
      }
      return;
    }

    final connected = await _ensureGoogleConnected();

    if (!connected || !mounted) {
      return;
    }

    final selectedSections = await _showBackupSectionPicker();

    if (selectedSections == null || !mounted) {
      return;
    }

    setState(() {
      _isBackingUpToGoogle = true;
      _lastBackupResult = null;
    });

    final progress = ValueNotifier<BackupProgress>(
      const BackupProgress(
        operation: BackupOperation.upload,
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

    _showTransferProgressDialog(
      progress,
      BackupOperation.upload,
    );

    try {
      final result = await _backupService.syncToGoogleDrive(
        sections: selectedSections,
        onProgress: (value) => progress.value = value,
      );

      if (!mounted) {
        return;
      }

      // The transfer dialog belongs to this operation. Close it BEFORE
      // showing the final result so it can never remain on screen after the
      // sync has completed.
      Navigator.of(context, rootNavigator: true).maybePop();

      setState(() {
        _lastBackupResult = result;
      });

      _showIncrementalBackupResult(result);
    } catch (e) {
      if (!mounted) {
        return;
      }

      // Close the transfer dialog before showing an error dialog/snackbar.
      Navigator.of(context, rootNavigator: true).maybePop();

      if (e is NoInternetConnectionException) {
        _showError(AppLocalizations.of(context).noInternetConnection);
      } else {
        _showError(
          AppLocalizations.of(context).googleDriveBackupFailed(
            error: e.toString(),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUpToGoogle = false;
        });
      }
      progress.dispose();
    }
  }

  Future<Set<BackupSection>?> _showBackupSectionPicker() async {
    final selected = BackupSection.values.toSet();

    return showModalBottomSheet<Set<BackupSection>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        final isArabic = Directionality.of(sheetContext) == TextDirection.rtl;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allSelected = selected.length == BackupSection.values.length;

            return Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
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
                      l10n.selectBackupSections,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: allSelected,
                      title: Text(l10n.backupAllSections),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setSheetState(() {
                          if (value == true) {
                            selected.addAll(BackupSection.values);
                          } else {
                            selected.clear();
                          }
                        });
                      },
                    ),
                    ...BackupSection.values.map((section) {
                      return CheckboxListTile(
                        value: selected.contains(section),
                        title: Text(_sectionTitle(section)),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setSheetState(() {
                            if (value == true) {
                              selected.add(section);
                            } else {
                              selected.remove(section);
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: selected.isEmpty
                            ? null
                            : () => Navigator.of(sheetContext).pop(
                                  Set<BackupSection>.from(selected),
                                ),
                        child: Text(l10n.backupToGoogleDrive),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _sectionTitle(BackupSection section) {
    final l10n = AppLocalizations.of(context);
    switch (section) {
      case BackupSection.passwords:
        return l10n.passwords;
      case BackupSection.bookmarks:
        return l10n.bookmarks;
      case BackupSection.media:
        return l10n.media;
      case BackupSection.documents:
        return l10n.documents;
    }
  }

  // ===========================================================================
  // Restore
  // ===========================================================================

  Future<void> _restoreFromGoogle() async {
    if (_isBusy) {
      return;
    }

    try {
      await _backupService.ensureInternetConnection();
    } on NoInternetConnectionException {
      if (mounted) {
        _showError(AppLocalizations.of(context).noInternetConnection);
      }
      return;
    }

    final connected = await _ensureGoogleConnected();

    if (!connected || !mounted) {
      return;
    }

    final selectedSections = await _showRestoreSectionPicker();

    if (selectedSections == null || !mounted) {
      return;
    }

    final confirmed = await _showRestoreConfirmation();

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isRestoringFromGoogle = true;
    });

    final progress = ValueNotifier<BackupProgress>(
      const BackupProgress(
        operation: BackupOperation.download,
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

    _showTransferProgressDialog(
      progress,
      BackupOperation.download,
    );

    try {
      await _backupService.restoreFromGoogleDrive(
        sections: selectedSections,
        onProgress: (value) => progress.value = value,
      );

      if (!mounted) {
        return;
      }

      // Close the transfer dialog before showing the restore result.
      Navigator.of(context, rootNavigator: true).maybePop();

      _showSuccess(
        AppLocalizations.of(context).googleDriveRestoreSuccess,
        duration: const Duration(seconds: 6),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      // Close the transfer dialog before showing an error.
      Navigator.of(context, rootNavigator: true).maybePop();

      if (e is NoInternetConnectionException) {
        _showError(AppLocalizations.of(context).noInternetConnection);
      } else {
        _showError(
          AppLocalizations.of(context).googleDriveRestoreFailed(
            error: e.toString(),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringFromGoogle = false;
        });
      }
      progress.dispose();
    }
  }

  void _showTransferProgressDialog(
    ValueNotifier<BackupProgress> progress,
    BackupOperation operation,
  ) {
    final l10n = AppLocalizations.of(context);
    final title = operation == BackupOperation.upload
        ? l10n.uploadToCloud
        : l10n.downloadFromCloud;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ValueListenableBuilder<BackupProgress>(
          valueListenable: progress,
          builder: (_, value, __) {
            final fraction = value.fraction;
            final percent = (fraction * 100).toStringAsFixed(0);
            final hasTotal = value.totalBytes > 0;
            final currentItem =
                value.currentItem.isEmpty ? '...' : value.currentItem;

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: hasTotal ? fraction : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      hasTotal
                          ? '${_formatBytes(value.transferredBytes)} / '
                              '${_formatBytes(value.totalBytes)}  •  $percent%'
                          : _formatBytes(value.transferredBytes),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatBytes(value.speedBytesPerSecond.round())}/s',
                    ),
                    if (value.eta != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ETA ${_formatDuration(value.eta!)}',
                      ),
                    ],
                    if (value.totalItems > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${value.currentItemIndex} / ${value.totalItems}',
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      currentItem,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDuration(Duration duration) {
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

  // ===========================================================================
  // Incremental backup result
  // ===========================================================================

  void _showIncrementalBackupResult(
    IncrementalBackupResult result,
  ) {
    final message = StringBuffer();

    message.writeln(
      AppLocalizations.of(context).googleDriveSyncSuccess,
    );

    message.writeln();

    message.writeln(
      AppLocalizations.of(context).createdCount(
        created: result.created,
      ),
    );

    message.writeln(
      AppLocalizations.of(context).updatedCount(
        updated: result.updated,
      ),
    );

    message.writeln(
      AppLocalizations.of(context).skippedCount(
        skipped: result.skipped,
      ),
    );

    message.writeln(
      AppLocalizations.of(context).deletedCount(
        deleted: result.deleted,
      ),
    );

    message.writeln(
      AppLocalizations.of(context).examinedCount(
        examined: result.examined,
      ),
    );

    message.writeln();

    message.write(
      AppLocalizations.of(context).uploadedDataLabel +
          _formatBytes(result.uploadedBytes),
    );

    _showSuccess(
      message.toString(),
      duration: const Duration(seconds: 8),
    );
  }

  // ===========================================================================
  // Google sign-in dialog
  // ===========================================================================

  Future<bool> _showGoogleSignInDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isRTL = Directionality.of(context) == TextDirection.rtl;

        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              AppLocalizations.of(context).connectGoogleDrive,
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
            ),
            content: Text(
              AppLocalizations.of(context).googleDriveBackupRequirement +
                  AppLocalizations.of(context).googleAccountRequirement,
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: Text(
                  AppLocalizations.of(context).cancel,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                icon: const Icon(
                  Icons.login_rounded,
                ),
                label: Text(
                  AppLocalizations.of(context).signIn,
                ),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  Future<Set<BackupSection>?> _showRestoreSectionPicker() async {
    final selected = BackupSection.values.toSet();

    return showModalBottomSheet<Set<BackupSection>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        final isArabic = Directionality.of(sheetContext) == TextDirection.rtl;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allSelected = selected.length == BackupSection.values.length;

            return Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
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
                      l10n.selectRestoreSections,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: allSelected,
                      title: Text(l10n.backupAllSections),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setSheetState(() {
                          if (value == true) {
                            selected.addAll(BackupSection.values);
                          } else {
                            selected.clear();
                          }
                        });
                      },
                    ),
                    ...BackupSection.values.map((section) {
                      return CheckboxListTile(
                        value: selected.contains(section),
                        title: Text(_sectionTitle(section)),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setSheetState(() {
                            if (value == true) {
                              selected.add(section);
                            } else {
                              selected.remove(section);
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: selected.isEmpty
                            ? null
                            : () => Navigator.of(sheetContext).pop(
                                  Set<BackupSection>.from(selected),
                                ),
                        child: Text(l10n.restoreFromGoogleDrive),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // Restore confirmation
  // ===========================================================================

  Future<bool> _showRestoreConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isRTL = Directionality.of(context) == TextDirection.rtl;

        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              AppLocalizations.of(context).restoreBackupConfirm,
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
            ),
            content: Text(
              AppLocalizations.of(context).restoreOnlyMissingPart1 +
                  AppLocalizations.of(context).restoreOnlyMissingPart2 +
                  AppLocalizations.of(context).restoreNoDeletePart1 +
                  AppLocalizations.of(context).restoreNoDeletePart2 +
                  AppLocalizations.of(context).restoreMissingDataSafe,
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: Text(
                  AppLocalizations.of(context).cancel,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                icon: const Icon(
                  Icons.restore_rounded,
                ),
                label: Text(
                  AppLocalizations.of(context).restore,
                ),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  // ===========================================================================
  // Cloud objects
  // ===========================================================================

  Future<void> _showCloudObjects() async {
    if (_isBusy) {
      return;
    }

    final connected = await _ensureGoogleConnected();

    if (!connected || !mounted) {
      return;
    }

    setState(() {
      _isLoadingCloudObjects = true;
    });

    try {
      final objects = await _backupService.listCloudBackupObjects();

      if (!mounted) {
        return;
      }

      await _showCloudObjectsDialog(objects);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        AppLocalizations.of(context).backupReadError(
          error: e.toString(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCloudObjects = false;
        });
      }
    }
  }

  Future<void> _showCloudObjectsDialog(
    List<dynamic> objects,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isRTL = Directionality.of(context) == TextDirection.rtl;

        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              AppLocalizations.of(context).keeplyCloudData,
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 420,
              child: objects.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context).noBackupData,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: objects.length,
                      separatorBuilder: (_, __) {
                        return const Divider(
                          height: 1,
                        );
                      },
                      itemBuilder: (context, index) {
                        final object = objects[index];

                        final name =
                            object.name ?? AppLocalizations.of(context).unnamed;

                        final size = int.tryParse(
                          object.size ?? '',
                        );

                        return ListTile(
                          leading: const Icon(
                            Icons.cloud_done_rounded,
                          ),
                          title: Text(
                            name,
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            size != null
                                ? _formatBytes(size)
                                : AppLocalizations.of(context).unknownSize,
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  AppLocalizations.of(context).close,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Delete cloud objects
  // ===========================================================================

  Future<void> _deleteAllCloudObjects() async {
    if (_isBusy) {
      return;
    }

    final connected = await _ensureGoogleConnected();

    if (!connected || !mounted) {
      return;
    }

    final confirmed = await _showDeleteAllConfirmation();

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isDeletingCloudObjects = true;
    });

    try {
      final deleted = await _backupService.deleteAllIncrementalCloudObjects();

      if (!mounted) {
        return;
      }

      setState(() {
        _lastBackupResult = null;
      });

      _showSuccess(
        AppLocalizations.of(context).cloudItemsDeleted(
          deleted: deleted,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        AppLocalizations.of(context).cloudDeleteError(
          error: e.toString(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingCloudObjects = false;
        });
      }
    }
  }

  Future<bool> _showDeleteAllConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isRTL = Directionality.of(context) == TextDirection.rtl;

        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              AppLocalizations.of(context).deleteCloudBackupConfirm,
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
            ),
            content: Text(
              AppLocalizations.of(context).deleteIncrementalObjectsPart1 +
                  AppLocalizations.of(context).deleteIncrementalObjectsPart2 +
                  AppLocalizations.of(context).irreversibleAction +
                  AppLocalizations.of(context).localDataUnaffected,
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: Text(
                  AppLocalizations.of(context).cancel,
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                icon: const Icon(
                  Icons.delete_forever_rounded,
                ),
                label: Text(
                  AppLocalizations.of(context).deleteAll,
                ),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  // ===========================================================================
  // Messages
  // ===========================================================================

  void _showSuccess(
    String message, {
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: _textDirection,
            child: Text(
              message,
              textAlign: _textAlign,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          duration: duration,
        ),
      );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: _textDirection,
            child: Text(
              message,
              textAlign: _textAlign,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 8),
        ),
      );
  }

  // ===========================================================================
  // UI
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final connected = _isGoogleConnected;

    return Directionality(
      textDirection: _textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.backupRestore,
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              24,
              20,
              32,
            ),
            children: [
              // =================================================================
              // Header
              // =================================================================

              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Icon(
                    Icons.cloud_sync_rounded,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                l10n.keeplyBackup,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              // =================================================================
              // Google Drive Connection
              // =================================================================

              _buildSectionTitle(
                l10n.googleDrive,
                theme,
              ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    textDirection: _textDirection,
                    children: [
                      Icon(
                        connected
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        size: 34,
                        color: connected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: _crossAxisAlignment,
                          children: [
                            Text(
                              connected
                                  ? l10n.googleDriveConnected
                                  : l10n.googleDriveDisconnected,
                              textAlign: _textAlign,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              connected
                                  ? (_backupService.googleDriveService
                                          .currentUser?.email ??
                                      l10n.googleAccount)
                                  : l10n.connectGoogleAccount,
                              textAlign: _textAlign,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (connected)
                        IconButton(
                          tooltip: l10n.disconnectAccount,
                          onPressed: _isBusy ? null : _signOutFromGoogle,
                          icon: _isSigningOutGoogle
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.logout_rounded,
                                ),
                        )
                      else
                        TextButton.icon(
                          onPressed: _isBusy ? null : _signInToGoogle,
                          icon: _isSigningInGoogle
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.login_rounded,
                                ),
                          label: Text(
                            l10n.connect,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================================
              // Backup
              // =================================================================

              _buildSectionTitle(
                l10n.backup,
                theme,
              ),

              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: _crossAxisAlignment,
                    children: [
                      Row(
                        textDirection: _textDirection,
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.sync,
                              textAlign: _textAlign,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${l10n.incrementalSyncDescription1}'
                        '${l10n.incrementalSyncDescription2}.',
                        textAlign: _textAlign,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: _isBusy ? null : _backupToGoogle,
                  icon: _isBackingUpToGoogle
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.cloud_upload_rounded,
                        ),
                  label: Text(
                    _isBackingUpToGoogle ? l10n.syncing : l10n.syncBackup,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : _showCloudObjects,
                  icon: _isLoadingCloudObjects
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.cloud_queue_rounded,
                        ),
                  label: Text(
                    _isLoadingCloudObjects
                        ? l10n.readingData
                        : l10n.viewCloudBackup,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : _restoreFromGoogle,
                  icon: _isRestoringFromGoogle
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.cloud_download_rounded,
                        ),
                  label: Text(
                    _isRestoringFromGoogle
                        ? l10n.restoring
                        : l10n.restoreFromGoogleDrive,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================================
              // Last backup result
              // =================================================================

              if (_lastBackupResult != null) ...[
                _buildSectionTitle(
                  l10n.lastSyncResult,
                  theme,
                ),
                const SizedBox(height: 12),
                _buildBackupResultCard(
                  theme,
                  _lastBackupResult!,
                ),
                const SizedBox(height: 30),
              ],

              // =================================================================
              // Delete cloud backup
              // =================================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: _crossAxisAlignment,
                    children: [
                      Row(
                        textDirection: _textDirection,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.manageCloudBackup,
                              textAlign: _textAlign,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.manageCloudBackupDescription +
                            l10n.deleteCloudBackupProgress,
                        textAlign: _textAlign,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                          onPressed: _isBusy ? null : _deleteAllCloudObjects,
                          icon: _isDeletingCloudObjects
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_forever_rounded,
                                ),
                          label: Text(
                            _isDeletingCloudObjects
                                ? l10n.deleteCloudBackupCompletely
                                : l10n.deleteCloudBackupAll,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================================
              // Backup architecture
              // =================================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: _crossAxisAlignment,
                    children: [
                      Row(
                        textDirection: _textDirection,
                        children: [
                          Icon(
                            Icons.cloud_sync_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.backupSystem,
                              textAlign: _textAlign,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.backupStorage,
                        textAlign: _textAlign,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.backupSystemMode,
                        textAlign: _textAlign,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Section title
  // ===========================================================================

  Widget _buildSectionTitle(
    String title,
    ThemeData theme,
  ) {
    return Align(
      alignment: _isRTL ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        title,
        textAlign: _textAlign,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ===========================================================================
  // Backup result card
  // ===========================================================================

  Widget _buildBackupResultCard(
    ThemeData theme,
    IncrementalBackupResult result,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildResultRow(
              theme,
              icon: Icons.add_circle_rounded,
              title: AppLocalizations.of(context).created,
              value: result.created.toString(),
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              theme,
              icon: Icons.sync_rounded,
              title: AppLocalizations.of(context).updated,
              value: result.updated.toString(),
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              theme,
              icon: Icons.check_circle_rounded,
              title: AppLocalizations.of(context).skipped,
              value: result.skipped.toString(),
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              theme,
              icon: Icons.delete_rounded,
              title: AppLocalizations.of(context).deleted,
              value: result.deleted.toString(),
            ),
            const Divider(
              height: 28,
            ),
            _buildResultRow(
              theme,
              icon: Icons.analytics_rounded,
              title: AppLocalizations.of(context).examined,
              value: result.examined.toString(),
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              theme,
              icon: Icons.cloud_upload_rounded,
              title: AppLocalizations.of(context).uploadedData,
              value: _formatBytes(
                result.uploadedBytes,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Result row
  // ===========================================================================

  Widget _buildResultRow(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      textDirection: _textDirection,
      children: [
        Icon(
          icon,
          size: 22,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            textAlign: _textAlign,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
