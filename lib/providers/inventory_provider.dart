import 'package:dobrak_mandiri_app/data/models/product.dart';
import 'package:dobrak_mandiri_app/data/repositories/inventory_repository.dart';
import 'package:flutter/foundation.dart';

/// Provider manajemen stok real-time PT. Dobrak Mandiri.
class InventoryProvider extends ChangeNotifier {
  InventoryProvider({required InventoryRepository inventoryRepository})
      : _repository = inventoryRepository;

  final InventoryRepository _repository;

  bool _isLoading = false;
  bool _isMutating = false;
  String? _statusMessage;
  bool _hasError = false;

  List<Product> get products => _repository.products;
  List<String> get categories => _repository.categories;
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  bool get isOfflineFallback => _repository.isOfflineFallback;
  String? get statusMessage => _statusMessage ?? _repository.lastSyncMessage;
  bool get hasError => _hasError;

  int get totalSku => products.length;
  int get totalUnits => products.fold<int>(0, (sum, p) => sum + p.stock);
  List<Product> get lowStockProducts =>
      products.where((p) => p.isLowStock).toList();
  int get lowStockCount => lowStockProducts.length;
  int get outOfStockCount => products.where((p) => p.isOutOfStock).length;

  Product? findProductById(int id) => _repository.findProductByIdOrSku(id: id);

  Future<void> loadProducts() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final result = await _repository.loadProducts();
      _hasError = !result.isSuccess;
      _statusMessage = result.isSuccess && !result.isOfflineMode
          ? null
          : result.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<RepositoryActionResult<Product>> addProduct(Product product) async {
    _isMutating = true;
    notifyListeners();

    try {
      return await _repository.addProduct(product);
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<RepositoryActionResult<Product>> updateProduct(Product product) async {
    _isMutating = true;
    notifyListeners();

    try {
      return await _repository.updateProduct(product);
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<RepositoryActionResult<Product>> adjustStock({
    required int productId,
    required int delta,
    String? reason,
  }) async {
    _isMutating = true;
    notifyListeners();

    try {
      return await _repository.adjustStock(
        productId: productId,
        delta: delta,
        reason: reason,
      );
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// Dipanggil setelah checkout POS selesai agar seluruh layar inventaris langsung terbarui.
  void notifyStockSynchronized() {
    notifyListeners();
  }
}
