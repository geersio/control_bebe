import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/measurement_display.dart';

enum BottleQuickAmountAddResult { saved, alreadyExists, maxReached }

/// Cantidades rápidas para biberón (ml en almacenamiento).
class BottleQuickAmountsPrefs {
  static const _kCustomMl = 'bottle_quick_custom_ml';
  static const _kHiddenDefaultsMl = 'bottle_quick_hidden_defaults_ml';

  /// Medidas habituales en España (preparados de fórmula / biberón).
  static const List<int> defaultMl = [60, 90, 120, 150, 180];

  static const int maxCustomCount = 8;

  final List<int> customMl;
  final List<int> hiddenDefaultMl;

  const BottleQuickAmountsPrefs({
    required this.customMl,
    this.hiddenDefaultMl = const [],
  });

  static const BottleQuickAmountsPrefs empty = BottleQuickAmountsPrefs(
    customMl: [],
  );

  List<int> visibleDefaultMl() => defaultMl
      .where((d) => !hiddenDefaultMl.contains(d))
      .toList();

  /// Lista para UI: presets y personalizados, sin duplicados, ordenados por ml.
  List<int> displayAmountsMl() {
    final out = <int>[...visibleDefaultMl()];
    for (final c in customMl) {
      if (findMatchingQuickAmountMl(c, out) == null) out.add(c);
    }
    out.sort();
    return out;
  }

  bool containsAmount(int ml) =>
      findMatchingQuickAmountMl(ml, displayAmountsMl()) != null;

  bool isDefaultAmount(int ml) =>
      defaultMl.contains(ml) && !hiddenDefaultMl.contains(ml);

  bool isCustomAmount(int ml) => customMl.contains(ml);

  static Future<BottleQuickAmountsPrefs> load() async {
    final sp = await SharedPreferences.getInstance();
    final hidden = _parseMlList(
      sp.getStringList(_kHiddenDefaultsMl) ?? [],
      allowed: defaultMl.toSet(),
    );
    final rawCustom = sp.getStringList(_kCustomMl) ?? [];
    final custom = <int>[];
    final visibleDefaults = defaultMl.where((d) => !hidden.contains(d));
    for (final s in rawCustom) {
      final n = int.tryParse(s);
      if (n == null || n <= 0 || n > 2000) continue;
      if (findMatchingQuickAmountMl(n, [...visibleDefaults, ...custom]) != null) {
        continue;
      }
      custom.add(n);
    }
    custom.sort();
    final loaded = BottleQuickAmountsPrefs(
      customMl: custom,
      hiddenDefaultMl: hidden,
    );
    if (rawCustom.length != custom.length) {
      await loaded.save();
    }
    return loaded;
  }

  static List<int> _parseMlList(
    List<String> raw, {
    Set<int>? allowed,
  }) {
    final out = <int>[];
    for (final s in raw) {
      final n = int.tryParse(s);
      if (n == null || n <= 0 || n > 2000) continue;
      if (allowed != null && !allowed.contains(n)) continue;
      if (!out.contains(n)) out.add(n);
    }
    out.sort();
    return out;
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(
      _kCustomMl,
      customMl.map((e) => e.toString()).toList(),
    );
    await sp.setStringList(
      _kHiddenDefaultsMl,
      hiddenDefaultMl.map((e) => e.toString()).toList(),
    );
  }

  BottleQuickAmountsPrefs copyWith({
    List<int>? customMl,
    List<int>? hiddenDefaultMl,
  }) =>
      BottleQuickAmountsPrefs(
        customMl: customMl ?? this.customMl,
        hiddenDefaultMl: hiddenDefaultMl ?? this.hiddenDefaultMl,
      );

  Future<BottleQuickAmountsPrefs?> addCustomAmount(int ml) async {
    if (containsAmount(ml)) return null;
    if (customMl.length >= maxCustomCount) return null;
    final next = copyWith(customMl: [...customMl, ml]..sort());
    await next.save();
    return next;
  }

  /// Quita un atajo (preset u personalizado) de la lista visible.
  Future<BottleQuickAmountsPrefs> removeAmount(int ml) async {
    if (customMl.contains(ml)) {
      final next = copyWith(
        customMl: customMl.where((e) => e != ml).toList(),
      );
      await next.save();
      return next;
    }
    if (defaultMl.contains(ml) && !hiddenDefaultMl.contains(ml)) {
      final next = copyWith(
        hiddenDefaultMl: [...hiddenDefaultMl, ml]..sort(),
      );
      await next.save();
      return next;
    }
    return this;
  }
}
