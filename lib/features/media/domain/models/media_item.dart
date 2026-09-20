/// Represents one media item stored inside Keeply.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier.
  final String id;

  /// Original file path on the device.
  final String filePath;

  /// Original file name.
  final String fileName;

  /// Media type, for example image, video, or other.
  final String fileType;

  /// Optional description.
  final String description;

  /// Date when the media was added.
  final DateTime createdAt;

  /// Date when the media was last updated.
  final DateTime updatedAt;

  /// Whether this item contains enough data to be stored.
  bool get hasData {
    return filePath.trim().isNotEmpty && fileName.trim().isNotEmpty;
  }

  /// Whether this media item is an image.
  bool get isImage {
    final type = fileType.toLowerCase();

    return type == 'image' ||
        type == 'jpg' ||
        type == 'jpeg' ||
        type == 'png' ||
        type == 'gif' ||
        type == 'webp' ||
        type == 'bmp';
  }

  /// Whether this media item is a video.
  bool get isVideo {
    final type = fileType.toLowerCase();

    return type == 'video' ||
        type == 'mp4' ||
        type == 'mov' ||
        type == 'avi' ||
        type == 'mkv' ||
        type == 'webm';
  }

  /// Creates a modified copy.
  MediaItem copyWith({
    String? id,
    String? filePath,
    String? fileName,
    String? fileType,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
