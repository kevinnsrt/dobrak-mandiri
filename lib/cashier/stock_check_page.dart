import 'package:flutter/material.dart';

class StockItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final int minStock;
  final String location;
  final IconData icon;

  const StockItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.minStock,
    required this.location,
    required this.icon,
  });

  bool get isLow => stock > 0 && stock <= minStock;
  bool get isOut => stock == 0;
}

class StockCheckPage extends StatefulWidget {
  const StockCheckPage({super.key});

  @override
  State<StockCheckPage> createState() => _StockCheckPageState();
}

class _StockCheckPageState extends State<StockCheckPage> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreenBg = const Color(0xFFE8F5E9);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String _selectedFilter = 'Semua Status';

  final List<StockItem> _stockList = const [
    StockItem(
      id: 'SKU-1001',
      name: 'Semen Portland 50kg',
      category: 'Bahan Bangunan',
      price: 68000,
      stock: 120,
      minStock: 20,
      location: 'Gudang A - Rak 01',
      icon: Icons.inventory_2,
    ),
    StockItem(
      id: 'SKU-1002',
      name: 'Pipa PVC 2 Inci (10m)',
      category: 'Pipa & Sanitari',
      price: 45000,
      stock: 8,
      minStock: 10,
      location: 'Gudang B - Rak 04',
      icon: Icons.plumbing,
    ),
    StockItem(
      id: 'SKU-1003',
      name: 'Cat Tembok Vinilex 5kg',
      category: 'Cat & Pelapis',
      price: 135000,
      stock: 25,
      minStock: 5,
      location: 'Gudang C - Rak 02',
      icon: Icons.format_paint,
    ),
    StockItem(
      id: 'SKU-1004',
      name: 'Paku Kayu 5cm (1kg)',
      category: 'Perkakas',
      price: 22000,
      stock: 0,
      minStock: 15,
      location: 'Gudang A - Rak 09',
      icon: Icons.hardware,
    ),
    StockItem(
      id: 'SKU-1005',
      name: 'Seng Gelombang 1.8m',
      category: 'Bahan Bangunan',
      price: 75000,
      stock: 60,
      minStock: 10,
      location: 'Gudang A - Rak 03',
      icon: Icons.roofing,
    ),
    StockItem(
      id: 'SKU-1006',
      name: 'Kuas Cat 3 Inci',
      category: 'Cat & Pelapis',
      price: 12500,
      stock: 4,
      minStock: 12,
      location: 'Gudang C - Rak 01',
      icon: Icons.brush,
    ),
    StockItem(
      id: 'SKU-1007',
      name: 'Kran Air Stainless 1/2 Inci',
      category: 'Pipa & Sanitari',
      price: 38000,
      stock: 35,
      minStock: 8,
      location: 'Gudang B - Rak 02',
      icon: Icons.water_drop,
    ),
    StockItem(
      id: 'SKU-1008',
      name: 'Batu Bata Merah (100 pcs)',
      category: 'Bahan Bangunan',
      price: 90000,
      stock: 500,
      minStock: 50,
      location: 'Area Terbuka - Blok D',
      icon: Icons.foundation,
    ),
    StockItem(
      id: 'SKU-1009',
      name: 'Keramik Polos 40x40 (1 dus)',
      category: 'Bahan Bangunan',
      price: 62000,
      stock: 0,
      minStock: 10,
      location: 'Gudang A - Rak 12',
      icon: Icons.grid_view,
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

  int get _totalSku => _stockList.length;
  int get _totalItemsCount => _stockList.fold(0, (sum, item) => sum + item.stock);
  int get _lowStockCount => _stockList.where((item) => item.isLow).length;
  int get _outOfStockCount => _stockList.where((item) => item.isOut).length;

  List<String> get _categories {
    List<String> list = ['Semua'];
    for (var item in _stockList) {
      if (!list.contains(item.category)) {
        list.add(item.category);
      }
    }
    return list;
  }

  List<StockItem> get _filteredStock {
    return _stockList.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || item.category == _selectedCategory;

      bool matchesStatus = true;
      if (_selectedFilter == 'Stok Menipis') {
        matchesStatus = item.isLow;
      } else if (_selectedFilter == 'Stok Habis') {
        matchesStatus = item.isOut;
      } else if (_selectedFilter == 'Stok Aman') {
        matchesStatus = !item.isLow && !item.isOut;
      }

      return matchesSearch && matchesCategory && matchesStatus;
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
          "Cek Stok Gudang",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Ringkasan Quick Stats ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  _buildStatBox("Total SKU", "$_totalSku", primaryGreen, lightGreenBg),
                  const SizedBox(width: 8),
                  _buildStatBox("Total Stok", "$_totalItemsCount", const Color(0xFF1976D2), const Color(0xFFE3F2FD)),
                  const SizedBox(width: 8),
                  _buildStatBox("Menipis", "$_lowStockCount", Colors.orange.shade800, Colors.orange.shade50),
                  const SizedBox(width: 8),
                  _buildStatBox("Habis", "$_outOfStockCount", Colors.red.shade700, Colors.red.shade50),
                ],
              ),
            ),

            // --- 2. Filter & Search ---
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  // Search Box
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari nama barang atau kode SKU...",
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

                  // Filter Chips
                  Row(
                    children: [
                      // Kategori Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              items: _categories.map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedCategory = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Status Dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFilter,
                              isExpanded: true,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              items: ['Semua Status', 'Stok Aman', 'Stok Menipis', 'Stok Habis'].map((status) {
                                return DropdownMenuItem(value: status, child: Text(status));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedFilter = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- 3. List Item Stok ---
            Expanded(
              child: _filteredStock.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            "Tidak ada barang ditemukan",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _filteredStock.length,
                      itemBuilder: (context, index) {
                        final item = _filteredStock[index];

                        Color badgeBg;
                        Color badgeTextColor;
                        String statusLabel;

                        if (item.isOut) {
                          badgeBg = Colors.red.shade50;
                          badgeTextColor = Colors.red.shade700;
                          statusLabel = 'Habis';
                        } else if (item.isLow) {
                          badgeBg = Colors.orange.shade50;
                          badgeTextColor = Colors.orange.shade800;
                          statusLabel = 'Menipis';
                        } else {
                          badgeBg = lightGreenBg;
                          badgeTextColor = primaryGreen;
                          statusLabel = 'Aman';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _showStockDetailSheet(item),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Row(
                                children: [
                                  // Icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: lightGreenBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(item.icon, color: primaryGreen, size: 26),
                                  ),
                                  const SizedBox(width: 14),

                                  // Detail Name & Category
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${item.id} • ${item.category}",
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                                            const SizedBox(width: 2),
                                            Text(
                                              item.location,
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Stock Quantity & Status Badge
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${item.stock} Unit",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: badgeTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: badgeTextColor,
                                          ),
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

  Widget _buildStatBox(String title, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockDetailSheet(StockItem item) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightGreenBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: primaryGreen, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Kode SKU: ${item.id}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              _buildDetailRow("Kategori Barang", item.category),
              _buildDetailRow("Harga Jual Satuan", _formatRupiah(item.price)),
              _buildDetailRow("Stok Saat Ini", "${item.stock} Unit"),
              _buildDetailRow("Batas Stok Minimum", "${item.minStock} Unit"),
              _buildDetailRow("Lokasi Penyimpanan", item.location),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
