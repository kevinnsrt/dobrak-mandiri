/// Peran pengguna pada aplikasi PT. Dobrak Mandiri.
enum UserRole {
  cashier,
  inventory,
  owner;

  String get displayLabel {
    switch (this) {
      case UserRole.cashier:
        return 'KASIR';
      case UserRole.inventory:
        return 'INVENTORY';
      case UserRole.owner:
        return 'MANAGER';
    }
  }

  static UserRole fromString(String? rawRole) {
    final normalized = (rawRole ?? '').toUpperCase().trim();
    if (normalized == 'INVENTORY' || normalized == 'GUDANG') {
      return UserRole.inventory;
    }
    if (normalized == 'OWNER' ||
        normalized == 'MANAGER' ||
        normalized == 'ADMIN' ||
        normalized == 'PEMILIK' ||
        normalized == 'MANAJER') {
      return UserRole.owner;
    }
    return UserRole.cashier;
  }
}

/// Informasi sesi pengguna aktif.
class UserSession {
  final String token;
  final String name;
  final String email;
  final String rawRole;
  final bool isLocalDemo;

  const UserSession({
    required this.token,
    required this.name,
    required this.email,
    required this.rawRole,
    this.isLocalDemo = false,
  });

  UserRole get role => UserRole.fromString(rawRole);

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      token: json['token']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Karyawan',
      email: json['email']?.toString() ?? '',
      rawRole: json['role']?.toString() ?? 'KASIR',
      isLocalDemo: json['is_local_demo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'name': name,
      'email': email,
      'role': rawRole,
      'is_local_demo': isLocalDemo,
    };
  }
}
