import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/data/models/user_session.dart';
import 'package:dobrak_mandiri_app/features/auth/presentation/pages/welcome_login_page.dart';
import 'package:dobrak_mandiri_app/features/dashboard/presentation/pages/cashier_dashboard_page.dart';
import 'package:dobrak_mandiri_app/features/dashboard/presentation/pages/inventory_dashboard_page.dart';
import 'package:dobrak_mandiri_app/features/dashboard/presentation/pages/owner_dashboard_page.dart';
import 'package:dobrak_mandiri_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Gateway autentikasi yang secara reaktif mengarahkan pengguna ke halaman login
/// atau dashboard sesuai perannya (Kasir, Inventaris, atau Owner/Manager).
class AuthGatewayPage extends StatelessWidget {
  const AuthGatewayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isInitializing) {
          return const _SplashLoadingView();
        }

        final session = authProvider.session;
        if (session == null || !authProvider.isAuthenticated) {
          return const WelcomeLoginPage();
        }

        switch (session.role) {
          case UserRole.inventory:
            return const InventoryDashboardPage();
          case UserRole.owner:
            return const OwnerDashboardPage();
          case UserRole.cashier:
            return const CashierDashboardPage();
        }
      },
    );
  }
}

class _SplashLoadingView extends StatelessWidget {
  const _SplashLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppTheme.lightGreenBg,
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: AppTheme.primaryGreen,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              AppConstants.companyName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Memeriksa sesi login...',
              style: TextStyle(fontSize: 13, color: AppTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}
