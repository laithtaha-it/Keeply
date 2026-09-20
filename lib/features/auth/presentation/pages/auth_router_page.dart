import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'lock_page.dart';
import 'vault_home_page.dart';
import 'welcome_page.dart';
import '../../../../l10n/app_localizations.dart';

class AuthRouterPage extends StatelessWidget {
  const AuthRouterPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const _LoadingPage();

          case AuthStatus.firstLaunch:
            return const WelcomePage();

          case AuthStatus.locked:
            // IMPORTANT:
            // When the vault is locked, always show the PIN lock screen.
            return const LockPage();

          case AuthStatus.authenticated:
            return const VaultHomePage();

          case AuthStatus.failure:
            return _ErrorPage(
              message: state.errorMessage,
            );
        }
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Loading
// -----------------------------------------------------------------------------

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Error
// -----------------------------------------------------------------------------

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({
    required this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 52,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).genericError,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message ?? AppLocalizations.of(context).initializationError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthCubit>().initialize();
                  },
                  child: Text(AppLocalizations.of(context).tryAgain),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
