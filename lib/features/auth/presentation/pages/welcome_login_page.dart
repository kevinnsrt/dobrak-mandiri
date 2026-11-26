import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/features/auth/presentation/pages/login_form_page.dart';
import 'package:flutter/material.dart';

/// Halaman sambutan awal sistem POS & Inventaris PT. Dobrak Mandiri.
class WelcomeLoginPage extends StatelessWidget {
  const WelcomeLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.sizeOf(context).height * 0.16,
              decoration: const BoxDecoration(
                color: AppTheme.lightGreenAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(100),
                  bottomRight: Radius.circular(100),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 40).clamp(0, double.infinity),
                    maxWidth: 520,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 24),
                          Column(
                            children: [
                              Semantics(
                                label: 'Ilustrasi toko bahan bangunan dan sistem POS inventaris',
                                child: Container(
                                  width: 168,
                                  height: 168,
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightGreenBg,
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                      color: AppTheme.lightGreenAccent,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.storefront_rounded,
                                        size: 68,
                                        color: AppTheme.primaryGreen,
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.point_of_sale_rounded,
                                            size: 24,
                                            color: AppTheme.infoBlue,
                                          ),
                                          SizedBox(width: 12),
                                          Icon(
                                            Icons.inventory_2_rounded,
                                            size: 24,
                                            color: AppTheme.warningOrange,
                                          ),
                                          SizedBox(width: 12),
                                          Icon(
                                            Icons.bar_chart_rounded,
                                            size: 24,
                                            color: AppTheme.purpleAccent,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'SISTEM POS & INVENTARIS',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                AppConstants.companyName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGreen,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Kelola transaksi kasir, stok bahan bangunan real-time, dan laporan penjualan toko dalam satu aplikasi terintegrasi.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.mutedText,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 54),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => const LoginFormPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: const Text(
                                  'MASUK KE SISTEM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
