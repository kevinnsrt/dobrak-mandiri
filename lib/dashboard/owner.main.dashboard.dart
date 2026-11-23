import 'package:dobrak_mandiri_app/authentication/login.dart';
import 'package:dobrak_mandiri_app/cashier/sales_report_page.dart';
import 'package:dobrak_mandiri_app/cashier/stock_check_page.dart';
import 'package:dobrak_mandiri_app/cashier/transaction_history_page.dart';
import 'package:dobrak_mandiri_app/services/auth_service.dart';
import 'package:dobrak_mandiri_app/services/stock_service.dart';
import 'package:dobrak_mandiri_app/services/transaction_service.dart';
import 'package:flutter/material.dart';

class OwnerMainDashboard extends StatefulWidget {
  const OwnerMainDashboard({super.key});

  @override
  State<OwnerMainDashboard> createState() => _OwnerMainDashboardState();
}

class _OwnerMainDashboardState extends State<OwnerMainDashboard> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreenBg = const Color(0xFFE8F5E9);

  bool _isLoading = true;
  String? _userName;
  String? _userEmail;

  // Data API
  double _totalOmzet = 0.0;
  int _transactionCount = 0;
  int _totalSkuCount = 0;
  int _lowStockCount = 0;

  // Filter Grafik Penjualan & Omset
  String _selectedPeriod = 'Mingguan'; // 'Harian', 'Mingguan', 'Bulanan'
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _rawTransactions = [];
  List<Map<String, dynamic>> _lowStockProducts = [];

  @override
  void initState() {
    super.initState();
    _loadManagerDashboardData();
  }

  Future<void> _loadManagerDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    final name = await AuthService.getUserName();
    final email = await AuthService.getUserEmail();

    // Fetch Transaksi & Stok secara parallel
    final results = await Future.wait([
      TransactionService.fetchTransactions(),
      StockService.fetchStockList(),
    ]);

    final trxResult = results[0] as TransactionListResult;
    final stockResult = results[1] as StockApiResult;

    double omzet = 0.0;
    int count = 0;
    List<Map<String, dynamic>> rawTrx = [];

    if (trxResult.isSuccess && trxResult.transactions != null) {
      final transactions = trxResult.transactions!;
      count = transactions.length;

      for (var t in transactions) {
        if (t is Map<String, dynamic>) {
          rawTrx.add(t);
          final total = (t['total_pembayaran'] as num?)?.toDouble() ??
              (t['total'] as num?)?.toDouble() ??
              0.0;
          omzet += total;
        }
      }
    }

    int skuCount = 0;
    int lowCount = 0;
    List<Map<String, dynamic>> lowItems = [];

    if (stockResult.isSuccess && stockResult.data != null) {
      final stockData = stockResult.data!;
      skuCount = stockData.length;

      for (var s in stockData) {
        if (s is Map<String, dynamic>) {
          final q = (s['kuantitas'] ?? s['stok'] ?? 0) as num;
          if (q > 0 && q <= 5) {
            lowCount++;
            lowItems.add(s);
          }
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _userName = name ?? 'Owner Toko';
      _userEmail = email ?? 'owner@pos.local';
      _totalOmzet = omzet;
      _transactionCount = count;
      _totalSkuCount = skuCount;
      _lowStockCount = lowCount;
      _rawTransactions = rawTrx;
      _lowStockProducts = lowItems.take(3).toList();
      _isLoading = false;
    });
  }

  void _showSnackBar(String message, {bool isSuccess = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? primaryGreen : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatRupiah(double amount) {
    String str = amount.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredChartData() {
    if (_selectedPeriod == 'Harian') {
      // Grouping jam operasional di hari _selectedDate berdasarkan updated_at
      final hours = [8, 10, 12, 14, 16, 18, 20];
      final Map<int, double> map = {for (var h in hours) h: 0.0};

      for (var t in _rawTransactions) {
        final total = (t['total_pembayaran'] as num?)?.toDouble() ?? 0.0;
        final dateStr = t['updated_at']?.toString() ?? t['tanggal_transaksi']?.toString() ?? t['created_at']?.toString();
        if (dateStr != null) {
          final dt = DateTime.tryParse(dateStr);
          if (dt != null && dt.year == _selectedDate.year && dt.month == _selectedDate.month && dt.day == _selectedDate.day) {
            int closestHour = 8;
            for (var h in hours) {
              if (dt.hour >= h) closestHour = h;
            }
            map[closestHour] = (map[closestHour] ?? 0.0) + total;
          }
        }
      }

      double maxVal = 0.0;
      map.forEach((k, v) {
        if (v > maxVal) maxVal = v;
      });

      return hours.map((h) {
        final val = map[h] ?? 0.0;
        final r = maxVal > 0 ? (val / maxVal) : 0.15;
        return {
          'label': "${h.toString().padLeft(2, '0')}:00",
          'omzet': val,
          'height': r < 0.15 ? 0.15 : r,
        };
      }).toList();
    } else if (_selectedPeriod == 'Bulanan') {
      // 12 Bulan Kalender (Jan - Des) di tahun _selectedDate berdasarkan updated_at
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final Map<int, double> map = {for (int m = 1; m <= 12; m++) m: 0.0};

      for (var t in _rawTransactions) {
        final total = (t['total_pembayaran'] as num?)?.toDouble() ?? 0.0;
        final dateStr = t['updated_at']?.toString() ?? t['tanggal_transaksi']?.toString() ?? t['created_at']?.toString();
        if (dateStr != null) {
          final dt = DateTime.tryParse(dateStr);
          if (dt != null && dt.year == _selectedDate.year) {
            map[dt.month] = (map[dt.month] ?? 0.0) + total;
          }
        }
      }

      double maxVal = 0.0;
      map.forEach((k, v) {
        if (v > maxVal) maxVal = v;
      });

      return List.generate(12, (index) {
        final m = index + 1;
        final val = map[m] ?? 0.0;
        final r = maxVal > 0 ? (val / maxVal) : 0.15;
        return {
          'label': monthNames[index],
          'omzet': val,
          'height': r < 0.15 ? 0.15 : r,
        };
      });
    } else {
      // 'Mingguan' (7 hari kalender di minggu yang mencakup _selectedDate)
      final DateTime monday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      final List<Map<String, dynamic>> res = [];

      double maxVal = 0.0;
      List<double> dailyTotals = List.filled(7, 0.0);

      for (int i = 0; i < 7; i++) {
        final dayDate = monday.add(Duration(days: i));

        for (var t in _rawTransactions) {
          final total = (t['total_pembayaran'] as num?)?.toDouble() ?? 0.0;
          final dateStr = t['updated_at']?.toString() ?? t['tanggal_transaksi']?.toString() ?? t['created_at']?.toString();
          if (dateStr != null) {
            final dt = DateTime.tryParse(dateStr);
            if (dt != null && dt.year == dayDate.year && dt.month == dayDate.month && dt.day == dayDate.day) {
              dailyTotals[i] += total;
            }
          }
        }

        if (dailyTotals[i] > maxVal) maxVal = dailyTotals[i];
      }

      for (int i = 0; i < 7; i++) {
        final dayDate = monday.add(Duration(days: i));
        final val = dailyTotals[i];
        final r = maxVal > 0 ? (val / maxVal) : 0.15;
        res.add({
          'label': "${dayNames[i]}\n${dayDate.day}/${dayDate.month}",
          'omzet': val,
          'height': r < 0.15 ? 0.15 : r,
        });
      }

      return res;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryGreen,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PT DOBRAK MANDIRI",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            Text(
              "Manager Dashboard",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              _showSnackBar("Tidak ada notifikasi manajerial baru");
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Muat Ulang Data Manager",
            onPressed: () {
              _loadManagerDashboardData();
              _showSnackBar("Data manajerial berhasil diperbarui!");
            },
          ),
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const LoginPage(),
                    ),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  "Sesi: ${_userName ?? 'Manager'}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text("Keluar (Logout)", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadManagerDashboardData,
          color: primaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. User Header Banner (Owner / Manager) ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                        decoration: BoxDecoration(
                          color: lightGreenBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.store, color: primaryGreen, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Selamat Datang,",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              _userName ?? "Owner Toko",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              _userEmail ?? "owner@pos.local",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: lightGreenBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "MANAGER",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- 2. Ringkasan Eksekutif Bebas Overflow ---
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()))
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: lightGreenBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.payments_outlined, color: primaryGreen, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Total Omzet Penjualan", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _formatRupiah(_totalOmzet),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _buildKPIStat("Total Transaksi", "$_transactionCount Struk", const Color(0xFF1976D2)),
                            ),
                            Container(height: 28, width: 1, color: Colors.grey.shade300),
                            Expanded(
                              child: _buildKPIStat("SKU Gudang", "$_totalSkuCount Item", const Color(0xFF7B1FA2)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // --- 3. Grafik Visual Tren Penjualan & Omset Filterable ---
                _buildSalesChartCard(),

                const SizedBox(height: 24),

                // --- 4. Menu Utama Manager (Tanpa "Pesanan Baru") ---
                Text(
                  "Menu Utama Manajerial",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.15,
                  children: [
                    _buildOwnerMenuCard(
                      title: "Cek Stok",
                      subtitle: "Lihat stok gudang",
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF1976D2), // Biru
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const StockCheckPage(),
                          ),
                        );
                      },
                    ),
                    _buildOwnerMenuCard(
                      title: "Laporan",
                      subtitle: "Ringkasan penjualan",
                      icon: Icons.bar_chart_rounded,
                      color: const Color(0xFFF57C00), // Oranye
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const SalesReportPage(),
                          ),
                        );
                      },
                    ),
                    _buildOwnerMenuCard(
                      title: "Riwayat",
                      subtitle: "Daftar transaksi",
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF7B1FA2), // Ungu
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const TransactionHistoryPage(),
                          ),
                        );
                      },
                    ),
                    _buildOwnerMenuCard(
                      title: "Tim & Kasir",
                      subtitle: "Manajemen staf aktif",
                      icon: Icons.people_alt_outlined,
                      color: const Color(0xFF00796B), // Teal
                      onTap: _showStaffManagementModal,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- 5. Alert Stok Menipis (<=5) ---
                if (_lowStockCount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Peringatan Stok Menipis ($_lowStockCount Item)",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => const StockCheckPage(),
                            ),
                          );
                        },
                        child: Text("Kelola Stok", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._lowStockProducts.map((p) {
                    final name = p['nama_produk']?.toString() ?? p['nama']?.toString() ?? 'Barang';
                    final qty = (p['kuantitas'] ?? p['stok'] ?? 0) as int;
                    final unit = p['satuan']?.toString() ?? p['unit']?.toString() ?? 'Unit';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade900, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          Text(
                            "Sisa: $qty $unit",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget Grafik Visual Omzet dengan Filter Periode & Kalender
  Widget _buildSalesChartCard() {
    final chartData = _getFilteredChartData();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Grafik Tren Penjualan", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text("Sesuai kalender berdasarkan updated_at", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _selectDate(context),
                icon: Icon(Icons.calendar_today, size: 14, color: primaryGreen),
                label: Text(
                  "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                  style: TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryGreen),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Choice Chips: Harian, Mingguan, Bulanan
          Row(
            children: ['Harian', 'Mingguan', 'Bulanan'].map((period) {
              final isSelected = _selectedPeriod == period;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(
                    period,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: primaryGreen,
                  backgroundColor: Colors.grey.shade100,
                  showCheckmark: false,
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

          const SizedBox(height: 20),

          SizedBox(
            height: 135,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: chartData.map((d) {
                  final double h = d['height'] as double;
                  final String label = d['label'] as String;
                  final double dayOmzet = d['omzet'] as double;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (dayOmzet > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              _shortenOmzet(dayOmzet),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryGreen),
                            ),
                          ),
                        Container(
                          width: _selectedPeriod == 'Bulanan' ? 16 : 22,
                          height: 80 * h,
                          decoration: BoxDecoration(
                            color: dayOmzet > 0 ? primaryGreen : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: dayOmzet > 0 ? FontWeight.bold : FontWeight.normal,
                            color: dayOmzet > 0 ? primaryGreen : Colors.grey.shade700,
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
    );
  }

  String _shortenOmzet(double amount) {
    if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(1)}Jt";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(0)}Rb";
    }
    return amount.toStringAsFixed(0);
  }

  // Modal Ringkasan Tim & Kasir Toko
  void _showStaffManagementModal() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Tim & Staf Toko", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Pengguna aktif dengan hak akses sistem POS", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(height: 24),
              _buildStaffTile("Winaldy Senna", "Kasir Utama Toko", "KASIR", primaryGreen),
              _buildStaffTile("Tim Gudang", "Pengelola Stok Inventaris", "INVENTORY", const Color(0xFF1976D2)),
              _buildStaffTile("Manajer Toko", "Akses Manajerial & Laporan", "MANAGER", const Color(0xFF7B1FA2)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("TUTUP", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaffTile(String name, String desc, String roleTag, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(name.substring(0, 1), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Text(roleTag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildOwnerMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
