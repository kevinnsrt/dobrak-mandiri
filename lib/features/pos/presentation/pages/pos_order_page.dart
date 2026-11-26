import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/core/widgets/status_banner.dart';
import 'package:dobrak_mandiri_app/data/models/product.dart';
import 'package:dobrak_mandiri_app/features/pos/presentation/widgets/cart_summary_panel.dart';
import 'package:dobrak_mandiri_app/features/pos/presentation/widgets/item_discount_dialog.dart';
import 'package:dobrak_mandiri_app/features/pos/presentation/widgets/payment_checkout_dialog.dart';
import 'package:dobrak_mandiri_app/features/pos/presentation/widgets/product_catalog_card.dart';
import 'package:dobrak_mandiri_app/providers/inventory_provider.dart';
import 'package:dobrak_mandiri_app/providers/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Halaman Kasir / Point of Sale (POS) dengan responsivitas HP & Tablet serta stok real-time.
class PosOrderPage extends StatefulWidget {
  const PosOrderPage({super.key});

  @override
  State<PosOrderPage> createState() => _PosOrderPageState();
}

class _PosOrderPageState extends State<PosOrderPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inventory = context.read<InventoryProvider>();
      if (inventory.products.isEmpty) {
        inventory.loadProducts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _buildCategories(List<Product> products) {
    final set = <String>{'Semua'};
    for (final p in products) {
      set.add(p.category);
    }
    return set.toList();
  }

  List<Product> _filterProducts(List<Product> products) {
    final query = _searchQuery.toLowerCase().trim();
    return products.where((p) {
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
      final matchesCat =
          _selectedCategory == 'Semua' || p.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();
  }

  void _openCartSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: CartSummaryPanel(
          isBottomSheet: true,
          onProceedCheckout: () {
            Navigator.pop(sheetContext);
            _openPaymentDialog();
          },
        ),
      ),
    );
  }

  void _openPaymentDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PaymentCheckoutDialog(),
    );
  }

  void _handleAddProduct(Product product) {
    final err = context.read<PosProvider>().addItem(product);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final pos = context.watch<PosProvider>();
    final categories = _buildCategories(inventory.products);
    final filteredProducts = _filterProducts(inventory.products);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kasir & Pesanan Baru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Stok terhubung real-time dengan gudang',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang Stok',
            onPressed: () => inventory.loadProducts(),
          ),
          if (!pos.isCartEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Kosongkan Keranjang',
              onPressed: () => pos.clearCart(),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 820;

            final catalogColumn = Column(
              children: [
                if (inventory.isOfflineFallback && inventory.statusMessage != null)
                  StatusBanner(
                    message: inventory.statusMessage!,
                    isOfflineMode: true,
                    onRetry: () => inventory.loadProducts(),
                  ),
                Container(
                  padding: const EdgeInsets.all(14),
                  color: Colors.white,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Cari nama bahan bangunan atau kode SKU...',
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
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final selected = category == _selectedCategory;
                            return ChoiceChip(
                              label: Text(category),
                              selected: selected,
                              selectedColor: AppTheme.primaryGreen,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selected ? Colors.white : Colors.black87,
                              ),
                              showCheckmark: false,
                              onSelected: (_) {
                                setState(() => _selectedCategory = category);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: inventory.loadProducts,
                    child: inventory.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredProducts.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 56,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      'Barang tidak ditemukan',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(14),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  final cartItem =
                                      pos.cartItemForProduct(product.id);
                                  return ProductCatalogCard(
                                    product: product,
                                    cartItem: cartItem,
                                    onAdd: () => _handleAddProduct(product),
                                    onDecrease: () =>
                                        pos.decreaseItem(product.id),
                                    onEditQtyAndDiscount: () {
                                      if (cartItem != null) {
                                        showDialog<void>(
                                          context: context,
                                          builder: (_) => ItemDiscountDialog(
                                            cartItem: cartItem,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                  ),
                ),
                if (!isWide && !pos.isCartEmpty)
                  _MobileCartFooter(
                    totalItems: pos.totalItemCount,
                    grandTotal: pos.grandTotal,
                    totalDiscount:
                        pos.totalItemDiscount + pos.globalDiscountAmount,
                    onOpenDetails: _openCartSheet,
                    onCheckout: _openPaymentDialog,
                  ),
              ],
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(flex: 3, child: catalogColumn),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: 380,
                    child: CartSummaryPanel(
                      onProceedCheckout: _openPaymentDialog,
                    ),
                  ),
                ],
              );
            }

            return catalogColumn;
          },
        ),
      ),
    );
  }
}

class _MobileCartFooter extends StatelessWidget {
  const _MobileCartFooter({
    required this.totalItems,
    required this.grandTotal,
    required this.totalDiscount,
    required this.onOpenDetails,
    required this.onCheckout,
  });

  final int totalItems;
  final double grandTotal;
  final double totalDiscount;
  final VoidCallback onOpenDetails;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onOpenDetails,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Badge(
                      label: Text('$totalItems'),
                      backgroundColor: AppTheme.primaryGreen,
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total ($totalItems Item)'
                          '${totalDiscount > 0 ? ' • Hemat ${CurrencyFormatter.formatCompact(totalDiscount)}' : ''}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          CurrencyFormatter.formatRupiah(grandTotal),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      'Keranjang & Diskon',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_up, color: AppTheme.primaryGreen),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onCheckout,
              icon: const Icon(Icons.payments_outlined),
              label: Text(
                'PROSES BAYAR (${CurrencyFormatter.formatRupiah(grandTotal)})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
