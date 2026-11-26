import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/data/models/cart_item.dart';
import 'package:dobrak_mandiri_app/data/models/product.dart';
import 'package:flutter/material.dart';

/// Kartu produk untuk katalog kasir POS dengan aksi cepat & indikator diskon/stok.
class ProductCatalogCard extends StatelessWidget {
  const ProductCatalogCard({
    super.key,
    required this.product,
    required this.cartItem,
    required this.onAdd,
    required this.onDecrease,
    required this.onEditQtyAndDiscount,
  });

  final Product product;
  final CartItem? cartItem;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;
  final VoidCallback onEditQtyAndDiscount;

  @override
  Widget build(BuildContext context) {
    final qty = cartItem?.quantity ?? 0;
    final hasDiscount = (cartItem?.discountAmount ?? 0) > 0;
    final isOut = product.isOutOfStock;
    final isLow = product.isLowStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: qty > 0
              ? AppTheme.primaryGreen.withValues(alpha: 0.6)
              : Colors.grey.shade200,
          width: qty > 0 ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isOut ? Colors.red.shade50 : AppTheme.lightGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                product.categoryIcon,
                color: isOut ? Colors.red : AppTheme.primaryGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
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
                    'SKU: ${product.sku} • Stok: ${product.stock} ${product.unit}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isOut || isLow
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isOut
                          ? Colors.red.shade700
                          : (isLow
                              ? Colors.orange.shade800
                              : Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${CurrencyFormatter.formatRupiah(product.price)} / ${product.unit}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      if (hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Diskon -${CurrencyFormatter.formatRupiah(cartItem!.discountAmount)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isOut)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Habis',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              )
            else if (qty == 0)
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Pilih'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(88, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreenBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          color: AppTheme.primaryGreen,
                          tooltip: 'Kurangi',
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: onDecrease,
                        ),
                        InkWell(
                          onTap: onEditQtyAndDiscount,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              '$qty',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          color: AppTheme.primaryGreen,
                          tooltip: 'Tambah',
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: onAdd,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onEditQtyAndDiscount,
                    child: const Text(
                      'Atur Qty / Diskon',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
