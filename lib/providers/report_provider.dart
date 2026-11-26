import 'package:dobrak_mandiri_app/data/models/sales_report.dart';
import 'package:dobrak_mandiri_app/data/models/transaction.dart';
import 'package:dobrak_mandiri_app/data/repositories/transaction_repository.dart';
import 'package:flutter/foundation.dart';

/// Provider laporan penjualan harian/mingguan/bulanan & riwayat transaksi real-time.
class ReportProvider extends ChangeNotifier {
  ReportProvider({required TransactionRepository transactionRepository})
      : _repository = transactionRepository;

  final TransactionRepository _repository;

  bool _isLoading = false;
  bool _hasError = false;
  String? _statusMessage;
  ReportPeriod _selectedPeriod = ReportPeriod.daily;
  DateTime _selectedDate = DateTime.now();

  List<Transaction> get allTransactions => _repository.transactions;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get isOfflineFallback => _repository.isOfflineFallback;
  String? get statusMessage => _statusMessage ?? _repository.lastSyncMessage;
  ReportPeriod get selectedPeriod => _selectedPeriod;
  DateTime get selectedDate => _selectedDate;

  /// Laporan dinamis sesuai periode (`Harian`, `Mingguan`, `Bulanan`) & tanggal terpilih.
  SalesReport get currentReport => SalesReport.fromTransactions(
        allTransactions: allTransactions,
        period: _selectedPeriod,
        referenceDate: _selectedDate,
      );

  /// Ringkasan hari ini secara real-time (untuk dashboard kasir & ringkasan cepat).
  SalesReport get todayReport => SalesReport.fromTransactions(
        allTransactions: allTransactions,
        period: ReportPeriod.daily,
        referenceDate: DateTime.now(),
      );

  /// Ringkasan bulan berjalan secara real-time.
  SalesReport get currentMonthReport => SalesReport.fromTransactions(
        allTransactions: allTransactions,
        period: ReportPeriod.monthly,
        referenceDate: DateTime.now(),
      );

  Future<void> loadTransactions() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final result = await _repository.loadTransactions();
      _hasError = !result.isSuccess;
      _statusMessage = result.isSuccess && !result.isOfflineMode
          ? null
          : result.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPeriod(ReportPeriod period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    notifyListeners();
  }

  void setReferenceDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<Transaction?> fetchTransactionDetail(Transaction trx) {
    return _repository.fetchTransactionDetail(trx);
  }

  /// Dipanggil setelah transaksi POS baru selesai agar riwayat & grafik langsung terbarui.
  void notifyTransactionsSynchronized() {
    notifyListeners();
  }
}
