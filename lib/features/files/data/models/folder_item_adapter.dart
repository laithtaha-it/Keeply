import 'package:hive/hive.dart';

import '../../domain/models/folder_item.dart';

class FolderItemAdapter extends TypeAdapter<FolderItem> {
  @override
  final int typeId = 4;

  @override
  FolderItem read(BinaryReader reader) {
    final fields = reader.readMap();

    return FolderItem(
      id: fields['id'] as String,
      name: fields['name'] as String,
      parentId: fields['parentId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        fields['createdAt'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        fields['updatedAt'] as int,
      ),
    );
  }

  @override
  void write(
    BinaryWriter writer,
    FolderItem obj,
  ) {
    writer.writeMap({
      'id': obj.id,
      'name': obj.name,
      'parentId': obj.parentId,
      'createdAt': obj.createdAt.millisecondsSinceEpoch,
      'updatedAt': obj.updatedAt.millisecondsSinceEpoch,
    });
  }
}
