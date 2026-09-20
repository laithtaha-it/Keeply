import 'package:hive/hive.dart';

import '../../domain/models/file_item.dart';

class FileItemAdapter extends TypeAdapter<FileItem> {
  @override
  final int typeId = 3;

  @override
  FileItem read(BinaryReader reader) {
    final fields = reader.readMap();

    return FileItem(
      id: fields['id'] as String,
      filePath: fields['filePath'] as String,
      fileName: fields['fileName'] as String,
      fileType: fields['fileType'] as String,
      folderId: fields['folderId'] as String,
      description: fields['description'] as String,
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
    FileItem obj,
  ) {
    writer.writeMap({
      'id': obj.id,
      'filePath': obj.filePath,
      'fileName': obj.fileName,
      'fileType': obj.fileType,
      'folderId': obj.folderId,
      'description': obj.description,
      'createdAt': obj.createdAt.millisecondsSinceEpoch,
      'updatedAt': obj.updatedAt.millisecondsSinceEpoch,
    });
  }
}
