import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/data/models/product.dart';
import 'package:dobrak_mandiri_app/features/inventory/presentation/widgets/product_form_dialog.dart';
import 'package:dobrak_mandiri_app/features/inventory/presentation/widgets/stock_adjustment_dialog.dart';
import 'package:flutter/material.dart';

/// Bottom sheet detail produk gudang beserta aksi restock, pengeluaran, & edit.
class ProductDetailSheet extends StatelessWidget {
  const ProductDetailSheet({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  Widget build(BuildContext context) {
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
                  color: AppTheme.lightGreenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  product.categoryIcon,
                  color: AppTheme.primaryGreen,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Kode SKU: ${product.sku}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _InfoRow('Kategori Barang', product.category),
          _InfoRow(
            'Harga Jual Satuan',
            '${CurrencyFormatter.formatRupiah(product.price)} / ${product.unit}',
          ),
          _InfoRow('Kuantitas Stok', '${product.stock} ${product.unit}'),
          _InfoRow('Batas Stok Minimum', '${product.minStock} ${product.unit}'),
          _InfoRow('Lokasi Penyimpanan', product.location),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog<void>(
                      context: context,
                      builder: (_) => StockAdjustmentDialog(
                        isStockIn: true,
                        initialProduct: product,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_box_outlined, size: 18),
                  label: const Text('Restock'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog<void>(
                      context: context,
                      builder: (_) => StockAdjustmentDialog(
                        isStockIn: false,
                        initialProduct: product,
                      ),
                    );
                  },
                  icon: const Icon(Icons.outbox_outlined, size: 18),
                  label: const Text('Keluar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningOrange,
                    side: const BorderSide(color: AppTheme.warningOrange),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showDialog<void>(
                  context: context,
                  builder: (_) => ProductFormDialog(existingProduct: product),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Data Produk & Harga'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
