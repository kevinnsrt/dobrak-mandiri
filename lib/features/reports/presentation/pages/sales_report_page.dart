import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/core/utils/date_formatter.dart';
import 'package:dobrak_mandiri_app/core/widgets/status_banner.dart';
import 'package:dobrak_mandiri_app/data/models/sales_report.dart';
import 'package:dobrak_mandiri_app/features/reports/presentation/widgets/revenue_bar_chart.dart';
import 'package:dobrak_mandiri_app/features/reports/presentation/widgets/transaction_detail_sheet.dart';
import 'package:dobrak_mandiri_app/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Halaman Rekapitulasi Laporan Penjualan & Keuangan Harian/Mingguan/Bulanan (Modul C).
class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reportProvider = context.read<ReportProvider>();
      if (reportProvider.allTransactions.isEmpty) {
        reportProvider.loadTransactions();
      }
    });
  }

  Future<void> _pickReferenceDate(BuildContext context, ReportProvider provider) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      provider.setReferenceDate(picked);
    }
  }

  String _periodTitle(SalesReport report) {
    switch (report.period) {
      case ReportPeriod.daily:
        return DateFormatter.formatLongDate(report.referenceDate);
      case ReportPeriod.weekly:
        final monday = report.referenceDate.subtract(
          Duration(days: report.referenceDate.weekday - 1),
        );
        final sunday = monday.add(const Duration(days: 6));
        return '${DateFormatter.formatDate(monday)} - ${DateFormatter.formatDate(sunday)}';
      case ReportPeriod.monthly:
        return DateFormatter.formatMonthYear(report.referenceDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final report = reportProvider.currentReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Penjualan & Keuangan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang Laporan',
            onPressed: () => reportProvider.loadTransactions(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: reportProvider.loadTransactions,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (reportProvider.isOfflineFallback &&
                  reportProvider.statusMessage != null) ...[
                StatusBanner(
                  message: reportProvider.statusMessage!,
                  isOfflineMode: true,
                  onRetry: () => reportProvider.loadTransactions(),
                ),
                const SizedBox(height: 12),
              ],

              // --- Filter Periode: Harian, Mingguan, Bulanan ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Periode Rekapitulasi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _pickReferenceDate(context, reportProvider),
                            icon: const Icon(Icons.calendar_today, size: 15),
                            label: Text(
                              _periodTitle(report),
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
                          final isSelected = report.period == period;
                          return ChoiceChip(
                            label: Text(period.label),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryGreen,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            onSelected: (_) => reportProvider.setPeriod(period),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // --- Kartu Omset Utama ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pendapatan (${report.period.label})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reportProvider.isOfflineFallback
                                ? 'Data Lokal'
                                : 'Real-Time',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (reportProvider.isLoading)
                      const CircularProgressIndicator(color: Colors.white)
                    else
                      Text(
                        CurrencyFormatter.formatRupiah(report.totalRevenue),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _HeaderMetric(
                          'Transaksi',
                          '${report.totalTransactions} TRX',
                        ),
                        _HeaderMetric(
                          'Volume Terjual',
                          '${report.totalItemsSold} Unit',
                        ),
                        _HeaderMetric(
                          'Rata-rata',
                          CurrencyFormatter.formatCompact(
                            report.averageTransactionValue,
                          ),
                        ),
                      ],
                    ),
                    if (report.totalDiscount > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Total Diskon Diberikan: ${CurrencyFormatter.formatRupiah(report.totalDiscount)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- Grafik Tren Penjualan ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grafik Tren Penjualan (${report.period.label})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _periodTitle(report),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      RevenueBarChart(buckets: report.chartBuckets),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Breakdown Metode Pembayaran Manual (Tunai & Transfer Manual) ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rekap Metode Pembayaran Manual',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PaymentBreakdownBar(
                        label: 'Tunai',
                        ratio: report.cashRatio,
                        amount: report.cashTotal,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(height: 12),
                      _PaymentBreakdownBar(
                        label: 'Transfer Manual',
                        ratio: report.manualTransferRatio,
                        amount: report.manualTransferTotal,
                        color: AppTheme.infoBlue,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Produk Terlaris ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Produk Terlaris Periode Ini',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (report.topProducts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Belum ada penjualan tercatat pada periode ini.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...report.topProducts.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 15,
                              backgroundColor: idx == 0
                                  ? AppTheme.primaryGreen
                                  : Colors.grey.shade200,
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: idx == 0 ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text('${item.qtySold} Unit Terjual'),
                            trailing: Text(
                              CurrencyFormatter.formatRupiah(item.revenue),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Daftar Ringkasan Transaksi Periode Terpilih ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Transaksi (${report.transactions.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (report.transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Belum ada transaksi pada tanggal/bulan terpilih.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...report.transactions.take(15).map(
                              (trx) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                onTap: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(24),
                                      ),
                                    ),
                                    builder: (_) =>
                                        TransactionDetailSheet(transaction: trx),
                                  );
                                },
                                title: Text(
                                  trx.invoiceNumber,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${DateFormatter.formatDateTime(trx.timestamp)} • ${trx.paymentMethod.label} • ${trx.totalItemQuantity} Unit',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  CurrencyFormatter.formatRupiah(trx.grandTotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PaymentBreakdownBar extends StatelessWidget {
  const _PaymentBreakdownBar({
    required this.label,
    required this.ratio,
    required this.amount,
    required this.color,
  });

  final String label;
  final double ratio;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label ($pct%)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              CurrencyFormatter.formatRupiah(amount),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
