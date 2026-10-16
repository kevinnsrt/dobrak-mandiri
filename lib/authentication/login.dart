import 'package:dobrak_mandiri_app/authentication/login-form.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    // Definisi Warna Aksen Hijau PT Dobrak Mandiri
    const Color primaryGreen = Color(0xFF2E7D32); // Hijau Emerald Tua (Profesional)
    const Color lightGreenAccent = Color(0xFFC8E6C9); // Hijau Sangat Muda (Untuk dekorasi)

    return Scaffold(
      backgroundColor: Colors.white, // Latar Putih Bersih
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.15, // 15% tinggi layar
              decoration: const BoxDecoration(
                color: lightGreenAccent, // Warna hijau muda lembut
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(100), // Membuat lengkungan besar
                  bottomRight: Radius.circular(100),
                ),
              ),
            ),
          ),

          // MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(), // Memberi ruang kosong di atas

                  // --- A. Ilustrasi Tema Inventaris/Gudang ---
                  // Saya menggunakan NetworkImage agar bisa langsung dicoba.
                  // Nanti ganti dengan AssetImage("assets/images/login_illustration.png")
                  Container(
                    height: MediaQuery.of(context).size.height * 0.35, // 35% tinggi layar
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                            'https://cdn.prod.website-files.com/5d8a2888296e91abbdcb65f0/617a9e254bd391bc19382714_Sistem%20Manajemen%20Inventory.jpg'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- B. Teks Judul ---
                  const Text(
                    "SISTEM INVENTARIS",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "PT DOBRAK MANDIRI",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: primaryGreen, // Warna hijau utama pada teks perusahaan
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Kelola stok barang dan aset perusahaan dengan mudah dan efisien dalam satu genggaman.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5, // Line height agar lebih enak dibaca
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(), // Memberi ruang kosong di antara teks dan tombol

                  // TOMBOL LOGIN
                  Container(
                    width: double.infinity,
                    height: 55,
                    margin: const EdgeInsets.only(bottom: 20), // Jarak dari bawah
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const LoginForm(),
                          ),
                        );
                        print("Tombol Login Ditekan");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen, // Warna background hijau solid
                        foregroundColor: Colors.white, // Warna teks putih
                        elevation: 5, // Sedikit bayangan agar terlihat 'mengambang'
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // Sudut sangat melengkung (modern)
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        "LOGIN",
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
        ],
      ),
    );
  }
}