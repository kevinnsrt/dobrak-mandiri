import 'package:dobrak_mandiri_app/data/services/api_client.dart';
import 'package:dobrak_mandiri_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'App launches to WelcomeLoginPage and completes offline POS checkout with real-time stock deduction (Tunai & Transfer Manual only)',
    (WidgetTester tester) async {
      final mockClient = ApiClient(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      await tester.pumpWidget(
        MyApp(dependencies: AppDependencies.create(apiClient: mockClient)),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi halaman awal saat belum login
      expect(find.text('SISTEM POS & INVENTARIS'), findsOneWidget);
      expect(find.text('MASUK KE SISTEM'), findsOneWidget);

      // 2. Masuk ke halaman Login & pilih Mode Lokal Kasir
      await tester.tap(find.text('MASUK KE SISTEM'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Kasir'));
      await tester.tap(find.text('Kasir'));
      await tester.pumpAndSettle();

      // 3. Verifikasi Dashboard Kasir & metrik awal 0
      expect(find.text('Dashboard Kasir'), findsOneWidget);
      expect(find.text('Pesanan Baru'), findsOneWidget);

      // 4. Buka modul POS / Pesanan Baru
      await tester.tap(find.text('Pesanan Baru'));
      await tester.pumpAndSettle();

      expect(find.text('Semen Portland 50kg'), findsOneWidget);
      expect(find.textContaining('Stok: 120 Sak'), findsOneWidget);

      // 5. Pilih 1 item Semen Portland 50kg
      await tester.tap(find.text('Pilih').first);
      await tester.pumpAndSettle();

      // 6. Tekan PROSES BAYAR
      await tester.tap(find.textContaining('PROSES BAYAR'));
      await tester.pumpAndSettle();

      // 7. Pastikan hanya Tunai & Transfer Manual yang tersedia (TIDAK ada QRIS)
      expect(find.text('Tunai'), findsOneWidget);
      expect(find.text('Transfer Manual'), findsOneWidget);
      expect(find.textContaining('QRIS'), findsNothing);

      // 8. Tekan Uang Pas dan Konfirmasi Bayar
      await tester.tap(find.text('Uang Pas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('KONFIRMASI BAYAR'));
      await tester.pumpAndSettle();

      // 9. Nota Faktur resmi tampil
      expect(find.text('Nota Faktur Pembayaran'), findsOneWidget);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // 10. Stok Semen Portland 50kg berkurang otomatis dari 120 menjadi 119 secara real-time!
      expect(find.textContaining('Stok: 119 Sak'), findsOneWidget);

      // 11. Kembali ke Dashboard Kasir dan pastikan Ringkasan Hari Ini ikut terbarui
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Dashboard Kasir'), findsOneWidget);
      expect(find.widgetWithText(Scaffold, '1'), findsWidgets);
    },
  );
}
