import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/data/models/cart_item.dart';
import 'package:dobrak_mandiri_app/data/models/product.dart';
import 'package:dobrak_mandiri_app/data/models/transaction_item.dart';
import 'package:dobrak_mandiri_app/data/services/api_client.dart';
import 'package:dobrak_mandiri_app/data/services/local_storage_service.dart';
import 'package:dobrak_mandiri_app/data/services/stock_service.dart';

class StockValidationResult {
  final bool isValid;
  final String? errorMessage;

  const StockValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  const StockValidationResult.invalid(this.errorMessage) : isValid = false;
}

class RepositoryActionResult<T> {
  final bool isSuccess;
  final String message;
  final T? data;
  final bool isOfflineMode;

  const RepositoryActionResult({
    required this.isSuccess,
    required this.message,
    this.data,
    this.isOfflineMode = false,
  });
}

/// Single Source of Truth untuk inventaris produk PT. Dobrak Mandiri.
class InventoryRepository {
  InventoryRepository({
    required StockService stockService,
    required LocalStorageService localStorage,
  })  : _stockService = stockService,
        _localStorage = localStorage;

  final StockService _stockService;
  final LocalStorageService _localStorage;

  List<Product> _products = [];
  List<String> _categories = List<String>.from(AppConstants.defaultCategories);
  bool _isOfflineFallback = false;
  String? _lastSyncMessage;

  List<Product> get products => List.unmodifiable(_products);
  List<String> get categories => List.unmodifiable(_categories);
  bool get isOfflineFallback => _isOfflineFallback;
  String? get lastSyncMessage => _lastSyncMessage;

  Product? findProductByIdOrSku({int? id, String? sku}) {
    for (final p in _products) {
      if (id != null && id > 0 && p.id == id) return p;
      if (sku != null && sku.isNotEmpty && p.sku == sku) return p;
    }
    return null;
  }

  /// Muat stok dari API REST, dengan fallback database lokal jika jaringan offline atau sesi demo.
  Future<RepositoryActionResult<List<Product>>> loadProducts() async {
    final session = await _localStorage.loadSession();
    final isDemoSession = session?.isLocalDemo ?? false;

    if (isDemoSession) {
      return _loadFromLocalStore(
        reason: 'Mode Lokal/Offline aktif. Perubahan stok tersimpan di perangkat.',
      );
    }

    try {
      final fetched = await _stockService.fetchProducts();

      List<String> fetchedCategories = AppConstants.defaultCategories;
      try {
        final remoteCategories = await _stockService.fetchCategories();
        if (remoteCategories.isNotEmpty) {
          fetchedCategories = remoteCategories;
        }
      } catch (_) {
        // Tetap gunakan kategori default jika endpoint kategori gagal, tanpa menimpa produk.
      }

      // Selalu sinkronkan dengan hasil server (termasuk jika kosong [] setelah hapus di DB).
      _products = fetched;
      await _localStorage.saveProducts(fetched);

      _mergeProductCategories(fetchedCategories);
      _isOfflineFallback = false;
      _lastSyncMessage = null;

      return RepositoryActionResult(
        isSuccess: true,
        message: 'Data stok berhasil disinkronkan dari server.',
        data: products,
      );
    } on ApiNetworkException catch (e) {
      return _loadFromLocalStore(reason: e.message);
    } on ApiHttpException catch (e) {
      final local = await _ensureLocalProducts();
      _products = local;
      _mergeProductCategories(AppConstants.defaultCategories);
      _isOfflineFallback = true;
      _lastSyncMessage = e.message;

      return RepositoryActionResult(
        isSuccess: false,
        message: e.message,
        data: products,
        isOfflineMode: true,
      );
    } catch (e) {
      return _loadFromLocalStore(reason: 'Gagal memuat stok: $e');
    }
  }

  Future<RepositoryActionResult<List<Product>>> _loadFromLocalStore({
    required String reason,
  }) async {
    _products = await _ensureLocalProducts();
    _mergeProductCategories(AppConstants.defaultCategories);
    _isOfflineFallback = true;
    _lastSyncMessage = reason;

    return RepositoryActionResult(
      isSuccess: true,
      message: reason,
      data: products,
      isOfflineMode: true,
    );
  }

  Future<List<Product>> _ensureLocalProducts() async {
    final cached = await _localStorage.loadProducts();
    if (cached.isNotEmpty) return cached;

    final seeds = List<Product>.from(LocalStorageService.defaultSeedProducts);
    await _localStorage.saveProducts(seeds);
    return seeds;
  }

  void _mergeProductCategories(List<String> baseCategories) {
    final set = <String>{...baseCategories};
    for (final p in _products) {
      if (p.category.trim().isNotEmpty) {
        set.add(p.category.trim());
      }
    }
    _categories = set.toList()..sort();
  }

  /// Validasi apakah seluruh item di keranjang memiliki stok yang cukup sebelum checkout.
  StockValidationResult validateCartStock(List<CartItem> cartItems) {
    if (cartItems.isEmpty) {
      return const StockValidationResult.invalid(
        'Keranjang belanja masih kosong.',
      );
    }

    for (final item in cartItems) {
      final liveProduct = findProductByIdOrSku(
        id: item.product.id,
        sku: item.product.sku,
      ) ??
          item.product;

      if (item.quantity <= 0) {
        return StockValidationResult.invalid(
          'Kuantitas untuk "${liveProduct.name}" harus lebih dari 0.',
        );
      }

      if (liveProduct.stock <= 0) {
        return StockValidationResult.invalid(
          'Stok "${liveProduct.name}" sedang habis (0 ${liveProduct.unit}).',
        );
      }

      if (item.quantity > liveProduct.stock) {
        return StockValidationResult.invalid(
          'Stok "${liveProduct.name}" tidak mencukupi. Tersedia ${liveProduct.stock} ${liveProduct.unit}, diminta ${item.quantity} ${liveProduct.unit}.',
        );
      }
    }

    return const StockValidationResult.valid();
  }

  /// Pengurangan stok secara sinkron & real-time setelah transaksi kasir berhasil.
  Future<void> deductStockSynchronously(List<TransactionItem> items) async {
    if (items.isEmpty) return;

    final updatedList = List<Product>.from(_products);
    for (final soldItem in items) {
      final index = updatedList.indexWhere(
            (p) =>
        (soldItem.productId > 0 && p.id == soldItem.productId) ||
            (soldItem.sku.isNotEmpty && p.sku == soldItem.sku) ||
            p.name.toLowerCase() == soldItem.productName.toLowerCase(),
      );

      if (index != -1) {
        final current = updatedList[index];
        final nextStock = (current.stock - soldItem.quantity).clamp(0, 1 << 30);
        updatedList[index] = current.copyWith(stock: nextStock);
      }
    }

    _products = updatedList;
    await _localStorage.saveProducts(_products);
  }

  /// Tambah produk baru ke API + database lokal.
  Future<RepositoryActionResult<Product>> addProduct(Product product) async {
    final duplicateSku = _products.any(
          (p) => p.sku.toLowerCase() == product.sku.toLowerCase(),
    );
    if (duplicateSku) {
      return RepositoryActionResult(
        isSuccess: false,
        message: 'Kode SKU "${product.sku}" sudah terdaftar.',
      );
    }

    final session = await _localStorage.loadSession();
    final isDemoSession = session?.isLocalDemo ?? false;

    if (!isDemoSession) {
      try {
        final created = await _stockService.createProduct(product);
        final saved = created.id > 0
            ? created
            : product.copyWith(id: _nextLocalId());
        _products = [saved, ..._products];
        _mergeProductCategories(_categories);
        await _localStorage.saveProducts(_products);

        return RepositoryActionResult(
          isSuccess: true,
          message: 'Produk "${saved.name}" berhasil ditambahkan.',
          data: saved,
        );
      } on ApiHttpException catch (e) {
        return RepositoryActionResult(isSuccess: false, message: e.message);
      } on ApiNetworkException {
        // Lanjutkan ke penyimpanan lokal jika server offline.
      }
    }

    final localCreated = product.copyWith(
      id: product.id > 0 ? product.id : _nextLocalId(),
    );
    _products = [localCreated, ..._products];
    _mergeProductCategories(_categories);
    _isOfflineFallback = true;
    await _localStorage.saveProducts(_products);

    return RepositoryActionResult(
      isSuccess: true,
      message: 'Produk "${localCreated.name}" disimpan di database lokal.',
      data: localCreated,
      isOfflineMode: true,
    );
  }

  /// Perbarui data produk / stok / harga.
  Future<RepositoryActionResult<Product>> updateProduct(Product product) async {
    if (product.stock < 0) {
      return const RepositoryActionResult(
        isSuccess: false,
        message: 'Stok tidak boleh bernilai negatif.',
      );
    }

    final session = await _localStorage.loadSession();
    final isDemoSession = session?.isLocalDemo ?? false;

    if (!isDemoSession) {
      try {
        final updated = await _stockService.updateProduct(product);
        _upsertLocalProduct(updated.id > 0 ? updated : product);
        await _localStorage.saveProducts(_products);

        return RepositoryActionResult(
          isSuccess: true,
          message: 'Data "${product.name}" berhasil diperbarui.',
          data: updated,
        );
      } on ApiHttpException catch (e) {
        return RepositoryActionResult(isSuccess: false, message: e.message);
      } on ApiNetworkException {
        // Fallback lokal jika jaringan offline.
      }
    }

    _upsertLocalProduct(product);
    _isOfflineFallback = true;
    await _localStorage.saveProducts(_products);

    return RepositoryActionResult(
      isSuccess: true,
      message: 'Perubahan "${product.name}" disimpan secara lokal.',
      data: product,
      isOfflineMode: true,
    );
  }

  /// Penyesuaian stok masuk (+delta) atau barang keluar (-delta) dengan validasi.
  Future<RepositoryActionResult<Product>> adjustStock({
    required int productId,
    required int delta,
    String? reason,
  }) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) {
      return const RepositoryActionResult(
        isSuccess: false,
        message: 'Produk tidak ditemukan dalam daftar stok.',
      );
    }

    final current = _products[index];
    final nextStock = current.stock + delta;
    if (nextStock < 0) {
      return RepositoryActionResult(
        isSuccess: false,
        message:
        'Stok "${current.name}" tidak mencukupi untuk dikurangi ${delta.abs()} ${current.unit} (Sisa: ${current.stock} ${current.unit}).',
      );
    }

    final updatedProduct = current.copyWith(stock: nextStock);
    return updateProduct(updatedProduct);
  }

  void _upsertLocalProduct(Product product) {
    final idx = _products.indexWhere(
          (p) =>
      (product.id > 0 && p.id == product.id) ||
          (product.sku.isNotEmpty && p.sku == product.sku),
    );
    if (idx != -1) {
      final list = List<Product>.from(_products);
      list[idx] = product;
      _products = list;
    } else {
      _products = [product, ..._products];
    }
    _mergeProductCategories(_categories);
  }

  int _nextLocalId() {
    if (_products.isEmpty) return 1;
    final maxId = _products.fold<int>(0, (max, p) => p.id > max ? p.id : max);
    return maxId + 1;
  }
}