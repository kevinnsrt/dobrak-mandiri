import 'package:dobrak_mandiri_app/authentication/login.dart';
import 'package:dobrak_mandiri_app/dashboard/cashier.main.dashboard.dart';
import 'package:dobrak_mandiri_app/dashboard/inventory.main.dashboard.dart';
import 'package:dobrak_mandiri_app/services/auth_service.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PT Dobrak Mandiri POS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      home: const AuthGateway(),
    );
  }
}

/// Widget Gateway untuk Memeriksa Status Sesi Login & Navigasi Berdasarkan Role
class AuthGateway extends StatelessWidget {
  const AuthGateway({super.key});

  Future<Widget> _checkAuthAndDetermineScreen() async {
    final bool loggedIn = await AuthService.isLoggedIn();

    if (!loggedIn) {
      return const LoginPage();
    }

    final String? role = await AuthService.getUserRole();
    debugPrint("Session check - User Role: $role");

    if (role == 'INVENTORY' || role == 'GUDANG') {
      return const InventoryMainDashboard();
    } else {
      // Default Kasir
      return const CashierMainDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _checkAuthAndDetermineScreen(),
      builder: (context, snapshot) {
        // Tampilan Splash / Loading saat mengecek Sesi
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: Color(0xFF2E7D32),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "PT DOBRAK MANDIRI",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Memeriksa sesi login...",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Jika terjadi error, arahkan ke Halaman Login
        if (snapshot.hasError || !snapshot.hasData) {
          return const LoginPage();
        }

        return snapshot.data!;
      },
    );
  }
}
