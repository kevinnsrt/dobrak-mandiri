import 'package:dobrak_mandiri_app/core/utils/date_formatter.dart';
import 'package:dobrak_mandiri_app/data/models/cart_item.dart';
import 'package:dobrak_mandiri_app/data/models/transaction.dart';

/// Periode rekapitulasi laporan penjualan.
enum ReportPeriod {
  daily,
  weekly,
  monthly;

  String get label {
    switch (this) {
      case ReportPeriod.daily:
        return 'Harian';
      case ReportPeriod.weekly:
        return 'Mingguan';
      case ReportPeriod.monthly:
        return 'Bulanan';
    }
  }
}

/// Ringkasan produk terlaris dalam periode laporan.
class TopProductSummary {
  final String name;
  final String sku;
  final int qtySold;
  final double revenue;

  const TopProductSummary({
    required this.name,
    this.sku = '',
    required this.qtySold,
    required this.revenue,
  });
}

/// Titik data batang pada grafik tren penjualan.
class SalesChartBucket {
  final String label;
  final double revenue;
  final int transactionCount;

  const SalesChartBucket({
    required this.label,
    required this.revenue,
    this.transactionCount = 0,
  });
}

/// Entitas Laporan Penjualan & Keuangan (Harian / Mingguan / Bulanan).
class SalesReport {
  final ReportPeriod period;
  final DateTime referenceDate;
  final double totalRevenue;
  final double totalDiscount;
  final int totalTransactions;
  final int totalItemsSold;
  final double averageTransactionValue;
  final double cashTotal;
  final double manualTransferTotal;
  final List<TopProductSummary> topProducts;
  final List<SalesChartBucket> chartBuckets;
  final List<Transaction> transactions;

  const SalesReport({
    required this.period,
    required this.referenceDate,
    required this.totalRevenue,
    required this.totalDiscount,
    required this.totalTransactions,
    required this.totalItemsSold,
    required this.averageTransactionValue,
    required this.cashTotal,
    required this.manualTransferTotal,
    required this.topProducts,
    required this.chartBuckets,
    required this.transactions,
  });

  double get cashRatio =>
      totalRevenue > 0 ? (cashTotal / totalRevenue).clamp(0.0, 1.0) : 0.0;

  double get manualTransferRatio =>
      totalRevenue > 0 ? (manualTransferTotal / totalRevenue).clamp(0.0, 1.0) : 0.0;

  /// Bangun laporan real-time dari daftar transaksi berdasarkan periode & tanggal.
  factory SalesReport.fromTransactions({
    required List<Transaction> allTransactions,
    required ReportPeriod period,
    required DateTime referenceDate,
  }) {
    final activeTransactions = allTransactions.where((trx) {
      if (trx.isCancelled) return false;
      switch (period) {
        case ReportPeriod.daily:
          return DateFormatter.isSameDay(trx.timestamp, referenceDate);
        case ReportPeriod.weekly:
          final monday = DateTime(
            referenceDate.year,
            referenceDate.month,
            referenceDate.day,
          ).subtract(Duration(days: referenceDate.weekday - 1));
          final sundayEnd = monday.add(const Duration(days: 7));
          return !trx.timestamp.isBefore(monday) && trx.timestamp.isBefore(sundayEnd);
        case ReportPeriod.monthly:
          return DateFormatter.isSameMonth(trx.timestamp, referenceDate);
      }
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    double totalRevenue = 0;
    double totalDiscount = 0;
    int totalItemsSold = 0;
    double cashTotal = 0;
    double manualTransferTotal = 0;

    final Map<String, _ProductAccumulator> productMap = {};

    for (final trx in activeTransactions) {
      totalRevenue += trx.grandTotal;
      totalDiscount += trx.totalDiscount;
      totalItemsSold += trx.totalItemQuantity;

      if (trx.paymentMethod == PaymentMethod.manualTransfer) {
        manualTransferTotal += trx.grandTotal;
      } else {
        cashTotal += trx.grandTotal;
      }

      for (final item in trx.items) {
        final key = item.productName;
        final existing = productMap[key];
        if (existing != null) {
          existing.qty += item.quantity;
          existing.revenue += item.totalPrice;
        } else {
          productMap[key] = _ProductAccumulator(
            name: item.productName,
            sku: item.sku,
            qty: item.quantity,
            revenue: item.totalPrice,
          );
        }
      }
    }

    final totalTransactions = activeTransactions.length;
    final avgValue =
        totalTransactions > 0 ? totalRevenue / totalTransactions : 0.0;

    final topProducts = productMap.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    final chartBuckets = _buildChartBuckets(
      transactions: activeTransactions,
      period: period,
      referenceDate: referenceDate,
    );

    return SalesReport(
      period: period,
      referenceDate: referenceDate,
      totalRevenue: totalRevenue,
      totalDiscount: totalDiscount,
      totalTransactions: totalTransactions,
      totalItemsSold: totalItemsSold,
      averageTransactionValue: avgValue,
      cashTotal: cashTotal,
      manualTransferTotal: manualTransferTotal,
      topProducts: topProducts
          .take(5)
          .map(
            (e) => TopProductSummary(
              name: e.name,
              sku: e.sku,
              qtySold: e.qty,
              revenue: e.revenue,
            ),
          )
          .toList(),
      chartBuckets: chartBuckets,
      transactions: activeTransactions,
    );
  }

  static List<SalesChartBucket> _buildChartBuckets({
    required List<Transaction> transactions,
    required ReportPeriod period,
    required DateTime referenceDate,
  }) {
    if (period == ReportPeriod.daily) {
      const hours = [8, 10, 12, 14, 16, 18, 20];
      final revenueMap = {for (final h in hours) h: 0.0};
      final countMap = {for (final h in hours) h: 0};

      for (final trx in transactions) {
        int bucketHour = hours.first;
        for (final h in hours) {
          if (trx.timestamp.hour >= h) {
            bucketHour = h;
          }
        }
        revenueMap[bucketHour] = (revenueMap[bucketHour] ?? 0) + trx.grandTotal;
        countMap[bucketHour] = (countMap[bucketHour] ?? 0) + 1;
      }

      return hours.map((h) {
        return SalesChartBucket(
          label: '${h.toString().padLeft(2, '0')}:00',
          revenue: revenueMap[h] ?? 0.0,
          transactionCount: countMap[h] ?? 0,
        );
      }).toList();
    }

    if (period == ReportPeriod.weekly) {
      final monday = DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day,
      ).subtract(Duration(days: referenceDate.weekday - 1));

      return List.generate(7, (i) {
        final day = monday.add(Duration(days: i));
        double sum = 0;
        int count = 0;
        for (final trx in transactions) {
          if (DateFormatter.isSameDay(trx.timestamp, day)) {
            sum += trx.grandTotal;
            count++;
          }
        }
        return SalesChartBucket(
          label: '${DateFormatter.shortDayName(day.weekday)}\n${day.day}/${day.month}',
          revenue: sum,
          transactionCount: count,
        );
      });
    }

    // Monthly: ringkasan per minggu dalam bulan terpilih (Minggu 1-5) agar tetap terbaca jelas di mobile.
    final daysInMonth =
        DateTime(referenceDate.year, referenceDate.month + 1, 0).day;
    final weekTotals = List<double>.filled(5, 0.0);
    final weekCounts = List<int>.filled(5, 0);

    for (final trx in transactions) {
      final weekIdx = ((trx.timestamp.day - 1) ~/ 7).clamp(0, 4);
      weekTotals[weekIdx] += trx.grandTotal;
      weekCounts[weekIdx] += 1;
    }

    final bucketCount = daysInMonth > 28 ? 5 : 4;
    return List.generate(bucketCount, (i) {
      final startDay = i * 7 + 1;
      final endDay = ((i + 1) * 7).clamp(1, daysInMonth);
      return SalesChartBucket(
        label: 'Tgl\n$startDay-$endDay',
        revenue: weekTotals[i],
        transactionCount: weekCounts[i],
      );
    });
  }
}

class _ProductAccumulator {
  final String name;
  final String sku;
  int qty;
  double revenue;

  _ProductAccumulator({
    required this.name,
    required this.sku,
    required this.qty,
    required this.revenue,
  });
}
