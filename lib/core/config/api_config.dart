/// Konfigurasi endpoint REST API PT. Dobrak Mandiri.
class ApiConfig {
  ApiConfig._();

  /// Base URL default sesuai konfigurasi backend lokal saat ini.
  static const String defaultBaseUrl = 'https://stelliform.user.cloudjkt02.com/api/v1';

  /// Timeout default untuk panggilan HTTP.
  static const Duration requestTimeout = Duration(seconds: 10);

  static String _baseUrl = defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static void setBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isNotEmpty) {
      _baseUrl = trimmed.endsWith('/')
          ? trimmed.substring(0, trimmed.length - 1)
          : trimmed;
    }
  }

  static void resetBaseUrl() {
    _baseUrl = defaultBaseUrl;
  }

  static Uri endpoint(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalized');
  }
}
