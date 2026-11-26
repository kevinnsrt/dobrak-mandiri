import 'package:dobrak_mandiri_app/data/models/transaction.dart';
import 'package:dobrak_mandiri_app/data/services/api_client.dart';
import 'package:dobrak_mandiri_app/data/services/local_storage_service.dart';

/// Service REST API transaksi penjualan PT. Dobrak Mandiri.
class TransactionService {
  TransactionService({
    required ApiClient apiClient,
    required LocalStorageService localStorage,
  })  : _apiClient = apiClient,
        _localStorage = localStorage;

  final ApiClient _apiClient;
  final LocalStorageService _localStorage;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _localStorage.getToken();
    return ApiClient.defaultHeaders(token: token);
  }

  Future<Map<String, dynamic>> createTransaction({
    required Transaction transaction,
  }) async {
    final headers = await _authHeaders();
    final amountPaidInt = transaction.cashPaid.round();

    final body = <String, dynamic>{
      'jenis_pembayaran': transaction.paymentMethod.apiValue,
      'jumlah_bayar': amountPaidInt,
      'detail': transaction.items.map((e) => e.toApiPayload()).toList(),
      if (transaction.globalDiscountAmount > 0)
        'diskon_global': transaction.globalDiscountAmount,
      if (transaction.transferReference != null &&
          transaction.transferReference!.isNotEmpty)
        'referensi_transfer': transaction.transferReference,
      if (transaction.customerName != null &&
          transaction.customerName!.isNotEmpty)
        'nama_pelanggan': transaction.customerName,
    };

    final decoded = await _apiClient.postJson(
      '/transaksi',
      headers: headers,
      body: body,
    );

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      return decoded;
    }
    return {};
  }

  Future<List<Transaction>> fetchTransactions() async {
    final headers = await _authHeaders();
    final decoded = await _apiClient.getJson(
      '/transaksi?per_page=1000&limit=1000',
      headers: headers,
    );

    final objects = ApiClient.extractObjectList(
      decoded,
      ['data', 'transaksi', 'result'],
    );
    return objects.map(Transaction.fromJson).toList();
  }

  Future<Transaction?> fetchTransactionDetail(int id) async {
    final headers = await _authHeaders();
    final decoded = await _apiClient.getJson(
      '/transaksi/$id',
      headers: headers,
    );

    if (decoded is Map<String, dynamic>) {
      final dataField =
          decoded['data'] ?? decoded['transaksi'] ?? decoded['result'];
      if (dataField is Map<String, dynamic>) {
        return Transaction.fromJson(dataField);
      }
      return Transaction.fromJson(decoded);
    }
    return null;
  }
}
