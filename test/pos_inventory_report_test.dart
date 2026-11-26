import 'dart:convert';

import 'package:dobrak_mandiri_app/data/models/cart_item.dart';
import 'package:dobrak_mandiri_app/data/models/product.dart';
import 'package:dobrak_mandiri_app/data/models/sales_report.dart';
import 'package:dobrak_mandiri_app/data/models/transaction.dart';
import 'package:dobrak_mandiri_app/data/models/transaction_item.dart';
import 'package:dobrak_mandiri_app/data/models/user_session.dart';
import 'package:dobrak_mandiri_app/data/repositories/inventory_repository.dart';
import 'package:dobrak_mandiri_app/data/repositories/transaction_repository.dart';
import 'package:dobrak_mandiri_app/data/services/api_client.dart';
import 'package:dobrak_mandiri_app/data/services/local_storage_service.dart';
import 'package:dobrak_mandiri_app/data/services/stock_service.dart';
import 'package:dobrak_mandiri_app/data/services/transaction_service.dart';
import 'package:dobrak_mandiri_app/providers/inventory_provider.dart';
import 'package:dobrak_mandiri_app/providers/pos_provider.dart';
import 'package:dobrak_mandiri_app/providers/report_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Models serialization & calculation', () {
    test('Product parses flexible API JSON and computes stock alerts', () {
      final product = Product.fromJson({
        'id_produk': 12,
        'kode_sku': 'SKU-202',
        'nama_produk': 'Semen Tiga Roda 50kg',
        'kategori': {'id': 1, 'nama_kategori': 'Bahan Bangunan'},
        'harga_jual': 70000,
        'kuantitas': 5,
        'stok_minimum': 10,
        'lokasi': 'Gudang A',
        'satuan': 'Sak',
      });

      expect(product.id, equals(12));
      expect(product.sku, equals('SKU-202'));
      expect(product.name, equals('Semen Tiga Roda 50kg'));
      expect(product.category, equals('Bahan Bangunan'));
      expect(product.price, equals(70000.0));
      expect(product.stock, equals(5));
      expect(product.isLowStock, isTrue);
      expect(product.isOutOfStock, isFalse);

      final roundTrip = Product.fromJson(product.toJson());
      expect(roundTrip.id, equals(product.id));
      expect(roundTrip.sku, equals(product.sku));
      expect(roundTrip.stock, equals(product.stock));
    });

    test('Transaction serializes and generates official Nota/Faktur text', () {
      final trx = Transaction(
        id: 99,
        invoiceNumber: 'INV/20261126/0001',
        timestamp: DateTime(2026, 11, 26, 10, 30),
        cashierName: 'Budi Kasir',
        customerName: 'Proyek Pak Andi',
        items: const [
          TransactionItem(
            productId: 1,
            sku: 'SKU-1001',
            productName: 'Semen Portland 50kg',
            unit: 'Sak',
            unitPrice: 68000,
            quantity: 2,
            discountType: DiscountType.nominal,
            discountValue: 6000,
            discountAmount: 6000,
          ),
        ],
        grossSubtotal: 136000,
        totalItemDiscount: 6000,
        globalDiscountAmount: 10000,
        subtotal: 120000,
        ppn: 0,
        grandTotal: 120000,
        paymentMethod: PaymentMethod.manualTransfer,
        transferReference: 'BCA - Ref 55412',
        cashPaid: 120000,
        change: 0,
      );

      final parsed = Transaction.fromJson(trx.toJson());
      expect(parsed.invoiceNumber, equals('INV/20261126/0001'));
      expect(parsed.paymentMethod, equals(PaymentMethod.manualTransfer));
      expect(parsed.totalDiscount, equals(16000.0));
      expect(parsed.grandTotal, equals(120000.0));

      final receipt = trx.toReceiptText();
      expect(receipt, contains('PT DOBRAK MANDIRI'));
      expect(receipt, contains('INV/20261126/0001'));
      expect(receipt, contains('Transfer Manual'));
      expect(receipt, contains('BCA - Ref 55412'));
    });

    test('SalesReport aggregates daily and monthly totals with Tunai & Transfer Manual only', () {
      final today = DateTime(2026, 11, 26, 14, 0);
      final earlierInMonth = DateTime(2026, 11, 10, 11, 0);

      final transactions = [
        Transaction(
          id: 1,
          invoiceNumber: 'INV/1',
          timestamp: today,
          cashierName: 'Kasir A',
          items: const [
            TransactionItem(
              productId: 1,
              sku: 'SKU-1',
              productName: 'Semen Portland',
              unitPrice: 70000,
              quantity: 3,
            ),
          ],
          grossSubtotal: 210000,
          subtotal: 210000,
          ppn: 0,
          grandTotal: 210000,
          paymentMethod: PaymentMethod.cash,
          cashPaid: 250000,
          change: 40000,
        ),
        Transaction(
          id: 2,
          invoiceNumber: 'INV/2',
          timestamp: earlierInMonth,
          cashierName: 'Kasir A',
          items: const [
            TransactionItem(
              productId: 2,
              sku: 'SKU-2',
              productName: 'Pipa PVC',
              unitPrice: 50000,
              quantity: 2,
            ),
          ],
          grossSubtotal: 100000,
          subtotal: 100000,
          ppn: 0,
          grandTotal: 100000,
          paymentMethod: PaymentMethod.manualTransfer,
          cashPaid: 100000,
          change: 0,
        ),
      ];

      final daily = SalesReport.fromTransactions(
        allTransactions: transactions,
        period: ReportPeriod.daily,
        referenceDate: today,
      );
      expect(daily.totalTransactions, equals(1));
      expect(daily.totalRevenue, equals(210000.0));
      expect(daily.totalItemsSold, equals(3));
      expect(daily.cashTotal, equals(210000.0));
      expect(daily.manualTransferTotal, equals(0.0));

      final monthly = SalesReport.fromTransactions(
        allTransactions: transactions,
        period: ReportPeriod.monthly,
        referenceDate: today,
      );
      expect(monthly.totalTransactions, equals(2));
      expect(monthly.totalRevenue, equals(310000.0));
      expect(monthly.totalItemsSold, equals(5));
      expect(monthly.cashTotal, equals(210000.0));
      expect(monthly.manualTransferTotal, equals(100000.0));
      expect(monthly.topProducts.first.name, equals('Semen Portland'));
    });
  });

  group('POS, Inventory & Report Real-time Integration', () {
    late LocalStorageService storage;
    late InventoryRepository inventoryRepo;
    late TransactionRepository transactionRepo;
    late InventoryProvider inventoryProvider;
    late ReportProvider reportProvider;
    late PosProvider posProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = LocalStorageService();
      await storage.saveSession(
        const UserSession(
          token: 'test-token',
          name: 'Kasir Uji',
          email: 'kasir@test.local',
          rawRole: 'KASIR',
          isLocalDemo: false,
        ),
      );

      final mockHttp = MockClient((request) async {
        if (request.url.path.endsWith('/stok') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id_produk': 1,
                  'kode_sku': 'SKU-1001',
                  'nama_produk': 'Semen Portland 50kg',
                  'kategori': 'Bahan Bangunan',
                  'harga': 68000,
                  'kuantitas': 10,
                  'stok_minimum': 3,
                  'satuan': 'Sak',
                },
                {
                  'id_produk': 2,
                  'kode_sku': 'SKU-1002',
                  'nama_produk': 'Cat Tembok 5kg',
                  'kategori': 'Cat & Pelapis',
                  'harga': 100000,
                  'kuantitas': 5,
                  'stok_minimum': 2,
                  'satuan': 'Kaleng',
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/kategori')) {
          return http.Response(jsonEncode(['Bahan Bangunan', 'Cat & Pelapis']), 200);
        }
        if (request.url.path.endsWith('/transaksi') && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id_transaksi': 501,
                'nomor_struk': 'INV/TEST/0501',
              },
            }),
            201,
          );
        }
        if (request.url.path.endsWith('/transaksi') && request.method == 'GET') {
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }
        return http.Response(jsonEncode({'success': true, 'data': {}}), 200);
      });

      final apiClient = ApiClient(httpClient: mockHttp);
      inventoryRepo = InventoryRepository(
        stockService: StockService(apiClient: apiClient, localStorage: storage),
        localStorage: storage,
      );
      transactionRepo = TransactionRepository(
        transactionService: TransactionService(
          apiClient: apiClient,
          localStorage: storage,
        ),
        localStorage: storage,
        inventoryRepository: inventoryRepo,
      );

      inventoryProvider = InventoryProvider(inventoryRepository: inventoryRepo);
      reportProvider = ReportProvider(transactionRepository: transactionRepo);
      posProvider = PosProvider(
        inventoryRepository: inventoryRepo,
        transactionRepository: transactionRepo,
        onCheckoutCompleted: () {
          inventoryProvider.notifyStockSynchronized();
          reportProvider.notifyTransactionsSynchronized();
        },
      );

      await inventoryProvider.loadProducts();
      await reportProvider.loadTransactions();
    });

    test('Rejects adding or setting quantity above available stock', () {
      final semen = inventoryProvider.products.first;
      expect(semen.stock, equals(10));

      final errExceed = posProvider.setItemQuantity(semen, 15);
      expect(errExceed, isNotNull);
      expect(errExceed, contains('tidak'));
      expect(posProvider.isCartEmpty, isTrue);

      final ok = posProvider.setItemQuantity(semen, 10);
      expect(ok, isNull);
      expect(posProvider.quantityForProduct(semen.id), equals(10));

      final errOneMore = posProvider.addItem(semen);
      expect(errOneMore, isNotNull);
      expect(posProvider.quantityForProduct(semen.id), equals(10));
    });

    test('Computes itemized discount, global discount, PPN and synchronously deducts stock on checkout', () async {
      final semen = inventoryProvider.products[0]; // Rp 68.000, stok 10
      final cat = inventoryProvider.products[1]; // Rp 100.000, stok 5

      posProvider.setItemQuantity(semen, 2); // gross 136.000
      posProvider.setItemDiscount(
        productId: semen.id,
        type: DiscountType.nominal,
        value: 6000, // net 130.000
      );

      posProvider.setItemQuantity(cat, 1); // gross 100.000
      posProvider.setItemDiscount(
        productId: cat.id,
        type: DiscountType.percent,
        value: 10, // diskon 10.000 -> net 90.000
      );

      // subtotal after item discounts = 220.000
      expect(posProvider.grossSubtotal, equals(236000.0));
      expect(posProvider.totalItemDiscount, equals(16000.0));
      expect(posProvider.subtotalAfterItemDiscount, equals(220000.0));

      // global discount 10% = 22.000 -> subtotal = 198.000
      posProvider.setGlobalDiscount(type: DiscountType.percent, value: 10);
      expect(posProvider.globalDiscountAmount, equals(22000.0));
      expect(posProvider.subtotal, equals(198000.0));

      // disable PPN -> grandTotal = 198.000
      posProvider.togglePpn(false);
      expect(posProvider.grandTotal, equals(198000.0));

      final result = await posProvider.checkout(
        paymentMethod: PaymentMethod.cash,
        cashPaid: 200000,
      );

      expect(result.isSuccess, isTrue);
      expect(result.transaction?.invoiceNumber, equals('INV/TEST/0501'));
      expect(result.transaction?.change, equals(2000.0));

      // Stok harus langsung berkurang sinkron di InventoryProvider!
      expect(inventoryProvider.findProductById(semen.id)?.stock, equals(8));
      expect(inventoryProvider.findProductById(cat.id)?.stock, equals(4));

      // Keranjang kosong & ReportProvider langsung ter-update!
      expect(posProvider.isCartEmpty, isTrue);
      expect(reportProvider.todayReport.totalTransactions, equals(1));
      expect(reportProvider.todayReport.totalRevenue, equals(198000.0));
      expect(reportProvider.todayReport.totalItemsSold, equals(3));
    });

    test('Inventory stock adjustment prevents negative stock on stock-out', () async {
      final cat = inventoryProvider.products[1]; // stok 5
      final failRes = await inventoryProvider.adjustStock(
        productId: cat.id,
        delta: -8,
        reason: 'Rusak',
      );

      expect(failRes.isSuccess, isFalse);
      expect(inventoryProvider.findProductById(cat.id)?.stock, equals(5));

      final okRes = await inventoryProvider.adjustStock(
        productId: cat.id,
        delta: -2,
        reason: 'Rusak',
      );
      expect(okRes.isSuccess, isTrue);
      expect(inventoryProvider.findProductById(cat.id)?.stock, equals(3));
    });
  });
}
