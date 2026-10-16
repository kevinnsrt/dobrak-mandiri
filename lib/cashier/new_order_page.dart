import 'package:flutter/material.dart';

// Model Data Produk
class ProductItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final IconData icon;

  const ProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.icon,
  });
}

// Model Item Keranjang Pesanan
class CartItem {
  final ProductItem product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}

class NewOrderPage extends StatefulWidget {
  const NewOrderPage({super.key});

  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage> {
  // Warna Utama Tema PT Dobrak Mandiri
  final Color primaryGreen = const Color(0xFF2E7D32);
  final Color lightGreenBg = const Color(0xFFE8F5E9);

  // Controller & State Pencarian
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  // Master Data Produk Inventaris Gudang PT Dobrak Mandiri
  final List<ProductItem> _allProducts = const [
    ProductItem(
      id: 'P001',
      name: 'Semen Portland 50kg',
      category: 'Bahan Bangunan',
      price: 68000,
      stock: 120,
      icon: Icons.inventory_2,
    ),
    ProductItem(
      id: 'P002',
      name: 'Pipa PVC 2 Inci (10m)',
      category: 'Pipa & Sanitari',
      price: 45000,
      stock: 40,
      icon: Icons.plumbing,
    ),
    ProductItem(
      id: 'P003',
      name: 'Cat Tembok Vinilex 5kg',
      category: 'Cat & Pelapis',
      price: 135000,
      stock: 25,
      icon: Icons.format_paint,
    ),
    ProductItem(
      id: 'P004',
      name: 'Paku Kayu 5cm (1kg)',
      category: 'Perkakas',
      price: 22000,
      stock: 80,
      icon: Icons.hardware,
    ),
    ProductItem(
      id: 'P005',
      name: 'Seng Gelombang 1.8m',
      category: 'Bahan Bangunan',
      price: 75000,
      stock: 60,
      icon: Icons.roofing,
    ),
    ProductItem(
      id: 'P006',
      name: 'Kuas Cat 3 Inci',
      category: 'Cat & Pelapis',
      price: 12500,
      stock: 150,
      icon: Icons.brush,
    ),
    ProductItem(
      id: 'P007',
      name: 'Kran Air Stainless 1/2 Inci',
      category: 'Pipa & Sanitari',
      price: 38000,
      stock: 35,
      icon: Icons.water_drop,
    ),
    ProductItem(
      id: 'P008',
      name: 'Batu Bata Merah (100 pcs)',
      category: 'Bahan Bangunan',
      price: 90000,
      stock: 500,
      icon: Icons.foundation,
    ),
  ];

  // Map untuk menyimpan item keranjang (Key: product.id)
  final Map<String, CartItem> _cart = {};

  // PPN 11% (Opsional toggle)
  bool _includePPN = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Kalkulasi Real-time ---
  double get _subtotal {
    double total = 0;
    for (var item in _cart.values) {
      total += item.totalPrice;
    }
    return total;
  }

  double get _ppnAmount => _includePPN ? _subtotal * 0.11 : 0;
  double get _grandTotal => _subtotal + _ppnAmount;
  int get _totalItemCount {
    int count = 0;
    for (var item in _cart.values) {
      count += item.quantity;
    }
    return count;
  }

  // Helper Format Mata Uang Rupiah
  String _formatRupiah(double amount) {
    String str = amount.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $result';
  }

  // Tambah/Kurang/Hapus Barang
  void _addItem(ProductItem product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        if (_cart[product.id]!.quantity < product.stock) {
          _cart[product.id]!.quantity++;
        } else {
          _showSnackBar('Stok maksimal (${product.stock}) telah dicapai!');
        }
      } else {
        _cart[product.id] = CartItem(product: product, quantity: 1);
      }
    });
  }

  void _decreaseItem(String productId) {
    setState(() {
      if (_cart.containsKey(productId)) {
        if (_cart[productId]!.quantity > 1) {
          _cart[productId]!.quantity--;
        } else {
          _cart.remove(productId);
        }
      }
    });
  }

  void _removeItem(String productId) {
    setState(() {
      _cart.remove(productId);
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black87,
      ),
    );
  }

  // Daftar Kategori Unik
  List<String> get _categories {
    List<String> list = ['Semua'];
    for (var p in _allProducts) {
      if (!list.contains(p.category)) {
        list.add(p.category);
      }
    }
    return list;
  }

  // Filter Produk berdasarkan Pencarian dan Kategori
  List<ProductItem> get _filteredProducts {
    return _allProducts.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || product.category == _selectedCategory;
      return matchesSearch && matchesCategory;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pesanan Baru",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "No. Transaksi: TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: "Kosongkan Keranjang",
              onPressed: () {
                _showConfirmDialog(
                  title: "Kosongkan Pesanan?",
                  content: "Semua barang yang dipilih akan dihapus dari keranjang.",
                  onConfirm: _clearCart,
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Bar Pencarian & Filter Kategori ---
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Column(
                children: [
                  // Search Input
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
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

                  // Category Chips (Horizontal Scroll)
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;
                        return ChoiceChip(
                          label: Text(
                            category,
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
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? primaryGreen : Colors.grey.shade300,
                            ),
                          ),
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. Daftar Barang (List View) ---
            Expanded(
              child: _filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            "Barang tidak ditemukan",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Coba ubah kata kunci pencarian atau kategori",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final cartItem = _cart[product.id];
                        final qty = cartItem?.quantity ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: qty > 0 ? primaryGreen.withValues(alpha: 0.5) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Icon Barang / Thumbnail
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: lightGreenBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(product.icon, color: primaryGreen, size: 28),
                                ),
                                const SizedBox(width: 14),

                                // Informasi Barang
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "SKU: ${product.id} • Stok: ${product.stock}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatRupiah(product.price),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Kontrol Jumlah Barang (+ / -)
                                if (qty == 0)
                                  ElevatedButton.icon(
                                    onPressed: () => _addItem(product),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text("Pilih", style: TextStyle(fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    decoration: BoxDecoration(
                                      color: lightGreenBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: primaryGreen.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 18),
                                          color: primaryGreen,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _decreaseItem(product.id),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text(
                                            '$qty',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: primaryGreen,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 18),
                                          color: primaryGreen,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _addItem(product),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // --- 3. Floating Ringkasan Pesanan & Total Real-time ---
            if (_cart.isNotEmpty) _buildBottomOrderSummary(),
          ],
        ),
      ),
    );
  }

  // --- Bottom Sheet Ringkasan Pesanan & Real-time Total ---
  Widget _buildBottomOrderSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Summary Ringkas
          InkWell(
            onTap: _showOrderDetailsBottomSheet,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Badge(
                      label: Text('$_totalItemCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: primaryGreen,
                      child: const Icon(Icons.shopping_bag_outlined, color: Colors.black87),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Pesanan ($_totalItemCount Item)",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          _formatRupiah(_grandTotal),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Detail",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_up, color: primaryGreen),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tombol Proses Pembayaran
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _showPaymentDialog,
              icon: const Icon(Icons.payments_outlined),
              label: Text(
                "PROSES BAYAR (${_formatRupiah(_grandTotal)})",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Modal Bottom Sheet: Rincian Lengkap Barang & Penjumlahan ---
  void _showOrderDetailsBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
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

                    // Title Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Rincian Keranjang",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _clearCart();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          label: const Text(
                            "Hapus Semua",
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),

                    // List Items in Cart
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cart.length,
                        itemBuilder: (context, index) {
                          final cartItem = _cart.values.elementAt(index);
                          final p = cartItem.product;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: lightGreenBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(p.icon, color: primaryGreen, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "${_formatRupiah(p.price)} x ${cartItem.quantity}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatRupiah(cartItem.totalPrice),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Controls & Hapus Individual
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      color: Colors.grey.shade700,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      onPressed: () {
                                        _decreaseItem(p.id);
                                        setModalState(() {});
                                        setState(() {});
                                        if (_cart.isEmpty) Navigator.pop(context);
                                      },
                                    ),
                                    Text(
                                      '${cartItem.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      color: primaryGreen,
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      onPressed: () {
                                        _addItem(p);
                                        setModalState(() {});
                                        setState(() {});
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      tooltip: "Hapus Item",
                                      onPressed: () {
                                        _removeItem(p.id);
                                        setModalState(() {});
                                        setState(() {});
                                        if (_cart.isEmpty) Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const Divider(),

                    // Ringkasan Penjumlahan Lengkap
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Subtotal Barang", style: TextStyle(color: Colors.grey)),
                            Text(_formatRupiah(_subtotal), style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text("PPN (11%)", style: TextStyle(color: Colors.grey)),
                                Checkbox(
                                  value: _includePPN,
                                  activeColor: primaryGreen,
                                  visualDensity: VisualDensity.compact,
                                  onChanged: (val) {
                                    setState(() {
                                      _includePPN = val ?? true;
                                    });
                                    setModalState(() {});
                                  },
                                ),
                              ],
                            ),
                            Text(_formatRupiah(_ppnAmount), style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
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
                              const Text(
                                "Total Pembayaran",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                _formatRupiah(_grandTotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tombol Bayar dari BottomSheet
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showPaymentDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("BAYAR SEKARANG", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Dialog Pembayaran (Metode Pembayaran & Kembalian) ---
  void _showPaymentDialog() {
    final TextEditingController cashController = TextEditingController();
    String selectedMethod = 'Tunai';
    double cashPaid = 0;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final change = cashPaid >= _grandTotal ? cashPaid - _grandTotal : 0.0;
            final isCashSufficient = selectedMethod != 'Tunai' || cashPaid >= _grandTotal;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.receipt_long, color: primaryGreen),
                  const SizedBox(width: 10),
                  const Text("Selesaikan Transaksi", style: TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Total
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: lightGreenBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text("Total Tagihan", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _formatRupiah(_grandTotal),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pilih Metode Pembayaran
                    const Text(
                      "Metode Pembayaran",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Tunai', 'QRIS', 'Transfer'].map((method) {
                        final isSelected = selectedMethod == method;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedMethod = method;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryGreen : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? primaryGreen : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                method,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Input Uang Tunai (Jika metode 'Tunai')
                    if (selectedMethod == 'Tunai') ...[
                      TextField(
                        controller: cashController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Uang Dibayar (Rp)",
                          prefixIcon: const Icon(Icons.money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            cashPaid = double.tryParse(val.replaceAll('.', '')) ?? 0;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Kembalian
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Uang Kembalian:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                          Text(
                            _formatRupiah(change),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: cashPaid >= _grandTotal ? primaryGreen : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isCashSufficient
                      ? () {
                          Navigator.pop(context);
                          _showSuccessReceiptDialog(_grandTotal, selectedMethod, change);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("KONFIRMASI"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Dialog Sukses Transaksi & Struk ---
  void _showSuccessReceiptDialog(double total, String method, double change) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightGreenBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: primaryGreen, size: 56),
              ),
              const SizedBox(height: 16),
              const Text(
                "Pembayaran Berhasil!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                "PT DOBRAK MANDIRI",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const Divider(height: 24),

              // Rincian Struk
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Metode Bayar", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(method, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Bayar", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(_formatRupiah(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryGreen)),
                ],
              ),
              if (method == 'Tunai') ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Kembalian", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(_formatRupiah(change), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showSnackBar("Struk berhasil dicetak!");
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text("Cetak", style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryGreen,
                        side: BorderSide(color: primaryGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearCart();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Selesai", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Ya, Hapus"),
            ),
          ],
        );
      },
    );
  }
}
