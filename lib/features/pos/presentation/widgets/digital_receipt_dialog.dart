import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/core/utils/date_formatter.dart';
import 'package:dobrak_mandiri_app/data/models/cart_item.dart';
import 'package:dobrak_mandiri_app/data/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Nota / Faktur transaksi resmi pengganti Bon Faktur manual PT. Dobrak Mandiri.
class DigitalReceiptDialog extends StatelessWidget {
  const DigitalReceiptDialog({
    super.key,
    required this.transaction,
    this.isOfflineSaved = false,
  });

  final Transaction transaction;
  final bool isOfflineSaved;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(20),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppTheme.lightGreenBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primaryGreen,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nota Faktur Pembayaran',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text(
                '${AppConstants.companyName} • ${AppConstants.companyTagline}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              if (isOfflineSaved) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tersimpan di perangkat (Mode Lokal/Offline) & stok otomatis berkurang.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                  ),
                ),
              ],
              const Divider(height: 22),
              _MetaRow('No. Faktur', transaction.invoiceNumber),
              _MetaRow(
                'Tanggal',
                DateFormatter.formatDateTime(transaction.timestamp),
              ),
              _MetaRow('Kasir', transaction.cashierName),
              if (transaction.customerName != null &&
                  transaction.customerName!.isNotEmpty)
                _MetaRow('Pelanggan', transaction.customerName!),
              const Divider(height: 20),
              const Text(
                'Rincian Barang',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
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
                              item.productName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatRupiah(item.totalPrice),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${item.quantity} ${item.unit} x ${CurrencyFormatter.formatRupiah(item.unitPrice)}'
                        '${item.discountAmount > 0 ? ' (Diskon -${CurrencyFormatter.formatRupiah(item.discountAmount)})' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 20),
              _MetaRow(
                'Subtotal Kotor',
                CurrencyFormatter.formatRupiah(transaction.grossSubtotal),
              ),
              if (transaction.totalItemDiscount > 0)
                _MetaRow(
                  'Diskon Item',
                  '-${CurrencyFormatter.formatRupiah(transaction.totalItemDiscount)}',
                ),
              if (transaction.globalDiscountAmount > 0)
                _MetaRow(
                  'Diskon Global',
                  '-${CurrencyFormatter.formatRupiah(transaction.globalDiscountAmount)}',
                ),
              if (transaction.ppn > 0)
                _MetaRow(
                  'PPN (11%)',
                  CurrencyFormatter.formatRupiah(transaction.ppn),
                ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL BAYAR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatRupiah(transaction.grandTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _MetaRow('Metode Bayar', transaction.paymentMethod.label),
              if (transaction.paymentMethod == PaymentMethod.cash) ...[
                _MetaRow(
                  'Uang Dibayar',
                  CurrencyFormatter.formatRupiah(transaction.cashPaid),
                ),
                _MetaRow(
                  'Kembalian',
                  CurrencyFormatter.formatRupiah(transaction.change),
                ),
              ] else if (transaction.transferReference != null &&
                  transaction.transferReference!.isNotEmpty)
                _MetaRow('Ref. Transfer', transaction.transferReference!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: transaction.toReceiptText()),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Teks Nota Faktur disalin ke clipboard.'),
                ),
              );
            }
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Salin Nota'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
