import 'package:dobrak_mandiri_app/cashier/sales_report_page.dart';
import 'package:dobrak_mandiri_app/cashier/stock_check_page.dart';
import 'package:flutter/material.dart';

class InventoryMainDashboard extends StatefulWidget {
  const InventoryMainDashboard({super.key});

  @override
  State<InventoryMainDashboard> createState() => _InventoryMainDashboardState();
}

class _InventoryMainDashboardState extends State<InventoryMainDashboard> {
  // Warna Utama PT Dobrak Mandiri
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreenBg = const Color(0xFFE8F5E9);

  void _showSnackBar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? primaryGreen : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryGreen,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "PT DOBRAK MANDIRI",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            Text(
              "Pengelola Inventaris",
              style: TextStyle(
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
              _showSnackBar("Tidak ada notifikasi baru");
            },
          ),
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.inventory_sharp, color: Colors.white),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Ringkasan Status Gudang ---
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
                          child: Icon(Icons.warehouse_outlined, color: primaryGreen, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Gudang Utama (Pusat)",
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              Text(
                                "Total SKU: 1,240 Item",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: lightGreenBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Aktif",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => const StockCheckPage(),
                              ),
                            );
                          },
                          child: _buildStatMetric("Stok Rendah", "12 Item", Colors.orange.shade800),
                        ),
                        Container(height: 28, width: 1, color: Colors.grey.shade300),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (context) => const StockCheckPage(),
                              ),
                            );
                          },
                          child: _buildStatMetric("Stok Habis", "3 Item", Colors.red.shade700),
                        ),
                        Container(height: 28, width: 1, color: Colors.grey.shade300),
                        _buildStatMetric("Barang Masuk", "+45 Hari ini", primaryGreen),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- 2. Menu Operasional Inventaris (Grid Box) ---
              Text(
                "Manajemen Stok & Gudang",
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
                childAspectRatio: 1.1,
                children: [
                  _buildInventoryMenuCard(
                    title: "Daftar Barang",
                    subtitle: "Master data & stok",
                    icon: Icons.inventory_2_outlined,
                    color: primaryGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const StockCheckPage(),
                        ),
                      );
                    },
                  ),
                  _buildInventoryMenuCard(
                    title: "Barang Masuk",
                    subtitle: "Restock / Supplier",
                    icon: Icons.move_to_inbox_outlined,
                    color: const Color(0xFF1976D2), // Biru
                    onTap: _showStockInDialog,
                  ),
                  _buildInventoryMenuCard(
                    title: "Barang Keluar",
                    subtitle: "Pengeluaran stok",
                    icon: Icons.outbox_outlined,
                    color: const Color(0xFFE65100), // Oranye
                    onTap: _showStockOutDialog,
                  ),
                  _buildInventoryMenuCard(
                    title: "Opname Stok",
                    subtitle: "Audit fisik barang",
                    icon: Icons.fact_check_outlined,
                    color: const Color(0xFF7B1FA2), // Ungu
                    onTap: _showStockOpnameDialog,
                  ),
                  _buildInventoryMenuCard(
                    title: "Kategori Barang",
                    subtitle: "Kelola kelompok item",
                    icon: Icons.category_outlined,
                    color: const Color(0xFF00796B), // Teal
                    onTap: _showCategoryOverviewSheet,
                  ),
                  _buildInventoryMenuCard(
                    title: "Laporan Stok",
                    subtitle: "Rekapitulasi inventaris",
                    icon: Icons.assessment_outlined,
                    color: const Color(0xFFC2185B), // Pink Tua
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const SalesReportPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // --- 3. Peringatan Stok Rendah (Urgent Alert Section) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Peringatan Stok Menipis",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
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
                    child: Text("Lihat Semua", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Card Item Peringatan Stok
              _buildLowStockItem(
                itemName: "Pipa PVC 2 Inci (10m)",
                category: "Bahan Bangunan",
                remainingStock: "2 Batang",
                minStock: "10 Batang",
              ),
              const SizedBox(height: 10),
              _buildLowStockItem(
                itemName: "Semen Portland 50kg",
                category: "Material Dasar",
                remainingStock: "5 Sak",
                minStock: "20 Sak",
              ),
              const SizedBox(height: 10),
              _buildLowStockItem(
                itemName: "Cat Tembok Vinilex 5kg",
                category: "Cat & Pelapis",
                remainingStock: "4 Kaleng",
                minStock: "12 Kaleng",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Modal Dialog: Restock / Barang Masuk ---
  void _showStockInDialog() {
    final TextEditingController qtyController = TextEditingController();
    final TextEditingController supplierController = TextEditingController();
    String selectedItem = 'Semen Portland 50kg';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.move_to_inbox_outlined, color: const Color(0xFF1976D2)),
              const SizedBox(width: 10),
              const Text("Penerimaan Barang Masuk", style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Pilih Barang", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedItem,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Semen Portland 50kg', child: Text('Semen Portland 50kg')),
                    DropdownMenuItem(value: 'Pipa PVC 2 Inci (10m)', child: Text('Pipa PVC 2 Inci (10m)')),
                    DropdownMenuItem(value: 'Cat Tembok Vinilex 5kg', child: Text('Cat Tembok Vinilex 5kg')),
                    DropdownMenuItem(value: 'Paku Kayu 5cm (1kg)', child: Text('Paku Kayu 5cm (1kg)')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedItem = val;
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Jumlah Masuk (Unit)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: supplierController,
                  decoration: InputDecoration(
                    labelText: "Nama Supplier / Vendor",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final qty = qtyController.text.isEmpty ? "10" : qtyController.text;
                _showSnackBar("Berhasil menambahkan $qty unit $selectedItem ke stok gudang!");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("SIMPAN STOK"),
            ),
          ],
        );
      },
    );
  }

  // --- Modal Dialog: Barang Keluar ---
  void _showStockOutDialog() {
    final TextEditingController qtyController = TextEditingController();
    String selectedReason = 'Pengeluaran Penjualan';
    String selectedItem = 'Semen Portland 50kg';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.outbox_outlined, color: const Color(0xFFE65100)),
              const SizedBox(width: 10),
              const Text("Pengeluaran Barang", style: TextStyle(fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Pilih Barang", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedItem,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Semen Portland 50kg', child: Text('Semen Portland 50kg')),
                    DropdownMenuItem(value: 'Pipa PVC 2 Inci (10m)', child: Text('Pipa PVC 2 Inci (10m)')),
                    DropdownMenuItem(value: 'Cat Tembok Vinilex 5kg', child: Text('Cat Tembok Vinilex 5kg')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedItem = val;
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Jumlah Keluar (Unit)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  decoration: InputDecoration(
                    labelText: "Alasan Pengeluaran",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Pengeluaran Penjualan', child: Text('Pengeluaran Penjualan')),
                    DropdownMenuItem(value: 'Barang Rusak / Cacat', child: Text('Barang Rusak / Cacat')),
                    DropdownMenuItem(value: 'Transfer Antar Gudang', child: Text('Transfer Antar Gudang')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedReason = val;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final qty = qtyController.text.isEmpty ? "5" : qtyController.text;
                _showSnackBar("Pengeluaran $qty unit $selectedItem berhasil dicatat.");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("PROSES KELUAR"),
            ),
          ],
        );
      },
    );
  }

  // --- Modal Dialog: Opname Stok ---
  void _showStockOpnameDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.fact_check_outlined, color: const Color(0xFF7B1FA2)),
              const SizedBox(width: 10),
              const Text("Audit Opname Stok", style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Audit Opname Stok Fisik",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                "Gunakan fitur ini untuk menyinkronkan jumlah fisik barang di gudang dengan catatan sistem secara real-time.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF7B1FA2)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Audit Terakhir: Kemarin, 17:00 WIB (Sesuai)",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const StockCheckPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("MULAI AUDIT"),
            ),
          ],
        );
      },
    );
  }

  // --- Bottom Sheet: Overview Kategori ---
  void _showCategoryOverviewSheet() {
    showModalBottomSheet<void>(
      context: context,
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
              const Text(
                "Kategori Barang Inventaris",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text("Kelompok item dan distribusi SKU di gudang", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(height: 24),

              _buildCategoryRow("Bahan Bangunan", "480 SKU", "Rp 245.000.000", primaryGreen),
              _buildCategoryRow("Cat & Pelapis", "320 SKU", "Rp 112.000.000", const Color(0xFF1976D2)),
              _buildCategoryRow("Pipa & Sanitari", "260 SKU", "Rp 85.000.000", const Color(0xFFE65100)),
              _buildCategoryRow("Perkakas & Hardware", "180 SKU", "Rp 42.000.000", const Color(0xFF7B1FA2)),

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

  Widget _buildCategoryRow(String name, String skuCount, String totalVal, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.category, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(skuCount, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            totalVal,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget: Metric Ringkasan ---
  Widget _buildStatMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // --- Helper Widget: Kartu Box Menu ---
  Widget _buildInventoryMenuCard({
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

  // --- Helper Widget: Card Warning Stok Menipis ---
  Widget _buildLowStockItem({
    required String itemName,
    required String category,
    required String remainingStock,
    required String minStock,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  category,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                remainingStock,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              Text(
                "Min: $minStock",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
