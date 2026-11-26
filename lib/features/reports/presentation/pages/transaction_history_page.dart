import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/core/utils/date_formatter.dart';
import 'package:dobrak_mandiri_app/core/widgets/status_banner.dart';
import 'package:dobrak_mandiri_app/data/models/transaction.dart';
import 'package:dobrak_mandiri_app/features/reports/presentation/widgets/transaction_detail_sheet.dart';
import 'package:dobrak_mandiri_app/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Halaman Riwayat Transaksi & Arsip Nota/Faktur Terstruktur.
class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _methodFilter = 'Semua';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _filterTransactions(List<Transaction> list) {
    final query = _searchQuery.toLowerCase().trim();
    return list.where((trx) {
      final matchesSearch = query.isEmpty ||
          trx.invoiceNumber.toLowerCase().contains(query) ||
          trx.cashierName.toLowerCase().contains(query) ||
          (trx.customerName ?? '').toLowerCase().contains(query);
      final matchesMethod = _methodFilter == 'Semua' ||
          trx.paymentMethod.label == _methodFilter;
      return matchesSearch && matchesMethod;
    }).toList();
  }

  Future<void> _openDetail(BuildContext context, Transaction trx) async {
    final reportProvider = context.read<ReportProvider>();
    final fresh = await reportProvider.fetchTransactionDetail(trx);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TransactionDetailSheet(transaction: fresh ?? trx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final transactions = _filterTransactions(reportProvider.allTransactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi & Faktur',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang Riwayat',
            onPressed: () => reportProvider.loadTransactions(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (reportProvider.isOfflineFallback &&
                reportProvider.statusMessage != null)
              StatusBanner(
                message: reportProvider.statusMessage!,
                isOfflineMode: true,
                onRetry: () => reportProvider.loadTransactions(),
              ),
            Container(
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari No. Faktur, kasir, atau pelanggan...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.primaryGreen,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: ['Semua', 'Tunai', 'Transfer Manual'].map((method) {
                      final isSelected = _methodFilter == method;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(method),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryGreen,
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          onSelected: (_) =>
                              setState(() => _methodFilter = method),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: reportProvider.loadTransactions,
                child: reportProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : transactions.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 56,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Center(
                                child: Text(
                                  'Belum ada riwayat transaksi',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final trx = transactions[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _openDetail(context, trx),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                trx.invoiceNumber,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.lightGreenBg,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                trx.isSynced
                                                    ? trx.status
                                                    : '${trx.status} (Lokal)',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryGreen,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${DateFormatter.formatDateTime(trx.timestamp)} • Kasir: ${trx.cashierName}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const Divider(height: 18),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    trx.paymentMethod.label,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${trx.totalItemQuantity} Unit',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              CurrencyFormatter.formatRupiah(
                                                trx.grandTotal,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
