/// Represents one bookmark stored inside Keeply.
///
/// Supported fields:
/// - Description
/// - URL
///
/// The fields should be encrypted before being persisted.
class Bookmark {
  const Bookmark({
    required this.id,
    required this.description,
    required this.url,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for this bookmark.
  final String id;

  /// Description of the bookmark.
  final String description;

  /// Website URL.
  final String url;

  /// Date when the bookmark was created.
  final DateTime createdAt;

  /// Date when the bookmark was last updated.
  final DateTime updatedAt;

  /// Returns true when at least one field contains data.
  bool get hasData {
    return description.trim().isNotEmpty || url.trim().isNotEmpty;
  }

  /// Creates a copy of this bookmark with modified values.
  Bookmark copyWith({
    String? id,
    String? description,
    String? url,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bookmark(
      id: id ?? this.id,
      description: description ?? this.description,
      url: url ?? this.url,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
