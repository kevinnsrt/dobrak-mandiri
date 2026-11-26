import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/data/models/product.dart';
import 'package:dobrak_mandiri_app/providers/inventory_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dialog penyesuaian stok real-time (Barang Masuk / Restock atau Barang Keluar).
class StockAdjustmentDialog extends StatefulWidget {
  const StockAdjustmentDialog({
    super.key,
    required this.isStockIn,
    this.initialProduct,
  });

  final bool isStockIn;
  final Product? initialProduct;

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _qtyController = TextEditingController();
  int? _selectedProductId;
  String _selectedReason = AppConstants.stockOutReasons.first;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final products = context.read<InventoryProvider>().products;
    _selectedProductId =
        widget.initialProduct?.id ?? (products.isNotEmpty ? products.first.id : null);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _submit(InventoryProvider inventory) async {
    if (_selectedProductId == null) return;
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      setState(() => _errorText = 'Jumlah harus lebih dari 0.');
      return;
    }

    final delta = widget.isStockIn ? qty : -qty;
    final result = await inventory.adjustStock(
      productId: _selectedProductId!,
      delta: delta,
      reason: widget.isStockIn ? 'Barang Masuk / Restock' : _selectedReason,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isStockIn
                ? 'Stok masuk +$qty berhasil disimpan.'
                : 'Pengeluaran stok -$qty ($_selectedReason) berhasil dicatat.',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else {
      setState(() => _errorText = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final products = inventory.products;

    if (products.isEmpty) {
      return AlertDialog(
        title: Text(widget.isStockIn ? 'Barang Masuk' : 'Barang Keluar'),
        content: const Text('Belum ada produk terdaftar di gudang.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      );
    }

    final selectedProduct = products.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse: () => products.first,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            widget.isStockIn ? Icons.add_box_outlined : Icons.outbox_outlined,
            color: widget.isStockIn
                ? AppTheme.infoBlue
                : AppTheme.warningOrange,
          ),
          const SizedBox(width: 10),
          Text(
            widget.isStockIn ? 'Barang Masuk (Restock)' : 'Barang Keluar',
            style: const TextStyle(fontSize: 17),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedProduct.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Pilih Barang'),
                items: products
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          '${p.name} (Stok: ${p.stock} ${p.unit})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: inventory.isMutating
                    ? null
                    : (val) {
                        setState(() {
                          _selectedProductId = val;
                          _errorText = null;
                        });
                      },
              ),
              const SizedBox(height: 10),
              Text(
                'Stok saat ini: ${selectedProduct.stock} ${selectedProduct.unit}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selectedProduct.isOutOfStock
                      ? Colors.red.shade700
                      : AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                enabled: !inventory.isMutating,
                decoration: InputDecoration(
                  labelText: widget.isStockIn
                      ? 'Jumlah Masuk (${selectedProduct.unit})'
                      : 'Jumlah Keluar (${selectedProduct.unit})',
                ),
                onChanged: (_) => setState(() => _errorText = null),
              ),
              if (!widget.isStockIn) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Alasan Pengeluaran'),
                  items: AppConstants.stockOutReasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: inventory.isMutating
                      ? null
                      : (v) {
                          if (v != null) setState(() => _selectedReason = v);
                        },
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: inventory.isMutating ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: inventory.isMutating ? null : () => _submit(inventory),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isStockIn
                ? AppTheme.infoBlue
                : AppTheme.warningOrange,
          ),
          child: inventory.isMutating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(widget.isStockIn ? 'TAMBAH STOK' : 'PROSES KELUAR'),
        ),
      ],
    );
  }
}
