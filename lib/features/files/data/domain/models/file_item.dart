/// Represents one file stored inside Keeply.
class FileItem {
  const FileItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.folderId,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String filePath;
  final String fileName;
  final String fileType;
  final String folderId;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasData {
    return filePath.trim().isNotEmpty && fileName.trim().isNotEmpty;
  }

  bool get isImage {
    final type = fileType.toLowerCase();

    return type == 'image' ||
        type == 'jpg' ||
        type == 'jpeg' ||
        type == 'png' ||
        type == 'gif' ||
        type == 'webp' ||
        type == 'bmp' ||
        type == 'heic' ||
        type == 'heif';
  }

  bool get isVideo {
    final type = fileType.toLowerCase();

    return type == 'video' ||
        type == 'mp4' ||
        type == 'mov' ||
        type == 'avi' ||
        type == 'mkv' ||
        type == 'webm' ||
        type == '3gp';
  }

  bool get isPdf {
    return fileType.toLowerCase() == 'pdf';
  }

  FileItem copyWith({
    String? id,
    String? filePath,
    String? fileName,
    String? fileType,
    String? folderId,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FileItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      folderId: folderId ?? this.folderId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
