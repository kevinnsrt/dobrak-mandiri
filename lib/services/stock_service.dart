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
}
