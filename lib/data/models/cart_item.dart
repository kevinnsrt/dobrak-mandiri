import 'package:dobrak_mandiri_app/data/models/product.dart';

/// Jenis diskon yang tersedia pada kasir POS.
enum DiscountType {
  nominal,
  percent;

  String get label => this == DiscountType.percent ? 'Persen (%)' : 'Nominal (Rp)';

  static DiscountType fromString(String? raw) {
    final normalized = (raw ?? '').toLowerCase();
    if (normalized.contains('percent') || normalized.contains('persen') || normalized == '%') {
      return DiscountType.percent;
    }
    return DiscountType.nominal;
  }
}

/// Metode pembayaran manual yang diizinkan sesuai BRD (Tunai & Transfer Manual).
enum PaymentMethod {
  cash,
  manualTransfer;

  String get label =>
      this == PaymentMethod.cash ? 'Tunai' : 'Transfer Manual';

  /// Nilai wire yang kompatibel dengan REST API backend.
  String get apiValue =>
      this == PaymentMethod.cash ? 'TUNAI' : 'TRANSFER';

  static PaymentMethod fromString(String? raw) {
    final normalized = (raw ?? '').toUpperCase().trim();
    if (normalized.contains('TRANSFER') || normalized.contains('BANK')) {
      return PaymentMethod.manualTransfer;
    }
    return PaymentMethod.cash;
  }
}

/// Item aktif di keranjang kasir POS sebelum checkout.
class CartItem {
  final Product product;
  final int quantity;
  final DiscountType discountType;
  final double discountValue;

  const CartItem({
    required this.product,
    this.quantity = 1,
    this.discountType = DiscountType.nominal,
    this.discountValue = 0.0,
  });

  /// Total kotor sebelum diskon item.
  double get grossSubtotal => product.price * quantity;

  /// Besaran nominal diskon item (dijamin tidak melebihi grossSubtotal).
  double get discountAmount {
    if (discountValue <= 0) return 0.0;
    if (discountType == DiscountType.percent) {
      final pct = discountValue.clamp(0.0, 100.0);
      return grossSubtotal * (pct / 100.0);
    }
    return discountValue.clamp(0.0, grossSubtotal);
  }

  /// Total bersih item setelah diskon item.
  double get netSubtotal => (grossSubtotal - discountAmount).clamp(0.0, double.infinity);

  CartItem copyWith({
    Product? product,
    int? quantity,
    DiscountType? discountType,
    double? discountValue,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
    );
  }
}
