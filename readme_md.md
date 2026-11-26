# 🛠️ Sistem Informasi Penjualan dan Inventaris Terintegrasi (PT. Dobrak Mandiri)

![Flutter](https://img.shields.io/badge/Framework-Flutter-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Language-Dart-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

Aplikasi *mobile* Point of Sale (POS) dan pengelolaan inventaris toko bahan bangunan **PT. Dobrak Mandiri**. Aplikasi ini dirancang untuk memodernisasi sistem operasional dari pencatatan konvensional ("Bon Faktur") menjadi sistem berbasis digital yang terintegrasi, cepat, akurat, dan real-time.

---

## 📌 Latar Belakang & Masalah

Sebelumnya, PT. Dobrak Mandiri mengandalkan sistem manual menggunakan "Bon Faktur" fisik. Metode ini menimbulkan beberapa kendala mendasar:
- **Kerentanan Data:** Dokumen fisik rentan hilang, rusak, dan tidak memiliki cadangan data (backup).
- **Penyimpanan Tidak Terstruktur:** Pengarsipan transaksi dan pencatatan stok barang sulit ditelusuri.
- **Perhitungan Tidak Efektif:** Rekapitulasi transaksi dan laporan keuangan manual berisiko tinggi salah hitung dan memakan waktu.

**Solusi IT:** Mengembangkan aplikasi mobile terpadu yang memodernisasi alur transaksi kasir, otomatisasi pemotongan stok gudang, serta penyusunan rekapitulasi laporan keuangan secara real-time.

---

## ✨ Fitur Utama (Core Features)

### 🛍️ 1. Modul Kasir & Point of Sale (POS)
- **Pencatatan Transaksi Cepat:** Pencarian dan pemilihan produk toko bangunan yang efisien.
- **Perhitungan Otomatis:** Menghitung subtotal, diskon (per item / diskon global), dan total bayar.
- **Metode Pembayaran Manual:** Mendukung opsi pembayaran Tunai (*Cash*) dan Transfer Bank Manual. *(Scope: Tanpa QRIS Dinamis / Payment Gateway)*.
- **Struk/Nota Digital:** Pencetakan/penayangan rincian nota transaksi terstruktur sebagai pengganti bon faktur fisik.

### 📦 2. Manajemen Inventaris (Stok Real-Time)
- **Pemotongan Stok Otomatis:** Stok gudang berkurang secara real-time begitu transaksi kasir selesai dikonfirmasi.
- **Validasi Ketersediaan Stok:** Mencegah transaksi checkout apabila kuantitas barang melebihi stok gudang yang ada.
- **Katalog & Manajemen Produk:** Memantau ketersediaan stok, mengubah kuantitas barang, dan mengelola inventaris toko.

### 📊 3. Laporan Penjualan & Keuangan
- **Rekapitulasi Otomatis:** Laporan penjualan harian dan bulanan yang diperbarui secara real-time.
- **Ringkasan Kinerja Toko:** Visualisasi dan statistik total pendapatan, volume barang terjual, serta jumlah transaksi.

---

## 🛠️ Arsitektur & Teknologi

- **Framework:** [Flutter](https://flutter.dev/) (Dart SDK)
- **State Management:** Provider / Riverpod / BLoC
- **Arsitektur Kode:** Feature-First / Clean Architecture
- **Target Platform:** Mobile (Android & iOS) — *Single-store implementation*

---

## 📁 Struktur Folder Proyek

```text
lib/
├── core/
│   ├── constants/       # Konstanta warna, asset path, dan teks
│   ├── theme/           # Tema aplikasi dan styling UI
│   └── utils/           # Helper fungsi, formatter mata uang, dan tanggal
├── data/
│   ├── models/          # Data Model (Product, Transaction, TransactionItem, SalesReport)
│   └── repositories/    # Service layer & manipulasi database/API
├── features/
│   ├── pos/             # Modul Kasir & Checkout
│   │   ├── controllers/
│   │   ├── views/
│   │   └── widgets/
│   ├── inventory/       # Modul Pengelolaan Stok Barang
│   │   ├── controllers/
│   │   ├── views/
│   │   └── widgets/
│   └── report/          # Modul Laporan Penjualan Harian & Bulanan
│       ├── controllers/
│       ├── views/
│       └── widgets/
└── main.dart            # Entry point aplikasi
```

---

## 🚀 Cara Menjalankan Proyek (Getting Started)

### Prasyarat System
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.0.0 atau lebih baru)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio / VS Code dengan plugin Flutter & Dart
- Emulator Android/iOS atau Perangkat Fisik (HP)

### Langkah Instalasi

1. **Clone repository ini:**
   ```bash
   git clone https://github.com/username/pt-dobrak-mandiri.git
   cd pt-dobrak-mandiri
   ```

2. **Dapatkan dependensi proyek:**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi:**
   ```bash
   flutter run
   ```

---

## 👥 Tim Pengembang (Kelompok 5)

Proyek ini disusun dan dikembangkan oleh **Kelompok 5** Universitas Sumatera Utara:

| Nama Anggota | Peran dalam Proyek | Tanggung Jawab Utama |
| :--- | :--- | :--- |
| **Valencia Browlim** | Project Manager | Pengelolaan timeline, mitigasi risiko, komunikasi mitra & penyusunan Project Charter/Laporan. |
| **Amanda Uli Lumbantoruan** | System Analyst | Analisis proses bisnis, diagram alir sistem (Use Case, Activity Diagram, ERD), dan penyusunan SRS. |
| **Elvan Yohanes Gultom** | UI/UX Designer | Perancangan *user flow* dan prototipe interaktif (Wireframe & UI Figma). |
| **Kevin Namalo Sirait** | Frontend Developer | Implementasi antarmuka Flutter, pembangunan modul POS, Inventaris, dan Dashboard. |
| **Andreas Cristianto Sinaga** | Backend Developer | Arsitektur database, logika pemotongan stok otomatis real-time, dan REST API laporan. |
| **Samuel Gautama Manik** | QA & Tester | Penyusunan *test case*, pengujian *black-box*, verifikasi bug, dan penyusunan *user manual*. |

---

## 🗓️ Timeline Proyek

| Fase | Deskripsi Kegiatan | Rentang Waktu |
| :---: | :--- | :---: |
| **Fase 1** | Inisiasi & Analisis Kebutuhan | 15 Sep - 30 Sep 2026 |
| **Fase 2** | Perancangan Sistem (Design & UI/UX) | 31 Sep - 13 Okt 2026 |
| **Fase 3** | Pengembangan Backend & Database | 14 Okt - 27 Okt 2026 |
| **Fase 4** | Pengembangan Frontend & Integrasi Modul | 28 Okt - 10 Nov 2026 |
| **Fase 5** | Pengujian Sistem (QA & Testing) | 11 Nov - 24 Nov 2026 |
| **Fase 6** | Finalisasi, Evaluasi Mitra & UAS | 25 Nov - 08 Des 2026 |

---

## 📄 Lisensi

Proyek ini dibuat untuk memenuhi tugas mata kuliah **Metodologi Pengembangan Teknologi Informasi (MPTI)** di **Universitas Sumatera Utara**.
 Hak Cipta © 2026 Kelompok 5 - PT. Dobrak Mandiri.