import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dobrak_mandiri_app/core/config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Exception untuk kegagalan jaringan (server tidak terjangkau / timeout).
class ApiNetworkException implements Exception {
  final String message;

  const ApiNetworkException(this.message);

  @override
  String toString() => message;
}

/// Exception untuk respons error dari server REST API (4xx / 5xx).
class ApiHttpException implements Exception {
  final int statusCode;
  final String message;

  const ApiHttpException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Wrapper HTTP client terpusat untuk komunikasi dengan REST API backend.
class ApiClient {
  ApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      () => _httpClient.get(
        ApiConfig.endpoint(path),
        headers: headers ?? defaultHeaders(),
      ),
      'GET $path',
    );
  }

  Future<dynamic> postJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    return _sendRequest(
      () => _httpClient.post(
        ApiConfig.endpoint(path),
        headers: headers ?? defaultHeaders(),
        body: body == null ? null : jsonEncode(body),
      ),
      'POST $path',
    );
  }

  Future<dynamic> putJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    return _sendRequest(
      () => _httpClient.put(
        ApiConfig.endpoint(path),
        headers: headers ?? defaultHeaders(),
        body: body == null ? null : jsonEncode(body),
      ),
      'PUT $path',
    );
  }

  static Map<String, String> defaultHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _sendRequest(
    Future<http.Response> Function() requestFn,
    String label,
  ) async {
    try {
      debugPrint('API Request: $label -> ${ApiConfig.baseUrl}');
      final response = await requestFn().timeout(ApiConfig.requestTimeout);
      debugPrint('API Response ($label): ${response.statusCode}');

      dynamic decoded;
      if (response.body.isNotEmpty) {
        try {
          decoded = jsonDecode(response.body);
        } on FormatException {
          decoded = {'message': response.body};
        }
      }

      final isHttpOk = response.statusCode >= 200 && response.statusCode < 300;
      final explicitSuccess =
          decoded is Map<String, dynamic> ? decoded['success'] as bool? : null;

      if (isHttpOk && (explicitSuccess ?? true)) {
        return decoded;
      }

      final message = extractErrorMessage(decoded, response.statusCode);
      throw ApiHttpException(response.statusCode, message);
    } on ApiHttpException {
      rethrow;
    } on TimeoutException {
      throw ApiNetworkException(
        'Koneksi ke server timeout (${ApiConfig.baseUrl}).',
      );
    } on SocketException catch (e) {
      throw ApiNetworkException(
        'Server tidak dapat dijangkau (${ApiConfig.baseUrl}): ${e.message}',
      );
    } on http.ClientException catch (e) {
      throw ApiNetworkException(
        'Gagal terhubung ke server (${ApiConfig.baseUrl}): ${e.message}',
      );
    }
  }

  /// Ekstrak list dari variasi struktur JSON REST API (`data`, `stok`, `transaksi`, dll).
  static List<Map<String, dynamic>> extractObjectList(
    dynamic decoded,
    List<String> keys,
  ) {
    List<dynamic> rawList = [];

    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      for (final key in keys) {
        final field = decoded[key];
        if (field is List) {
          rawList = field;
          break;
        }
        if (field is Map<String, dynamic>) {
          for (final nestedKey in keys) {
            final nested = field[nestedKey];
            if (nested is List) {
              rawList = nested;
              break;
            }
          }
          if (rawList.isNotEmpty) break;
        }
      }
    }

    return rawList.whereType<Map<String, dynamic>>().toList();
  }

  static String extractErrorMessage(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      String msg = decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          'Permintaan gagal (Status $statusCode)';

      if (decoded['errors'] is Map<String, dynamic>) {
        final errorsMap = decoded['errors'] as Map<String, dynamic>;
        final details = <String>[];
        errorsMap.forEach((_, value) {
          if (value is List) {
            details.addAll(value.map((e) => e.toString()));
          } else if (value != null) {
            details.add(value.toString());
          }
        });
        if (details.isNotEmpty) {
          msg = '$msg\n• ${details.join('\n• ')}';
        }
      }
      return msg;
    }
    return 'Permintaan gagal (Status $statusCode)';
  }
}
