import 'package:dobrak_mandiri_app/services/stock_service.dart';
import 'package:flutter/material.dart';

class StockItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final int minStock;
  final String location;
  final String unit;
  final IconData icon;

  const StockItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.minStock,
    required this.location,
    this.unit = 'Unit',
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

  // State API
  bool _isLoading = true;
  String? _errorMessage;
  List<StockItem> _stockList = [];

  // Fallback Data jika server offline
  final List<StockItem> _fallbackProducts = const [
    StockItem(
      id: 'SKU-1001',
      name: 'Semen Portland 50kg',
      category: 'Bahan Bangunan',
      price: 68000,
      stock: 120,
      minStock: 20,
      location: 'Gudang A - Rak 01',
      unit: 'Sak',
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
      unit: 'Batang',
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
      unit: 'Kaleng',
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
      unit: 'Kg',
      icon: Icons.hardware,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchStockDataFromApi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Panggil HTTP GET http://172.20.10.2:8080/api/v1/stok dengan Bearer Token
  Future<void> _fetchStockDataFromApi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await StockService.fetchStockList();

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      final List<StockItem> parsedItems = [];

      for (var rawJson in result.data!) {
        if (rawJson is Map<String, dynamic>) {
          parsedItems.add(_parseStockItem(rawJson));
        }
      }

      setState(() {
        _stockList = parsedItems.isEmpty ? List.from(_fallbackProducts) : parsedItems;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result.message;
        _stockList = List.from(_fallbackProducts); // gunakan fallback agar UI tidak kosong
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengambil stok API: ${result.message}"),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Parser fleksibel JSON dari REST API /api/v1/stok
  StockItem _parseStockItem(Map<String, dynamic> json) {
    // 1. Kode SKU diambil dari field "kode_sku"
    final String id = json['kode_sku']?.toString() ??
        json['sku']?.toString() ??
        json['kode']?.toString() ??
        json['kode_barang']?.toString() ??
        json['id']?.toString() ??
        'SKU-00';

    // 2. Nama Barang diambil dari field "nama_produk"
    final String name = json['nama_produk']?.toString() ??
        json['nama']?.toString() ??
        json['nama_barang']?.toString() ??
        json['name']?.toString() ??
        'Barang Tanpa Nama';

    final String category = json['kategori']?.toString() ??
        json['kategori_nama']?.toString() ??
        json['category']?.toString() ??
        json['kategori_label']?.toString() ??
        'Bahan Bangunan';

    final double price = (json['harga'] as num?)?.toDouble() ??
        (json['harga_jual'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0.0;

    // 3. Unit / Jumlah Kuantitas diambil dari field "kuantitas"
    final int stock = (json['kuantitas'] as num?)?.toInt() ??
        (json['stok'] as num?)?.toInt() ??
        (json['jumlah'] as num?)?.toInt() ??
        (json['stock'] as num?)?.toInt() ??
        0;

    final int minStock = (json['stok_minimum'] as num?)?.toInt() ??
        (json['min_stok'] as num?)?.toInt() ??
        (json['min_stock'] as num?)?.toInt() ??
        10;

    final String location = json['lokasi']?.toString() ??
        json['lokasi_gudang']?.toString() ??
        json['gudang']?.toString() ??
        json['location']?.toString() ??
        'Gudang Utama';

    final String unit = json['satuan']?.toString() ??
        json['unit']?.toString() ??
        'Unit';

    return StockItem(
      id: id,
      name: name,
      category: category,
      price: price,
      stock: stock,
      minStock: minStock,
      location: location,
      unit: unit,
      icon: _getIconForCategory(category),
    );
  }

  IconData _getIconForCategory(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('pipa') || lower.contains('sanitari')) {
      return Icons.plumbing;
    } else if (lower.contains('cat') || lower.contains('pelapis')) {
      return Icons.format_paint;
    } else if (lower.contains('perkakas') || lower.contains('alat')) {
      return Icons.hardware;
    }
    return Icons.inventory_2;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Muat Ulang Data Stok",
            onPressed: _fetchStockDataFromApi,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchStockDataFromApi,
          color: primaryGreen,
          child: Column(
            children: [
              // Banner Error jika API gagal
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
                          "Menggunakan data offline. API: $_errorMessage",
                          style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                        ),
                      ),
                      TextButton(
                        onPressed: _fetchStockDataFromApi,
                        child: const Text("Coba Lagi", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

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
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: primaryGreen),
                            const SizedBox(height: 14),
                            const Text("Memuat data stok dari API...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      )
                    : _filteredStock.isEmpty
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
                                              "${item.stock} ${item.unit}",
                                              style: TextStyle(
                                                fontSize: 15,
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
              _buildDetailRow("Jumlah Kuantitas", "${item.stock} ${item.unit}"),
              _buildDetailRow("Batas Stok Minimum", "${item.minStock} ${item.unit}"),
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
