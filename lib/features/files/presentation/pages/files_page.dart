import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/file_item.dart';
import '../../domain/models/folder_item.dart';
import '../../../../l10n/app_localizations.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({
    super.key,
    required this.hiveService,
  });

  final HiveService hiveService;

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  String? _currentFolderId;
  late String _currentFolderName;
  bool _hasInitializedFolderName = false;

  List<FileItem> _files = [];
  List<FolderItem> _folders = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolder();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedFolderName) {
      _currentFolderName = AppLocalizations.of(context).documents;
      _hasInitializedFolderName = true;
    }
  }

  Future<void> _loadFolder() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final folderId = _currentFolderId ?? '';

      final folders = widget.hiveService.getFoldersInParent(folderId);
      final files = widget.hiveService.getFilesInFolder(folderId);

      final validFiles = <FileItem>[];

      for (final file in files) {
        final localFile = File(file.filePath);

        if (await localFile.exists()) {
          validFiles.add(file);
        }
      }

      if (!mounted) return;

      setState(() {
        _folders = folders;
        _files = validFiles;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(AppLocalizations.of(context).documentsLoadError);
    }
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
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
              AppLocalizations.of(context).newFolder,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              textDirection: Directionality.of(context),
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).folderName,
                hintTextDirection: Directionality.of(context),
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.glassStrong,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: AppColors.glassBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: AppColors.glassBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: AppColors.cyberEmerald,
                  ),
                ),
              ),
              onSubmitted: (value) {
                Navigator.of(dialogContext).pop(value);
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  AppLocalizations.of(context).cancel,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cyberEmerald,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(controller.text);
                },
                child: Text(
                  AppLocalizations.of(context).create,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) {
      return;
    }

    try {
      final now = DateTime.now();

      final folder = FolderItem(
        id: now.microsecondsSinceEpoch.toString(),
        name: name.trim(),
        parentId: _currentFolderId ?? '',
        createdAt: now,
        updatedAt: now,
      );

      await widget.hiveService.putFolder(folder);
      await _loadFolder();

      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).folderCreated);
    } catch (_) {
      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).folderCreateError);
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final storageDirectory = await _getFilesDirectory();

      int savedCount = 0;

      for (final pickedFile in result.files) {
        final sourcePath = pickedFile.path;

        if (sourcePath == null || sourcePath.trim().isEmpty) {
          continue;
        }

        final sourceFile = File(sourcePath);

        if (!await sourceFile.exists()) {
          continue;
        }

        final originalName = pickedFile.name.trim().isNotEmpty
            ? pickedFile.name.trim()
            : p.basename(sourcePath);

        final timestamp = DateTime.now().microsecondsSinceEpoch;

        final safeName = _createSafeFileName(
          originalName,
          timestamp,
        );

        final destinationPath = p.join(
          storageDirectory.path,
          safeName,
        );

        final copiedFile = await sourceFile.copy(destinationPath);

        final now = DateTime.now();

        final extension =
            p.extension(originalName).replaceFirst('.', '').toLowerCase();

        final file = FileItem(
          id: '${timestamp}_$savedCount',
          filePath: copiedFile.path,
          fileName: originalName,
          fileType: extension,
          folderId: _currentFolderId ?? '',
          description: '',
          createdAt: now,
          updatedAt: now,
        );

        await widget.hiveService.putFile(file);

        savedCount++;
      }

      await _loadFolder();

      if (!mounted) return;

      if (savedCount == 0) {
        _showMessage(AppLocalizations.of(context).noFilesAdded);
      } else if (savedCount == 1) {
        _showMessage(AppLocalizations.of(context).documentAdded);
      } else {
        _showMessage(AppLocalizations.of(context)
            .documentsAddedCount(savedCount: savedCount));
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).documentsAddError);
    }
  }

  Future<Directory> _getFilesDirectory() async {
    final appDirectory = await getApplicationDocumentsDirectory();

    final directory = Directory(
      p.join(
        appDirectory.path,
        'secure_vault_files',
      ),
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  String _createSafeFileName(
    String originalName,
    int timestamp,
  ) {
    final extension = p.extension(originalName);
    final baseName = p.basenameWithoutExtension(originalName);

    final safeBaseName = baseName
        .replaceAll(
          RegExp(r'[^a-zA-Z0-9_\- ]'),
          '_',
        )
        .trim();

    final finalBaseName = safeBaseName.isEmpty ? 'file' : safeBaseName;

    return '${finalBaseName}_$timestamp$extension';
  }

  Future<void> _openFolder(FolderItem folder) async {
    setState(() {
      _currentFolderId = folder.id;
      _currentFolderName = folder.name;
    });

    await _loadFolder();
  }

  Future<void> _goBackFolder() async {
    final currentId = _currentFolderId;

    if (currentId == null || currentId.isEmpty) {
      return;
    }

    final currentFolder = widget.hiveService.getFolder(currentId);

    if (currentFolder == null) {
      setState(() {
        _currentFolderId = null;
        _currentFolderName = AppLocalizations.of(context).documents;
      });

      await _loadFolder();
      return;
    }

    final parentId = currentFolder.parentId;

    if (parentId.isEmpty) {
      setState(() {
        _currentFolderId = null;
        _currentFolderName = AppLocalizations.of(context).documents;
      });

      await _loadFolder();
      return;
    }

    final parentFolder = widget.hiveService.getFolder(parentId);

    setState(() {
      _currentFolderId = parentId;
      _currentFolderName =
          parentFolder?.name ?? AppLocalizations.of(context).documents;
    });

    await _loadFolder();
  }

  Future<void> _openFile(FileItem item) async {
    final file = File(item.filePath);

    if (!await file.exists()) {
      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).documentNotFound);
      return;
    }

    final extension =
        p.extension(item.fileName).replaceFirst('.', '').toLowerCase();

    if (extension == 'pdf') {
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _PdfViewerPage(
            file: file,
            title: item.fileName,
          ),
        ),
      );

      return;
    }

    if (_isImageFile(extension)) {
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _ImageViewerPage(
            file: file,
            title: item.fileName,
          ),
        ),
      );

      return;
    }

    if (extension == 'txt') {
      await _openTextFile(
        file,
        item.fileName,
      );

      return;
    }

    if (extension == 'docx') {
      await _openDocxFile(
        file,
        item.fileName,
      );

      return;
    }

    if (extension == 'xlsx') {
      await _openXlsxFile(
        file,
        item.fileName,
      );

      return;
    }

    if (extension == 'pptx') {
      await _openPptxFile(
        file,
        item.fileName,
      );

      return;
    }

    await _openWithExternalApp(
      file,
      item.fileName,
    );
  }

  bool _isImageFile(String extension) {
    return [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
    ].contains(extension);
  }

  Future<void> _openTextFile(
    File file,
    String fileName,
  ) async {
    try {
      final content = await file.readAsString();

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _TextViewerPage(
            title: fileName,
            content: content,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).textFileReadError);
    }
  }

  Future<void> _openDocxFile(
    File file,
    String fileName,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final documentFile = archive.findFile(
        'word/document.xml',
      );

      if (documentFile == null) {
        throw Exception('DOCX document.xml not found');
      }

      final xml = utf8.decode(
        documentFile.content as List<int>,
        allowMalformed: true,
      );

      final paragraphs = _extractDocxParagraphs(xml);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _OfficeTextViewerPage(
            title: fileName,
            icon: Icons.description_rounded,
            content: paragraphs.isEmpty
                ? AppLocalizations.of(context).noReadableText
                : paragraphs.join('\n\n'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).wordReadError);
    }
  }

  List<String> _extractDocxParagraphs(String xml) {
    final paragraphMatches = RegExp(
      r'<w:p\b[^>]*>(.*?)</w:p>',
      dotAll: true,
    ).allMatches(xml);

    final result = <String>[];

    for (final paragraph in paragraphMatches) {
      final paragraphXml = paragraph.group(1) ?? '';

      final textMatches = RegExp(
        r'<w:t\b[^>]*>(.*?)</w:t>',
        dotAll: true,
      ).allMatches(paragraphXml);

      final buffer = StringBuffer();

      for (final text in textMatches) {
        buffer.write(
          _decodeXml(text.group(1) ?? ''),
        );
      }

      final value = buffer.toString().trim();

      if (value.isNotEmpty) {
        result.add(value);
      }
    }

    return result;
  }

  Future<void> _openXlsxFile(
    File file,
    String fileName,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final sharedStringsFile = archive.findFile(
        'xl/sharedStrings.xml',
      );

      final sharedStrings = <String>[];

      if (sharedStringsFile != null) {
        final xml = utf8.decode(
          sharedStringsFile.content as List<int>,
          allowMalformed: true,
        );

        final stringMatches = RegExp(
          r'<si\b[^>]*>(.*?)</si>',
          dotAll: true,
        ).allMatches(xml);

        for (final match in stringMatches) {
          final value = _extractAllXmlText(
            match.group(1) ?? '',
          );

          sharedStrings.add(value);
        }
      }

      final worksheetFiles = archive.files
          .where(
            (entry) =>
                entry.name.startsWith('xl/worksheets/sheet') &&
                entry.name.endsWith('.xml'),
          )
          .toList();

      worksheetFiles.sort(
        (a, b) => a.name.compareTo(b.name),
      );

      final sheets = <_SpreadsheetSheet>[];

      for (final worksheetFile in worksheetFiles) {
        final xml = utf8.decode(
          worksheetFile.content as List<int>,
          allowMalformed: true,
        );

        final rows = _extractXlsxRows(
          xml,
          sharedStrings,
        );

        sheets.add(
          _SpreadsheetSheet(
            name: p.basenameWithoutExtension(
              worksheetFile.name,
            ),
            rows: rows,
          ),
        );
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _XlsxViewerPage(
            title: fileName,
            sheets: sheets,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).excelReadError);
    }
  }

  List<List<String>> _extractXlsxRows(
    String xml,
    List<String> sharedStrings,
  ) {
    final rows = <List<String>>[];

    final rowMatches = RegExp(
      r'<row\b[^>]*>(.*?)</row>',
      dotAll: true,
    ).allMatches(xml);

    for (final rowMatch in rowMatches) {
      final rowXml = rowMatch.group(1) ?? '';
      final cells = <_SpreadsheetCell>[];

      final cellMatches = RegExp(
        r'<c\b([^>]*)>(.*?)</c>',
        dotAll: true,
      ).allMatches(rowXml);

      for (final cellMatch in cellMatches) {
        final attributes = cellMatch.group(1) ?? '';
        final content = cellMatch.group(2) ?? '';

        final referenceMatch = RegExp(
          r'\br="([^"]+)"',
        ).firstMatch(attributes);

        final typeMatch = RegExp(
          r'\bt="([^"]+)"',
        ).firstMatch(attributes);

        final reference = referenceMatch?.group(1) ?? '';
        final type = typeMatch?.group(1) ?? '';

        final valueMatch = RegExp(
          r'<v\b[^>]*>(.*?)</v>',
          dotAll: true,
        ).firstMatch(content);

        final inlineMatch = RegExp(
          r'<t\b[^>]*>(.*?)</t>',
          dotAll: true,
        ).firstMatch(content);

        String value = '';

        if (inlineMatch != null) {
          value = _decodeXml(
            inlineMatch.group(1) ?? '',
          );
        } else if (valueMatch != null) {
          value = _decodeXml(
            valueMatch.group(1) ?? '',
          );
        }

        if (type == 's') {
          final index = int.tryParse(value);

          if (index != null && index >= 0 && index < sharedStrings.length) {
            value = sharedStrings[index];
          }
        }

        cells.add(
          _SpreadsheetCell(
            reference: reference,
            value: value,
          ),
        );
      }

      if (cells.isEmpty) {
        continue;
      }

      final maxColumn = cells.fold<int>(
        0,
        (current, cell) {
          final column = _xlsxColumnIndex(cell.reference);

          return column > current ? column : current;
        },
      );

      final row = List<String>.filled(
        maxColumn + 1,
        '',
      );

      for (final cell in cells) {
        final column = _xlsxColumnIndex(cell.reference);

        if (column >= 0 && column < row.length) {
          row[column] = cell.value;
        }
      }

      rows.add(row);
    }

    return rows;
  }

  int _xlsxColumnIndex(String reference) {
    final match = RegExp(
      r'^([A-Z]+)',
    ).firstMatch(reference.toUpperCase());

    if (match == null) {
      return 0;
    }

    final letters = match.group(1)!;
    var result = 0;

    for (final char in letters.codeUnits) {
      result = result * 26 + char - 64;
    }

    return result - 1;
  }

  Future<void> _openPptxFile(
    File file,
    String fileName,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final slideFiles = archive.files
          .where(
            (entry) =>
                entry.name.startsWith('ppt/slides/slide') &&
                entry.name.endsWith('.xml'),
          )
          .toList();

      slideFiles.sort(
        (a, b) => a.name.compareTo(b.name),
      );

      final slides = <String>[];

      for (final slideFile in slideFiles) {
        if (!mounted) return;
        final xml = utf8.decode(
          slideFile.content as List<int>,
          allowMalformed: true,
        );

        final text = _extractAllXmlText(
          xml,
          tagPattern: r'a:t',
        );

        if (text.trim().isNotEmpty) {
          slides.add(text.trim());
        } else {
          slides.add(AppLocalizations.of(context).emptySlide);
        }
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _PptxViewerPage(
            title: fileName,
            slides: slides,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).powerpointReadError);
    }
  }

  String _extractAllXmlText(
    String xml, {
    String? tagPattern,
  }) {
    final tag = tagPattern ?? r'[a-zA-Z0-9_:]+';

    final matches = RegExp(
      '<$tag\\b[^>]*>(.*?)</$tag>',
      dotAll: true,
    ).allMatches(xml);

    final values = <String>[];

    for (final match in matches) {
      final value = _decodeXml(
        match.group(1) ?? '',
      ).trim();

      if (value.isNotEmpty) {
        values.add(value);
      }
    }

    return values.join(' ');
  }

  String _decodeXml(String value) {
    return value
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAllMapped(
      RegExp(r'&#x([0-9a-fA-F]+);'),
      (match) {
        final code = int.tryParse(
          match.group(1)!,
          radix: 16,
        );

        return code == null ? match.group(0)! : String.fromCharCode(code);
      },
    ).replaceAllMapped(
      RegExp(r'&#([0-9]+);'),
      (match) {
        final code = int.tryParse(
          match.group(1)!,
        );

        return code == null ? match.group(0)! : String.fromCharCode(code);
      },
    );
  }

  Future<void> _openWithExternalApp(
    File file,
    String fileName,
  ) async {
    try {
      final result = await OpenFilex.open(file.path);

      if (result.type.name == 'done') {
        return;
      }

      if (!mounted) return;

      if (result.type.name == 'noAppToOpen') {
        await _showNoViewerDialog(fileName);
        return;
      }

      _showMessage(
        result.message.isNotEmpty
            ? result.message
            : AppLocalizations.of(context).documentOpenError,
      );
    } catch (_) {
      if (!mounted) return;

      await _showNoViewerDialog(fileName);
    }
  }

  Future<void> _showNoViewerDialog(String fileName) async {
    if (!mounted) return;

    await showDialog<void>(
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
              AppLocalizations.of(context).noAppToOpenFile,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              AppLocalizations.of(context).noAppForFile(fileName: fileName),
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cyberEmerald,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  AppLocalizations.of(context).ok,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showFileOptions(FileItem item) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (_) {
        return _FileOptionsSheet(
          item: item,
          onShare: () {
            Navigator.of(context).pop();
            _shareFile(item);
          },
          onDelete: () {
            Navigator.of(context).pop();
            _deleteFile(item);
          },
        );
      },
    );
  }

  Future<void> _shareFile(FileItem item) async {
    try {
      final file = File(item.filePath);

      if (!await file.exists()) {
        if (!mounted) return;

        _showMessage(AppLocalizations.of(context).documentMissing);
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
      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).documentShareError);
    }
  }

  Future<void> _deleteFile(FileItem item) async {
    final confirmed = await _showDeleteDialog(
      title: AppLocalizations.of(context).deleteDocumentConfirm,
      message: AppLocalizations.of(context)
          .deleteDocumentMessage(fileName: item.fileName),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final file = File(item.filePath);

      if (await file.exists()) {
        await file.delete();
      }

      await widget.hiveService.deleteFile(item.id);
      await _loadFolder();

      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).documentDeleted);
    } catch (_) {
      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).documentDeleteError);
    }
  }

  Future<void> _deleteFolder(FolderItem folder) async {
    final childFolders = widget.hiveService.getFoldersInParent(folder.id);
    final childFiles = widget.hiveService.getFilesInFolder(folder.id);

    if (childFolders.isNotEmpty || childFiles.isNotEmpty) {
      _showMessage(
        AppLocalizations.of(context).folderNotEmpty,
      );
      return;
    }

    final confirmed = await _showDeleteDialog(
      title: AppLocalizations.of(context).deleteFolderConfirm,
      message: AppLocalizations.of(context)
          .deleteFolderMessage(folderName: folder.name),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.hiveService.deleteFolder(folder.id);
      await _loadFolder();

      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).folderDeleted);
    } catch (_) {
      if (!mounted) return;

      _showMessage(AppLocalizations.of(context).folderDeleteError);
    }
  }

  Future<bool?> _showDeleteDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
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
              title,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              message,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: Text(
                  AppLocalizations.of(context).cancel,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE05252),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: Text(
                  AppLocalizations.of(context).delete,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.glassStrong,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: AppColors.glassBorder,
            ),
          ),
          content: Directionality(
            textDirection: Directionality.of(context),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.cyberEmerald,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = _currentFolderId == null;

    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 76,
          titleSpacing: 20,
          title: Row(
            children: [
              if (!isRoot) ...[
                _HeaderIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: _goBackFolder,
                ),
                const SizedBox(width: 12),
              ],
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
                  Icons.folder_special_rounded,
                  color: AppColors.cyberEmerald,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentFolderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context).folderFileCount(
                          folders: _folders.length, files: _files.length),
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            _HeaderIconButton(
              icon: Icons.create_new_folder_outlined,
              onTap: _createFolder,
            ),
            const SizedBox(width: 8),
            _HeaderIconButton(
              icon: Icons.refresh_rounded,
              onTap: _loadFolder,
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _pickFiles,
          backgroundColor: AppColors.cyberEmerald,
          foregroundColor: Colors.black,
          elevation: 4,
          icon: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 22,
          ),
          label: Text(
            AppLocalizations.of(context).addDocument,
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.cyberEmerald,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_folders.isEmpty && _files.isEmpty) {
      return _EmptyDocumentsState(
        onAddFile: _pickFiles,
        onCreateFolder: _createFolder,
      );
    }

    return RefreshIndicator(
      color: AppColors.cyberEmerald,
      backgroundColor: AppColors.glassStrong,
      onRefresh: _loadFolder,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          120,
        ),
        children: [
          if (_folders.isNotEmpty) ...[
            _SectionHeader(
              title: AppLocalizations.of(context).folders,
              icon: Icons.folder_rounded,
            ),
            const SizedBox(height: 10),
            ..._folders.map(
              (folder) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FolderCard(
                  folder: folder,
                  onTap: () => _openFolder(folder),
                  onDelete: () => _deleteFolder(folder),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_files.isNotEmpty) ...[
            _SectionHeader(
              title: AppLocalizations.of(context).documents,
              icon: Icons.description_rounded,
            ),
            const SizedBox(height: 10),
            ..._files.map(
              (file) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FileCard(
                  file: file,
                  onTap: () => _openFile(file),
                  onLongPress: () => _showFileOptions(file),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PdfViewerPage extends StatelessWidget {
  const _PdfViewerPage({
    required this.file,
    required this.title,
  });

  final File file;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SfPdfViewer.file(file),
      ),
    );
  }
}

class _ImageViewerPage extends StatelessWidget {
  const _ImageViewerPage({
    required this.file,
    required this.title,
  });

  final File file;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context).imageDisplayError,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TextViewerPage extends StatelessWidget {
  const _TextViewerPage({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              40,
            ),
            child: Text(
              content,
              textAlign: TextAlign.start,
              textDirection: Directionality.of(context),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfficeTextViewerPage extends StatelessWidget {
  const _OfficeTextViewerPage({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              40,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(18),
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
                        color: AppColors.cyberEmerald.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.cyberEmerald,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).readOnlyDocumentPreview,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.glassBorder,
                  ),
                ),
                child: Text(
                  content,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.75,
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

class _XlsxViewerPage extends StatelessWidget {
  const _XlsxViewerPage({
    required this.title,
    required this.sheets,
  });

  final String title;
  final List<_SpreadsheetSheet> sheets;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: DefaultTabController(
        length: sheets.isEmpty ? 1 : sheets.length,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppColors.textPrimary,
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            bottom: sheets.isEmpty
                ? null
                : TabBar(
                    isScrollable: true,
                    indicatorColor: AppColors.cyberEmerald,
                    labelColor: AppColors.cyberEmerald,
                    unselectedLabelColor: AppColors.textMuted,
                    tabs: [
                      for (final sheet in sheets)
                        Tab(
                          text: sheet.name,
                        ),
                    ],
                  ),
          ),
          body: sheets.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context).noReadableWorksheets,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : TabBarView(
                  children: [
                    for (final sheet in sheets)
                      _SpreadsheetSheetView(
                        sheet: sheet,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SpreadsheetSheetView extends StatelessWidget {
  const _SpreadsheetSheetView({
    required this.sheet,
  });

  final _SpreadsheetSheet sheet;

  @override
  Widget build(BuildContext context) {
    if (sheet.rows.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).emptyWorksheet,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Directionality(
      textDirection: Directionality.of(context),
      child: InteractiveViewer(
        constrained: false,
        minScale: 0.5,
        maxScale: 3,
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: TableBorder.all(
                color: AppColors.glassBorder,
                width: 0.7,
              ),
              children: [
                for (final row in sheet.rows)
                  TableRow(
                    children: [
                      for (final cell in row)
                        Container(
                          constraints: const BoxConstraints(
                            minWidth: 90,
                            minHeight: 42,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          color: AppColors.glass,
                          child: Text(
                            cell,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
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

class _PptxViewerPage extends StatelessWidget {
  const _PptxViewerPage({
    required this.title,
    required this.slides,
  });

  final String title;
  final List<String> slides;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: slides.isEmpty
            ? Center(
                child: Text(
                  AppLocalizations.of(context).noReadableSlides,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : PageView.builder(
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      12,
                      18,
                      30,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.glass,
                        borderRadius: BorderRadius.circular(24),
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
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.cyberEmerald.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.slideshow_rounded,
                                  color: AppColors.cyberEmerald,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)
                                    .slideNumber(index: index + 1),
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                slides[index],
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  height: 1.7,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glass,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.glassBorder,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.cyberEmerald,
            size: 17,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            textAlign: TextAlign.start,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDocumentsState extends StatelessWidget {
  const _EmptyDocumentsState({
    required this.onAddFile,
    required this.onCreateFolder,
  });

  final VoidCallback onAddFile;
  final VoidCallback onCreateFolder;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            28,
            30,
            28,
            120,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: AppColors.cyberEmerald.withValues(
                    alpha: 0.08,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cyberEmerald.withValues(
                      alpha: 0.18,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.folder_special_outlined,
                  color: AppColors.cyberEmerald,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).yourDocuments,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                AppLocalizations.of(context).documentsDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAddFile,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cyberEmerald,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(
                      double.infinity,
                      52,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.upload_file_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    AppLocalizations.of(context).addDocument,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCreateFolder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size(
                      double.infinity,
                      52,
                    ),
                    side: const BorderSide(
                      color: AppColors.glassBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.create_new_folder_outlined,
                  ),
                  label: Text(
                    AppLocalizations.of(context).createFolder,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
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

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.onTap,
    required this.onDelete,
  });

  final FolderItem folder;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(14),
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.cyberEmerald.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: AppColors.cyberEmerald,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).folder,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: AppLocalizations.of(context).delete,
                  splashRadius: 21,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textMuted,
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

class _FileCard extends StatelessWidget {
  const _FileCard({
    required this.file,
    required this.onTap,
    required this.onLongPress,
  });

  final FileItem file;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = _fileColor(file.fileType);

    return Directionality(
      textDirection: Directionality.of(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(14),
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _fileIcon(file.fileType),
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              file.fileType.isEmpty
                                  ? AppLocalizations.of(context).file
                                  : file.fileType.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.textMuted,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context).secure,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _fileIcon(String type) {
    final extension = type.toLowerCase();

    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'svg',
    ].contains(extension)) {
      return Icons.image_rounded;
    }

    if ([
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',
    ].contains(extension)) {
      return Icons.video_file_rounded;
    }

    if ([
      'mp3',
      'wav',
      'm4a',
      'aac',
      'ogg',
      'flac',
    ].contains(extension)) {
      return Icons.audio_file_rounded;
    }

    if (extension == 'pdf') {
      return Icons.picture_as_pdf_rounded;
    }

    if ([
      'doc',
      'docx',
      'txt',
      'rtf',
    ].contains(extension)) {
      return Icons.description_rounded;
    }

    if ([
      'xls',
      'xlsx',
      'csv',
    ].contains(extension)) {
      return Icons.table_chart_rounded;
    }

    if ([
      'ppt',
      'pptx',
    ].contains(extension)) {
      return Icons.slideshow_rounded;
    }

    if ([
      'zip',
      'rar',
      '7z',
      'tar',
    ].contains(extension)) {
      return Icons.archive_rounded;
    }

    return Icons.insert_drive_file_rounded;
  }

  Color _fileColor(String type) {
    final extension = type.toLowerCase();

    if (extension == 'pdf') {
      return const Color(0xFFE05252);
    }

    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
    ].contains(extension)) {
      return const Color(0xFF6C8CFF);
    }

    if ([
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',
    ].contains(extension)) {
      return const Color(0xFFB06CFF);
    }

    if ([
      'mp3',
      'wav',
      'm4a',
      'aac',
      'ogg',
    ].contains(extension)) {
      return const Color(0xFFFFB84D);
    }

    if ([
      'doc',
      'docx',
      'txt',
      'rtf',
    ].contains(extension)) {
      return const Color(0xFF4EA1FF);
    }

    if ([
      'xls',
      'xlsx',
      'csv',
    ].contains(extension)) {
      return AppColors.cyberEmerald;
    }

    if ([
      'ppt',
      'pptx',
    ].contains(extension)) {
      return const Color(0xFFFF7043);
    }

    return AppColors.neonBlue;
  }
}

class _FileOptionsSheet extends StatelessWidget {
  const _FileOptionsSheet({
    required this.item,
    required this.onShare,
    required this.onDelete,
  });

  final FileItem item;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            22,
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
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.neonBlue.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _optionIcon(item.fileType),
                      color: AppColors.neonBlue,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.cyberEmerald,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.fileType.isEmpty
                                  ? AppLocalizations.of(context).secureFile
                                  : item.fileType.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _SheetAction(
                icon: Icons.share_rounded,
                title: AppLocalizations.of(context).shareDocument,
                onTap: onShare,
              ),
              const SizedBox(height: 9),
              _SheetAction(
                icon: Icons.delete_outline_rounded,
                title: AppLocalizations.of(context).deleteDocument,
                destructive: true,
                onTap: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _optionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFE05252) : AppColors.textPrimary;

    return Material(
      color: AppColors.glass,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: AppColors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 21,
              ),
              const SizedBox(width: 13),
              Text(
                title,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(
                  alpha: 0.45,
                ),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpreadsheetSheet {
  const _SpreadsheetSheet({
    required this.name,
    required this.rows,
  });

  final String name;
  final List<List<String>> rows;
}

class _SpreadsheetCell {
  const _SpreadsheetCell({
    required this.reference,
    required this.value,
  });

  final String reference;
  final String value;
}
