import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/backup/backup_service.dart';
import 'core/cloud/google_drive_service.dart';
import 'core/security/biometric_service.dart';
import 'core/security/encryption_service.dart';
import 'core/security/pin_service.dart';
import 'core/security/secure_storage_service.dart';
import 'core/security/vault_lock_service.dart';
import 'core/localization/language_controller.dart';
import 'core/storage/hive_service.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // Core Services
  // ===========================================================================

  final secureStorage = SecureStorageService();

  final encryptionService = EncryptionService(
    secureStorage: secureStorage,
  );

  final hiveService = HiveService();

  final biometricService = BiometricService();

  final pinService = PinService(
    secureStorage: secureStorage,
  );

  final vaultLockService = VaultLockService(
    secureStorage: secureStorage,
    biometricService: biometricService,
  );

  // ===========================================================================
  // Google Drive
  // ===========================================================================

  final googleDriveService = GoogleDriveService();

  // ===========================================================================
  // Authentication
  // ===========================================================================

  final authCubit = AuthCubit(
    pinService: pinService,
    biometricService: biometricService,
    vaultLockService: vaultLockService,
    encryptionService: encryptionService,
  );

  // ===========================================================================
  // Language
  // ===========================================================================

  final languageController = LanguageController();
  await languageController.load();

  // ===========================================================================
  // Application
  // ===========================================================================

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SecureStorageService>.value(
          value: secureStorage,
        ),

        RepositoryProvider<EncryptionService>.value(
          value: encryptionService,
        ),

        RepositoryProvider<HiveService>.value(
          value: hiveService,
        ),

        RepositoryProvider<BiometricService>.value(
          value: biometricService,
        ),

        RepositoryProvider<PinService>.value(
          value: pinService,
        ),

        // VaultLockService is a ChangeNotifier/Listenable,
        // so it must not be registered using RepositoryProvider.
        ChangeNotifierProvider<VaultLockService>.value(
          value: vaultLockService,
        ),

        RepositoryProvider<GoogleDriveService>.value(
          value: googleDriveService,
        ),

        // Backup Service
        RepositoryProvider<BackupService>(
          create: (_) => BackupService(
            hiveService: hiveService,
            encryptionService: encryptionService,
            googleDriveService: googleDriveService,
            secureStorage: secureStorage,
          ),
        ),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageController>.value(
            value: languageController,
          ),
        ],
        child: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: KeeplyApp(
            secureStorage: secureStorage,
            encryptionService: encryptionService,
            hiveService: hiveService,
            biometricService: biometricService,
            pinService: pinService,
            vaultLockService: vaultLockService,
          ),
        ),
      ),
    ),
  );

  // ===========================================================================
  // Initialize Services
  // ===========================================================================

  try {
    await encryptionService.initialize();

    await hiveService.initialize();

    await vaultLockService.initialize();

    await authCubit.initialize();
  } catch (error, stackTrace) {
    debugPrint(
      'Keeply initialization error: $error',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );
  }
}
