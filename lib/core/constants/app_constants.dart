/// Konstanta bisnis aplikasi PT. Dobrak Mandiri.
class AppConstants {
  AppConstants._();

  static const String companyName = 'PT DOBRAK MANDIRI';
  static const String companyTagline = 'Toko Bahan Bangunan & Konstruksi';
  static const String storeAddress = 'Single Store - Gudang Utama Pusat';
  static const double ppnRate = 0.11;
  static const int defaultMinStock = 5;

  static const List<String> defaultCategories = [
    'Bahan Bangunan',
    'Cat & Pelapis',
    'Pipa & Sanitari',
    'Perkakas & Hardware',
  ];

  static const List<String> defaultUnits = [
    'Sak',
    'Batang',
    'Kaleng',
    'Kg',
    'Pcs',
    'Unit',
    'Meter',
    'Dus',
  ];

  static const List<String> stockOutReasons = [
    'Penyesuaian Stok Rusak / Cacat',
    'Pemakaian Internal Toko',
    'Pengembalian ke Supplier',
    'Koreksi Stock Opname',
  ];
}
