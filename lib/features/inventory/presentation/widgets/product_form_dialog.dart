import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/data/models/product.dart';
import 'package:dobrak_mandiri_app/providers/inventory_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dialog form tambah atau edit produk inventaris PT. Dobrak Mandiri.
class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({
    super.key,
    this.existingProduct,
  });

  final Product? existingProduct;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuController;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _locationController;

  late String _selectedCategory;
  late String _selectedUnit;
  late List<String> _categoryOptions;
  late List<String> _unitOptions;

  bool get _isEditing => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProduct;
    final providerCategories = context.read<InventoryProvider>().categories;

    _categoryOptions = {
      ...AppConstants.defaultCategories,
      ...providerCategories,
      if (existing != null) existing.category,
    }.toList();

    _unitOptions = {
      ...AppConstants.defaultUnits,
      if (existing != null) existing.unit,
    }.toList();

    _selectedCategory = existing?.category ?? _categoryOptions.first;
    _selectedUnit = existing?.unit ?? _unitOptions.first;

    _skuController = TextEditingController(
      text: existing?.sku ??
          'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    );
    _nameController = TextEditingController(text: existing?.name ?? '');
    _priceController = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(0) : '',
    );
    _stockController = TextEditingController(
      text: existing != null ? '${existing.stock}' : '0',
    );
    _minStockController = TextEditingController(
      text: '${existing?.minStock ?? AppConstants.defaultMinStock}',
    );
    _locationController = TextEditingController(
      text: existing?.location ?? 'Gudang Utama',
    );
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<InventoryProvider>();
    final product = Product(
      id: widget.existingProduct?.id ?? 0,
      sku: _skuController.text.trim(),
      name: _nameController.text.trim(),
      category: _selectedCategory,
      price: double.parse(_priceController.text.replaceAll('.', '').trim()),
      stock: int.parse(_stockController.text.trim()),
      minStock: int.parse(_minStockController.text.trim()),
      location: _locationController.text.trim().isEmpty
          ? 'Gudang Utama'
          : _locationController.text.trim(),
      unit: _selectedUnit,
    );

    final result = _isEditing
        ? await provider.updateProduct(product)
        : await provider.addProduct(product);

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMutating = context.watch<InventoryProvider>().isMutating;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_isEditing ? 'Edit Data Produk' : 'Tambah Barang Baru'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _skuController,
                  enabled: !isMutating,
                  decoration: const InputDecoration(labelText: 'Kode SKU'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'SKU wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  enabled: !isMutating,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: _categoryOptions
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: isMutating
                      ? null
                      : (v) {
                          if (v != null) setState(() => _selectedCategory = v);
                        },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        enabled: !isMutating,
                        decoration:
                            const InputDecoration(labelText: 'Harga Jual (Rp)'),
                        validator: (v) {
                          final parsed = double.tryParse(
                            (v ?? '').replaceAll('.', '').trim(),
                          );
                          if (parsed == null || parsed < 0) {
                            return 'Harga tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(labelText: 'Satuan'),
                        items: _unitOptions
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: isMutating
                            ? null
                            : (v) {
                                if (v != null) setState(() => _selectedUnit = v);
                              },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        enabled: !isMutating,
                        decoration:
                            const InputDecoration(labelText: 'Stok Saat Ini'),
                        validator: (v) {
                          final parsed = int.tryParse((v ?? '').trim());
                          if (parsed == null || parsed < 0) {
                            return 'Stok >= 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _minStockController,
                        keyboardType: TextInputType.number,
                        enabled: !isMutating,
                        decoration:
                            const InputDecoration(labelText: 'Batas Minimum'),
                        validator: (v) {
                          final parsed = int.tryParse((v ?? '').trim());
                          if (parsed == null || parsed < 0) {
                            return 'Min >= 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  enabled: !isMutating,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi Rak / Gudang',
                    hintText: 'Contoh: Gudang A - Rak 01',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isMutating ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: isMutating ? null : _submit,
          child: isMutating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(_isEditing ? 'SIMPAN PERUBAHAN' : 'SIMPAN BARANG'),
        ),
      ],
    );
  }
}
