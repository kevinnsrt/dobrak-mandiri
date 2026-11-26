import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/core/utils/date_formatter.dart';
import 'package:dobrak_mandiri_app/data/models/cart_item.dart';
import 'package:dobrak_mandiri_app/data/models/transaction_item.dart';

/// Entitas transaksi lengkap beserta informasi Nota/Faktur PT. Dobrak Mandiri.
class Transaction {
  final int id;
  final String invoiceNumber;
  final DateTime timestamp;
  final String cashierName;
  final String? customerName;
  final List<TransactionItem> items;
  final double grossSubtotal;
  final double totalItemDiscount;
  final DiscountType globalDiscountType;
  final double globalDiscountValue;
  final double globalDiscountAmount;
  final double subtotal;
  final double ppn;
  final double grandTotal;
  final PaymentMethod paymentMethod;
  final String? transferReference;
  final double cashPaid;
  final double change;
  final String status;
  final bool isSynced;

  const Transaction({
    required this.id,
    required this.invoiceNumber,
    required this.timestamp,
    required this.cashierName,
    this.customerName,
    required this.items,
    required this.grossSubtotal,
    this.totalItemDiscount = 0.0,
    this.globalDiscountType = DiscountType.nominal,
    this.globalDiscountValue = 0.0,
    this.globalDiscountAmount = 0.0,
    required this.subtotal,
    required this.ppn,
    required this.grandTotal,
    required this.paymentMethod,
    this.transferReference,
    required this.cashPaid,
    required this.change,
    this.status = 'Lunas',
    this.isSynced = true,
  });

  double get totalDiscount => totalItemDiscount + globalDiscountAmount;

  int get totalItemQuantity =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get isCancelled => status.toLowerCase().contains('batal');

  Transaction copyWith({
    int? id,
    String? invoiceNumber,
    DateTime? timestamp,
    String? cashierName,
    String? customerName,
    List<TransactionItem>? items,
    double? grossSubtotal,
    double? totalItemDiscount,
    DiscountType? globalDiscountType,
    double? globalDiscountValue,
    double? globalDiscountAmount,
    double? subtotal,
    double? ppn,
    double? grandTotal,
    PaymentMethod? paymentMethod,
    String? transferReference,
    double? cashPaid,
    double? change,
    String? status,
    bool? isSynced,
  }) {
    return Transaction(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      timestamp: timestamp ?? this.timestamp,
      cashierName: cashierName ?? this.cashierName,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      grossSubtotal: grossSubtotal ?? this.grossSubtotal,
      totalItemDiscount: totalItemDiscount ?? this.totalItemDiscount,
      globalDiscountType: globalDiscountType ?? this.globalDiscountType,
      globalDiscountValue: globalDiscountValue ?? this.globalDiscountValue,
      globalDiscountAmount: globalDiscountAmount ?? this.globalDiscountAmount,
      subtotal: subtotal ?? this.subtotal,
      ppn: ppn ?? this.ppn,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transferReference: transferReference ?? this.transferReference,
      cashPaid: cashPaid ?? this.cashPaid,
      change: change ?? this.change,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final id = (json['id_transaksi'] as num?)?.toInt() ??
        (json['id'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;

    final invoiceNumber = json['nomor_struk']?.toString() ??
        json['nomor_faktur']?.toString() ??
        json['invoice']?.toString() ??
        'INV/$id';

    DateTime parsedDate = DateTime.now();
    final dateStr = json['updated_at']?.toString() ??
        json['tanggal_transaksi']?.toString() ??
        json['created_at']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
    }

    final pengguna = json['pengguna'] is Map<String, dynamic>
        ? json['pengguna'] as Map<String, dynamic>
        : null;
    final cashierName = pengguna?['nama']?.toString() ??
        pengguna?['name']?.toString() ??
        json['nama_kasir']?.toString() ??
        'Kasir Toko';

    final customerName = json['nama_pelanggan']?.toString();

    final List<TransactionItem> parsedItems = [];
    final detailList = json['detail'] ?? json['items'] ?? json['details'];
    if (detailList is List) {
      for (final raw in detailList) {
        if (raw is Map<String, dynamic>) {
          parsedItems.add(TransactionItem.fromJson(raw));
        }
      }
    }

    final grossFromItems = parsedItems.fold<double>(
      0.0,
      (sum, item) => sum + item.grossTotal,
    );
    final itemDiscountFromItems = parsedItems.fold<double>(
      0.0,
      (sum, item) => sum + item.discountAmount,
    );

    final rawTotal = (json['grand_total'] as num?)?.toDouble() ??
        (json['total_pembayaran'] as num?)?.toDouble() ??
        (json['total'] as num?)?.toDouble();

    final subtotal = (json['subtotal'] as num?)?.toDouble() ??
        (grossFromItems > 0 ? grossFromItems - itemDiscountFromItems : (rawTotal ?? 0.0));

    final globalDiscountType =
        DiscountType.fromString(json['jenis_diskon_global']?.toString());
    final globalDiscountValue =
        (json['nilai_diskon_global'] as num?)?.toDouble() ?? 0.0;
    final globalDiscountAmount =
        (json['diskon_global'] as num?)?.toDouble() ?? 0.0;

    final totalItemDiscount =
        (json['diskon_item'] as num?)?.toDouble() ?? itemDiscountFromItems;

    final grossSubtotal =
        (json['subtotal_kotor'] as num?)?.toDouble() ??
            (grossFromItems > 0 ? grossFromItems : subtotal + totalItemDiscount + globalDiscountAmount);

    final ppn = (json['ppn'] as num?)?.toDouble() ?? 0.0;
    final grandTotal = rawTotal ?? (subtotal + ppn);

    final paymentMethod = PaymentMethod.fromString(
      json['jenis_pembayaran_label']?.toString() ??
          json['jenis_pembayaran']?.toString() ??
          json['metode_pembayaran']?.toString() ??
          json['payment_method']?.toString(),
    );

    final transferReference = json['referensi_transfer']?.toString() ??
        json['catatan_pembayaran']?.toString();

    final change = (json['kembalian'] as num?)?.toDouble() ?? 0.0;
    final cashPaid = (json['jumlah_bayar'] as num?)?.toDouble() ??
        (grandTotal + change);

    final status = json['status']?.toString() ?? 'Lunas';
    final isSynced = json['is_synced'] as bool? ?? true;

    return Transaction(
      id: id,
      invoiceNumber: invoiceNumber,
      timestamp: parsedDate,
      cashierName: cashierName,
      customerName: customerName,
      items: parsedItems.isEmpty
          ? [
              TransactionItem(
                productId: 0,
                sku: '-',
                productName: 'Barang Pesanan',
                unitPrice: grandTotal,
                quantity: 1,
              ),
            ]
          : parsedItems,
      grossSubtotal: grossSubtotal,
      totalItemDiscount: totalItemDiscount,
      globalDiscountType: globalDiscountType,
      globalDiscountValue: globalDiscountValue,
      globalDiscountAmount: globalDiscountAmount,
      subtotal: subtotal,
      ppn: ppn,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      transferReference: transferReference,
      cashPaid: cashPaid,
      change: change,
      status: status,
      isSynced: isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_transaksi': id,
      'nomor_struk': invoiceNumber,
      'tanggal_transaksi': timestamp.toIso8601String(),
      'nama_kasir': cashierName,
      if (customerName != null && customerName!.isNotEmpty)
        'nama_pelanggan': customerName,
      'detail': items.map((e) => e.toJson()).toList(),
      'subtotal_kotor': grossSubtotal,
      'diskon_item': totalItemDiscount,
      'jenis_diskon_global': globalDiscountType.name,
      'nilai_diskon_global': globalDiscountValue,
      'diskon_global': globalDiscountAmount,
      'subtotal': subtotal,
      'ppn': ppn,
      'grand_total': grandTotal,
      'total_pembayaran': grandTotal,
      'jenis_pembayaran': paymentMethod.apiValue,
      'jenis_pembayaran_label': paymentMethod.label,
      if (transferReference != null && transferReference!.isNotEmpty)
        'referensi_transfer': transferReference,
      'jumlah_bayar': cashPaid,
      'kembalian': change,
      'status': status,
      'is_synced': isSynced,
    };
  }

  /// Format teks Nota / Faktur resmi untuk disalin atau dibagikan kasir.
  String toReceiptText() {
    final buffer = StringBuffer()
      ..writeln('================================')
      ..writeln(AppConstants.companyName)
      ..writeln(AppConstants.companyTagline)
      ..writeln('--------------------------------')
      ..writeln('No. Faktur : $invoiceNumber')
      ..writeln('Tanggal    : ${DateFormatter.formatDateTime(timestamp)}')
      ..writeln('Kasir      : $cashierName');
    if (customerName != null && customerName!.isNotEmpty) {
      buffer.writeln('Pelanggan  : $customerName');
    }
    buffer.writeln('--------------------------------');

    for (final item in items) {
      buffer.writeln(item.productName);
      buffer.writeln(
        '  ${item.quantity} ${item.unit} x ${CurrencyFormatter.formatRupiah(item.unitPrice)} = ${CurrencyFormatter.formatRupiah(item.grossTotal)}',
      );
      if (item.discountAmount > 0) {
        buffer.writeln(
          '  Diskon item: -${CurrencyFormatter.formatRupiah(item.discountAmount)}',
        );
      }
    }

    buffer
      ..writeln('--------------------------------')
      ..writeln('Subtotal Kotor : ${CurrencyFormatter.formatRupiah(grossSubtotal)}');
    if (totalItemDiscount > 0) {
      buffer.writeln(
        'Diskon Item    : -${CurrencyFormatter.formatRupiah(totalItemDiscount)}',
      );
    }
    if (globalDiscountAmount > 0) {
      buffer.writeln(
        'Diskon Global  : -${CurrencyFormatter.formatRupiah(globalDiscountAmount)}',
      );
    }
    if (ppn > 0) {
      buffer.writeln('PPN (11%)      : ${CurrencyFormatter.formatRupiah(ppn)}');
    }
    buffer
      ..writeln('TOTAL BAYAR    : ${CurrencyFormatter.formatRupiah(grandTotal)}')
      ..writeln('Metode Bayar   : ${paymentMethod.label}');

    if (paymentMethod == PaymentMethod.cash) {
      buffer
        ..writeln('Uang Dibayar   : ${CurrencyFormatter.formatRupiah(cashPaid)}')
        ..writeln('Kembalian      : ${CurrencyFormatter.formatRupiah(change)}');
    } else if (transferReference != null && transferReference!.isNotEmpty) {
      buffer.writeln('Ref. Transfer  : $transferReference');
    }

    buffer
      ..writeln('Status         : $status')
      ..writeln('================================')
      ..writeln('Terima kasih telah berbelanja di')
      ..writeln(AppConstants.companyName);

    return buffer.toString();
  }
}
