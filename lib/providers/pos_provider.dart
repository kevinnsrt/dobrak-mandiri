import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/data/models/cart_item.dart';
import 'package:dobrak_mandiri_app/data/models/product.dart';
import 'package:dobrak_mandiri_app/data/repositories/inventory_repository.dart';
import 'package:dobrak_mandiri_app/data/repositories/transaction_repository.dart';
import 'package:flutter/foundation.dart';

/// Provider keranjang POS, diskon item/global, validasi stok, & checkout kasir.
class PosProvider extends ChangeNotifier {
  PosProvider({
    required InventoryRepository inventoryRepository,
    required TransactionRepository transactionRepository,
    VoidCallback? onCheckoutCompleted,
  })  : _inventoryRepository = inventoryRepository,
        _transactionRepository = transactionRepository,
        _onCheckoutCompleted = onCheckoutCompleted;

  final InventoryRepository _inventoryRepository;
  final TransactionRepository _transactionRepository;
  final VoidCallback? _onCheckoutCompleted;

  final Map<int, CartItem> _cart = {};
  DiscountType _globalDiscountType = DiscountType.nominal;
  double _globalDiscountValue = 0.0;
  bool _includePpn = true;
  bool _isSubmitting = false;

  List<CartItem> get cartItems => _cart.values.toList();
  bool get isCartEmpty => _cart.isEmpty;
  DiscountType get globalDiscountType => _globalDiscountType;
  double get globalDiscountValue => _globalDiscountValue;
  bool get includePpn => _includePpn;
  bool get isSubmitting => _isSubmitting;

  int get totalItemCount =>
      _cart.values.fold<int>(0, (sum, item) => sum + item.quantity);

  int quantityForProduct(int productId) => _cart[productId]?.quantity ?? 0;

  CartItem? cartItemForProduct(int productId) => _cart[productId];

  /// Subtotal kotor seluruh item sebelum diskon apa pun.
  double get grossSubtotal => _cart.values.fold<double>(
        0.0,
        (sum, item) => sum + item.grossSubtotal,
      );

  /// Total akumulasi diskon per item.
  double get totalItemDiscount => _cart.values.fold<double>(
        0.0,
        (sum, item) => sum + item.discountAmount,
      );

  /// Subtotal setelah diskon item (dasar perhitungan diskon global).
  double get subtotalAfterItemDiscount =>
      (grossSubtotal - totalItemDiscount).clamp(0.0, double.infinity);

  /// Besaran nominal diskon global yang diterapkan.
  double get globalDiscountAmount {
    if (_globalDiscountValue <= 0 || subtotalAfterItemDiscount <= 0) {
      return 0.0;
    }
    if (_globalDiscountType == DiscountType.percent) {
      final pct = _globalDiscountValue.clamp(0.0, 100.0);
      return subtotalAfterItemDiscount * (pct / 100.0);
    }
    return _globalDiscountValue.clamp(0.0, subtotalAfterItemDiscount);
  }

  /// Subtotal bersih setelah diskon item & diskon global.
  double get subtotal =>
      (subtotalAfterItemDiscount - globalDiscountAmount)
          .clamp(0.0, double.infinity);

  double get ppnAmount => _includePpn ? subtotal * AppConstants.ppnRate : 0.0;

  double get grandTotal => subtotal + ppnAmount;

  Product _resolveLiveProduct(Product fallback) {
    return _inventoryRepository.findProductByIdOrSku(
          id: fallback.id,
          sku: fallback.sku,
        ) ??
        fallback;
  }

  /// Tambah item ke keranjang dengan validasi stok real-time.
  /// Mengembalikan pesan error jika stok tidak mencukupi, atau `null` jika berhasil.
  String? addItem(Product product, {int quantity = 1}) {
    final liveProduct = _resolveLiveProduct(product);
    if (liveProduct.stock <= 0) {
      return 'Stok "${liveProduct.name}" habis (0 ${liveProduct.unit}).';
    }

    final existing = _cart[liveProduct.id];
    final targetQty = (existing?.quantity ?? 0) + quantity;
    if (targetQty > liveProduct.stock) {
      return 'Stok "${liveProduct.name}" tidak mencukupi (tersedia: ${liveProduct.stock} ${liveProduct.unit}).';
    }

    if (existing != null) {
      _cart[liveProduct.id] = existing.copyWith(
        product: liveProduct,
        quantity: targetQty,
      );
    } else {
      _cart[liveProduct.id] = CartItem(
        product: liveProduct,
        quantity: targetQty,
      );
    }

    notifyListeners();
    return null;
  }

  /// Atur kuantitas item secara langsung (misalnya input jumlah banyak di kasir).
  String? setItemQuantity(Product product, int quantity) {
    final liveProduct = _resolveLiveProduct(product);
    if (quantity <= 0) {
      _cart.remove(liveProduct.id);
      notifyListeners();
      return null;
    }

    if (quantity > liveProduct.stock) {
      return 'Stok "${liveProduct.name}" hanya tersedia ${liveProduct.stock} ${liveProduct.unit}, tidak dapat memasukkan $quantity ${liveProduct.unit}.';
    }

    final existing = _cart[liveProduct.id];
    if (existing != null) {
      _cart[liveProduct.id] = existing.copyWith(
        product: liveProduct,
        quantity: quantity,
      );
    } else {
      _cart[liveProduct.id] = CartItem(
        product: liveProduct,
        quantity: quantity,
      );
    }

    notifyListeners();
    return null;
  }

  void decreaseItem(int productId) {
    final existing = _cart[productId];
    if (existing == null) return;

    if (existing.quantity > 1) {
      _cart[productId] = existing.copyWith(quantity: existing.quantity - 1);
    } else {
      _cart.remove(productId);
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _cart.remove(productId);
    notifyListeners();
  }

  /// Atur diskon per item (nominal Rupiah atau persentase).
  void setItemDiscount({
    required int productId,
    required DiscountType type,
    required double value,
  }) {
    final existing = _cart[productId];
    if (existing == null) return;

    final safeValue = value < 0 ? 0.0 : value;
    _cart[productId] = existing.copyWith(
      discountType: type,
      discountValue: safeValue,
    );
    notifyListeners();
  }

  /// Atur diskon global pada transaksi.
  void setGlobalDiscount({
    required DiscountType type,
    required double value,
  }) {
    _globalDiscountType = type;
    _globalDiscountValue = value < 0 ? 0.0 : value;
    notifyListeners();
  }

  void togglePpn(bool include) {
    _includePpn = include;
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _globalDiscountType = DiscountType.nominal;
    _globalDiscountValue = 0.0;
    notifyListeners();
  }

  /// Validasi stok terbaru & proses pembayaran (Tunai / Transfer Manual).
  Future<CheckoutResult> checkout({
    required PaymentMethod paymentMethod,
    required double cashPaid,
    String? transferReference,
    String? customerName,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final result = await _transactionRepository.submitCheckout(
        cartItems: cartItems,
        globalDiscountType: _globalDiscountType,
        globalDiscountValue: _globalDiscountValue,
        globalDiscountAmount: globalDiscountAmount,
        grossSubtotal: grossSubtotal,
        totalItemDiscount: totalItemDiscount,
        subtotal: subtotal,
        ppn: ppnAmount,
        grandTotal: grandTotal,
        paymentMethod: paymentMethod,
        cashPaid: cashPaid,
        transferReference: transferReference,
        customerName: customerName,
      );

      if (result.isSuccess) {
        clearCart();
        _onCheckoutCompleted?.call();
      }
      return result;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
