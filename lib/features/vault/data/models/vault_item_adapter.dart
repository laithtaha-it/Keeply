import 'package:hive/hive.dart';

import '../../domain/models/vault_item.dart';

class VaultItemAdapter extends TypeAdapter<VaultItem> {
  @override
  final int typeId = 0;

  @override
  VaultItem read(BinaryReader reader) {
    final fields = reader.readMap();

    return VaultItem(
      id: fields['id'] as String,
      emailOrUsername: fields['emailOrUsername'] as String,
      password: fields['password'] as String,
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
    VaultItem obj,
  ) {
    writer.writeMap({
      'id': obj.id,
      'emailOrUsername': obj.emailOrUsername,
      'password': obj.password,
      'description': obj.description,
      'createdAt': obj.createdAt.millisecondsSinceEpoch,
      'updatedAt': obj.updatedAt.millisecondsSinceEpoch,
    });
  }
}
