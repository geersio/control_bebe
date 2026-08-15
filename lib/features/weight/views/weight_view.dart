import 'dart:async';
import 'dart:math' as math;

import 'package:control_bebe/l10n/app_date_locale.dart';
import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/main_app_title_bar.dart';
import '../../../core/theme/edit_dialog_theme.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/providers/record_stream_providers.dart';
import '../../../core/widgets/edit_bottom_sheet.dart';
import '../../../core/widgets/edit_list_rows.dart';
import '../../../core/widgets/inline_confirming_button.dart';
import '../../../core/widgets/confirm_delete_record_dialog.dart';
import '../../../core/widgets/stream_record_load_error.dart';
import '../../../core/models/weight_record.dart';
import '../../../core/models/height_record.dart';
import '../../../core/models/measurement_units.dart';
import '../../../core/providers/measurement_prefs_provider.dart';
import '../../../core/providers/baby_profile_provider.dart';
import '../../../core/utils/measurement_display.dart';
import '../../../core/utils/growth_change_guard.dart';
import '../../../core/utils/history_calendar_window.dart';
import '../../../core/utils/history_highlight.dart';
import '../../../core/widgets/history_entry_reveal.dart';

class WeightView extends ConsumerStatefulWidget {
  final VoidCallback? onTitleTap;
  final VoidCallback onSettingsTap;
  final ScrollController? scrollController;

  /// Si es false, no se suscribe a Firestore hasta que la pestaña sea visible.
  final bool isActiveTab;

  const WeightView({
    super.key,
    this.onTitleTap,
    required this.onSettingsTap,
    this.scrollController,
    this.isActiveTab = true,
  });

  @override
  ConsumerState<WeightView> createState() => _WeightViewState();
}

class _WeightViewState extends ConsumerState<WeightView>
    with HistoryHighlightState {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightFocusNode = FocusNode();
  final _heightFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final _heightFormKey = GlobalKey<FormState>();
  final Set<int> _deletedWeightIds = {};
  final Set<int> _deletedHeightIds = {};
  WeightRecord? _optimisticWeight;
  HeightRecord? _optimisticHeight;
  WeightRecord? _pendingHistoryReveal;
  HeightRecord? _pendingHeightHistoryReveal;
  bool _awaitingHistoryReveal = false;
  bool _awaitingHeightHistoryReveal = false;
  DateTime _lastHistoryScrollExpand = DateTime.fromMillisecondsSinceEpoch(0);

  /// Misma altura visual que [ElevatedButton] de esta fila.
  static const double _weightControlHeight = 56;

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_onEntryTextChanged);
    _heightController.addListener(_onEntryTextChanged);
  }

  void _onEntryTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _weightController.removeListener(_onEntryTextChanged);
    _heightController.removeListener(_onEntryTextChanged);
    _weightFocusNode.dispose();
    _heightFocusNode.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  WeightRecord? _latestWeightOf(Iterable<WeightRecord> records) {
    WeightRecord? best;
    for (final r in records) {
      if (r.id != null && _deletedWeightIds.contains(r.id)) continue;
      if (best == null || r.dateTime.isAfter(best.dateTime)) best = r;
    }
    return best;
  }

  HeightRecord? _latestHeightOf(Iterable<HeightRecord> records) {
    HeightRecord? best;
    for (final r in records) {
      if (r.id != null && _deletedHeightIds.contains(r.id)) continue;
      if (best == null || r.dateTime.isAfter(best.dateTime)) best = r;
    }
    return best;
  }

  Widget _buildSuddenChangeHint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.primaryOrange,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }

  KeyboardActionsConfig _weightKeyboardConfig(AppLocalizations l10n) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: AppTheme.softPrimaryFill,
      nextFocus: false,
      actions: [
        KeyboardActionsItem(
          focusNode: _weightFocusNode,
          displayArrows: false,
          toolbarButtons: [
            (node) => IconButton(
              icon: const Icon(Icons.check_rounded),
              color: AppTheme.palettePrimary,
              tooltip: l10n.commonDone,
              onPressed: () => node.unfocus(),
            ),
          ],
        ),
      ],
    );
  }

  KeyboardActionsConfig _heightKeyboardConfig(AppLocalizations l10n) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: AppTheme.softPrimaryFill,
      nextFocus: false,
      actions: [
        KeyboardActionsItem(
          focusNode: _heightFocusNode,
          displayArrows: false,
          toolbarButtons: [
            (node) => IconButton(
              icon: const Icon(Icons.check_rounded),
              color: AppTheme.palettePrimary,
              tooltip: l10n.commonDone,
              onPressed: () => node.unfocus(),
            ),
          ],
        ),
      ],
    );
  }

  List<WeightRecord> _mergeOptimisticWeight(List<WeightRecord> records) {
    final opt = _optimisticWeight;
    if (opt == null) return records;
    final match = records.any(
      (r) =>
          (r.weightKg - opt.weightKg).abs() < 0.0001 &&
          HistoryHighlightKeys.recordsMatchWithinSeconds(
            r.dateTime,
            opt.dateTime,
          ),
    );
    if (match) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _optimisticWeight = null);
      });
      return records;
    }
    return [opt, ...records];
  }

  List<HeightRecord> _mergeOptimisticHeight(List<HeightRecord> records) {
    final opt = _optimisticHeight;
    if (opt == null) return records;
    final match = records.any(
      (r) =>
          (r.heightCm - opt.heightCm).abs() < 0.0001 &&
          HistoryHighlightKeys.recordsMatchWithinSeconds(
            r.dateTime,
            opt.dateTime,
          ),
    );
    if (match) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _optimisticHeight = null);
      });
      return records;
    }
    return [opt, ...records];
  }

  Future<bool> _registerWeight() async {
    if (!_formKey.currentState!.validate()) return false;

    final prefs =
        ref.read(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    final weightKg = parseWeightInputToKg(_weightController.text, prefs);
    if (weightKg == null || weightKg <= 0) return false;

    final record = WeightRecord(weightKg: weightKg, dateTime: DateTime.now());
    setState(() {
      _pendingHistoryReveal = record;
      _awaitingHistoryReveal = true;
    });

    // Limpiar el campo inmediatamente sin esperar confirmación de red
    _weightController.clear();
    unawaited(IsarService.addWeightRecord(record));
    return true;
  }

  Future<bool> _registerHeight() async {
    if (!_heightFormKey.currentState!.validate()) return false;

    final heightCm = parseHeightInputToCm(_heightController.text);
    if (heightCm == null || heightCm <= 0) return false;

    final record = HeightRecord(heightCm: heightCm, dateTime: DateTime.now());
    setState(() {
      _pendingHeightHistoryReveal = record;
      _awaitingHeightHistoryReveal = true;
    });

    _heightController.clear();
    unawaited(IsarService.addHeightRecord(record));
    return true;
  }

  void _revealWeightHistory() {
    final record = _pendingHistoryReveal;
    if (record == null) return;
    markHistoryHighlight(HistoryHighlightKeys.weight(record));
    setState(() {
      _optimisticWeight = record;
      _awaitingHistoryReveal = false;
      _pendingHistoryReveal = null;
    });
  }

  void _revealHeightHistory() {
    final record = _pendingHeightHistoryReveal;
    if (record == null) return;
    markHistoryHighlight(HistoryHighlightKeys.height(record));
    setState(() {
      _optimisticHeight = record;
      _awaitingHeightHistoryReveal = false;
      _pendingHeightHistoryReveal = null;
    });
  }

  List<WeightRecord> _recordsForHistory(List<WeightRecord> records) {
    return _mergeOptimisticWeight(
      hidePendingHistoryRecord(
        records: records,
        awaitingReveal: _awaitingHistoryReveal,
        pending: _pendingHistoryReveal,
        matchesPending: HistoryHighlightKeys.weightMatchesPending,
      ),
    );
  }

  List<HeightRecord> _heightRecordsForHistory(List<HeightRecord> records) {
    return _mergeOptimisticHeight(
      hidePendingHistoryRecord(
        records: records,
        awaitingReveal: _awaitingHeightHistoryReveal,
        pending: _pendingHeightHistoryReveal,
        matchesPending: HistoryHighlightKeys.heightMatchesPending,
      ),
    );
  }

  void _deleteWeightRecord(int id) {
    setState(() => _deletedWeightIds.add(id));
    unawaited(
      IsarService.deleteWeightRecord(id).then((_) {
        if (mounted) setState(() => _deletedWeightIds.remove(id));
      }),
    );
  }

  void _deleteHeightRecord(int id) {
    setState(() => _deletedHeightIds.add(id));
    unawaited(
      IsarService.deleteHeightRecord(id).then((_) {
        if (mounted) setState(() => _deletedHeightIds.remove(id));
      }),
    );
  }

  bool _onWeightHistoryScrollNotification(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is! ScrollUpdateNotification &&
        n is! ScrollEndNotification &&
        n is! OverscrollNotification) {
      return false;
    }
    final m = n.metrics;
    if (!m.hasPixels) return false;
    final nearEnd =
        m.maxScrollExtent <= 0 || m.pixels >= m.maxScrollExtent - 100;
    if (!nearEnd) return false;
    final now = DateTime.now();
    if (now.difference(_lastHistoryScrollExpand) <
        const Duration(milliseconds: 500)) {
      return false;
    }
    final all = ref.read(weightRecordsForChartStreamProvider).valueOrNull;
    final heights = ref.read(heightRecordsStreamProvider).valueOrNull;
    if (all == null || heights == null) return false;
    final totalWeights = all
        .where((r) => r.id == null || !_deletedWeightIds.contains(r.id))
        .length;
    final totalHeights = heights
        .where((r) => r.id == null || !_deletedHeightIds.contains(r.id))
        .length;
    final total = totalWeights + totalHeights;
    final limit = ref.read(growthHistoryVisibleLimitProvider);
    if (limit >= total) return false;
    _lastHistoryScrollExpand = now;
    unawaited(_maybeExpandWeightHistoryWindow());
    return false;
  }

  Future<void> _maybeExpandWeightHistoryWindow() async {
    final data = ref.read(weightRecordsForChartStreamProvider).valueOrNull;
    final heights = ref.read(heightRecordsStreamProvider).valueOrNull;
    if (!mounted || data == null || heights == null) return;
    final totalWeights = data
        .where((r) => r.id == null || !_deletedWeightIds.contains(r.id))
        .length;
    final totalHeights = heights
        .where((r) => r.id == null || !_deletedHeightIds.contains(r.id))
        .length;
    final total = totalWeights + totalHeights;
    final limit = ref.read(growthHistoryVisibleLimitProvider);
    if (limit >= total) return;
    ref.read(growthHistoryVisibleLimitProvider.notifier).state = math.min(
      limit + kWeightHistoryPageIncrement,
      total,
    );
  }

  Widget _buildHeightCard(
    BuildContext context,
    AppLocalizations l10n, {
    required String hintText,
    String? suddenChangeHint,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.sectionCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.height_rounded, color: AppTheme.pageTitleIconWeight),
                const SizedBox(width: 8),
                Text(
                  l10n.heightTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            KeyboardActions(
              config: _heightKeyboardConfig(l10n),
              disableScroll: true,
              child: Form(
                key: _heightFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.heightFieldLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: _weightControlHeight,
                            child: TextFormField(
                              controller: _heightController,
                              focusNode: _heightFocusNode,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: const [
                                LooseDecimalInputFormatter(),
                              ],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) =>
                                  _heightFocusNode.unfocus(),
                              onTapOutside: (_) => _heightFocusNode.unfocus(),
                              expands: true,
                              maxLines: null,
                              minLines: null,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                hintText: hintText,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                isDense: false,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return l10n.heightValidatorEmpty;
                                }
                                final cm = parseHeightInputToCm(v);
                                if (cm == null || cm < 25 || cm > 130) {
                                  return l10n.heightValidatorInvalid;
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: _weightControlHeight,
                            child: InlineConfirmingButton(
                              onPressed: _registerHeight,
                              onSavedVisible: _revealHeightHistory,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                minimumSize: const Size(
                                  0,
                                  _weightControlHeight,
                                ),
                                maximumSize: const Size(
                                  double.infinity,
                                  _weightControlHeight,
                                ),
                                fixedSize: const Size(
                                  double.infinity,
                                  _weightControlHeight,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  l10n.heightRegister,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (suddenChangeHint != null)
                      _buildSuddenChangeHint(suddenChangeHint),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthHistorySection(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<WeightRecord>> weightRecordsAsync,
    AsyncValue<List<HeightRecord>> heightRecordsAsync,
    int historyVisibleLimit,
  ) {
    return weightRecordsAsync.when(
      skipLoadingOnReload: true,
      data: (allWeightRecords) {
        return heightRecordsAsync.when(
          skipLoadingOnReload: true,
          data: (allHeightRecords) {
            final weights = _recordsForHistory(
              allWeightRecords
                  .where(
                    (r) => r.id == null || !_deletedWeightIds.contains(r.id),
                  )
                  .toList(),
            );
            final heights = _heightRecordsForHistory(
              allHeightRecords
                  .where(
                    (r) => r.id == null || !_deletedHeightIds.contains(r.id),
                  )
                  .toList(),
            );
            final allVisible = <_GrowthHistoryRecord>[
              ...weights.map(_GrowthHistoryRecord.weight),
              ...heights.map(_GrowthHistoryRecord.height),
            ]..sort((a, b) => b.dateTime.compareTo(a.dateTime));
            final takeCount = math.min(historyVisibleLimit, allVisible.length);
            final records = allVisible.take(takeCount).toList();
            final hasMoreInList = allVisible.length > takeCount;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.historyTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (records.isEmpty)
                  Text(
                    l10n.growthHistoryEmpty,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textLight,
                      height: 1.4,
                    ),
                  )
                else ...[
                  ...records.map((entry) {
                    final weight = entry.weight;
                    if (weight != null) {
                      return HistoryEntryReveal(
                        highlighted: isHistoryHighlighted(
                          HistoryHighlightKeys.weight(weight),
                        ),
                        accentColor: AppTheme.weightHistoryAccent,
                        child: _WeightRecordTile(
                          record: weight,
                          onDelete: weight.id != null
                              ? () async {
                                  final ok = await confirmDeleteRecord(context);
                                  if (!context.mounted || !ok) return;
                                  _deleteWeightRecord(weight.id!);
                                }
                              : null,
                        ),
                      );
                    }
                    final height = entry.height!;
                    return HistoryEntryReveal(
                      highlighted: isHistoryHighlighted(
                        HistoryHighlightKeys.height(height),
                      ),
                      accentColor: AppTheme.heightHistoryAccent,
                      child: _HeightRecordTile(
                        record: height,
                        onDelete: height.id != null
                            ? () async {
                                final ok = await confirmDeleteRecord(context);
                                if (!context.mounted || !ok) return;
                                _deleteHeightRecord(height.id!);
                              }
                            : null,
                      ),
                    );
                  }),
                  if (hasMoreInList)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.historyScrollLoadMore,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, _) => StreamRecordLoadError(
            message: l10n.heightHistoryLoadError,
            onRetry: () => ref.invalidate(heightRecordsStreamProvider),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => StreamRecordLoadError(
        message: l10n.weightHistoryLoadError,
        onRetry: () => ref.invalidate(weightRecordsForChartStreamProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs =
        ref.watch(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    final chartRecordsAsync = widget.isActiveTab
        ? ref.watch(weightRecordsForChartStreamProvider)
        : ref.read(weightRecordsForChartStreamProvider);
    final heightRecordsAsync = widget.isActiveTab
        ? ref.watch(heightRecordsStreamProvider)
        : ref.read(heightRecordsStreamProvider);
    final historyVisibleLimit = ref.watch(growthHistoryVisibleLimitProvider);
    final useCommaDecimal =
        Localizations.localeOf(context).languageCode == 'es';
    final latestWeight = _latestWeightOf(
      _mergeOptimisticWeight(chartRecordsAsync.valueOrNull ?? const []),
    );
    final latestHeight = _latestHeightOf(
      _mergeOptimisticHeight(heightRecordsAsync.valueOrNull ?? const []),
    );
    final typedKg = parseWeightInputToKg(_weightController.text, prefs);
    final weightSuddenHint =
        latestWeight != null &&
            typedKg != null &&
            isSuddenWeightChange(
              previousKg: latestWeight.weightKg,
              previousAt: latestWeight.dateTime,
              nextKg: typedKg,
            )
        ? l10n.weightSuddenChangeHint(
            formatWeightFromKg(latestWeight.weightKg, prefs, l10n),
          )
        : null;
    final typedCm = parseHeightInputToCm(_heightController.text);
    final heightSuddenHint =
        latestHeight != null &&
            typedCm != null &&
            isSuddenHeightChange(
              previousCm: latestHeight.heightCm,
              previousAt: latestHeight.dateTime,
              nextCm: typedCm,
            )
        ? l10n.heightSuddenChangeHint(
            formatHeightFromCm(latestHeight.heightCm, l10n),
          )
        : null;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: ref
                  .watch(babyProfileProvider)
                  .when(
                    data: (baby) {
                      return GestureDetector(
                        onTap: () => FocusScope.of(context).unfocus(),
                        behavior: HitTestBehavior.opaque,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: _onWeightHistoryScrollNotification,
                          child: SingleChildScrollView(
                            controller: widget.scrollController,
                            padding: EdgeInsets.fromLTRB(
                              AppTheme.screenEdgePadding,
                              MainAppTitleBar.totalHeight +
                                  AppTheme.contentPaddingTopAfterTitleBar,
                              AppTheme.screenEdgePadding,
                              20 + AppTheme.safeBottomPadding(context),
                            ),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppTheme.sectionCardPadding,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.monitor_weight,
                                              color:
                                                  AppTheme.pageTitleIconWeight,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              l10n.weightTitle,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textDark,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        KeyboardActions(
                                          config: _weightKeyboardConfig(l10n),
                                          // Sin esto, BottomAreaAvoider mete LayoutBuilder +
                                          // SingleChildScrollView con minHeight = maxHeight del padre;
                                          // dentro del Column del card eso puede ser ∞ y rompe el layout.
                                          disableScroll: true,
                                          child: Form(
                                            key: _formKey,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  weightFieldLabelForPrefs(
                                                    prefs,
                                                    l10n,
                                                  ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        color:
                                                            AppTheme.textLight,
                                                      ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      flex: 2,
                                                      child: SizedBox(
                                                        height:
                                                            _weightControlHeight,
                                                        child: TextFormField(
                                                          controller:
                                                              _weightController,
                                                          focusNode:
                                                              _weightFocusNode,
                                                          keyboardType:
                                                              const TextInputType.numberWithOptions(
                                                                decimal: true,
                                                              ),
                                                          inputFormatters: const [
                                                            LooseDecimalInputFormatter(),
                                                          ],
                                                          textInputAction:
                                                              TextInputAction
                                                                  .done,
                                                          onFieldSubmitted: (_) =>
                                                              _weightFocusNode
                                                                  .unfocus(),
                                                          onTapOutside: (_) =>
                                                              _weightFocusNode
                                                                  .unfocus(),
                                                          expands: true,
                                                          maxLines: null,
                                                          minLines: null,
                                                          textAlignVertical:
                                                              TextAlignVertical
                                                                  .center,
                                                          decoration: InputDecoration(
                                                            hintText: weightEntryHint(
                                                              prefs,
                                                              l10n,
                                                              lastKg:
                                                                  latestWeight
                                                                      ?.weightKg,
                                                              useCommaDecimal:
                                                                  useCommaDecimal,
                                                            ),
                                                            contentPadding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      20,
                                                                ),
                                                            isDense: false,
                                                          ),
                                                          validator: (v) {
                                                            if (v == null ||
                                                                v
                                                                    .trim()
                                                                    .isEmpty) {
                                                              return l10n
                                                                  .weightValidatorEmpty;
                                                            }
                                                            final kg =
                                                                parseWeightInputToKg(
                                                                  v,
                                                                  prefs,
                                                                );
                                                            if (kg == null ||
                                                                kg <= 0 ||
                                                                kg > 50) {
                                                              return l10n
                                                                  .weightValidatorInvalid;
                                                            }
                                                            return null;
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: SizedBox(
                                                        height:
                                                            _weightControlHeight,
                                                        child: InlineConfirmingButton(
                                                          onPressed:
                                                              _registerWeight,
                                                          onSavedVisible:
                                                              _revealWeightHistory,
                                                          style: ElevatedButton.styleFrom(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      12,
                                                                ),
                                                            minimumSize: const Size(
                                                              0,
                                                              _weightControlHeight,
                                                            ),
                                                            maximumSize: const Size(
                                                              double.infinity,
                                                              _weightControlHeight,
                                                            ),
                                                            fixedSize: const Size(
                                                              double.infinity,
                                                              _weightControlHeight,
                                                            ),
                                                            tapTargetSize:
                                                                MaterialTapTargetSize
                                                                    .shrinkWrap,
                                                            visualDensity:
                                                                VisualDensity
                                                                    .compact,
                                                          ),
                                                          child: FittedBox(
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            child: Text(
                                                              l10n.weightRegister,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (weightSuddenHint != null)
                                                  _buildSuddenChangeHint(
                                                    weightSuddenHint,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildHeightCard(
                                  context,
                                  l10n,
                                  hintText: heightEntryHint(
                                    l10n,
                                    lastCm: latestHeight?.heightCm,
                                    useCommaDecimal: useCommaDecimal,
                                  ),
                                  suddenChangeHint: heightSuddenHint,
                                ),
                                const SizedBox(height: 24),
                                _buildGrowthHistorySection(
                                  context,
                                  l10n,
                                  chartRecordsAsync,
                                  heightRecordsAsync,
                                  historyVisibleLimit,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(
                      child: StreamRecordLoadError(
                        message: l10n.weightStreamError,
                        onRetry: () => ref.invalidate(babyProfileProvider),
                      ),
                    ),
                  ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: MainAppTitleBar(
                onTitleTap: widget.onTitleTap,
                onSettingsTap: widget.onSettingsTap,
              ),
            ),
            const TitleBarScrollFade(),
          ],
        ),
      ),
    );
  }
}

class _GrowthHistoryRecord {
  final WeightRecord? weight;
  final HeightRecord? height;

  const _GrowthHistoryRecord.weight(WeightRecord record)
    : weight = record,
      height = null;

  const _GrowthHistoryRecord.height(HeightRecord record)
    : weight = null,
      height = record;

  DateTime get dateTime => weight?.dateTime ?? height!.dateTime;
}

class _WeightRecordTile extends ConsumerWidget {
  final WeightRecord record;
  final VoidCallback? onDelete;

  const _WeightRecordTile({required this.record, this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs =
        ref.watch(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    final dateCode = dateFormatLanguageCode(context);
    final accent = AppTheme.weightHistoryAccent;
    final borderRadius = BorderRadius.circular(AppTheme.homeCardRadius);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: AppTheme.historyRecordStripeWidth,
                decoration: AppTheme.historyRecordStripeDecoration(accent),
              ),
              Padding(
                padding: AppTheme.historyRecordLeadingPadding,
                child: Center(
                  child: CircleAvatar(
                    radius: AppTheme.historyRecordAvatarRadius,
                    backgroundColor: accent.withValues(
                      alpha: AppTheme.historyRecordAvatarAccentOpacity,
                    ),
                    child: Icon(
                      Icons.monitor_weight_outlined,
                      color: accent,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: AppTheme.historyRecordContentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatWeightFromKg(record.weightKg, prefs, l10n),
                        style: AppTheme.historyRecordPrimaryValueStyle(accent),
                      ),
                      SizedBox(height: AppTheme.historyRecordDetailToDateGap),
                      Text(
                        DateFormat(
                          'd MMM, HH:mm',
                          dateCode,
                        ).format(record.dateTime),
                        style: AppTheme.historyRecordDateTimeStyle(context),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: AppTheme.historyRecordTrailingOuterPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () =>
                              _showEditDialog(context, ref, record),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    WeightRecord record,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final prefs =
        ref.read(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    final controller = TextEditingController(
      text: weightInputDisplayFromKg(record.weightKg, prefs),
    );
    var selectedAt = record.dateTime;
    final editWeightFocus = FocusNode();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => EditBottomSheet(
          title: l10n.weightEditTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                weightFieldLabelForPrefs(prefs, l10n),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                focusNode: editWeightFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: const [LooseDecimalInputFormatter()],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => editWeightFocus.unfocus(),
                onTapOutside: (_) => editWeightFocus.unfocus(),
                decoration: InputDecoration(
                  hintText: weightEntryHint(prefs, l10n),
                  filled: true,
                  fillColor: AppTheme.fieldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                    borderSide: const BorderSide(color: AppTheme.fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                    borderSide: const BorderSide(color: AppTheme.fieldBorder),
                  ),
                ),
              ),
              SizedBox(height: EditDialogTheme.spacingBetweenSections),
              EditListCard(
                children: [
                  EditInstantRow.dateTime(
                    context: context,
                    label: l10n.commonDateTime,
                    value: selectedAt,
                    showDivider: false,
                    onTap: () async {
                      final picked = await pickEditDateTime(
                        context,
                        initial: selectedAt,
                      );
                      if (picked != null) {
                        setState(() => selectedAt = picked);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          onCancel: () => Navigator.pop(ctx),
          onSave: () async {
            final kg = parseWeightInputToKg(controller.text, prefs);
            if (kg != null && kg > 0 && kg <= 50) {
              await IsarService.updateWeightRecord(
                record.copyWith(weightKg: kg, dateTime: selectedAt),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            }
          },
        ),
      ),
    ).whenComplete(() {
      editWeightFocus.dispose();
      controller.dispose();
    });
  }
}

class _HeightRecordTile extends StatelessWidget {
  final HeightRecord record;
  final VoidCallback? onDelete;

  const _HeightRecordTile({required this.record, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateCode = dateFormatLanguageCode(context);
    const accent = AppTheme.heightHistoryAccent;
    final borderRadius = BorderRadius.circular(AppTheme.homeCardRadius);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: AppTheme.historyRecordStripeWidth,
                decoration: AppTheme.historyRecordStripeDecoration(accent),
              ),
              Padding(
                padding: AppTheme.historyRecordLeadingPadding,
                child: Center(
                  child: CircleAvatar(
                    radius: AppTheme.historyRecordAvatarRadius,
                    backgroundColor: accent.withValues(
                      alpha: AppTheme.historyRecordAvatarAccentOpacity,
                    ),
                    child: const Icon(
                      Icons.height_rounded,
                      color: accent,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: AppTheme.historyRecordContentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatHeightFromCm(record.heightCm, l10n),
                        style: AppTheme.historyRecordPrimaryValueStyle(accent),
                      ),
                      SizedBox(height: AppTheme.historyRecordDetailToDateGap),
                      Text(
                        DateFormat(
                          'd MMM, HH:mm',
                          dateCode,
                        ).format(record.dateTime),
                        style: AppTheme.historyRecordDateTimeStyle(context),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: AppTheme.historyRecordTrailingOuterPadding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditDialog(context, record),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, HeightRecord record) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: heightInputDisplayFromCm(record.heightCm),
    );
    var selectedAt = record.dateTime;
    final editHeightFocus = FocusNode();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => EditBottomSheet(
          title: l10n.heightEditTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.heightFieldLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                focusNode: editHeightFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: const [LooseDecimalInputFormatter()],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => editHeightFocus.unfocus(),
                onTapOutside: (_) => editHeightFocus.unfocus(),
                decoration: InputDecoration(
                  hintText: l10n.hintExampleHeight,
                  filled: true,
                  fillColor: AppTheme.fieldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                    borderSide: const BorderSide(color: AppTheme.fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                    borderSide: const BorderSide(color: AppTheme.fieldBorder),
                  ),
                ),
              ),
              SizedBox(height: EditDialogTheme.spacingBetweenSections),
              EditListCard(
                children: [
                  EditInstantRow.dateTime(
                    context: context,
                    label: l10n.commonDateTime,
                    value: selectedAt,
                    showDivider: false,
                    onTap: () async {
                      final picked = await pickEditDateTime(
                        context,
                        initial: selectedAt,
                      );
                      if (picked != null) {
                        setState(() => selectedAt = picked);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          onCancel: () => Navigator.pop(ctx),
          onSave: () async {
            final cm = parseHeightInputToCm(controller.text);
            if (cm != null && cm >= 25 && cm <= 130) {
              await IsarService.updateHeightRecord(
                record.copyWith(heightCm: cm, dateTime: selectedAt),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            }
          },
        ),
      ),
    ).whenComplete(() {
      editHeightFocus.dispose();
      controller.dispose();
    });
  }
}
