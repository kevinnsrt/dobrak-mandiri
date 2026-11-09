import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginResult {
  final bool isSuccess;
  final String message;
  final String? token;
  final String? role;
  final String? userName;

  const LoginResult({
    required this.isSuccess,
    required this.message,
    this.token,
    this.role,
    this.userName,
  });
}

class AuthService {
  // Base URL REST API Authentication
  static const String baseUrl = 'http://172.20.10.2:8080/api/v1';

  // Key untuk penyimpanan SharedPreferences
  static const String keyToken = 'bearer_token';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyUserRole = 'user_role';

  /// In-memory storage fallback agar login tetap sukses tanpa crash jika plugin belum dire-register
  static String? _inMemoryToken;
  static String? _inMemoryEmail;
  static String? _inMemoryName;
  static String? _inMemoryRole;

  /// Fungsi untuk melakukan HTTP POST Request Login ke REST API
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final Uri loginUri = Uri.parse('$baseUrl/auth/login');

    try {
      debugPrint("Mengirim request login ke: $loginUri");

      final response = await http.post(
        loginUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint("Status Code Login API: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body) as Map<String, dynamic>;

      final bool isApiSuccess = responseData['success'] as bool? ?? (response.statusCode == 200 || response.statusCode == 201);

      if (isApiSuccess) {
        // Ekstraksi data token & user dari API
        final dataObj = responseData['data'] is Map<String, dynamic> ? responseData['data'] as Map<String, dynamic> : null;

        String? extractedToken = responseData['token'] as String? ??
            responseData['accessToken'] as String? ??
            dataObj?['token'] as String? ??
            dataObj?['accessToken'] as String?;

        final userObj = dataObj?['user'] is Map<String, dynamic> ? dataObj!['user'] as Map<String, dynamic> : null;
        String? role = userObj?['role'] as String? ?? responseData['role'] as String?;
        String? userName = userObj?['nama'] as String? ?? userObj?['name'] as String?;
        String? userEmail = userObj?['email'] as String? ?? email.trim();

        if (extractedToken != null && extractedToken.isNotEmpty) {
          // Simpan ke in-memory fallback dahulu
          _inMemoryToken = extractedToken;
          _inMemoryEmail = userEmail;
          _inMemoryName = userName;
          _inMemoryRole = role;

          // Simpan ke SharedPreferences disk
          try {
            await saveToken(extractedToken);
            await saveUserEmail(userEmail);
            if (role != null) await saveUserRole(role);
            if (userName != null) await saveUserName(userName);
          } catch (storageError) {
            debugPrint("Warning SharedPreferences write diabaikan: $storageError");
          }

          return LoginResult(
            isSuccess: true,
            message: responseData['message'] as String? ?? 'Login berhasil.',
            token: extractedToken,
            role: role,
            userName: userName,
          );
        } else {
          return const LoginResult(
            isSuccess: false,
            message: 'Token tidak ditemukan dalam respon server.',
          );
        }
      } else {
        String errorMessage = responseData['message'] as String? ??
            responseData['error'] as String? ??
            'Login gagal. Periksa email dan kata sandi Anda (Status: ${response.statusCode})';

        return LoginResult(
          isSuccess: false,
          message: errorMessage,
        );
      }
    } catch (e) {
      debugPrint("Error saat koneksi ke API Login: $e");

      return LoginResult(
        isSuccess: false,
        message: 'Gagal terhubung ke server (http://172.20.10.2:8080). Pastikan jaringan terhubung.\nDetail: ${e.toString()}',
      );
    }
  }

  /// Menyimpan Bearer Token ke SharedPreferences
  static Future<bool> saveToken(String token) async {
    _inMemoryToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(keyToken, token);
      debugPrint("saveToken SharedPreferences status: $success");
      return success;
    } catch (e) {
      debugPrint("Warning SharedPreferences saveToken (membutuhkan Full Rebuild App): $e");
      return false;
    }
  }

  /// Mengambil Bearer Token yang tersimpan
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final diskToken = prefs.getString(keyToken);
      debugPrint("getToken from disk: $diskToken, fallback inMemory: $_inMemoryToken");
      return diskToken ?? _inMemoryToken;
    } catch (e) {
      debugPrint("Warning SharedPreferences getToken: $e");
      return _inMemoryToken;
    }
  }

  /// Mengambil Header Authorization dengan format "Bearer {token}"
  static Future<Map<String, String>> getAuthHeader() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Menyimpan Email Pengguna
  static Future<bool> saveUserEmail(String email) async {
    _inMemoryEmail = email;
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(keyUserEmail, email);
    } catch (e) {
      return false;
    }
  }

  /// Mengambil Email Pengguna
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyUserEmail) ?? _inMemoryEmail;
    } catch (e) {
      return _inMemoryEmail;
    }
  }

  /// Menyimpan Nama Pengguna
  static Future<bool> saveUserName(String name) async {
    _inMemoryName = name;
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(keyUserName, name);
    } catch (e) {
      return false;
    }
  }

  /// Mengambil Nama Pengguna
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyUserName) ?? _inMemoryName;
    } catch (e) {
      return _inMemoryName;
    }
  }

  /// Menyimpan Role Pengguna
  static Future<bool> saveUserRole(String role) async {
    _inMemoryRole = role;
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(keyUserRole, role);
    } catch (e) {
      return false;
    }
  }

  /// Mengambil Role Pengguna
  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyUserRole) ?? _inMemoryRole;
    } catch (e) {
      return _inMemoryRole;
    }
  }

  /// Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    final hasToken = token != null && token.isNotEmpty;
    debugPrint("isLoggedIn check: $hasToken");
    return hasToken;
  }

  /// Hapus Token & Session via HTTP POST Request ke REST API /auth/logout
  static Future<bool> logout() async {
    final Uri logoutUri = Uri.parse('$baseUrl/auth/logout');

    try {
      final headers = await getAuthHeader();
      debugPrint("Mengirim request logout ke: $logoutUri dengan header: $headers");

      final response = await http.post(
        logoutUri,
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      debugPrint("Status Code Logout API: ${response.statusCode}");
      debugPrint("Response Body Logout: ${response.body}");
    } catch (e) {
      debugPrint("Warning error saat panggil API Logout: $e");
    } finally {
      // Selalu bersihkan sesi lokal (in-memory dan SharedPreferences)
      _inMemoryToken = null;
      _inMemoryEmail = null;
      _inMemoryName = null;
      _inMemoryRole = null;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(keyToken);
        await prefs.remove(keyUserEmail);
        await prefs.remove(keyUserName);
        await prefs.remove(keyUserRole);
      } catch (e) {
        debugPrint("Warning SharedPreferences logout clear error: $e");
      }
    }

    return true;
  }
}
