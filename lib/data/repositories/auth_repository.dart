import 'package:dobrak_mandiri_app/data/models/user_session.dart';
import 'package:dobrak_mandiri_app/data/services/auth_service.dart';
import 'package:dobrak_mandiri_app/data/services/local_storage_service.dart';

/// Repository autentikasi & manajemen sesi lokal/offline demo.
class AuthRepository {
  AuthRepository({
    required AuthService authService,
    required LocalStorageService localStorage,
  })  : _authService = authService,
        _localStorage = localStorage;

  final AuthService _authService;
  final LocalStorageService _localStorage;

  Future<UserSession?> getCurrentSession() {
    return _localStorage.loadSession();
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) {
    return _authService.login(email: email, password: password);
  }

  /// Masuk dengan sesi lokal (offline) saat backend belum aktif atau untuk pengujian single-store.
  Future<UserSession> loginOfflineDemo({
    required UserRole role,
    String? customName,
  }) async {
    final defaultName = switch (role) {
      UserRole.cashier => 'Kasir Utama Toko',
      UserRole.inventory => 'Staf Gudang',
      UserRole.owner => 'Manager Toko',
    };
    final defaultEmail = switch (role) {
      UserRole.cashier => 'kasir@dobrakmandiri.local',
      UserRole.inventory => 'gudang@dobrakmandiri.local',
      UserRole.owner => 'owner@dobrakmandiri.local',
    };

    final session = UserSession(
      token: 'local-demo-${role.name}-${DateTime.now().millisecondsSinceEpoch}',
      name: customName ?? defaultName,
      email: defaultEmail,
      rawRole: role.displayLabel,
      isLocalDemo: true,
    );

    await _localStorage.saveSession(session);
    return session;
  }

  Future<void> logout() {
    return _authService.logout();
  }

  Future<String> getBaseUrl() => _localStorage.loadBaseUrl();

  Future<void> updateBaseUrl(String url) => _localStorage.saveBaseUrl(url);
}
