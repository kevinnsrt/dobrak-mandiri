import 'dart:convert';

import 'package:dobrak_mandiri_app/core/config/api_config.dart';
import 'package:dobrak_mandiri_app/data/models/product.dart';
import 'package:dobrak_mandiri_app/data/models/transaction.dart';
import 'package:dobrak_mandiri_app/data/models/user_session.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layanan penyimpanan lokal berbasis SharedPreferences + in-memory cache.
/// Berfungsi sebagai cache sesi, database produk lokal, dan riwayat transaksi offline.
class LocalStorageService {
  static const String keyToken = 'bearer_token';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyUserRole = 'user_role';
  static const String keyIsLocalDemo = 'is_local_demo';
  static const String keyBaseUrl = 'api_base_url';
  static const String keyProducts = 'local_products_v1';
  static const String keyTransactions = 'local_transactions_v1';

  final Map<String, String> _memoryFallback = {};

  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('SharedPreferences fallback active: $e');
      return null;
    }
  }

  Future<void> _setString(String key, String value) async {
    _memoryFallback[key] = value;
    final prefs = await _getPrefs();
    await prefs?.setString(key, value);
  }

  Future<String?> _getString(String key) async {
    final prefs = await _getPrefs();
    return prefs?.getString(key) ?? _memoryFallback[key];
  }

  Future<void> _removeKeys(List<String> keys) async {
    for (final k in keys) {
      _memoryFallback.remove(k);
    }
    final prefs = await _getPrefs();
    if (prefs != null) {
      for (final k in keys) {
        await prefs.remove(k);
      }
    }
  }

  // --- Session Storage ---

  Future<void> saveSession(UserSession session) async {
    await _setString(keyToken, session.token);
    await _setString(keyUserName, session.name);
    await _setString(keyUserEmail, session.email);
    await _setString(keyUserRole, session.rawRole);
    await _setString(keyIsLocalDemo, session.isLocalDemo.toString());
  }

  Future<UserSession?> loadSession() async {
    final token = await _getString(keyToken);
    if (token == null || token.isEmpty) return null;

    final name = await _getString(keyUserName) ?? 'Kasir Toko';
    final email = await _getString(keyUserEmail) ?? '';
    final role = await _getString(keyUserRole) ?? 'KASIR';
    final isDemo = (await _getString(keyIsLocalDemo)) == 'true';

    return UserSession(
      token: token,
      name: name,
      email: email,
      rawRole: role,
      isLocalDemo: isDemo,
    );
  }

  Future<String?> getToken() => _getString(keyToken);

  Future<void> clearSession() async {
    await _removeKeys([
      keyToken,
      keyUserName,
      keyUserEmail,
      keyUserRole,
      keyIsLocalDemo,
    ]);
  }

  // --- Server URL Config ---

  Future<void> saveBaseUrl(String url) async {
    ApiConfig.setBaseUrl(url);
    await _setString(keyBaseUrl, ApiConfig.baseUrl);
  }

  Future<String> loadBaseUrl() async {
    final saved = await _getString(keyBaseUrl);
    if (saved != null && saved.isNotEmpty) {
      ApiConfig.setBaseUrl(saved);
    }
    return ApiConfig.baseUrl;
  }

  // --- Local Products Storage ---

  Future<void> saveProducts(List<Product> products) async {
    final encoded = jsonEncode(products.map((p) => p.toJson()).toList());
    await _setString(keyProducts, encoded);
  }

  Future<List<Product>> loadProducts() async {
    final raw = await _getString(keyProducts);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Product.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('Failed decoding cached products: $e');
    }
    return [];
  }

  // --- Local Transactions Storage ---

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final encoded = jsonEncode(transactions.map((t) => t.toJson()).toList());
    await _setString(keyTransactions, encoded);
  }

  Future<List<Transaction>> loadTransactions() async {
    final raw = await _getString(keyTransactions);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Transaction.fromJson)
            .toList();
      }
    } catch (e) {
      debugPrint('Failed decoding cached transactions: $e');
    }
    return [];
  }

  /// Seed awal produk bahan bangunan PT. Dobrak Mandiri untuk mode lokal/offline pertama kali.
  static List<Product> get defaultSeedProducts => const [
        Product(
          id: 1,
          sku: 'SKU-1001',
          name: 'Semen Portland 50kg',
          category: 'Bahan Bangunan',
          price: 68000,
          stock: 120,
          minStock: 20,
          location: 'Gudang A - Rak 01',
          unit: 'Sak',
        ),
        Product(
          id: 2,
          sku: 'SKU-1002',
          name: 'Pipa PVC 2 Inci (4m)',
          category: 'Pipa & Sanitari',
          price: 45000,
          stock: 40,
          minStock: 10,
          location: 'Gudang B - Rak 04',
          unit: 'Batang',
        ),
        Product(
          id: 3,
          sku: 'SKU-1003',
          name: 'Cat Tembok Vinilex 5kg',
          category: 'Cat & Pelapis',
          price: 135000,
          stock: 25,
          minStock: 5,
          location: 'Gudang C - Rak 02',
          unit: 'Kaleng',
        ),
        Product(
          id: 4,
          sku: 'SKU-1004',
          name: 'Paku Kayu 5cm (1kg)',
          category: 'Perkakas & Hardware',
          price: 22000,
          stock: 80,
          minStock: 15,
          location: 'Gudang A - Rak 09',
          unit: 'Kg',
        ),
        Product(
          id: 5,
          sku: 'SKU-1005',
          name: 'Besi Beton Polos 10mm (12m)',
          category: 'Bahan Bangunan',
          price: 89000,
          stock: 5,
          minStock: 10,
          location: 'Gudang Luar - Blok B',
          unit: 'Batang',
        ),
        Product(
          id: 6,
          sku: 'SKU-1006',
          name: 'Keramik Lantai 40x40 Putih',
          category: 'Bahan Bangunan',
          price: 58000,
          stock: 64,
          minStock: 12,
          location: 'Gudang A - Rak 05',
          unit: 'Dus',
        ),
      ];
}
