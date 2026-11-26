import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Menu profil & logout bersama untuk semua dashboard peran.
class DashboardProfileMenu extends StatelessWidget {
  const DashboardProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final session = auth.session;

    return PopupMenuButton<String>(
      tooltip: 'Menu Akun',
      icon: const CircleAvatar(
        backgroundColor: Colors.white24,
        child: Icon(Icons.person, color: Colors.white),
      ),
      onSelected: (value) async {
        if (value == 'logout') {
          await context.read<AuthProvider>().logout();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session?.name ?? 'Karyawan',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (session?.email.isNotEmpty ?? false)
                Text(
                  session!.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Role: ${session?.role.displayLabel ?? 'KASIR'}'
                '${(session?.isLocalDemo ?? false) ? ' (Lokal)' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: AppTheme.dangerRed, size: 20),
              SizedBox(width: 8),
              Text(
                'Keluar (Logout)',
                style: TextStyle(color: AppTheme.dangerRed),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
