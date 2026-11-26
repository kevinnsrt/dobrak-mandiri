import 'package:dobrak_mandiri_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Entitas produk/barang toko bangunan PT. Dobrak Mandiri.
class Product {
  final int id;
  final String sku;
  final String name;
  final String category;
  final double price;
  final int stock;
  final int minStock;
  final String location;
  final String unit;

  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.minStock = AppConstants.defaultMinStock,
    this.location = 'Gudang Utama',
    this.unit = 'Unit',
  });

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= minStock;
  bool get isSafeStock => stock > minStock;

  String get stockStatusLabel {
    if (isOutOfStock) return 'Habis';
    if (isLowStock) return 'Menipis';
    return 'Aman';
  }

  IconData get categoryIcon => iconForCategory(category);

  static IconData iconForCategory(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('pipa') || lower.contains('sanitari')) {
      return Icons.plumbing;
    }
    if (lower.contains('cat') || lower.contains('pelapis')) {
      return Icons.format_paint;
    }
    if (lower.contains('perkakas') || lower.contains('alat') || lower.contains('hardware')) {
      return Icons.hardware;
    }
    return Icons.inventory_2;
  }

  Product copyWith({
    int? id,
    String? sku,
    String? name,
    String? category,
    double? price,
    int? stock,
    int? minStock,
    String? location,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      location: location ?? this.location,
      unit: unit ?? this.unit,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawSku = json['kode_sku']?.toString() ??
        json['sku']?.toString() ??
        json['kode']?.toString() ??
        json['kode_barang']?.toString();

    final parsedId = (json['id_produk'] as num?)?.toInt() ??
        (json['id'] as num?)?.toInt() ??
        (json['id_stok'] as num?)?.toInt() ??
        int.tryParse(json['id_produk']?.toString() ?? '') ??
        int.tryParse(json['id']?.toString() ?? '') ??
        int.tryParse((rawSku ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;

    final sku = (rawSku != null && rawSku.isNotEmpty)
        ? rawSku
        : (parsedId > 0 ? 'SKU-$parsedId' : 'SKU-000');

    final name = json['nama_produk']?.toString() ??
        json['nama']?.toString() ??
        json['nama_barang']?.toString() ??
        json['name']?.toString() ??
        'Barang Tanpa Nama';

    String category = 'Bahan Bangunan';
    final rawCategory = json['kategori'] ?? json['category'] ?? json['kategori_relasi'];
    if (rawCategory is Map<String, dynamic>) {
      category = rawCategory['nama_kategori']?.toString() ??
          rawCategory['nama']?.toString() ??
          rawCategory['name']?.toString() ??
          'Bahan Bangunan';
    } else if (rawCategory != null && rawCategory.toString().isNotEmpty) {
      category = rawCategory.toString();
    } else {
      category = json['kategori_nama']?.toString() ??
          json['nama_kategori']?.toString() ??
          json['category_name']?.toString() ??
          'Bahan Bangunan';
    }

    final price = _parseDouble(
      json['harga'] ?? json['harga_jual'] ?? json['price'],
      fallback: 0.0,
    );

    final stock = _parseInt(
      json['kuantitas'] ?? json['stok'] ?? json['jumlah'] ?? json['stock'],
      fallback: 0,
    );

    final minStock = _parseInt(
      json['stok_minimum'] ?? json['min_stok'] ?? json['min_stock'],
      fallback: AppConstants.defaultMinStock,
    );

    final location = json['lokasi']?.toString() ??
        json['lokasi_gudang']?.toString() ??
        json['gudang']?.toString() ??
        json['location']?.toString() ??
        'Gudang Utama';

    final unit = json['satuan']?.toString() ??
        json['unit']?.toString() ??
        'Unit';

    return Product(
      id: parsedId,
      sku: sku,
      name: name,
      category: category,
      price: price,
      stock: stock < 0 ? 0 : stock,
      minStock: minStock < 0 ? 0 : minStock,
      location: location.isEmpty ? 'Gudang Utama' : location,
      unit: unit.isEmpty ? 'Unit' : unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_produk': id,
      'kode_sku': sku,
      'nama_produk': name,
      'kategori': category,
      'harga': price,
      'kuantitas': stock,
      'stok_minimum': minStock,
      'lokasi': location,
      'satuan': unit,
    };
  }

  /// Payload untuk endpoint POST/PUT `/stok`.
  Map<String, dynamic> toApiPayload() {
    return {
      'kode_sku': sku,
      'sku': sku,
      'nama_produk': name,
      'nama': name,
      'kuantitas': stock,
      'stok': stock,
      'harga': price,
      'harga_jual': price,
      'kategori': category,
      'lokasi': location,
      'satuan': unit,
      'unit': unit,
      'stok_minimum': minStock,
      'min_stok': minStock,
    };
  }

  static int _parseInt(dynamic val, {int fallback = 0}) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? fallback;
    return fallback;
  }

  static double _parseDouble(dynamic val, {double fallback = 0.0}) {
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? fallback;
    return fallback;
  }
}
