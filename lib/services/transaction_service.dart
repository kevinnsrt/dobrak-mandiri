import 'dart:convert';
import 'package:dobrak_mandiri_app/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TransactionApiResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? data;

  const TransactionApiResult({
    required this.isSuccess,
    required this.message,
    this.data,
  });
}

class TransactionListResult {
  final bool isSuccess;
  final String message;
  final List<dynamic>? transactions;

  const TransactionListResult({
    required this.isSuccess,
    required this.message,
    this.transactions,
  });
}

class TransactionDetailResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? transaction;

  const TransactionDetailResult({
    required this.isSuccess,
    required this.message,
    this.transaction,
  });
}

class TransactionService {
  static const String baseUrl = 'http://172.20.10.2:8080/api/v1';

  /// Mengirim HTTP POST Transaksi ke REST API http://172.20.10.2:8080/api/v1/transaksi dengan Bearer Token
  static Future<TransactionApiResult> createTransaction({
    required String paymentMethod,
    required double subtotal,
    required double ppn,
    required double grandTotal,
    required double cashPaid,
    required double change,
    required List<Map<String, dynamic>> items,
  }) async {
    final Uri uri = Uri.parse('$baseUrl/transaksi');

    try {
      final headers = await AuthService.getAuthHeader();
      final String upperPaymentMethod = paymentMethod.toUpperCase();
      final int amountPaidInt = (upperPaymentMethod == 'TUNAI' ? cashPaid : grandTotal).toInt();

      // Payload sesuai dengan cURL spesifikasi backend
      final body = {
        'jenis_pembayaran': upperPaymentMethod,
        'jumlah_bayar': amountPaidInt,
        'detail': items,
      };

      debugPrint("Mengirim POST Transaksi ke: $uri");
      debugPrint("Payload Transaksi: ${jsonEncode(body)}");

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      debugPrint("Status Code POST /transaksi: ${response.statusCode}");
      debugPrint("Response Body POST /transaksi: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body) as Map<String, dynamic>;

      final bool isSuccess = responseData['success'] as bool? ?? (response.statusCode == 200 || response.statusCode == 201);

      if (isSuccess) {
        return TransactionApiResult(
          isSuccess: true,
          message: responseData['message'] as String? ?? 'Transaksi berhasil diproses!',
          data: responseData['data'] is Map<String, dynamic> ? responseData['data'] as Map<String, dynamic> : responseData,
        );
      } else {
        String msg = responseData['message'] as String? ?? 'Data yang dikirim tidak valid.';

        // Ekstraksi rincian error validasi dari objek "errors" jika ada
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

        return TransactionApiResult(isSuccess: false, message: msg);
      }
    } catch (e) {
      debugPrint("Error saat POST /transaksi: $e");
      return TransactionApiResult(
        isSuccess: false,
        message: 'Gagal terhubung ke server transaksi: ${e.toString()}',
      );
    }
  }

  /// Mengambil daftar transaksi dari HTTP GET http://172.20.10.2:8080/api/v1/transaksi dengan Bearer Token
  static Future<TransactionListResult> fetchTransactions() async {
    final Uri uri = Uri.parse('$baseUrl/transaksi?per_page=1000&limit=1000');

    try {
      final headers = await AuthService.getAuthHeader();
      debugPrint("Mengirim GET request ke: $uri");

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      debugPrint("Status Code GET /transaksi: ${response.statusCode}");
      debugPrint("Response Body GET /transaksi: ${response.body}");

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        List<dynamic> list = [];

        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map<String, dynamic>) {
          final dataField = decoded['data'] ?? decoded['transaksi'] ?? decoded['result'];
          if (dataField is List) {
            list = dataField;
          } else if (dataField is Map<String, dynamic>) {
            final nestedList = dataField['data'] ?? dataField['transaksi'] ?? dataField['result'];
            if (nestedList is List) {
              list = nestedList;
            }
          }
        }

        return TransactionListResult(
          isSuccess: true,
          message: 'Daftar transaksi berhasil dimuat.',
          transactions: list,
        );
      } else {
        String msg = 'Gagal mengambil riwayat transaksi (Status ${response.statusCode})';
        if (decoded is Map<String, dynamic>) {
          msg = decoded['message'] as String? ?? decoded['error'] as String? ?? msg;
        }
        return TransactionListResult(isSuccess: false, message: msg);
      }
    } catch (e) {
      debugPrint("Error saat GET /transaksi: $e");
      return TransactionListResult(
        isSuccess: false,
        message: 'Gagal terhubung ke server transaksi: ${e.toString()}',
      );
    }
  }

  /// Mengambil detail transaksi spesifik dari HTTP GET http://172.20.10.2:8080/api/v1/transaksi/{id}
  static Future<TransactionDetailResult> fetchTransactionDetail(int id) async {
    final Uri uri = Uri.parse('$baseUrl/transaksi/$id');

    try {
      final headers = await AuthService.getAuthHeader();
      debugPrint("Mengirim GET request detail transaksi ke: $uri");

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      debugPrint("Status Code GET /transaksi/$id: ${response.statusCode}");
      debugPrint("Response Body GET /transaksi/$id: ${response.body}");

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic>? trxData;

        if (decoded is Map<String, dynamic>) {
          final dataField = decoded['data'] ?? decoded['transaksi'] ?? decoded['result'];
          if (dataField is Map<String, dynamic>) {
            trxData = dataField;
          } else {
            trxData = decoded;
          }
        }

        return TransactionDetailResult(
          isSuccess: true,
          message: 'Detail transaksi berhasil dimuat.',
          transaction: trxData,
        );
      } else {
        String msg = 'Gagal mengambil detail transaksi (Status ${response.statusCode})';
        if (decoded is Map<String, dynamic>) {
          msg = decoded['message'] as String? ?? decoded['error'] as String? ?? msg;
        }
        return TransactionDetailResult(isSuccess: false, message: msg);
      }
    } catch (e) {
      debugPrint("Error saat GET /transaksi/$id: $e");
      return TransactionDetailResult(
        isSuccess: false,
        message: 'Gagal terhubung ke server transaksi: ${e.toString()}',
      );
    }
  }
}
