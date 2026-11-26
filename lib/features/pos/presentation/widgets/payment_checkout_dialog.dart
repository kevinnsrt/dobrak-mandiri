import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/data/models/cart_item.dart';
import 'package:dobrak_mandiri_app/data/models/transaction.dart';
import 'package:dobrak_mandiri_app/features/pos/presentation/widgets/digital_receipt_dialog.dart';
import 'package:dobrak_mandiri_app/providers/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dialog penyelesaian pembayaran POS (Tunai / Transfer Manual tanpa QRIS/Gateway).
class PaymentCheckoutDialog extends StatefulWidget {
  const PaymentCheckoutDialog({super.key});

  @override
  State<PaymentCheckoutDialog> createState() => _PaymentCheckoutDialogState();
}

class _PaymentCheckoutDialogState extends State<PaymentCheckoutDialog> {
  final _cashController = TextEditingController();
  final _transferRefController = TextEditingController();
  final _customerNameController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.cash;
  double _cashPaid = 0;

  @override
  void dispose() {
    _cashController.dispose();
    _transferRefController.dispose();
    _customerNameController.dispose();
    super.dispose();
  }

  void _setQuickCash(double amount) {
    setState(() {
      _cashPaid = amount;
      _cashController.text = amount.round().toString();
    });
  }

  Future<void> _confirmCheckout(PosProvider pos) async {
    final result = await pos.checkout(
      paymentMethod: _selectedMethod,
      cashPaid: _selectedMethod == PaymentMethod.cash ? _cashPaid : pos.grandTotal,
      transferReference: _selectedMethod == PaymentMethod.manualTransfer
          ? _transferRefController.text
          : null,
      customerName: _customerNameController.text,
    );

    if (!mounted) return;

    if (result.isSuccess && result.transaction != null) {
      Navigator.pop(context);
      await _showReceipt(result.transaction!, result.isOfflineSaved);
    } else {
      await showDialog<void>(
        context: context,
        builder: (errContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Text('Transaksi Gagal'),
            ],
          ),
          content: Text(result.message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(errContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showReceipt(Transaction transaction, bool isOfflineSaved) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DigitalReceiptDialog(
        transaction: transaction,
        isOfflineSaved: isOfflineSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pos = context.watch<PosProvider>();
    final grandTotal = pos.grandTotal;
    final change = _cashPaid >= grandTotal ? _cashPaid - grandTotal : 0.0;
    final isCashValid =
        _selectedMethod != PaymentMethod.cash || _cashPaid >= grandTotal;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.receipt_long, color: AppTheme.primaryGreen),
          SizedBox(width: 10),
          Text('Selesaikan Pembayaran', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Tagihan',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      CurrencyFormatter.formatRupiah(grandTotal),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    if (pos.totalItemDiscount > 0 || pos.globalDiscountAmount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Termasuk total diskon -${CurrencyFormatter.formatRupiah(pos.totalItemDiscount + pos.globalDiscountAmount)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _customerNameController,
                enabled: !pos.isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Nama Pelanggan / Proyek (Opsional)',
                  hintText: 'Contoh: Pak Budi / Proyek Renovasi',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Metode Pembayaran Manual',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: PaymentMethod.values.map((method) {
                  final isSelected = _selectedMethod == method;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: pos.isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _selectedMethod = method;
                                });
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                method == PaymentMethod.cash
                                    ? Icons.payments_outlined
                                    : Icons.account_balance_outlined,
                                size: 18,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  method.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (_selectedMethod == PaymentMethod.cash) ...[
                TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  enabled: !pos.isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Uang Tunai Dibayar (Rp)',
                    prefixIcon: Icon(Icons.money),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _cashPaid = CurrencyFormatter.parseInput(val);
                    });
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Uang Pas'),
                      onPressed: pos.isSubmitting
                          ? null
                          : () => _setQuickCash(grandTotal.ceilToDouble()),
                    ),
                    for (final preset in [50000.0, 100000.0, 200000.0, 500000.0])
                      ActionChip(
                        label: Text(CurrencyFormatter.formatRupiah(preset)),
                        onPressed: pos.isSubmitting
                            ? null
                            : () => _setQuickCash(preset),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Uang Kembalian:',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    Text(
                      CurrencyFormatter.formatRupiah(change),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCashValid ? AppTheme.primaryGreen : Colors.red,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 20,
                        color: AppTheme.infoBlue,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verifikasi manual: pastikan bukti transfer dari pelanggan sudah diterima di rekening toko sebelum konfirmasi transaksi.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _transferRefController,
                  enabled: !pos.isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bank / No. Referensi (Opsional)',
                    hintText: 'Contoh: BCA - Ref 882104',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: pos.isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: (isCashValid && !pos.isSubmitting)
              ? () => _confirmCheckout(pos)
              : null,
          child: pos.isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'KONFIRMASI BAYAR',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
