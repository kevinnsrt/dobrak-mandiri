import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/features/dashboard/presentation/widgets/dashboard_menu_card.dart';
import 'package:dobrak_mandiri_app/features/dashboard/presentation/widgets/dashboard_profile_menu.dart';
import 'package:dobrak_mandiri_app/features/inventory/presentation/pages/inventory_list_page.dart';
import 'package:dobrak_mandiri_app/features/inventory/presentation/widgets/product_form_dialog.dart';
import 'package:dobrak_mandiri_app/features/inventory/presentation/widgets/stock_adjustment_dialog.dart';
import 'package:dobrak_mandiri_app/providers/inventory_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dashboard Pengelola Inventaris / Gudang PT. Dobrak Mandiri.
class InventoryDashboardPage extends StatefulWidget {
  const InventoryDashboardPage({super.key});

  @override
  State<InventoryDashboardPage> createState() => _InventoryDashboardPageState();
}

class _InventoryDashboardPageState extends State<InventoryDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadProducts();
    });
  }

  void _openStockInChooser() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pilih Jenis Barang Masuk',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                showDialog<void>(
                  context: context,
                  builder: (_) => const StockAdjustmentDialog(isStockIn: true),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Restock Barang yang Sudah Ada'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                showDialog<void>(
                  context: context,
                  builder: (_) => const ProductFormDialog(),
                );
              },
              icon: const Icon(Icons.new_label_outlined),
              label: const Text('Daftarkan Produk Baru'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryOverviewSheet(InventoryProvider inventory) {
    final Map<String, int> skuPerCategory = {};
    final Map<String, int> unitsPerCategory = {};
    for (final p in inventory.products) {
      skuPerCategory[p.category] = (skuPerCategory[p.category] ?? 0) + 1;
      unitsPerCategory[p.category] =
          (unitsPerCategory[p.category] ?? 0) + p.stock;
    }

    final categories = skuPerCategory.keys.toList()..sort();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distribusi Kategori Barang',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Ringkasan SKU & jumlah unit per kategori di gudang',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Divider(height: 22),
              Expanded(
                child: categories.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada data kategori produk.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: categories.length,
                        itemBuilder: (_, idx) {
                          final cat = categories[idx];
                          final skuCount = skuPerCategory[cat] ?? 0;
                          final unitCount = unitsPerCategory[cat] ?? 0;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.lightGreenBg,
                              child: Icon(
                                Icons.category,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            title: Text(
                              cat,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('$skuCount SKU terdaftar'),
                            trailing: Text(
                              '$unitCount Unit',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('TUTUP'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final alertProducts = inventory.products
        .where((p) => p.isLowStock || p.isOutOfStock)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.companyName,
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            Text(
              'Pengelola Inventaris',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat Ulang Stok',
            onPressed: () => inventory.loadProducts(),
          ),
          const DashboardProfileMenu(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: inventory.loadProducts,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                            decoration: const BoxDecoration(
                              color: AppTheme.lightGreenBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warehouse_outlined,
                              color: AppTheme.primaryGreen,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  AppConstants.storeAddress,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'Total SKU: ${inventory.totalSku} Item',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const InventoryListPage(
                                    initialStatusFilter: 'Stok Menipis',
                                  ),
                                ),
                              );
                            },
                            child: _MetricTile(
                              'Stok Menipis',
                              '${inventory.lowStockCount} Item',
                              AppTheme.warningOrange,
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const InventoryListPage(
                                    initialStatusFilter: 'Stok Habis',
                                  ),
                                ),
                              );
                            },
                            child: _MetricTile(
                              'Stok Habis',
                              '${inventory.outOfStockCount} Item',
                              Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Manajemen Stok & Gudang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  children: [
                    DashboardMenuCard(
                      title: 'Daftar Barang',
                      subtitle: 'Cari, edit & cek stok',
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.primaryGreen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const InventoryListPage(),
                          ),
                        );
                      },
                    ),
                    DashboardMenuCard(
                      title: 'Barang Masuk',
                      subtitle: 'Restock / item baru',
                      icon: Icons.add_box_outlined,
                      color: AppTheme.infoBlue,
                      onTap: _openStockInChooser,
                    ),
                    DashboardMenuCard(
                      title: 'Barang Keluar',
                      subtitle: 'Kurangi stok gudang',
                      icon: Icons.outbox_outlined,
                      color: AppTheme.warningOrange,
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          builder: (_) =>
                              const StockAdjustmentDialog(isStockIn: false),
                        );
                      },
                    ),
                    DashboardMenuCard(
                      title: 'Kategori Barang',
                      subtitle: 'Distribusi kategori',
                      icon: Icons.category_outlined,
                      color: AppTheme.tealAccent,
                      onTap: () => _showCategoryOverviewSheet(inventory),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Peringatan Stok Menipis & Habis',
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
                            builder: (_) => const InventoryListPage(
                              initialStatusFilter: 'Stok Menipis',
                            ),
                          ),
                        );
                      },
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                if (inventory.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (alertProducts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Semua stok barang dalam kondisi aman.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...alertProducts.take(6).map(
                        (item) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () {
                              showDialog<void>(
                                context: context,
                                builder: (_) => StockAdjustmentDialog(
                                  isStockIn: true,
                                  initialProduct: item,
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: item.isOutOfStock
                                  ? Colors.red.shade50
                                  : Colors.orange.shade50,
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: item.isOutOfStock
                                    ? Colors.red.shade700
                                    : AppTheme.warningOrange,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${item.category} • Min: ${item.minStock} ${item.unit}',
                            ),
                            trailing: Text(
                              '${item.stock} ${item.unit}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: item.isOutOfStock
                                    ? Colors.red.shade700
                                    : AppTheme.warningOrange,
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
