import 'package:dobrak_mandiri_app/core/config/api_config.dart';
import 'package:dobrak_mandiri_app/data/models/user_session.dart';
import 'package:dobrak_mandiri_app/data/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

/// Provider manajemen autentikasi & sesi karyawan PT. Dobrak Mandiri.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  final AuthRepository _authRepository;

  UserSession? _session;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _baseUrl = ApiConfig.defaultBaseUrl;

  UserSession? get session => _session;
  bool get isAuthenticated => _session != null && _session!.token.isNotEmpty;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get baseUrl => _baseUrl;

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    try {
      _baseUrl = await _authRepository.getBaseUrl();
      _session = await _authRepository.getCurrentSession();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(
        email: email,
        password: password,
      );
      if (result.isSuccess && result.session != null) {
        _session = result.session;
        return true;
      }
      _errorMessage = result.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginOfflineDemo(UserRole role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = await _authRepository.loginOfflineDemo(role: role);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();
      _session = null;
      _errorMessage = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateServerUrl(String newUrl) async {
    await _authRepository.updateBaseUrl(newUrl);
    _baseUrl = ApiConfig.baseUrl;
    notifyListeners();
  }
}
