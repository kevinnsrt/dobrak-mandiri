import 'package:dobrak_mandiri_app/data/models/user_session.dart';
import 'package:dobrak_mandiri_app/data/services/api_client.dart';
import 'package:dobrak_mandiri_app/data/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';

class LoginResult {
  final bool isSuccess;
  final String message;
  final UserSession? session;

  const LoginResult({
    required this.isSuccess,
    required this.message,
    this.session,
  });
}

/// Service REST API autentikasi karyawan PT. Dobrak Mandiri.
class AuthService {
  AuthService({
    required ApiClient apiClient,
    required LocalStorageService localStorage,
  })  : _apiClient = apiClient,
        _localStorage = localStorage;

  final ApiClient _apiClient;
  final LocalStorageService _localStorage;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final decoded = await _apiClient.postJson(
        '/auth/login',
        body: {
          'email': email.trim(),
          'password': password,
        },
      );

      if (decoded is! Map<String, dynamic>) {
        return const LoginResult(
          isSuccess: false,
          message: 'Format respons login dari server tidak valid.',
        );
      }

      final dataObj = decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : null;

      final extractedToken = decoded['token'] as String? ??
          decoded['accessToken'] as String? ??
          dataObj?['token'] as String? ??
          dataObj?['accessToken'] as String?;

      if (extractedToken == null || extractedToken.isEmpty) {
        return const LoginResult(
          isSuccess: false,
          message: 'Token autentikasi tidak ditemukan dalam respons server.',
        );
      }

      final userObj = dataObj?['user'] is Map<String, dynamic>
          ? dataObj!['user'] as Map<String, dynamic>
          : null;

      final role = userObj?['role']?.toString() ??
          decoded['role']?.toString() ??
          'KASIR';
      final userName = userObj?['nama']?.toString() ??
          userObj?['name']?.toString() ??
          'Kasir Toko';
      final userEmail = userObj?['email']?.toString() ?? email.trim();

      final session = UserSession(
        token: extractedToken,
        name: userName,
        email: userEmail,
        rawRole: role,
      );

      await _localStorage.saveSession(session);

      return LoginResult(
        isSuccess: true,
        message: decoded['message']?.toString() ?? 'Login berhasil.',
        session: session,
      );
    } on ApiHttpException catch (e) {
      return LoginResult(isSuccess: false, message: e.message);
    } on ApiNetworkException catch (e) {
      return LoginResult(isSuccess: false, message: e.message);
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      return LoginResult(
        isSuccess: false,
        message: 'Terjadi kesalahan saat login: $e',
      );
    }
  }

  Future<void> logout() async {
    try {
      final token = await _localStorage.getToken();
      if (token != null && token.isNotEmpty && !token.startsWith('local-demo-')) {
        await _apiClient.postJson(
          '/auth/logout',
          headers: ApiClient.defaultHeaders(token: token),
        );
      }
    } catch (e) {
      debugPrint('Logout API warning (local session will still be cleared): $e');
    } finally {
      await _localStorage.clearSession();
    }
  }
}
