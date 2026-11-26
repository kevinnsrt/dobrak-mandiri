/// Helper pemformatan mata uang Rupiah tanpa ketergantungan locale eksternal.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final RegExp _thousandsRegex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

  /// Format lengkap, contoh: `Rp 68.000` atau `-Rp 5.000`.
  static String formatRupiah(num amount) {
    final isNegative = amount < 0;
    final absValue = amount.abs().round();
    final formatted = absValue
        .toString()
        .replaceAllMapped(_thousandsRegex, (m) => '${m[1]}.');
    return isNegative ? '-Rp $formatted' : 'Rp $formatted';
  }

  /// Format ringkas untuk label grafik, contoh: `1.5Jt` atau `68Rb`.
  static String formatCompact(num amount) {
    final abs = amount.abs();
    if (abs >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Jt';
    }
    if (abs >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}Rb';
    }
    return amount.toStringAsFixed(0);
  }

  /// Parse string angka yang mungkin berisi titik pemisah ribuan.
  static double parseInput(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }
}
