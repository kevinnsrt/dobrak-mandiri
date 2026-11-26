import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/data/models/cart_item.dart';
import 'package:dobrak_mandiri_app/providers/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dialog untuk input kuantitas cepat (pembelian banyak) dan diskon per item.
class ItemDiscountDialog extends StatefulWidget {
  const ItemDiscountDialog({
    super.key,
    required this.cartItem,
  });

  final CartItem cartItem;

  @override
  State<ItemDiscountDialog> createState() => _ItemDiscountDialogState();
}

class _ItemDiscountDialogState extends State<ItemDiscountDialog> {
  late final TextEditingController _qtyController;
  late final TextEditingController _discountController;
  late DiscountType _discountType;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '${widget.cartItem.quantity}');
    _discountType = widget.cartItem.discountType;
    _discountController = TextEditingController(
      text: widget.cartItem.discountValue > 0
          ? widget.cartItem.discountValue.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  int get _parsedQty => int.tryParse(_qtyController.text.trim()) ?? 0;

  double get _parsedDiscount =>
      double.tryParse(_discountController.text.replaceAll('.', '').trim()) ?? 0;

  double get _previewGross => widget.cartItem.product.price * (_parsedQty > 0 ? _parsedQty : 0);

  double get _previewDiscountAmount {
    if (_parsedDiscount <= 0 || _previewGross <= 0) return 0;
    if (_discountType == DiscountType.percent) {
      return _previewGross * (_parsedDiscount.clamp(0, 100) / 100);
    }
    return _parsedDiscount.clamp(0, _previewGross);
  }

  double get _previewNet => (_previewGross - _previewDiscountAmount).clamp(0, double.infinity);

  void _save() {
    final posProvider = context.read<PosProvider>();
    final product = widget.cartItem.product;
    final qty = _parsedQty;

    if (qty <= 0) {
      posProvider.removeItem(product.id);
      Navigator.pop(context);
      return;
    }

    final qtyError = posProvider.setItemQuantity(product, qty);
    if (qtyError != null) {
      setState(() {
        _errorText = qtyError;
      });
      return;
    }

    if (_discountType == DiscountType.percent && _parsedDiscount > 100) {
      setState(() {
        _errorText = 'Persentase diskon tidak boleh melebihi 100%.';
      });
      return;
    }

    posProvider.setItemDiscount(
      productId: product.id,
      type: _discountType,
      value: _parsedDiscount,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.cartItem.product;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        product.name,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Harga: ${CurrencyFormatter.formatRupiah(product.price)} / ${product.unit}\nStok tersedia: ${product.stock} ${product.unit}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kuantitas (${product.unit})',
                hintText: 'Masukkan jumlah barang',
                helperText: 'Ketik 0 untuk menghapus item dari keranjang',
              ),
              onChanged: (_) => setState(() => _errorText = null),
            ),
            const SizedBox(height: 16),
            const Text(
              'Diskon Per Item (Opsional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<DiscountType>(
              segments: const [
                ButtonSegment(
                  value: DiscountType.nominal,
                  label: Text('Nominal (Rp)'),
                ),
                ButtonSegment(
                  value: DiscountType.percent,
                  label: Text('Persen (%)'),
                ),
              ],
              selected: {_discountType},
              onSelectionChanged: (set) {
                setState(() {
                  _discountType = set.first;
                  _errorText = null;
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _discountType == DiscountType.percent
                    ? 'Nilai Diskon (%)'
                    : 'Nilai Diskon (Rp)',
                hintText: _discountType == DiscountType.percent ? '0 - 100' : '0',
                suffixIcon: _discountController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _discountController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() => _errorText = null),
            ),
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
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _PreviewRow(
                    'Subtotal Kotor',
                    CurrencyFormatter.formatRupiah(_previewGross),
                  ),
                  _PreviewRow(
                    'Diskon Item',
                    '-${CurrencyFormatter.formatRupiah(_previewDiscountAmount)}',
                  ),
                  const Divider(height: 12),
                  _PreviewRow(
                    'Total Item',
                    CurrencyFormatter.formatRupiah(_previewNet),
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow(this.label, this.value, {this.isBold = false});

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: isBold ? AppTheme.primaryGreen : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
