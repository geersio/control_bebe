import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/measurement_units.dart';

final measurementPrefsProvider =
    AsyncNotifierProvider<MeasurementPrefsNotifier, MeasurementPrefs>(
      MeasurementPrefsNotifier.new,
    );

class MeasurementPrefsNotifier extends AsyncNotifier<MeasurementPrefs> {
  @override
  Future<MeasurementPrefs> build() => MeasurementPrefs.load();

  Future<void> setWeight(WeightUnitMode weight) async {
    final current = await future;
    final next = current.copyWith(weight: weight);
    await next.save();
    state = AsyncData(next);
  }

  Future<void> setLiquid(LiquidUnitMode liquid) async {
    final current = await future;
    final next = current.copyWith(liquid: liquid);
    await next.save();
    state = AsyncData(next);
  }

  /// `null` o vacío = moneda automática según el dispositivo.
  Future<void> setCurrency(String? currencyCode) async {
    final current = await future;
    final normalized = (currencyCode == null || currencyCode.isEmpty)
        ? null
        : currencyCode.toUpperCase();
    final next = normalized == null
        ? current.copyWith(clearCurrency: true)
        : current.copyWith(currencyCode: normalized);
    await next.save();
    state = AsyncData(next);
  }
}
