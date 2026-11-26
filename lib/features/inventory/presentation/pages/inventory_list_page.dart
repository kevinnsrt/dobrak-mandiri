import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/core/widgets/status_banner.dart';
import 'package:dobrak_mandiri_app/data/models/product.dart';
import 'package:dobrak_mandiri_app/features/inventory/presentation/widgets/product_detail_sheet.dart';
import 'package:dobrak_mandiri_app/features/inventory/presentation/widgets/product_form_dialog.dart';
import 'package:dobrak_mandiri_app/providers/inventory_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Halaman Manajemen & Pencarian Stok Terstruktur (Modul B).
class InventoryListPage extends StatefulWidget {
  const InventoryListPage({
    super.key,
    this.initialStatusFilter = 'Semua Status',
  });

  final String initialStatusFilter;

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  late String _selectedStatus;
  String _sortBy = 'Nama A-Z';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatusFilter;
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

  List<Product> _filterAndSort(List<Product> products) {
    final query = _searchQuery.toLowerCase().trim();
    final filtered = products.where((item) {
      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.sku.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'Semua' || item.category == _selectedCategory;

      final matchesStatus = switch (_selectedStatus) {
        'Stok Menipis' => item.isLowStock,
        'Stok Habis' => item.isOutOfStock,
        'Stok Aman' => item.isSafeStock,
        _ => true,
      };

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    switch (_sortBy) {
      case 'Stok Terendah':
        filtered.sort((a, b) => a.stock.compareTo(b.stock));
      case 'Stok Tertinggi':
        filtered.sort((a, b) => b.stock.compareTo(a.stock));
      case 'Harga Tertinggi':
        filtered.sort((a, b) => b.price.compareTo(a.price));
      default:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final categories = _buildCategories(inventory.products);
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'Semua';
    }
    final items = _filterAndSort(inventory.products);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manajemen Inventaris & Stok',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang Stok',
            onPressed: () => inventory.loadProducts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (_) => const ProductFormDialog(),
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Barang'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (inventory.isOfflineFallback && inventory.statusMessage != null)
              StatusBanner(
                message: inventory.statusMessage!,
                isOfflineMode: true,
                onRetry: () => inventory.loadProducts(),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              color: Colors.white,
              child: Row(
                children: [
                  _StatFilterBox(
                    title: 'Total SKU',
                    value: '${inventory.totalSku}',
                    color: AppTheme.primaryGreen,
                    bgColor: AppTheme.lightGreenBg,
                    isSelected: _selectedStatus == 'Semua Status',
                    onTap: () =>
                        setState(() => _selectedStatus = 'Semua Status'),
                  ),
                  const SizedBox(width: 8),
                  _StatFilterBox(
                    title: 'Total Unit',
                    value: '${inventory.totalUnits}',
                    color: AppTheme.infoBlue,
                    bgColor: const Color(0xFFE3F2FD),
                    isSelected: false,
                    onTap: () =>
                        setState(() => _selectedStatus = 'Semua Status'),
                  ),
                  const SizedBox(width: 8),
                  _StatFilterBox(
                    title: 'Menipis',
                    value: '${inventory.lowStockCount}',
                    color: AppTheme.warningOrange,
                    bgColor: Colors.orange.shade50,
                    isSelected: _selectedStatus == 'Stok Menipis',
                    onTap: () =>
                        setState(() => _selectedStatus = 'Stok Menipis'),
                  ),
                  const SizedBox(width: 8),
                  _StatFilterBox(
                    title: 'Habis',
                    value: '${inventory.outOfStockCount}',
                    color: Colors.red.shade700,
                    bgColor: Colors.red.shade50,
                    isSelected: _selectedStatus == 'Stok Habis',
                    onTap: () =>
                        setState(() => _selectedStatus = 'Stok Habis'),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari nama barang, SKU, atau lokasi...',
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
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Kategori',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: categories
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedCategory = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStatus,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: const [
                            'Semua Status',
                            'Stok Aman',
                            'Stok Menipis',
                            'Stok Habis',
                          ]
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedStatus = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _sortBy,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Urutkan',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: const [
                            'Nama A-Z',
                            'Stok Terendah',
                            'Stok Tertinggi',
                            'Harga Tertinggi',
                          ]
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _sortBy = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: inventory.loadProducts,
                child: inventory.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Icon(Icons.inventory, size: 56, color: Colors.grey),
                              SizedBox(height: 10),
                              Center(
                                child: Text(
                                  'Tidak ada barang sesuai filter',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 84),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final Color badgeBg;
                              final Color badgeFg;
                              if (item.isOutOfStock) {
                                badgeBg = Colors.red.shade50;
                                badgeFg = Colors.red.shade700;
                              } else if (item.isLowStock) {
                                badgeBg = Colors.orange.shade50;
                                badgeFg = AppTheme.warningOrange;
                              } else {
                                badgeBg = AppTheme.lightGreenBg;
                                badgeFg = AppTheme.primaryGreen;
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24),
                                        ),
                                      ),
                                      builder: (_) =>
                                          ProductDetailSheet(product: item),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppTheme.lightGreenBg,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            item.categoryIcon,
                                            color: AppTheme.primaryGreen,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${item.sku} • ${item.category} • ${CurrencyFormatter.formatRupiah(item.price)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on_outlined,
                                                    size: 13,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    item.location,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${item.stock} ${item.unit}',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: badgeFg,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: badgeBg,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                item.stockStatusLabel,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: badgeFg,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _StatFilterBox extends StatelessWidget {
  const _StatFilterBox({
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String value;
  final Color color;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
