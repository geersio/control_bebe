import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../percentiles_data.dart';
import '../../features/weight/models/weight_chart_prefs.dart';

final weightChartPrefsProvider =
    AsyncNotifierProvider<WeightChartPrefsNotifier, WeightChartPrefs>(
      WeightChartPrefsNotifier.new,
    );

final heightChartPrefsProvider =
    AsyncNotifierProvider<HeightChartPrefsNotifier, HeightChartPrefs>(
      HeightChartPrefsNotifier.new,
    );

class WeightChartPrefsNotifier extends AsyncNotifier<WeightChartPrefs> {
  @override
  Future<WeightChartPrefs> build() => WeightChartPrefs.load();

  Future<void> setTimeRange(WeightChartTimeRange timeRange) async {
    final current = await future;
    if (current.timeRange == timeRange) return;
    final next = current.copyWith(timeRange: timeRange);
    await next.save();
    state = AsyncData(next);
  }

  Future<void> setPercentile(WeightPercentile percentile) async {
    final current = await future;
    if (current.percentile == percentile) return;
    final next = current.copyWith(percentile: percentile);
    await next.save();
    state = AsyncData(next);
  }
}

class HeightChartPrefsNotifier extends AsyncNotifier<HeightChartPrefs> {
  @override
  Future<HeightChartPrefs> build() => HeightChartPrefs.load();

  Future<void> setTimeRange(WeightChartTimeRange timeRange) async {
    final current = await future;
    if (current.timeRange == timeRange) return;
    final next = current.copyWith(timeRange: timeRange);
    await next.save();
    state = AsyncData(next);
  }

  Future<void> setPercentile(WeightPercentile percentile) async {
    final current = await future;
    if (current.percentile == percentile) return;
    final next = current.copyWith(percentile: percentile);
    await next.save();
    state = AsyncData(next);
  }
}
