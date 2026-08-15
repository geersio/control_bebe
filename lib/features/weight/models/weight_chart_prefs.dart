import 'package:shared_preferences/shared_preferences.dart';

import 'package:control_bebe/l10n/app_localizations.dart';

import '../../../core/percentiles_data.dart';

/// Periodo mostrado en la gráfica de evolución de peso (desde hoy hacia atrás).
enum WeightChartTimeRange {
  days7,
  days30,
  days90,
  year1,
  all;

  int? get trailingDays => switch (this) {
    WeightChartTimeRange.days7 => 7,
    WeightChartTimeRange.days30 => 30,
    WeightChartTimeRange.days90 => 90,
    WeightChartTimeRange.year1 => 365,
    WeightChartTimeRange.all => null,
  };

  String label(AppLocalizations l10n) => switch (this) {
    WeightChartTimeRange.days7 => l10n.weightChartRange7d,
    WeightChartTimeRange.days30 => l10n.weightChartRange30d,
    WeightChartTimeRange.days90 => l10n.weightChartRange90d,
    WeightChartTimeRange.year1 => l10n.weightChartRange365d,
    WeightChartTimeRange.all => l10n.weightChartRangeAll,
  };

  static const List<WeightChartTimeRange> pickerValues = [
    WeightChartTimeRange.days7,
    WeightChartTimeRange.days30,
    WeightChartTimeRange.days90,
    WeightChartTimeRange.year1,
    WeightChartTimeRange.all,
  ];
}

/// Preferencias de visualización de la gráfica de peso (rango temporal y
/// percentil de referencia), persistidas localmente.
class WeightChartPrefs {
  static const _kTimeRange = 'weight_chart_time_range';
  static const _kPercentile = 'weight_chart_percentile';

  final WeightChartTimeRange timeRange;
  final WeightPercentile percentile;

  const WeightChartPrefs({required this.timeRange, required this.percentile});

  static const WeightChartPrefs defaults = WeightChartPrefs(
    timeRange: WeightChartTimeRange.all,
    percentile: WeightPercentile.p50,
  );

  static Future<WeightChartPrefs> load() async {
    final sp = await SharedPreferences.getInstance();
    final tName = sp.getString(_kTimeRange);
    final pName = sp.getString(_kPercentile);
    WeightChartTimeRange t;
    WeightPercentile p;
    try {
      t = tName != null
          ? WeightChartTimeRange.values.byName(tName)
          : defaults.timeRange;
    } catch (_) {
      t = defaults.timeRange;
    }
    try {
      p = pName != null
          ? WeightPercentile.values.byName(pName)
          : defaults.percentile;
    } catch (_) {
      p = defaults.percentile;
    }
    return WeightChartPrefs(timeRange: t, percentile: p);
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTimeRange, timeRange.name);
    await sp.setString(_kPercentile, percentile.name);
  }

  WeightChartPrefs copyWith({
    WeightChartTimeRange? timeRange,
    WeightPercentile? percentile,
  }) => WeightChartPrefs(
    timeRange: timeRange ?? this.timeRange,
    percentile: percentile ?? this.percentile,
  );
}

/// Preferencias de visualización de la gráfica de altura (rango temporal y
/// percentil de referencia), persistidas localmente.
class HeightChartPrefs {
  static const _kTimeRange = 'height_chart_time_range';
  static const _kPercentile = 'height_chart_percentile';

  final WeightChartTimeRange timeRange;
  final WeightPercentile percentile;

  const HeightChartPrefs({required this.timeRange, required this.percentile});

  static const HeightChartPrefs defaults = HeightChartPrefs(
    timeRange: WeightChartTimeRange.all,
    percentile: WeightPercentile.p50,
  );

  static Future<HeightChartPrefs> load() async {
    final sp = await SharedPreferences.getInstance();
    final tName = sp.getString(_kTimeRange);
    final pName = sp.getString(_kPercentile);
    WeightChartTimeRange t;
    WeightPercentile p;
    try {
      t = tName != null
          ? WeightChartTimeRange.values.byName(tName)
          : defaults.timeRange;
    } catch (_) {
      t = defaults.timeRange;
    }
    try {
      p = pName != null
          ? WeightPercentile.values.byName(pName)
          : defaults.percentile;
    } catch (_) {
      p = defaults.percentile;
    }
    return HeightChartPrefs(timeRange: t, percentile: p);
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTimeRange, timeRange.name);
    await sp.setString(_kPercentile, percentile.name);
  }

  HeightChartPrefs copyWith({
    WeightChartTimeRange? timeRange,
    WeightPercentile? percentile,
  }) => HeightChartPrefs(
    timeRange: timeRange ?? this.timeRange,
    percentile: percentile ?? this.percentile,
  );
}
