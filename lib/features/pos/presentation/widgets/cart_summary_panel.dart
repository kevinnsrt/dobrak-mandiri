import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/data/models/cart_item.dart';
import 'package:dobrak_mandiri_app/features/pos/presentation/widgets/item_discount_dialog.dart';
import 'package:dobrak_mandiri_app/providers/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Panel isi keranjang kasir yang dapat dipakai di bottom sheet (HP) maupun split-panel (tablet).
class CartSummaryPanel extends StatelessWidget {
  const CartSummaryPanel({
    super.key,
    required this.onProceedCheckout,
    this.isBottomSheet = false,
  });

  final VoidCallback onProceedCheckout;
  final bool isBottomSheet;

  Future<void> _showGlobalDiscountDialog(
    BuildContext context,
    PosProvider pos,
  ) async {
    DiscountType selectedType = pos.globalDiscountType;
    final controller = TextEditingController(
      text: pos.globalDiscountValue > 0
          ? pos.globalDiscountValue.toStringAsFixed(0)
          : '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Atur Diskon Global'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Berlaku pada subtotal setelah diskon item (${CurrencyFormatter.formatRupiah(pos.subtotalAfterItemDiscount)}).',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
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
                  selected: {selectedType},
                  onSelectionChanged: (s) {
                    setDialogState(() {
                      selectedType = s.first;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: selectedType == DiscountType.percent
                        ? 'Persentase Diskon (%)'
                        : 'Nominal Diskon (Rp)',
                    hintText: '0',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  pos.setGlobalDiscount(type: DiscountType.nominal, value: 0);
                  Navigator.pop(dialogContext);
                },
                child: const Text('Hapus Diskon', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () {
                  final raw = double.tryParse(
                        controller.text.replaceAll('.', '').trim(),
                      ) ??
                      0;
                  final clamped = selectedType == DiscountType.percent
                      ? raw.clamp(0.0, 100.0)
                      : raw.clamp(0.0, pos.subtotalAfterItemDiscount);
                  pos.setGlobalDiscount(type: selectedType, value: clamped);
                  Navigator.pop(dialogContext);
                },
                child: const Text('Terapkan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBottomSheet) ...[
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
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Keranjang (${pos.totalItemCount} Item)',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!pos.isCartEmpty)
                TextButton.icon(
                  onPressed: () {
                    pos.clearCart();
                    if (isBottomSheet) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: const Text(
                    'Kosongkan',
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
            ],
          ),
          const Divider(),
          Expanded(
            child: pos.isCartEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada barang dipilih',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: pos.cartItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final item = pos.cartItems[index];
                      return _CartItemRow(
                        item: item,
                        onDecrease: () {
                          pos.decreaseItem(item.product.id);
                          if (isBottomSheet && pos.isCartEmpty) {
                            Navigator.pop(context);
                          }
                        },
                        onIncrease: () {
                          final err = pos.addItem(item.product);
                          if (err != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                          }
                        },
                        onRemove: () {
                          pos.removeItem(item.product.id);
                          if (isBottomSheet && pos.isCartEmpty) {
                            Navigator.pop(context);
                          }
                        },
                        onEdit: () {
                          showDialog<void>(
                            context: context,
                            builder: (_) => ItemDiscountDialog(cartItem: item),
                          );
                        },
                      );
                    },
                  ),
          ),
          if (!pos.isCartEmpty) ...[
            const Divider(),
            _BreakdownRow(
              'Subtotal Kotor',
              CurrencyFormatter.formatRupiah(pos.grossSubtotal),
            ),
            if (pos.totalItemDiscount > 0)
              _BreakdownRow(
                'Diskon Item',
                '-${CurrencyFormatter.formatRupiah(pos.totalItemDiscount)}',
                valueColor: Colors.orange.shade800,
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _showGlobalDiscountDialog(context, pos),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  icon: const Icon(
                    Icons.local_offer_outlined,
                    size: 16,
                    color: AppTheme.primaryGreen,
                  ),
                  label: Text(
                    pos.globalDiscountAmount > 0
                        ? 'Ubah Diskon Global'
                        : '+ Diskon Global',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
                Text(
                  pos.globalDiscountAmount > 0
                      ? '-${CurrencyFormatter.formatRupiah(pos.globalDiscountAmount)}'
                      : 'Rp 0',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: pos.globalDiscountAmount > 0
                        ? Colors.orange.shade800
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: pos.includePpn,
                      activeColor: AppTheme.primaryGreen,
                      visualDensity: VisualDensity.compact,
                      onChanged: (val) => pos.togglePpn(val ?? true),
                    ),
                    const Text(
                      'PPN (11%)',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.formatRupiah(pos.ppnAmount),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Bayar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    CurrencyFormatter.formatRupiah(pos.grandTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onProceedCheckout,
                icon: const Icon(Icons.payments_outlined),
                label: const Text(
                  'PROSES PEMBAYARAN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
    required this.onEdit,
  });

  final CartItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = item.product;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            onTap: onEdit,
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
                const SizedBox(height: 2),
                Text(
                  '${CurrencyFormatter.formatRupiah(p.price)} x ${item.quantity} ${p.unit}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (item.discountAmount > 0)
                  Text(
                    'Diskon: -${CurrencyFormatter.formatRupiah(item.discountAmount)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatRupiah(item.netSubtotal),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Ubah Qty / Diskon',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: onDecrease,
            ),
            Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                size: 20,
                color: AppTheme.primaryGreen,
              ),
              onPressed: onIncrease,
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
