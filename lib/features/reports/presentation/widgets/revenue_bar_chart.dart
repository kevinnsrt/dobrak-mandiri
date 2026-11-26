import 'package:dobrak_mandiri_app/core/theme/app_theme.dart';
import 'package:dobrak_mandiri_app/core/utils/currency_formatter.dart';
import 'package:dobrak_mandiri_app/data/models/sales_report.dart';
import 'package:flutter/material.dart';

/// Grafik batang sederhana dan responsif untuk tren omset penjualan.
class RevenueBarChart extends StatelessWidget {
  const RevenueBarChart({
    super.key,
    required this.buckets,
    this.barColor = AppTheme.primaryGreen,
  });

  final List<SalesChartBucket> buckets;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Belum ada data grafik untuk periode ini.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    final maxRevenue = buckets.fold<double>(
      0.0,
      (max, b) => b.revenue > max ? b.revenue : max,
    );

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: buckets.map((bucket) {
          final ratio = maxRevenue > 0 ? (bucket.revenue / maxRevenue) : 0.0;
          final barHeight = bucket.revenue > 0 ? (84 * ratio).clamp(10.0, 84.0) : 8.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (bucket.revenue > 0)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatter.formatCompact(bucket.revenue),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: barColor,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 24,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: bucket.revenue > 0
                          ? barColor
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bucket.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: bucket.revenue > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: bucket.revenue > 0
                          ? barColor
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
