/// Represents one item stored inside Keeply.
///
/// Stores the username/email, password, and description directly.
///
/// No encryption is performed by this model.
/// Encryption is intentionally not used for the current
/// Keeply local storage and incremental Google Drive backup flow.
class VaultItem {
  const VaultItem({
    required this.id,
    required this.emailOrUsername,
    required this.password,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique identifier for this item.
  final String id;

  /// Email or username.
  final String emailOrUsername;

  /// Password.
  final String password;

  /// Description.
  final String description;

  /// Date when the item was created.
  final DateTime createdAt;

  /// Date when the item was last updated.
  final DateTime updatedAt;

  /// Returns true when at least one field contains data.
  ///
  /// A completely empty item must not be saved.
  bool get hasData {
    return emailOrUsername.trim().isNotEmpty ||
        password.trim().isNotEmpty ||
        description.trim().isNotEmpty;
  }

  /// Creates a copy of this item with modified values.
  VaultItem copyWith({
    String? id,
    String? emailOrUsername,
    String? password,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VaultItem(
      id: id ?? this.id,
      emailOrUsername: emailOrUsername ?? this.emailOrUsername,
      password: password ?? this.password,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
