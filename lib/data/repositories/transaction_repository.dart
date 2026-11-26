import 'package:dobrak_mandiri_app/data/models/cart_item.dart';
import 'package:dobrak_mandiri_app/data/models/transaction.dart';
import 'package:dobrak_mandiri_app/data/models/transaction_item.dart';
import 'package:dobrak_mandiri_app/data/repositories/inventory_repository.dart';
import 'package:dobrak_mandiri_app/data/services/api_client.dart';
import 'package:dobrak_mandiri_app/data/services/local_storage_service.dart';
import 'package:dobrak_mandiri_app/data/services/transaction_service.dart';

class CheckoutResult {
  final bool isSuccess;
  final String message;
  final Transaction? transaction;
  final bool isOfflineSaved;

  const CheckoutResult({
    required this.isSuccess,
    required this.message,
    this.transaction,
    this.isOfflineSaved = false,
  });
}

/// Single Source of Truth untuk riwayat transaksi & pemrosesan checkout POS.
class TransactionRepository {
  TransactionRepository({
    required TransactionService transactionService,
    required LocalStorageService localStorage,
    required InventoryRepository inventoryRepository,
  })  : _transactionService = transactionService,
        _localStorage = localStorage,
        _inventoryRepository = inventoryRepository;

  final TransactionService _transactionService;
  final LocalStorageService _localStorage;
  final InventoryRepository _inventoryRepository;

  List<Transaction> _transactions = [];
  bool _isOfflineFallback = false;
  String? _lastSyncMessage;

  List<Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isOfflineFallback => _isOfflineFallback;
  String? get lastSyncMessage => _lastSyncMessage;

  Future<RepositoryActionResult<List<Transaction>>> loadTransactions() async {
    final localCached = await _localStorage.loadTransactions();
    final session = await _localStorage.loadSession();
    final isDemoSession = session?.isLocalDemo ?? false;

    if (isDemoSession) {
      _transactions = _sortByNewest(localCached);
      _isOfflineFallback = true;
      _lastSyncMessage =
          'Mode Lokal/Offline aktif. Riwayat transaksi dimuat dari perangkat.';
      return RepositoryActionResult(
        isSuccess: true,
        message: _lastSyncMessage!,
        data: transactions,
        isOfflineMode: true,
      );
    }

    try {
      final remoteList = await _transactionService.fetchTransactions();
      final unsyncedLocal =
          localCached.where((t) => !t.isSynced).toList();

      final merged = <Transaction>[
        ...unsyncedLocal,
        ...remoteList,
      ];
      _transactions = _sortByNewest(merged);
      await _localStorage.saveTransactions(_transactions);

      _isOfflineFallback = false;
      _lastSyncMessage = null;

      return RepositoryActionResult(
        isSuccess: true,
        message: 'Riwayat transaksi berhasil dimuat.',
        data: transactions,
      );
    } on ApiNetworkException catch (e) {
      _transactions = _sortByNewest(localCached);
      _isOfflineFallback = true;
      _lastSyncMessage = e.message;

      return RepositoryActionResult(
        isSuccess: true,
        message: e.message,
        data: transactions,
        isOfflineMode: true,
      );
    } on ApiHttpException catch (e) {
      _transactions = _sortByNewest(localCached);
      _isOfflineFallback = true;
      _lastSyncMessage = e.message;

      return RepositoryActionResult(
        isSuccess: false,
        message: e.message,
        data: transactions,
        isOfflineMode: true,
      );
    } catch (e) {
      _transactions = _sortByNewest(localCached);
      _isOfflineFallback = true;
      _lastSyncMessage = 'Gagal memuat transaksi: $e';

      return RepositoryActionResult(
        isSuccess: false,
        message: _lastSyncMessage!,
        data: transactions,
        isOfflineMode: true,
      );
    }
  }

  /// Proses checkout POS: validasi stok -> kirim ke server / simpan lokal -> kurangi stok real-time.
  Future<CheckoutResult> submitCheckout({
    required List<CartItem> cartItems,
    required DiscountType globalDiscountType,
    required double globalDiscountValue,
    required double globalDiscountAmount,
    required double grossSubtotal,
    required double totalItemDiscount,
    required double subtotal,
    required double ppn,
    required double grandTotal,
    required PaymentMethod paymentMethod,
    required double cashPaid,
    String? transferReference,
    String? customerName,
  }) async {
    // 1. Validasi stok real-time sebelum transaksi dikirim.
    final stockValidation = _inventoryRepository.validateCartStock(cartItems);
    if (!stockValidation.isValid) {
      return CheckoutResult(
        isSuccess: false,
        message: stockValidation.errorMessage ?? 'Stok barang tidak mencukupi.',
      );
    }

    // 2. Validasi nominal pembayaran.
    final effectivePaid =
        paymentMethod == PaymentMethod.cash ? cashPaid : grandTotal;
    if (paymentMethod == PaymentMethod.cash && effectivePaid < grandTotal) {
      return const CheckoutResult(
        isSuccess: false,
        message: 'Nominal uang tunai kurang dari total tagihan.',
      );
    }

    final change = paymentMethod == PaymentMethod.cash
        ? (effectivePaid - grandTotal).clamp(0.0, double.infinity)
        : 0.0;

    final session = await _localStorage.loadSession();
    final cashierName = session?.name ?? 'Kasir Toko';
    final now = DateTime.now();
    final localId = now.millisecondsSinceEpoch;
    final generatedInvoice = _generateInvoiceNumber(now);

    final transactionItems =
        cartItems.map(TransactionItem.fromCartItem).toList();

    var draftTransaction = Transaction(
      id: localId,
      invoiceNumber: generatedInvoice,
      timestamp: now,
      cashierName: cashierName,
      customerName: customerName?.trim().isEmpty == true ? null : customerName?.trim(),
      items: transactionItems,
      grossSubtotal: grossSubtotal,
      totalItemDiscount: totalItemDiscount,
      globalDiscountType: globalDiscountType,
      globalDiscountValue: globalDiscountValue,
      globalDiscountAmount: globalDiscountAmount,
      subtotal: subtotal,
      ppn: ppn,
      grandTotal: grandTotal,
      paymentMethod: paymentMethod,
      transferReference: transferReference?.trim().isEmpty == true
          ? null
          : transferReference?.trim(),
      cashPaid: effectivePaid,
      change: change,
      status: 'Lunas',
      isSynced: !(session?.isLocalDemo ?? false),
    );

    final isDemoSession = session?.isLocalDemo ?? false;

    if (!isDemoSession) {
      try {
        final responseData = await _transactionService.createTransaction(
          transaction: draftTransaction,
        );

        final serverId = (responseData['id_transaksi'] as num?)?.toInt() ??
            (responseData['id'] as num?)?.toInt() ??
            draftTransaction.id;
        final serverInvoice = responseData['nomor_struk']?.toString() ??
            responseData['nomor_faktur']?.toString() ??
            responseData['invoice']?.toString() ??
            draftTransaction.invoiceNumber;

        draftTransaction = draftTransaction.copyWith(
          id: serverId,
          invoiceNumber: serverInvoice,
          isSynced: true,
        );

        await _recordCompletedTransaction(draftTransaction);

        return CheckoutResult(
          isSuccess: true,
          message: 'Transaksi berhasil diselesaikan!',
          transaction: draftTransaction,
        );
      } on ApiHttpException catch (e) {
        return CheckoutResult(isSuccess: false, message: e.message);
      } on ApiNetworkException {
        // Lanjutkan penyimpanan lokal jika koneksi server terputus.
      }
    }

    final offlineTransaction = draftTransaction.copyWith(isSynced: false);
    _isOfflineFallback = true;
    await _recordCompletedTransaction(offlineTransaction);

    return CheckoutResult(
      isSuccess: true,
      message: 'Transaksi berhasil dicatat secara lokal (Offline).',
      transaction: offlineTransaction,
      isOfflineSaved: true,
    );
  }

  Future<Transaction?> fetchTransactionDetail(Transaction fallback) async {
    final session = await _localStorage.loadSession();
    if ((session?.isLocalDemo ?? false) || !fallback.isSynced) {
      return fallback;
    }

    try {
      final fetched = await _transactionService.fetchTransactionDetail(fallback.id);
      if (fetched != null) {
        // Gabungkan data rincian lokal (seperti diskon/referensi) jika backend belum menyimpannya.
        return fetched.copyWith(
          totalItemDiscount: fetched.totalItemDiscount > 0
              ? fetched.totalItemDiscount
              : fallback.totalItemDiscount,
          globalDiscountAmount: fetched.globalDiscountAmount > 0
              ? fetched.globalDiscountAmount
              : fallback.globalDiscountAmount,
          transferReference: fetched.transferReference ?? fallback.transferReference,
          customerName: fetched.customerName ?? fallback.customerName,
        );
      }
    } catch (_) {
      // Kembalikan fallback jika gagal mengambil detail server.
    }
    return fallback;
  }

  Future<void> _recordCompletedTransaction(Transaction completed) async {
    // 1. Simpan transaksi ke riwayat terstruktur & storage lokal.
    _transactions = _sortByNewest([completed, ..._transactions]);
    await _localStorage.saveTransactions(_transactions);

    // 2. Kurangi stok produk secara sinkron & real-time!
    await _inventoryRepository.deductStockSynchronously(completed.items);
  }

  String _generateInvoiceNumber(DateTime dt) {
    final datePart =
        '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
    final todayCount = _transactions
            .where(
              (t) =>
                  t.timestamp.year == dt.year &&
                  t.timestamp.month == dt.month &&
                  t.timestamp.day == dt.day,
            )
            .length +
        1;
    final seq = todayCount.toString().padLeft(4, '0');
    return 'INV/$datePart/$seq';
  }

  List<Transaction> _sortByNewest(List<Transaction> list) {
    final copy = List<Transaction>.from(list);
    copy.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return copy;
  }
}
