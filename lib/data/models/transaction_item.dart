import 'package:dobrak_mandiri_app/data/models/cart_item.dart';

/// Detail item transaksi pada Nota/Faktur dan Riwayat Transaksi.
class TransactionItem {
  final int productId;
  final String sku;
  final String productName;
  final String unit;
  final double unitPrice;
  final int quantity;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;

  const TransactionItem({
    required this.productId,
    required this.sku,
    required this.productName,
    this.unit = 'Unit',
    required this.unitPrice,
    required this.quantity,
    this.discountType = DiscountType.nominal,
    this.discountValue = 0.0,
    this.discountAmount = 0.0,
  });

  double get grossTotal => unitPrice * quantity;
  double get totalPrice => (grossTotal - discountAmount).clamp(0.0, double.infinity);

  factory TransactionItem.fromCartItem(CartItem cartItem) {
    return TransactionItem(
      productId: cartItem.product.id,
      sku: cartItem.product.sku,
      productName: cartItem.product.name,
      unit: cartItem.product.unit,
      unitPrice: cartItem.product.price,
      quantity: cartItem.quantity,
      discountType: cartItem.discountType,
      discountValue: cartItem.discountValue,
      discountAmount: cartItem.discountAmount,
    );
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final prod = json['produk'] is Map<String, dynamic>
        ? json['produk'] as Map<String, dynamic>
        : null;

    final productId = (json['id_produk'] as num?)?.toInt() ??
        (prod?['id_produk'] as num?)?.toInt() ??
        (prod?['id'] as num?)?.toInt() ??
        0;

    final sku = json['kode_sku']?.toString() ??
        prod?['kode_sku']?.toString() ??
        '';

    final productName = prod?['nama_produk']?.toString() ??
        prod?['nama']?.toString() ??
        json['nama_produk']?.toString() ??
        json['nama']?.toString() ??
        json['name']?.toString() ??
        'Produk Barang';

    final unit = json['satuan']?.toString() ??
        prod?['satuan']?.toString() ??
        'Unit';

    final qty = (json['jumlah'] as num?)?.toInt() ??
        (json['kuantitas'] as num?)?.toInt() ??
        (json['qty'] as num?)?.toInt() ??
        1;

    final safeQty = qty <= 0 ? 1 : qty;

    final unitPrice = (json['harga'] as num?)?.toDouble() ??
        (json['harga_satuan'] as num?)?.toDouble() ??
        (prod?['harga'] as num?)?.toDouble() ??
        (json['subtotal'] as num?)?.toDouble() ??
        0.0;

    final discountType = DiscountType.fromString(json['jenis_diskon']?.toString());
    final discountValue = (json['nilai_diskon'] as num?)?.toDouble() ?? 0.0;
    final discountAmount = (json['diskon'] as num?)?.toDouble() ??
        (json['diskon_item'] as num?)?.toDouble() ??
        0.0;

    return TransactionItem(
      productId: productId,
      sku: sku,
      productName: productName,
      unit: unit,
      unitPrice: unitPrice,
      quantity: safeQty,
      discountType: discountType,
      discountValue: discountValue,
      discountAmount: discountAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_produk': productId,
      'kode_sku': sku,
      'nama_produk': productName,
      'satuan': unit,
      'harga': unitPrice,
      'jumlah': quantity,
      'jenis_diskon': discountType.name,
      'nilai_diskon': discountValue,
      'diskon': discountAmount,
      'subtotal': totalPrice,
    };
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'id_produk': productId,
      'jumlah': quantity,
      if (discountAmount > 0) 'diskon': discountAmount,
    };
  }
}
