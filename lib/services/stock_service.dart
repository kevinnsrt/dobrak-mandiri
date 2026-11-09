import 'dart:convert';
import 'package:dobrak_mandiri_app/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StockApiResult {
  final bool isSuccess;
  final String message;
  final List<dynamic>? data;

  const StockApiResult({
    required this.isSuccess,
    required this.message,
    this.data,
  });
}

class StockService {
  static const String baseUrl = 'http://172.20.10.2:8080/api/v1';

  /// Mengambil data daftar stok dari HTTP GET http://172.20.10.2:8080/api/v1/stok dengan per_page=1000
  static Future<StockApiResult> fetchStockList() async {
    // Tambahkan per_page=1000 & limit=1000 agar backend mengirimkan seluruh daftar stok tanpa terpotong paginasi
    final Uri uri = Uri.parse('$baseUrl/stok?per_page=1000&limit=1000&all=true');

    try {
      final headers = await AuthService.getAuthHeader();
      debugPrint("Mengirim GET request ke: $uri dengan headers: $headers");

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      debugPrint("Status Code GET /stok: ${response.statusCode}");
      debugPrint("Response Body GET /stok: ${response.body}");

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        List<dynamic> items = [];

        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map<String, dynamic>) {
          // Cari field array di data, stok, items, atau result
          final dataField = decoded['data'] ?? decoded['stok'] ?? decoded['items'] ?? decoded['result'];

          if (dataField is List) {
            items = dataField;
          } else if (dataField is Map<String, dynamic>) {
            final nestedList = dataField['data'] ?? dataField['stok'] ?? dataField['items'] ?? dataField['result'];
            if (nestedList is List) {
              items = nestedList;
            }
          }
        }

        debugPrint("Total item stok berhasil di-parse: ${items.length} item");

        return StockApiResult(
          isSuccess: true,
          message: decoded is Map ? (decoded['message'] as String? ?? 'Data stok berhasil dimuat.') : 'Data stok berhasil dimuat.',
          data: items,
        );
      } else {
        String msg = 'Gagal mengambil data stok (Status: ${response.statusCode})';
        if (decoded is Map<String, dynamic>) {
          msg = decoded['message'] as String? ?? decoded['error'] as String? ?? msg;
        }
        return StockApiResult(
          isSuccess: false,
          message: msg,
        );
      }
    } catch (e) {
      debugPrint("Error saat GET /stok: $e");
      return StockApiResult(
        isSuccess: false,
        message: 'Gagal terhubung ke API Stok: ${e.toString()}',
      );
    }
  }

  /// Fungsi stockUpdate untuk menambah/memperbarui stok via HTTP POST http://172.20.10.2:8080/api/v1/stok
  static Future<StockApiResult> stockUpdate({
    required String kodeSku,
    required String namaProduk,
    required int kuantitas,
    double? harga,
    String? kategori,
    String? lokasi,
    String? satuan,
    int? stokMinimum,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/stok');

    try {
      final headers = await AuthService.getAuthHeader();

      final body = {
        'kode_sku': kodeSku,
        'sku': kodeSku,
        'nama_produk': namaProduk,
        'nama': namaProduk,
        'kuantitas': kuantitas,
        'stok': kuantitas,
        if (harga != null) 'harga': harga,
        if (harga != null) 'harga_jual': harga,
        if (kategori != null) 'kategori': kategori,
        if (lokasi != null) 'lokasi': lokasi,
        if (satuan != null) 'satuan': satuan,
        if (satuan != null) 'unit': satuan,
        if (stokMinimum != null) 'stok_minimum': stokMinimum,
        if (stokMinimum != null) 'min_stok': stokMinimum,
      };

      debugPrint("Mengirim POST stockUpdate ke: $uri");
      debugPrint("Payload Stock Update: ${jsonEncode(body)}");

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      debugPrint("Status Code POST /stok: ${response.statusCode}");
      debugPrint("Response Body POST /stok: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body) as Map<String, dynamic>;

      final bool isSuccess = responseData['success'] as bool? ?? (response.statusCode == 200 || response.statusCode == 201);

      if (isSuccess) {
        List<dynamic> items = [];
        final dataField = responseData['data'];
        if (dataField is List) {
          items = dataField;
        } else if (dataField is Map<String, dynamic>) {
          items = [dataField];
        }

        return StockApiResult(
          isSuccess: true,
          message: responseData['message'] as String? ?? 'Stok berhasil diperbarui.',
          data: items,
        );
      } else {
        String msg = responseData['message'] as String? ?? 'Gagal memperbarui stok.';
        if (responseData['errors'] is Map<String, dynamic>) {
          final Map<String, dynamic> errorsMap = responseData['errors'] as Map<String, dynamic>;
          final List<String> errList = [];
          errorsMap.forEach((key, val) {
            if (val is List) {
              errList.addAll(val.map((e) => e.toString()));
            } else if (val is String) {
              errList.add(val);
            }
          });
          if (errList.isNotEmpty) {
            msg = "$msg\n• ${errList.join('\n• ')}";
          }
        }
        return StockApiResult(
          isSuccess: false,
          message: msg,
        );
      }
    } catch (e) {
      debugPrint("Error saat POST /stok: $e");
      return StockApiResult(
        isSuccess: false,
        message: 'Gagal terhubung ke server stok: ${e.toString()}',
      );
    }
  }

  /// Fungsi updateStockById untuk memperbarui barang spesifik via HTTP PUT http://172.20.10.2:8080/api/v1/stok/{id_produk}
  static Future<StockApiResult> updateStockById({
    required dynamic id,
    required String kodeSku,
    required String namaProduk,
    required int kuantitas,
    double? harga,
    String? kategori,
    String? lokasi,
    String? satuan,
    int? stokMinimum,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/stok/$id');

    try {
      final headers = await AuthService.getAuthHeader();

      final body = {
        'kode_sku': kodeSku,
        'sku': kodeSku,
        'nama_produk': namaProduk,
        'nama': namaProduk,
        'kuantitas': kuantitas,
        'stok': kuantitas,
        if (harga != null) 'harga': harga,
        if (harga != null) 'harga_jual': harga,
        if (kategori != null) 'kategori': kategori,
        if (lokasi != null) 'lokasi': lokasi,
        if (satuan != null) 'satuan': satuan,
        if (satuan != null) 'unit': satuan,
        if (stokMinimum != null) 'stok_minimum': stokMinimum,
        if (stokMinimum != null) 'min_stok': stokMinimum,
      };

      debugPrint("Mengirim PUT update stock ke: $uri");
      debugPrint("Payload Update Stock: ${jsonEncode(body)}");

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      debugPrint("Status Code PUT /stok/$id: ${response.statusCode}");
      debugPrint("Response Body PUT /stok/$id: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body) as Map<String, dynamic>;

      final bool isSuccess = responseData['success'] as bool? ?? (response.statusCode == 200 || response.statusCode == 201);

      if (isSuccess) {
        List<dynamic> items = [];
        final dataField = responseData['data'];
        if (dataField is List) {
          items = dataField;
        } else if (dataField is Map<String, dynamic>) {
          items = [dataField];
        }

        return StockApiResult(
          isSuccess: true,
          message: responseData['message'] as String? ?? 'Stok berhasil diperbarui.',
          data: items,
        );
      } else {
        String msg = responseData['message'] as String? ?? 'Gagal memperbarui stok.';
        if (responseData['errors'] is Map<String, dynamic>) {
          final Map<String, dynamic> errorsMap = responseData['errors'] as Map<String, dynamic>;
          final List<String> errList = [];
          errorsMap.forEach((key, val) {
            if (val is List) {
              errList.addAll(val.map((e) => e.toString()));
            } else if (val is String) {
              errList.add(val);
            }
          });
          if (errList.isNotEmpty) {
            msg = "$msg\n• ${errList.join('\n• ')}";
          }
        }
        return StockApiResult(
          isSuccess: false,
          message: msg,
        );
      }
    } catch (e) {
      debugPrint("Error saat PUT /stok/$id: $e");
      return StockApiResult(
        isSuccess: false,
        message: 'Gagal terhubung ke server stok: ${e.toString()}',
      );
    }
  }
}
