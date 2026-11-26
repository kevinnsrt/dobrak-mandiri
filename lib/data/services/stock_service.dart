import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:dobrak_mandiri_app/data/models/product.dart';
import 'package:dobrak_mandiri_app/data/services/api_client.dart';
import 'package:dobrak_mandiri_app/data/services/local_storage_service.dart';

/// Service REST API manajemen stok & produk PT. Dobrak Mandiri.
class StockService {
  StockService({
    required ApiClient apiClient,
    required LocalStorageService localStorage,
  })  : _apiClient = apiClient,
        _localStorage = localStorage;

  final ApiClient _apiClient;
  final LocalStorageService _localStorage;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _localStorage.getToken();
    return ApiClient.defaultHeaders(token: token);
  }

  Future<List<Product>> fetchProducts() async {
    final headers = await _authHeaders();
    final decoded = await _apiClient.getJson(
      '/stok?per_page=1000&limit=1000&all=true',
      headers: headers,
    );

    final objects = ApiClient.extractObjectList(
      decoded,
      ['data', 'stok', 'items', 'result'],
    );
    return objects.map(Product.fromJson).toList();
  }

  Future<List<String>> fetchCategories() async {
    try {
      final headers = await _authHeaders();
      final decoded = await _apiClient.getJson('/kategori', headers: headers);
      final objects = ApiClient.extractObjectList(
        decoded,
        ['data', 'kategori', 'result'],
      );
      final categories = <String>{};

      if (objects.isNotEmpty) {
        for (final item in objects) {
          final name = item['nama_kategori']?.toString() ??
              item['nama']?.toString() ??
              item['name']?.toString();
          if (name != null && name.isNotEmpty) categories.add(name);
        }
      } else if (decoded is List) {
        for (final item in decoded) {
          if (item is String && item.isNotEmpty) categories.add(item);
        }
      }

      if (categories.isNotEmpty) return categories.toList();
    } catch (_) {
      // Fallback ke daftar default jika endpoint /kategori tidak tersedia.
    }
    return List<String>.from(AppConstants.defaultCategories);
  }

  Future<Product> createProduct(Product product) async {
    final headers = await _authHeaders();
    final decoded = await _apiClient.postJson(
      '/stok',
      headers: headers,
      body: product.toApiPayload(),
    );

    final list = ApiClient.extractObjectList(
      decoded,
      ['data', 'stok', 'result'],
    );
    if (list.isNotEmpty) {
      return Product.fromJson(list.first);
    }
    if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
      return Product.fromJson(decoded['data'] as Map<String, dynamic>);
    }
    return product;
  }

  Future<Product> updateProduct(Product product) async {
    final headers = await _authHeaders();
    final idSegment = product.id > 0 ? product.id.toString() : product.sku;
    final decoded = await _apiClient.putJson(
      '/stok/$idSegment',
      headers: headers,
      body: product.toApiPayload(),
    );

    final list = ApiClient.extractObjectList(
      decoded,
      ['data', 'stok', 'result'],
    );
    if (list.isNotEmpty) {
      return Product.fromJson(list.first);
    }
    if (decoded is Map<String, dynamic> && decoded['data'] is Map<String, dynamic>) {
      return Product.fromJson(decoded['data'] as Map<String, dynamic>);
    }
    return product;
  }
}
