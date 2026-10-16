import 'package:flutter/material.dart';

class TopProductItem {
  final String name;
  final int qtySold;
  final double revenue;

  const TopProductItem({
    required this.name,
    required this.qtySold,
    required this.revenue,
  });
}

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreenBg = const Color(0xFFE8F5E9);

  String _selectedPeriod = 'Hari Ini';

  // Summary Metrics Data berdasarkan Periode
  double get _totalRevenue {
    switch (_selectedPeriod) {
      case 'Hari Ini':
        return 4850000;
      case 'Minggu Ini':
        return 32400000;
      case 'Bulan Ini':
        return 128500000;
      default:
        return 4850000;
    }
  }

  int get _totalTransactions {
    switch (_selectedPeriod) {
      case 'Hari Ini':
        return 38;
      case 'Minggu Ini':
        return 245;
      case 'Bulan Ini':
        return 980;
      default:
        return 38;
    }
  }

  int get _totalItemsSold {
    switch (_selectedPeriod) {
      case 'Hari Ini':
        return 142;
      case 'Minggu Ini':
        return 890;
      case 'Bulan Ini':
        return 3420;
      default:
        return 142;
    }
  }

  double get _avgTransactionValue => _totalTransactions > 0 ? _totalRevenue / _totalTransactions : 0;

  final List<TopProductItem> _topProducts = const [
    TopProductItem(name: 'Semen Portland 50kg', qtySold: 45, revenue: 3060000),
    TopProductItem(name: 'Cat Tembok Vinilex 5kg', qtySold: 12, revenue: 1620000),
    TopProductItem(name: 'Pipa PVC 2 Inci (10m)', qtySold: 18, revenue: 810000),
    TopProductItem(name: 'Seng Gelombang 1.8m', qtySold: 10, revenue: 750000),
    TopProductItem(name: 'Paku Kayu 5cm (1kg)', qtySold: 25, revenue: 550000),
  ];

  String _formatRupiah(double amount) {
    String str = amount.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
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
          "Laporan Penjualan",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Filter Periode Waktu ---
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['Hari Ini', 'Minggu Ini', 'Bulan Ini'].map((period) {
                    final isSelected = _selectedPeriod == period;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          period,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryGreen,
                        backgroundColor: Colors.white,
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
                              _selectedPeriod = period;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // --- 2. Main Revenue Card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGreen, const Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Omset Penjualan",
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedPeriod,
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRupiah(_totalRevenue),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeaderSubMetric("Transaksi", "$_totalTransactions TRX"),
                        _buildHeaderSubMetric("Item Terjual", "$_totalItemsSold Unit"),
                        _buildHeaderSubMetric("Rata-rata", _formatRupiah(_avgTransactionValue)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- 3. Breakdown Metode Pembayaran ---
              Text(
                "Metode Pembayaran",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildPaymentMethodRow("Tunai (Cash)", 0.65, _formatRupiah(_totalRevenue * 0.65), primaryGreen),
                    const SizedBox(height: 12),
                    _buildPaymentMethodRow("QRIS", 0.25, _formatRupiah(_totalRevenue * 0.25), const Color(0xFF1976D2)),
                    const SizedBox(height: 12),
                    _buildPaymentMethodRow("Transfer Bank", 0.10, _formatRupiah(_totalRevenue * 0.10), const Color(0xFFE65100)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- 4. Produk Terlaris (Top Selling) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Produk Terlaris",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    "Top 5 Items",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: _topProducts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: index == 0 ? primaryGreen : Colors.grey.shade200,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: index == 0 ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "${item.qtySold} Unit Terjual",
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatRupiah(item.revenue),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSubMetric(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildPaymentMethodRow(String title, double percentage, String amount, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
