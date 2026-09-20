import '../../features/vault/domain/models/vault_item.dart';
import '../storage/hive_service.dart';
import '../backup/backup_service.dart';

/// Debug-only test for Keeply incremental Google Drive backup.
///
/// This test intentionally uses only VaultItem objects.
/// It verifies:
///
/// 1. First sync creates all objects.
/// 2. Second sync without changes skips all objects.
/// 3. Updating one object updates only that object.
/// 4. Adding one object creates only that object.
/// 5. Deleting one object deletes only that cloud object.
///
/// IMPORTANT:
/// Run this only when you are comfortable creating/deleting
/// temporary Keeply test data in the connected Google Drive
/// appDataFolder.
class BackupIncrementalTestService {
  BackupIncrementalTestService({
    required HiveService hiveService,
    required BackupService backupService,
  })  : _hiveService = hiveService,
        _backupService = backupService;

  final HiveService _hiveService;
  final BackupService _backupService;

  static const String _prefix = 'SV_TEST_';

  Future<String> run() async {
    final output = StringBuffer();

    output.writeln('========================================');
    output.writeln('Keeply Incremental Backup Test');
    output.writeln('========================================');

    try {
      // ---------------------------------------------------------------
      // Google Drive connection
      // ---------------------------------------------------------------

      if (!_backupService.isGoogleConnected) {
        throw StateError(
          'Google Drive is not connected.',
        );
      }

      output.writeln('Google Drive: CONNECTED');
      output.writeln('');

      // ---------------------------------------------------------------
      // Cleanup previous test data
      // ---------------------------------------------------------------

      output.writeln('Cleaning previous local test data...');

      await _deleteLocalTestItems();

      // ---------------------------------------------------------------
      // Create test data
      // ---------------------------------------------------------------

      final now = DateTime.now().toUtc();

      final item1 = VaultItem(
        id: '${_prefix}1',
        emailOrUsername: 'test1@example.com',
        password: 'Password_111',
        description: 'Incremental Test 1',
        createdAt: now,
        updatedAt: now,
      );

      final item2 = VaultItem(
        id: '${_prefix}2',
        emailOrUsername: 'test2@example.com',
        password: 'Password_222',
        description: 'Incremental Test 2',
        createdAt: now,
        updatedAt: now,
      );

      final item3 = VaultItem(
        id: '${_prefix}3',
        emailOrUsername: 'test3@example.com',
        password: 'Password_333',
        description: 'Incremental Test 3',
        createdAt: now,
        updatedAt: now,
      );

      await _hiveService.putItem(item1);
      await _hiveService.putItem(item2);
      await _hiveService.putItem(item3);

      output.writeln('Created 3 local test objects.');
      output.writeln('');

      // ===============================================================
      // TEST 1
      // ===============================================================

      output.writeln('TEST 1: First Backup');
      output.writeln('Expected: created=3');

      final result1 = await _backupService.syncToGoogleDrive();

      _printResult(
        output,
        result1,
      );

      _assert(
        result1.created == 3,
        'TEST 1 failed: expected created=3.',
      );

      _assert(
        result1.updated == 0,
        'TEST 1 failed: expected updated=0.',
      );

      _assert(
        result1.skipped == 0,
        'TEST 1 failed: expected skipped=0.',
      );

      _assert(
        result1.uploadedBytes > 0,
        'TEST 1 failed: expected uploadedBytes > 0.',
      );

      output.writeln('PASS');
      output.writeln('');

      // ===============================================================
      // TEST 2
      // ===============================================================

      output.writeln('TEST 2: Backup Without Changes');
      output.writeln(
        'Expected: created=0, updated=0, skipped=3, uploadedBytes=0',
      );

      final result2 = await _backupService.syncToGoogleDrive();

      _printResult(
        output,
        result2,
      );

      _assert(
        result2.created == 0,
        'TEST 2 failed: expected created=0.',
      );

      _assert(
        result2.updated == 0,
        'TEST 2 failed: expected updated=0.',
      );

      _assert(
        result2.skipped == 3,
        'TEST 2 failed: expected skipped=3.',
      );

      _assert(
        result2.uploadedBytes == 0,
        'TEST 2 failed: expected uploadedBytes=0.',
      );

      output.writeln('PASS');
      output.writeln('');

      // ===============================================================
      // TEST 3
      // ===============================================================

      output.writeln('TEST 3: Modify One Object');
      output.writeln(
        'Expected: created=0, updated=1, skipped=2',
      );

      final updatedItem1 = item1.copyWith(
        password: 'Password_111_CHANGED',
        updatedAt: DateTime.now().toUtc(),
      );

      await _hiveService.putItem(
        updatedItem1,
      );

      final result3 = await _backupService.syncToGoogleDrive();

      _printResult(
        output,
        result3,
      );

      _assert(
        result3.created == 0,
        'TEST 3 failed: expected created=0.',
      );

      _assert(
        result3.updated == 1,
        'TEST 3 failed: expected updated=1.',
      );

      _assert(
        result3.skipped == 2,
        'TEST 3 failed: expected skipped=2.',
      );

      _assert(
        result3.uploadedBytes > 0,
        'TEST 3 failed: expected uploadedBytes > 0.',
      );

      output.writeln('PASS');
      output.writeln('');

      // ===============================================================
      // TEST 4
      // ===============================================================

      output.writeln('TEST 4: Add One Object');
      output.writeln(
        'Expected: created=1, updated=0, skipped=3',
      );

      final item4 = VaultItem(
        id: '${_prefix}4',
        emailOrUsername: 'test4@example.com',
        password: 'Password_444',
        description: 'Incremental Test 4',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      );

      await _hiveService.putItem(
        item4,
      );

      final result4 = await _backupService.syncToGoogleDrive();

      _printResult(
        output,
        result4,
      );

      _assert(
        result4.created == 1,
        'TEST 4 failed: expected created=1.',
      );

      _assert(
        result4.updated == 0,
        'TEST 4 failed: expected updated=0.',
      );

      _assert(
        result4.skipped == 3,
        'TEST 4 failed: expected skipped=3.',
      );

      _assert(
        result4.uploadedBytes > 0,
        'TEST 4 failed: expected uploadedBytes > 0.',
      );

      output.writeln('PASS');
      output.writeln('');

      // ===============================================================
      // TEST 5
      // ===============================================================

      output.writeln('TEST 5: Delete One Object');
      output.writeln(
        'Expected: created=0, updated=0, skipped=3, deleted=1',
      );

      await _hiveService.deleteItem(
        '${_prefix}4',
      );

      final result5 = await _backupService.syncToGoogleDrive();

      _printResult(
        output,
        result5,
      );

      _assert(
        result5.created == 0,
        'TEST 5 failed: expected created=0.',
      );

      _assert(
        result5.updated == 0,
        'TEST 5 failed: expected updated=0.',
      );

      _assert(
        result5.skipped == 3,
        'TEST 5 failed: expected skipped=3.',
      );

      _assert(
        result5.deleted == 1,
        'TEST 5 failed: expected deleted=1.',
      );

      _assert(
        result5.uploadedBytes == 0,
        'TEST 5 failed: expected uploadedBytes=0.',
      );

      output.writeln('PASS');
      output.writeln('');

      // ---------------------------------------------------------------
      // Final cleanup
      // ---------------------------------------------------------------

      output.writeln('Cleaning local test data...');

      await _deleteLocalTestItems();

      output.writeln('');
      output.writeln('========================================');
      output.writeln('ALL TESTS PASSED');
      output.writeln('========================================');

      return output.toString();
    } catch (e) {
      output.writeln('');
      output.writeln('========================================');
      output.writeln('TEST FAILED');
      output.writeln('========================================');
      output.writeln(e);

      // Try to clean local test data even if a test fails.
      try {
        await _deleteLocalTestItems();
      } catch (_) {}

      return output.toString();
    }
  }

  Future<void> _deleteLocalTestItems() async {
    final items = _hiveService.getAllItems();

    for (final item in items) {
      if (!item.id.startsWith(_prefix)) {
        continue;
      }

      await _hiveService.deleteItem(
        item.id,
      );
    }
  }

  void _printResult(
    StringBuffer output,
    IncrementalBackupResult result,
  ) {
    output.writeln(
      '  created       = ${result.created}',
    );

    output.writeln(
      '  updated       = ${result.updated}',
    );

    output.writeln(
      '  skipped       = ${result.skipped}',
    );

    output.writeln(
      '  deleted       = ${result.deleted}',
    );

    output.writeln(
      '  uploadedBytes = ${result.uploadedBytes}',
    );

    output.writeln(
      '  examined      = ${result.examined}',
    );
  }

  void _assert(
    bool condition,
    String message,
  ) {
    if (!condition) {
      throw StateError(
        message,
      );
    }
  }
}
