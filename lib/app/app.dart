import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../core/security/biometric_service.dart';
import '../core/security/encryption_service.dart';
import '../core/security/pin_service.dart';
import '../core/security/secure_storage_service.dart';
import '../core/security/vault_lock_service.dart';
import '../core/storage/hive_service.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/language_controller.dart';
import '../features/auth/presentation/pages/auth_router_page.dart';

class KeeplyApp extends StatefulWidget {
  const KeeplyApp({
    super.key,
    required this.secureStorage,
    required this.encryptionService,
    required this.hiveService,
    required this.biometricService,
    required this.pinService,
    required this.vaultLockService,
  });

  final SecureStorageService secureStorage;
  final EncryptionService encryptionService;
  final HiveService hiveService;
  final BiometricService biometricService;
  final PinService pinService;
  final VaultLockService vaultLockService;

  @override
  State<KeeplyApp> createState() => _KeeplyAppState();
}

class _KeeplyAppState extends State<KeeplyApp> {
  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final languageController = context.watch<LanguageController>();

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,

      // -----------------------------------------------------------------------
      // Localization
      // -----------------------------------------------------------------------

      locale: languageController.locale,
      supportedLocales: AppLocalizations.supportedLocales,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Arabic is the fallback/default language.
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) {
          return const Locale('ar');
        }

        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }

        return const Locale('ar');
      },

      // -----------------------------------------------------------------------
      // Theme
      // -----------------------------------------------------------------------

      theme: AppTheme.light(),

      // -----------------------------------------------------------------------
      // Initial Page
      // -----------------------------------------------------------------------

      home: const AuthRouterPage(),
    );
  }
}
