import 'dart:math' as math;

import 'models.dart';

/// Summarizes observed prices. LLM forecasts are requested separately.
class PriceOutlook {
  const PriceOutlook({
    required this.low,
    required this.high,
    required this.reportCount,
  });

  final double low, high;
  final int reportCount;

  factory PriceOutlook.fromReports(Price current, List<Price> history) {
    // Keep one modal quote per report date and make sure the current report wins.
    final byDate = <String, Price>{};
    for (final report in history) {
      byDate[dateOnly(report.date)] = report;
    }
    byDate[dateOnly(current.date)] = current;
    final points = byDate.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final recent = points.length <= 7
        ? points
        : points.sublist(points.length - 7);
    final recentModalLow = recent.map((p) => p.modal).reduce(math.min);
    final recentModalHigh = recent.map((p) => p.modal).reduce(math.max);
    final low = current.min == null
        ? recentModalLow
        : math.min(current.min!, recentModalLow);
    final high = current.max == null
        ? recentModalHigh
        : math.max(current.max!, recentModalHigh);

    return PriceOutlook(low: low, high: high, reportCount: points.length);
  }
}
