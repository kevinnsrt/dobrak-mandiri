import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/core/utils/date_formatter.dart';
import 'package:dobrak_mandiri_app/data/models/cart_item.dart';
import 'package:dobrak_mandiri_app/data/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet detail Nota/Faktur transaksi terstruktur.
class TransactionDetailSheet extends StatelessWidget {
  const TransactionDetailSheet({
    super.key,
    required this.transaction,
  });

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCancelled = transaction.isCancelled;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppConstants.companyName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        transaction.invoiceNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? Colors.red.shade50
                        : AppTheme.lightGreenBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCancelled
                          ? Colors.red.shade700
                          : AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tanggal: ${DateFormatter.formatDateTime(transaction.timestamp)} • Kasir: ${transaction.cashierName}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (transaction.customerName != null &&
                transaction.customerName!.isNotEmpty)
              Text(
                'Pelanggan: ${transaction.customerName}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const Divider(height: 24),
            const Text(
              'Daftar Barang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...transaction.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} (${item.quantity} ${item.unit})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatRupiah(item.totalPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (item.discountAmount > 0)
                      Text(
                        'Diskon item: -${CurrencyFormatter.formatRupiah(item.discountAmount)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            _DetailRow(
              'Subtotal Kotor',
              CurrencyFormatter.formatRupiah(transaction.grossSubtotal),
            ),
            if (transaction.totalItemDiscount > 0)
              _DetailRow(
                'Diskon Item',
                '-${CurrencyFormatter.formatRupiah(transaction.totalItemDiscount)}',
              ),
            if (transaction.globalDiscountAmount > 0)
              _DetailRow(
                'Diskon Global',
                '-${CurrencyFormatter.formatRupiah(transaction.globalDiscountAmount)}',
              ),
            _DetailRow(
              'PPN (11%)',
              CurrencyFormatter.formatRupiah(transaction.ppn),
            ),
            _DetailRow('Metode Bayar', transaction.paymentMethod.label),
            if (transaction.paymentMethod == PaymentMethod.cash) ...[
              _DetailRow(
                'Uang Dibayar',
                CurrencyFormatter.formatRupiah(transaction.cashPaid),
              ),
              _DetailRow(
                'Kembalian',
                CurrencyFormatter.formatRupiah(transaction.change),
              ),
            ] else if (transaction.transferReference != null &&
                transaction.transferReference!.isNotEmpty)
              _DetailRow('Ref. Transfer', transaction.transferReference!),
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
                    'Total Transaksi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    CurrencyFormatter.formatRupiah(transaction.grandTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: transaction.toReceiptText()),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nota Faktur disalin ke clipboard.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Salin Nota'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nota Faktur siap dicetak!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Cetak Nota'),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
