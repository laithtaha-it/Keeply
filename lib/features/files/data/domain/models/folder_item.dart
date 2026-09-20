/// Represents one folder stored inside Keeply.
class FolderItem {
  const FolderItem({
    required this.id,
    required this.name,
    required this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasData {
    return name.trim().isNotEmpty;
  }

  FolderItem copyWith({
    String? id,
    String? name,
    String? parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FolderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
