import 'package:flutter/material.dart';

class TransactionRecord {
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

  final List<TransactionRecord> _transactions = [
    TransactionRecord(
      id: 'TRX-20250520-001',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      cashierName: 'Winaldy Senna',
      subtotal: 136000,
      ppn: 14960,
      grandTotal: 150960,
      paymentMethod: 'Tunai',
      cashPaid: 160000,
      change: 9040,
      status: 'Lunas',
      items: const [
        TransactionItem(name: 'Semen Portland 50kg', qty: 2, price: 68000),
      ],
    ),
    TransactionRecord(
      id: 'TRX-20250520-002',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
      cashierName: 'Winaldy Senna',
      subtotal: 270000,
      ppn: 29700,
      grandTotal: 299700,
      paymentMethod: 'QRIS',
      cashPaid: 299700,
      change: 0,
      status: 'Lunas',
      items: const [
        TransactionItem(name: 'Cat Tembok Vinilex 5kg', qty: 2, price: 135000),
      ],
    ),
    TransactionRecord(
      id: 'TRX-20250520-003',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      cashierName: 'Winaldy Senna',
      subtotal: 90000,
      ppn: 9900,
      grandTotal: 99900,
      paymentMethod: 'Tunai',
      cashPaid: 100000,
      change: 100,
      status: 'Lunas',
      items: const [
        TransactionItem(name: 'Pipa PVC 2 Inci (10m)', qty: 2, price: 45000),
      ],
    ),
    TransactionRecord(
      id: 'TRX-20250519-012',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      cashierName: 'Winaldy Senna',
      subtotal: 225000,
      ppn: 24750,
      grandTotal: 249750,
      paymentMethod: 'Transfer',
      cashPaid: 249750,
      change: 0,
      status: 'Lunas',
      items: const [
        TransactionItem(name: 'Seng Gelombang 1.8m', qty: 3, price: 75000),
      ],
    ),
    TransactionRecord(
      id: 'TRX-20250519-008',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      cashierName: 'Winaldy Senna',
      subtotal: 44000,
      ppn: 4840,
      grandTotal: 48840,
      paymentMethod: 'Tunai',
      cashPaid: 50000,
      change: 1160,
      status: 'Dibatalkan',
      items: const [
        TransactionItem(name: 'Paku Kayu 5cm (1kg)', qty: 2, price: 22000),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      ),
      body: SafeArea(
        child: Column(
          children: [
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
              child: _filteredTransactions.isEmpty
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
                            onTap: () => _showTransactionDetailSheet(trx),
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
              if (trx.paymentMethod == 'Tunai') ...[
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
