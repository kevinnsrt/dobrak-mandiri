import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/core/utils/date_formatter.dart';
import 'package:dobrak_mandiri_app/data/models/sales_report.dart';
import 'package:dobrak_mandiri_app/features/dashboard/presentation/widgets/dashboard_menu_card.dart';
import 'package:dobrak_mandiri_app/features/dashboard/presentation/widgets/dashboard_profile_menu.dart';
import 'package:dobrak_mandiri_app/features/inventory/presentation/pages/inventory_list_page.dart';
import 'package:dobrak_mandiri_app/features/reports/presentation/pages/sales_report_page.dart';
import 'package:dobrak_mandiri_app/features/reports/presentation/pages/transaction_history_page.dart';
import 'package:dobrak_mandiri_app/features/reports/presentation/widgets/revenue_bar_chart.dart';
import 'package:dobrak_mandiri_app/providers/auth_provider.dart';
import 'package:dobrak_mandiri_app/providers/inventory_provider.dart';
import 'package:dobrak_mandiri_app/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dashboard Owner / Manager PT. Dobrak Mandiri.
class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
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

  Future<void> _selectDate(BuildContext context, ReportProvider report) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: report.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      report.setReferenceDate(picked);
    }
  }

  void _showTeamAccessModal(BuildContext context) {
    final session = context.read<AuthProvider>().session;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hak Akses Peran Sistem POS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Sesi Aktif: ${session?.name ?? 'Manager'} (${session?.role.displayLabel ?? 'MANAGER'})',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 22),
            const _RoleTile(
              'Kasir Toko',
              'Transaksi POS, Diskon, Pembayaran Manual, & Nota Faktur',
              'KASIR',
              AppTheme.primaryGreen,
            ),
            const _RoleTile(
              'Staf Gudang / Inventaris',
              'Kelola Produk, Stok Masuk/Keluar, & Peringatan Menipis',
              'INVENTORY',
              AppTheme.infoBlue,
            ),
            const _RoleTile(
              'Owner / Manager',
              'Monitoring Omset Harian/Bulanan, Audit Transaksi & Stok',
              'MANAGER',
              AppTheme.purpleAccent,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('TUTUP'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().session;
    final inventory = context.watch<InventoryProvider>();
    final reportProvider = context.watch<ReportProvider>();
    final activeReport = reportProvider.currentReport;
    final monthReport = reportProvider.currentMonthReport;
    final lowItems = inventory.lowStockProducts;

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
              'Manager Dashboard',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang Data',
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
                          Icons.store,
                          color: AppTheme.primaryGreen,
                          size: 28,
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
                              session?.name ?? 'Manager Toko',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (session?.email.isNotEmpty ?? false)
                              Text(
                                session!.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
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
                        child: const Text(
                          'MANAGER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppTheme.lightGreenBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.payments_outlined,
                                color: AppTheme.primaryGreen,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Omset Bulan Berjalan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      CurrencyFormatter.formatRupiah(
                                        monthReport.totalRevenue,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _KpiStat(
                              'Transaksi Bulan Ini',
                              '${monthReport.totalTransactions} Struk',
                              AppTheme.infoBlue,
                            ),
                            Container(
                              height: 28,
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                            _KpiStat(
                              'SKU Gudang',
                              '${inventory.totalSku} Item',
                              AppTheme.purpleAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grafik Tren Penjualan',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _selectDate(context, reportProvider),
                              icon: const Icon(Icons.calendar_today, size: 14),
                              label: Text(
                                DateFormatter.formatDate(
                                  reportProvider.selectedDate,
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: ReportPeriod.values.map((period) {
                            final isSelected = activeReport.period == period;
                            return ChoiceChip(
                              label: Text(period.label),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryGreen,
                              showCheckmark: false,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                              onSelected: (_) =>
                                  reportProvider.setPeriod(period),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        RevenueBarChart(buckets: activeReport.chartBuckets),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Menu Utama Manajerial',
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
                  childAspectRatio: 1.15,
                  children: [
                    DashboardMenuCard(
                      title: 'Cek Stok',
                      subtitle: 'Lihat & kelola stok',
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
                      subtitle: 'Harian & bulanan',
                      icon: Icons.bar_chart_rounded,
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
                      subtitle: 'Daftar transaksi',
                      icon: Icons.receipt_long_rounded,
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
                    DashboardMenuCard(
                      title: 'Tim & Akses',
                      subtitle: 'Peran staf toko',
                      icon: Icons.people_alt_outlined,
                      color: AppTheme.tealAccent,
                      onTap: () => _showTeamAccessModal(context),
                    ),
                  ],
                ),
                if (lowItems.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Peringatan Stok Menipis (${lowItems.length} Item)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningOrange,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const InventoryListPage(
                                initialStatusFilter: 'Stok Menipis',
                              ),
                            ),
                          );
                        },
                        child: const Text('Kelola Stok'),
                      ),
                    ],
                  ),
                  ...lowItems.take(3).map(
                        (item) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: Colors.orange.shade50,
                          child: ListTile(
                            leading: const Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.warningOrange,
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Text(
                              'Sisa: ${item.stock} ${item.unit}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiStat extends StatelessWidget {
  const _KpiStat(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile(this.title, this.desc, this.tag, this.color);

  final String title;
  final String desc;
  final String tag;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Text(
              title[0],
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
