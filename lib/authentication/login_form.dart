import 'package:dobrak_mandiri_app/dashboard/cashier.main.dashboard.dart';
import 'package:dobrak_mandiri_app/dashboard/inventory.main.dashboard.dart';
import 'package:dobrak_mandiri_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // Controller untuk membaca inputan text
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Service Autentikasi
  final AuthService _authService = AuthService();

  // State
  bool _isPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Fungsi Handle Login HTTP REST API ---
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validasi input awal
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("Email dan kata sandi tidak boleh kosong.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Panggil API Login
      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final displayName = result.userName ?? "Kasir Toko";

        // Tampilkan pesan berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text("Login Berhasil! Selamat datang, $displayName.")),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        Widget destination;
        if (result.role == 'INVENTORY' || result.role == 'GUDANG') {
          destination = const InventoryMainDashboard();
        } else {
          destination = const CashierMainDashboard();
        }

        // Navigasi ke Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (context) => destination,
          ),
        );
      } else {
        // Tampilkan pesan error
        _showErrorDialog(result.message);
      }
    } catch (e, stackTrace) {
      debugPrint("Exception in _handleLogin: $e\n$stackTrace");
      if (mounted) {
        _showErrorDialog("Terjadi kesalahan saat memproses login:\n${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Text("Gagal Login"),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);
    const Color lightGreenAccent = Color(0xFFC8E6C9);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- 1. Dekorasi Lengkungan Hijau Atas ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.14,
              decoration: const BoxDecoration(
                color: lightGreenAccent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                  bottomRight: Radius.circular(80),
                ),
              ),
            ),
          ),

          // --- 2. Form Login Utama ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),

                    // --- Header Judul ---
                    const Text(
                      "SISTEM INVENTARIS",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "PT DOBRAK MANDIRI",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Silakan masuk menggunakan akun karyawan Anda",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // --- Input Field: Email ---
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: "Email",
                        hintText: "contoh: kasir@pos.local",
                        prefixIcon: const Icon(Icons.email_outlined, color: primaryGreen),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: primaryGreen, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Input Field: Password ---
                    TextField(
                      controller: _passwordController,
                      obscureText: _isPasswordObscured,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: "Kata Sandi",
                        hintText: "Masukkan kata sandi Anda",
                        prefixIcon: const Icon(Icons.lock_outline, color: primaryGreen),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordObscured
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordObscured = !_isPasswordObscured;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: primaryGreen, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Opsi Lupa Password ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : () {},
                        child: const Text(
                          "Lupa Kata Sandi?",
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Tombol Masuk ---
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "MASUK",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
