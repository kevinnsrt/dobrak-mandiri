import 'package:dobrak_mandiri_app/services/transaction_service.dart';
import 'package:flutter/material.dart';

class TransactionRecord {
  final int rawId;
  final String id;
  final DateTime timestamp;
  final String cashierName;
  final double subtotal;
  final double ppn;
  final double grandTotal;
  final String paymentMethod;
  final double cashPaid;
  final double change;
  final String status;
  final List<TransactionItem> items;

  const TransactionRecord({
    required this.rawId,
    required this.id,
    required this.timestamp,
    required this.cashierName,
    required this.subtotal,
    required this.ppn,
    required this.grandTotal,
    required this.paymentMethod,
    required this.cashPaid,
    required this.change,
    required this.status,
    required this.items,
  });
}

class TransactionItem {
  final String name;
  final int qty;
  final double price;

  const TransactionItem({
    required this.name,
    required this.qty,
    required this.price,
  });

  double get totalPrice => qty * price;
}

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreenBg = const Color(0xFFE8F5E9);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'Semua';

  bool _isLoading = true;
  String? _errorMessage;
  List<TransactionRecord> _transactions = [];

  final List<TransactionRecord> _fallbackTransactions = [
    TransactionRecord(
      rawId: 1,
      id: 'INV/2026/11/0001',
      timestamp: DateTime.now(),
      cashierName: 'Kasir Toko',
      subtotal: 2702.7,
      ppn: 297.3,
      grandTotal: 3000,
      paymentMethod: 'QRIS',
      cashPaid: 3000,
      change: 0,
      status: 'Lunas',
      items: const [
        TransactionItem(name: 'Semen Portland 50kg', qty: 1, price: 3000),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchTransactionsFromApi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactionsFromApi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await TransactionService.fetchTransactions();

    if (!mounted) return;

    if (result.isSuccess && result.transactions != null) {
      final List<TransactionRecord> parsed = [];

      for (var raw in result.transactions!) {
        if (raw is Map<String, dynamic>) {
          parsed.add(_parseTransactionRecord(raw));
        }
      }

      setState(() {
        _transactions = parsed.isEmpty ? List.from(_fallbackTransactions) : parsed;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result.message;
        _transactions = List.from(_fallbackTransactions);
        _isLoading = false;
      });
    }
  }

  TransactionRecord _parseTransactionRecord(Map<String, dynamic> json) {
    final int rawId = (json['id_transaksi'] as num?)?.toInt() ??
        (json['id'] as num?)?.toInt() ??
        1;

    final String id = json['nomor_struk']?.toString() ??
        json['invoice']?.toString() ??
        'INV/$rawId';

    DateTime parsedDate = DateTime.now();
    final dateStr = json['tanggal_transaksi']?.toString() ?? json['created_at']?.toString();
    if (dateStr != null) {
      parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
    }

    final pengguna = json['pengguna'] is Map<String, dynamic> ? json['pengguna'] as Map<String, dynamic> : null;
    final String cashier = pengguna?['nama']?.toString() ??
        pengguna?['name']?.toString() ??
        json['nama_kasir']?.toString() ??
        'Kasir Toko';

    final double subtotal = (json['subtotal'] as num?)?.toDouble() ??
        (json['total_pembayaran'] as num?)?.toDouble() ??
        (json['total'] as num?)?.toDouble() ??
        0.0;

    final double ppn = (json['ppn'] as num?)?.toDouble() ?? (subtotal * 0.11);
    final double grandTotal = (json['grand_total'] as num?)?.toDouble() ??
        (json['total'] as num?)?.toDouble() ??
        (subtotal + ppn);

    final String paymentMethod = json['jenis_pembayaran_label']?.toString() ??
        json['jenis_pembayaran']?.toString() ??
        json['metode_pembayaran']?.toString() ??
        'TUNAI';

    final double change = (json['kembalian'] as num?)?.toDouble() ?? 0.0;

    // Parse items / detail
    final List<TransactionItem> items = [];
    final detailList = json['detail'] ?? json['items'] ?? json['details'];
    if (detailList is List) {
      for (var d in detailList) {
        if (d is Map<String, dynamic>) {
          final prod = d['produk'] is Map<String, dynamic> ? d['produk'] as Map<String, dynamic> : null;
          final itemName = prod?['nama_produk']?.toString() ??
              prod?['nama']?.toString() ??
              d['nama_produk']?.toString() ??
              d['nama']?.toString() ??
              'Produk Barang';
          final qty = (d['jumlah'] as num?)?.toInt() ?? (d['kuantitas'] as num?)?.toInt() ?? 1;
          final price = (d['harga'] as num?)?.toDouble() ?? (d['harga_satuan'] as num?)?.toDouble() ?? (grandTotal / qty);

          items.add(TransactionItem(name: itemName, qty: qty, price: price));
        }
      }
    }

    if (items.isEmpty) {
      items.add(TransactionItem(name: 'Barang Pesanan', qty: 1, price: grandTotal));
    }

    return TransactionRecord(
      rawId: rawId,
      id: id,
      timestamp: parsedDate,
      cashierName: cashier,
      subtotal: subtotal,
      ppn: ppn,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      cashPaid: grandTotal + change,
      change: change,
      status: 'Lunas',
      items: items,
    );
  }

  /// Panggil GET /api/v1/transaksi/{id} saat kartu transaksi diklik untuk mengambil detail lengkap
  Future<void> _openTransactionDetail(TransactionRecord trx) async {
    // Tampilkan loading dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryGreen),
              const SizedBox(height: 12),
              const Text("Memuat detail transaksi...", style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );

    final detailResult = await TransactionService.fetchTransactionDetail(trx.rawId);

    if (!mounted) return;
    Navigator.pop(context); // Tutup loading dialog

    if (detailResult.isSuccess && detailResult.transaction != null) {
      final freshRecord = _parseTransactionRecord(detailResult.transaction!);
      _showTransactionDetailSheet(freshRecord);
    } else {
      // Fallback ke data lokal jika API detail gagal
      _showTransactionDetailSheet(trx);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memuat detail API: ${detailResult.message}. Menampilkan data lokal."),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    }
  }

  String _formatRupiah(double amount) {
    String str = amount.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  List<TransactionRecord> get _filteredTransactions {
    return _transactions.where((trx) {
      final matchesSearch = trx.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          trx.cashierName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == 'Semua' || trx.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: const Text(
          "Riwayat Transaksi",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Muat Ulang Riwayat",
            onPressed: _fetchTransactionsFromApi,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchTransactionsFromApi,
          color: primaryGreen,
          child: Column(
            children: [
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.orange.shade100,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.orange.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Riwayat offline: $_errorMessage",
                          style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),

              // --- Search & Filter Bar ---
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Cari No. Transaksi...",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: primaryGreen),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['Semua', 'Lunas', 'Dibatalkan'].map((status) {
                        final isSelected = _statusFilter == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: primaryGreen,
                            backgroundColor: Colors.grey.shade100,
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? primaryGreen : Colors.grey.shade300,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _statusFilter = status;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // --- Transaction List ---
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: primaryGreen),
                            const SizedBox(height: 14),
                            const Text("Memuat riwayat transaksi dari API...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      )
                    : _filteredTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  "Belum ada riwayat transaksi",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final trx = _filteredTransactions[index];
                              final isCancel = trx.status == 'Dibatalkan';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _openTransactionDetail(trx),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              trx.id,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isCancel ? Colors.red.shade50 : lightGreenBg,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                trx.status,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isCancel ? Colors.red.shade700 : primaryGreen,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${_formatDate(trx.timestamp)} • Kasir: ${trx.cashierName}",
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        const Divider(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    trx.paymentMethod,
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "${trx.items.length} Item",
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              _formatRupiah(trx.grandTotal),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isCancel ? Colors.grey : primaryGreen,
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
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetailSheet(TransactionRecord trx) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PT DOBRAK MANDIRI",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      Text(
                        trx.id,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: trx.status == 'Lunas' ? lightGreenBg : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      trx.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: trx.status == 'Lunas' ? primaryGreen : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Tanggal: ${_formatDate(trx.timestamp)}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Divider(height: 24),

              // Itemized list
              const Text("Daftar Pesanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              ...trx.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text("${item.name} x${item.qty}", style: const TextStyle(fontSize: 13)),
                        ),
                        Text(_formatRupiah(item.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  )),

              const Divider(height: 20),

              _buildDetailRow("Subtotal", _formatRupiah(trx.subtotal)),
              _buildDetailRow("PPN (11%)", _formatRupiah(trx.ppn)),
              _buildDetailRow("Metode Bayar", trx.paymentMethod),
              if (trx.paymentMethod.toUpperCase() == 'TUNAI') ...[
                _buildDetailRow("Uang Dibayar", _formatRupiah(trx.cashPaid)),
                _buildDetailRow("Kembalian", _formatRupiah(trx.change)),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightGreenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      _formatRupiah(trx.grandTotal),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryGreen),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Struk berhasil dicetak ulang!")),
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text("CETAK STRUK", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
