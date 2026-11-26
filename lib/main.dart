import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/data/repositories/auth_repository.dart';
import 'package:dobrak_mandiri_app/data/repositories/inventory_repository.dart';
import 'package:dobrak_mandiri_app/data/repositories/transaction_repository.dart';
import 'package:dobrak_mandiri_app/data/services/api_client.dart';
import 'package:dobrak_mandiri_app/data/services/auth_service.dart';
import 'package:dobrak_mandiri_app/data/services/local_storage_service.dart';
import 'package:dobrak_mandiri_app/data/services/stock_service.dart';
import 'package:dobrak_mandiri_app/data/services/transaction_service.dart';
import 'package:dobrak_mandiri_app/features/auth/presentation/pages/auth_gateway_page.dart';
import 'package:dobrak_mandiri_app/providers/auth_provider.dart';
import 'package:dobrak_mandiri_app/providers/inventory_provider.dart';
import 'package:dobrak_mandiri_app/providers/pos_provider.dart';
import 'package:dobrak_mandiri_app/providers/report_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp(dependencies: AppDependencies.create()));
}

/// Kontainer dependensi aplikasi untuk Dependency Injection & kemudahan testing.
class AppDependencies {
  AppDependencies({
    required this.authRepository,
    required this.inventoryRepository,
    required this.transactionRepository,
  });

  final AuthRepository authRepository;
  final InventoryRepository inventoryRepository;
  final TransactionRepository transactionRepository;

  factory AppDependencies.create({ApiClient? apiClient, LocalStorageService? localStorage}) {
    final storage = localStorage ?? LocalStorageService();
    final client = apiClient ?? ApiClient();

    final authService = AuthService(apiClient: client, localStorage: storage);
    final stockService = StockService(apiClient: client, localStorage: storage);
    final transactionService =
        TransactionService(apiClient: client, localStorage: storage);

    final authRepository =
        AuthRepository(authService: authService, localStorage: storage);
    final inventoryRepository = InventoryRepository(
      stockService: stockService,
      localStorage: storage,
    );
    final transactionRepository = TransactionRepository(
      transactionService: transactionService,
      localStorage: storage,
      inventoryRepository: inventoryRepository,
    );

    return AppDependencies(
      authRepository: authRepository,
      inventoryRepository: inventoryRepository,
      transactionRepository: transactionRepository,
    );
  }
}

class MyApp extends StatelessWidget {
  MyApp({
    super.key,
    AppDependencies? dependencies,
  }) : dependencies = dependencies ?? AppDependencies.create();

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) =>
              AuthProvider(authRepository: dependencies.authRepository)
                ..initialize(),
        ),
        ChangeNotifierProvider<InventoryProvider>(
          create: (_) => InventoryProvider(
            inventoryRepository: dependencies.inventoryRepository,
          ),
        ),
        ChangeNotifierProvider<ReportProvider>(
          create: (_) => ReportProvider(
            transactionRepository: dependencies.transactionRepository,
          ),
        ),
        ChangeNotifierProxyProvider2<InventoryProvider, ReportProvider,
            PosProvider>(
          create: (context) => PosProvider(
            inventoryRepository: dependencies.inventoryRepository,
            transactionRepository: dependencies.transactionRepository,
            onCheckoutCompleted: () {
              context.read<InventoryProvider>().notifyStockSynchronized();
              context.read<ReportProvider>().notifyTransactionsSynchronized();
            },
          ),
          update: (_, __, ___, previous) => previous!,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PT Dobrak Mandiri POS',
        theme: AppTheme.lightTheme,
        home: const AuthGatewayPage(),
      ),
    );
  }
}
