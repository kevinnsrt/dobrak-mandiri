import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Banner informatif untuk status mode lokal/offline atau peringatan API.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.isOfflineMode = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool isOfflineMode;

  @override
  Widget build(BuildContext context) {
    final bgColor = isOfflineMode ? Colors.blue.shade50 : AppTheme.warningBg;
    final fgColor = isOfflineMode ? Colors.blue.shade900 : AppTheme.warningOrange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: bgColor,
      child: Row(
        children: [
          Icon(
            isOfflineMode ? Icons.cloud_off_outlined : Icons.info_outline,
            size: 18,
            color: fgColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: fgColor),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: Text(
                'Sinkronkan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
