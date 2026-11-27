import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/features/dashboard/presentation/widgets/dashboard_menu_card.dart';
import 'package:dobrak_mandiri_app/features/dashboard/presentation/widgets/dashboard_profile_menu.dart';
import 'package:dobrak_mandiri_app/features/inventory/presentation/pages/inventory_list_page.dart';
import 'package:dobrak_mandiri_app/features/pos/presentation/pages/pos_order_page.dart';
import 'package:dobrak_mandiri_app/features/reports/presentation/pages/sales_report_page.dart';
import 'package:dobrak_mandiri_app/features/reports/presentation/pages/transaction_history_page.dart';
import 'package:dobrak_mandiri_app/providers/auth_provider.dart';
import 'package:dobrak_mandiri_app/providers/inventory_provider.dart';
import 'package:dobrak_mandiri_app/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dashboard Utama Kasir PT. Dobrak Mandiri dengan ringkasan real-time.
class CashierDashboardPage extends StatefulWidget {
  const CashierDashboardPage({super.key});

  @override
  State<CashierDashboardPage> createState() => _CashierDashboardPageState();
}

class _CashierDashboardPageState extends State<CashierDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  Future<void> _refreshAll() async {
    final inventory = context.read<InventoryProvider>();
    final report = context.read<ReportProvider>();
    await Future.wait([
      inventory.loadProducts(),
      report.loadTransactions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;
    final today = context.watch<ReportProvider>().todayReport;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.companyName,
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            Text(
              'Dashboard Kasir',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sinkronkan Data',
            onPressed: _refreshAll,
          ),
          const DashboardProfileMenu(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppTheme.lightGreenBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: AppTheme.primaryGreen,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selamat Datang,',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              session?.name ?? 'Kasir Toko',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (session?.email.isNotEmpty ?? false)
                              Text(
                                session!.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreenBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          session?.role.displayLabel ?? 'KASIR',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Menu Utama',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: [
                    DashboardMenuCard(
                      title: 'Pesanan Baru',
                      subtitle: 'Kasir & Nota POS',
                      icon: Icons.add_shopping_cart_rounded,
                      color: AppTheme.primaryGreen,
                      onTap: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const PosOrderPage(),
                          ),
                        );
                      },
                    ),
                    DashboardMenuCard(
                      title: 'Cek Stok',
                      subtitle: 'Stok gudang real-time',
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.infoBlue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const InventoryListPage(),
                          ),
                        );
                      },
                    ),
                    DashboardMenuCard(
                      title: 'Laporan',
                      subtitle: 'Rekap harian/bulanan',
                      icon: Icons.insert_chart_outlined_rounded,
                      color: AppTheme.warningOrange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SalesReportPage(),
                          ),
                        );
                      },
                    ),
                    DashboardMenuCard(
                      title: 'Riwayat',
                      subtitle: 'Arsip nota & faktur',
                      icon: Icons.receipt_long_outlined,
                      color: AppTheme.purpleAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const TransactionHistoryPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
