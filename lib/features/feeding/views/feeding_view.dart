import 'dart:async';

import 'package:control_bebe/l10n/app_date_locale.dart';
import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:control_bebe/l10n/app_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/main_app_title_bar.dart';
import '../../../core/theme/edit_dialog_theme.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/providers/record_stream_providers.dart';
import '../../../core/widgets/edit_bottom_sheet.dart';
import '../../../core/widgets/edit_list_rows.dart';
import '../../../core/widgets/inline_confirming_button.dart';
import '../../../core/services/next_feeding_notification_service.dart';
import '../../../core/services/lactation_live_activity_service.dart';
import '../../../core/services/lactation_timer_controller.dart';
import '../../../core/widgets/stream_record_load_error.dart';
import '../../../core/widgets/confirm_delete_record_dialog.dart';
import '../../../core/models/measurement_units.dart';
import '../../../core/providers/measurement_prefs_provider.dart';
import '../../../core/utils/measurement_display.dart';
import '../../../core/models/feeding_record.dart';
import '../../../core/models/lactation_timer.dart';
import '../../../core/models/enums.dart';
import 'bottle_view.dart';
import 'solid_food_view.dart';
import '../widgets/breast_side_picker_sheet.dart';
import '../../../core/utils/feeding_ml_estimate.dart';
import '../../../core/utils/solid_food_display.dart';
import '../../../core/utils/history_calendar_window.dart';
import '../../../core/utils/history_highlight.dart';
import '../../../core/widgets/history_entry_reveal.dart';

class FeedingView extends ConsumerStatefulWidget {
  final VoidCallback? onTitleTap;
  final VoidCallback onSettingsTap;
  final ScrollController? scrollController;
  final bool isActiveTab;

  const FeedingView({
    super.key,
    this.onTitleTap,
    required this.onSettingsTap,
    this.scrollController,
    this.isActiveTab = true,
  });

  @override
  ConsumerState<FeedingView> createState() => _FeedingViewState();
}

enum _FeedTypeSlot { breast, bottle, solid }

class _FeedingViewState extends ConsumerState<FeedingView>
    with HistoryHighlightState, WidgetsBindingObserver {
  Timer? _timer;
  StreamSubscription<void>? _timerChangedSub;
  LactationTimer? _activeTimer;
  FeedingRecord? _optimisticFeedingRecord;
  FeedingRecord? _pendingHistoryReveal;
  bool _awaitingHistoryReveal = false;
  _FeedTypeSlot? _confirmingSlot;
  InlineSavePhase _confirmPhase = InlineSavePhase.idle;
  final Set<int> _deletedFeedingIds = {};
  DateTime _lastHistoryScrollExpand = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _isConfirming => _confirmPhase != InlineSavePhase.idle;

  InlineSavePhase _phaseForSlot(_FeedTypeSlot slot) =>
      _confirmingSlot == slot ? _confirmPhase : InlineSavePhase.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadActiveTimer();
    _timerChangedSub = LactationTimerController.onTimerChanged.listen((_) {
      unawaited(_loadActiveTimer());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timerChangedSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        LactationTimerController.reloadFromDisk().then(
          (_) => _loadActiveTimer(),
        ),
      );
    }
  }

  Future<void> _loadActiveTimer() async {
    final timer = await IsarService.getActiveLactationTimer();
    if (mounted) {
      setState(() => _activeTimer = timer);
      if (timer != null) {
        _startTick();
        unawaited(LactationLiveActivityService.syncForActiveTimer());
      }
    }
  }

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_activeTimer?.isPaused == true) return;
      setState(() {});
    });
  }

  Future<void> _togglePauseBreast() async {
    if (_activeTimer == null || _isConfirming) return;
    await LactationTimerController.togglePause();
    await _loadActiveTimer();
  }

  Future<void> _startBreast(LactationSide side) async {
    final now = DateTime.now();
    // Actualizar UI inmediatamente sin esperar confirmación de red
    if (mounted) {
      setState(() {
        _activeTimer = LactationTimer(side: side, startedAt: now);
      });
      _startTick();
    }
    await IsarService.startLactationTimer(side);
    unawaited(NextFeedingNotificationService.cancelScheduled());
    unawaited(LactationLiveActivityService.syncForActiveTimer());
  }

  Future<void> _runFeedTypeConfirm({
    required _FeedTypeSlot slot,
    required Future<bool> Function() action,
    VoidCallback? onSavedVisible,
  }) async {
    if (_isConfirming) return;

    HapticFeedback.lightImpact();
    setState(() {
      _confirmingSlot = slot;
      _confirmPhase = InlineSavePhase.loading;
    });

    final startedAt = DateTime.now();
    var saved = false;
    try {
      saved = await action();
    } catch (_) {
      if (mounted) {
        setState(() {
          _confirmPhase = InlineSavePhase.idle;
          _confirmingSlot = null;
        });
      }
      rethrow;
    }

    if (!mounted) return;

    final elapsed = DateTime.now().difference(startedAt);
    const minLoading = Duration(milliseconds: 750);
    final remaining = minLoading - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) return;

    if (!saved) {
      setState(() {
        _confirmPhase = InlineSavePhase.idle;
        _confirmingSlot = null;
      });
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _confirmPhase = InlineSavePhase.saved);
    onSavedVisible?.call();

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _confirmPhase = InlineSavePhase.idle;
      _confirmingSlot = null;
    });
  }

  Future<void> _handleStopBreast() async {
    if (_isConfirming) return;
    if (_activeTimer == null) {
      final stored = await IsarService.getActiveLactationTimer();
      if (stored == null) return;
      if (mounted) {
        setState(() => _activeTimer = stored);
        _startTick();
      }
    }

    unawaited(LactationLiveActivityService.stop());
    _timer?.cancel();
    _completeStoppedBreastTimer();

    await _runFeedTypeConfirm(
      slot: _FeedTypeSlot.breast,
      action: _persistStoppedBreast,
      onSavedVisible: _revealFeedingHistory,
    );
  }

  Future<bool> _persistStoppedBreast() async {
    final active = await IsarService.getActiveLactationTimer();
    if (active == null) return false;
    final durationSeconds = active.elapsed.inSeconds;
    final stopped = await IsarService.stopLactationTimer();
    if (stopped == null) return false;
    final record = FeedingRecord(
      type: stopped.side == LactationSide.left
          ? FeedingType.leftBreast
          : FeedingType.rightBreast,
      dateTime: stopped.startedAt,
      durationSeconds: durationSeconds,
    );
    setState(() {
      _pendingHistoryReveal = record;
      _awaitingHistoryReveal = true;
    });
    await IsarService.addFeedingRecord(record);
    await NextFeedingNotificationService.syncFromStorage();
    return true;
  }

  Future<void> _confirmFeedTypeFromRoute({
    required _FeedTypeSlot slot,
    required FeedingRecord record,
  }) async {
    await _runFeedTypeConfirm(
      slot: slot,
      action: () async {
        setState(() {
          _pendingHistoryReveal = record;
          _awaitingHistoryReveal = true;
        });
        await IsarService.addFeedingRecord(record);
        await NextFeedingNotificationService.syncFromStorage();
        return true;
      },
      onSavedVisible: () {
        markHistoryHighlight(HistoryHighlightKeys.feeding(record));
        setState(() {
          _optimisticFeedingRecord = record;
          _awaitingHistoryReveal = false;
          _pendingHistoryReveal = null;
        });
      },
    );
  }

  void _revealFeedingHistory() {
    final record = _pendingHistoryReveal;
    if (record == null) return;
    markHistoryHighlight(HistoryHighlightKeys.feeding(record));
    setState(() {
      _optimisticFeedingRecord = record;
      _awaitingHistoryReveal = false;
      _pendingHistoryReveal = null;
    });
  }

  void _completeStoppedBreastTimer() {
    if (mounted) setState(() => _activeTimer = null);
  }

  Future<void> _openBottle() async {
    if (_isConfirming) return;
    final record = await Navigator.push<FeedingRecord>(
      context,
      MaterialPageRoute(builder: (_) => const BottleView()),
    );
    if (record != null && mounted) {
      await _confirmFeedTypeFromRoute(
        slot: _FeedTypeSlot.bottle,
        record: record,
      );
    }
  }

  Future<void> _onBreastTypeTap() async {
    if (_activeTimer != null) {
      await _handleStopBreast();
      return;
    }
    if (_isConfirming) return;
    final side = await showBreastSidePickerSheet(context);
    if (!mounted || side == null) return;
    await _startBreast(side);
  }

  Future<void> _openSolidFood() async {
    if (_isConfirming) return;
    final record = await Navigator.push<FeedingRecord>(
      context,
      MaterialPageRoute(builder: (_) => const SolidFoodView()),
    );
    if (record != null && mounted) {
      await _confirmFeedTypeFromRoute(
        slot: _FeedTypeSlot.solid,
        record: record,
      );
    }
  }

  void _deleteFeedingRecord(int id) {
    setState(() => _deletedFeedingIds.add(id));
    unawaited(
      IsarService.deleteFeedingRecord(id).then((_) {
        if (mounted) setState(() => _deletedFeedingIds.remove(id));
      }),
    );
  }

  List<FeedingRecord> _feedingRecordsWithoutDeleted(List<FeedingRecord> raw) {
    final out = List<FeedingRecord>.from(raw)
      ..removeWhere((r) => r.id != null && _deletedFeedingIds.contains(r.id));
    return _mergeOptimisticFeeding(
      hidePendingHistoryRecord(
        records: out,
        awaitingReveal: _awaitingHistoryReveal,
        pending: _pendingHistoryReveal,
        matchesPending: HistoryHighlightKeys.feedingMatchesPending,
      ),
    );
  }

  List<FeedingRecord> _mergeOptimisticFeeding(List<FeedingRecord> records) {
    final opt = _optimisticFeedingRecord;
    if (opt == null) return records;
    final match = records.any(
      (r) =>
          r.type == opt.type &&
          HistoryHighlightKeys.recordsMatchWithinSeconds(
            r.dateTime,
            opt.dateTime,
          ),
    );
    if (match) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _optimisticFeedingRecord = null);
      });
      return records;
    }
    return [opt, ...records];
  }

  bool _onFeedingHistoryScrollNotification(ScrollNotification n) {
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
    final days = ref.read(feedingHistoryFirestoreDaysProvider);
    if (days >= kHistoryPaginationMaxDays) {
      return false;
    }
    _lastHistoryScrollExpand = now;
    unawaited(_maybeExpandFeedingHistoryWindow());
    return false;
  }

  Future<void> _maybeExpandFeedingHistoryWindow() async {
    final hasOlder = await ref.read(hasOlderFeedingRecordsProvider.future);
    if (!mounted || !hasOlder) return;
    final days = ref.read(feedingHistoryFirestoreDaysProvider);
    if (days >= kHistoryPaginationMaxDays) return;
    ref.read(feedingHistoryFirestoreDaysProvider.notifier).state =
        days + kHistoryPaginationStepDays;
  }

  Widget _feedingHistoryColumn(
    BuildContext context,
    List<FeedingRecord> records,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final dateCode = dateFormatLanguageCode(context);
    final prefs =
        ref.watch(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    final sorted = List<FeedingRecord>.from(records)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    // Ocultar registros borrados optimistamente
    sorted.removeWhere(
      (r) => r.id != null && _deletedFeedingIds.contains(r.id),
    );
    final grouped = <String, List<FeedingRecord>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    for (final r in sorted) {
      final d = r.dateTime;
      final day = DateTime(d.year, d.month, d.day);
      String key;
      if (day == today) {
        key = l10n.today;
      } else if (day == yesterday) {
        key = l10n.yesterday;
      } else {
        key = DateFormat('d/M', dateCode).format(d);
      }
      grouped.putIfAbsent(key, () => []).add(r);
    }
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    if (sorted.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.historyTitle, style: titleStyle),
          const SizedBox(height: 12),
          Text(
            l10n.feedingHistoryEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textLight,
              height: 1.4,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.historyTitle, style: titleStyle),
        const SizedBox(height: 16),
        ...grouped.entries.expand(
          (e) => [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.key,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight,
                  ),
                ),
                Text(
                  formatVolumeFromMl(
                    sumEstimatedFeedingMl(e.value).round(),
                    prefs,
                    l10n,
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textLight),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...e.value.map(
              (r) => HistoryEntryReveal(
                highlighted: isHistoryHighlighted(
                  HistoryHighlightKeys.feeding(r),
                ),
                accentColor: feedingHistoryAccent(r.type),
                child: _FeedingRecordTile(
                  record: r,
                  onDelete: r.id != null
                      ? () async {
                          final ok = await confirmDeleteRecord(context);
                          if (!context.mounted || !ok) return;
                          _deleteFeedingRecord(r.id!);
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final feedingRecordsAsync = widget.isActiveTab
        ? ref.watch(feedingRecordsStreamProvider)
        : ref.read(feedingRecordsStreamProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onFeedingHistoryScrollNotification,
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.screenEdgePadding,
                    MainAppTitleBar.totalHeight +
                        AppTheme.contentPaddingTopAfterTitleBar,
                    AppTheme.screenEdgePadding,
                    20 + AppTheme.safeBottomPadding(context),
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppTheme.sectionCardPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.utensils,
                                color: AppTheme.pageTitleIconFeeding,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.feedingTitle,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 360),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            child: _activeTimer == null
                                ? const SizedBox.shrink()
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 340,
                                        ),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        transitionBuilder: (child, animation) {
                                          final slide =
                                              Tween<Offset>(
                                                begin: const Offset(0, -0.12),
                                                end: Offset.zero,
                                              ).animate(
                                                CurvedAnimation(
                                                  parent: animation,
                                                  curve: Curves.easeOutCubic,
                                                ),
                                              );
                                          return SizedBox(
                                            width: double.infinity,
                                            child: ClipRect(
                                              child: FadeTransition(
                                                opacity: animation,
                                                child: SlideTransition(
                                                  position: slide,
                                                  child: child,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: _ActiveTimerBanner(
                                          key: ValueKey(
                                            'lactation_${_activeTimer!.startedAt.millisecondsSinceEpoch}_'
                                            '${_activeTimer!.side.index}',
                                          ),
                                          timer: _activeTimer!,
                                          onPause: () =>
                                              unawaited(_togglePauseBreast()),
                                          onStop: () =>
                                              unawaited(_handleStopBreast()),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                          ),
                          Text(
                            l10n.feedingSessionType,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: AppTheme.textLight),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _TomaTypeButton(
                                  label: l10n.feedingBreast,
                                  isActive: _activeTimer != null,
                                  confirmPhase: _phaseForSlot(
                                    _FeedTypeSlot.breast,
                                  ),
                                  onTap: _onBreastTypeTap,
                                  iconBuilder: (c) => FaIcon(
                                    FontAwesomeIcons.personBreastfeeding,
                                    size: 28,
                                    color: c,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TomaTypeButton(
                                  label: l10n.feedingBottle,
                                  isActive: false,
                                  confirmPhase: _phaseForSlot(
                                    _FeedTypeSlot.bottle,
                                  ),
                                  onTap: _openBottle,
                                  iconBuilder: (c) => Icon(
                                    MdiIcons.babyBottle,
                                    size: 28,
                                    color: c,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TomaTypeButton(
                                  label: l10n.feedingSolidFood,
                                  isActive: false,
                                  confirmPhase: _phaseForSlot(
                                    _FeedTypeSlot.solid,
                                  ),
                                  onTap: _openSolidFood,
                                  iconBuilder: (c) => Icon(
                                    MdiIcons.silverwareForkKnife,
                                    size: 28,
                                    color: c,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          feedingRecordsAsync.when(
                            skipLoadingOnReload: true,
                            data: (records) {
                              final truncateDays = ref.watch(
                                feedingHistoryFirestoreDaysProvider,
                              );
                              final visible = historyRecordsOnOrAfter(
                                records,
                                (r) => r.dateTime,
                                historyWindowStartForDays(truncateDays),
                              );
                              final merged = _feedingRecordsWithoutDeleted(
                                visible,
                              );
                              return _feedingHistoryColumn(context, merged);
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => StreamRecordLoadError(
                              message: l10n.feedingStreamError,
                              onRetry: () =>
                                  ref.invalidate(feedingRecordsStreamProvider),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _ActiveTimerBanner extends StatelessWidget {
  final LactationTimer timer;
  final VoidCallback onPause;
  final VoidCallback onStop;

  const _ActiveTimerBanner({
    super.key,
    required this.timer,
    required this.onPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalSeconds = timer.elapsed.inSeconds;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.softPrimaryFill,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Row(
        children: [
          timer.side == LactationSide.left
              ? const FaIcon(
                  FontAwesomeIcons.personBreastfeeding,
                  color: AppTheme.palettePrimary,
                  size: 32,
                )
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(-1, 1, 1),
                  child: const FaIcon(
                    FontAwesomeIcons.personBreastfeeding,
                    color: AppTheme.palettePrimary,
                    size: 32,
                  ),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.feedingActiveTimer(
                    timer.side == LactationSide.left
                        ? l10n.feedingSideLeft
                        : l10n.feedingSideRight,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  formatDurationSecondsLocalized(l10n, totalSeconds),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.palettePrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onPause,
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.palettePrimary.withValues(alpha: 0.12),
              foregroundColor: AppTheme.palettePrimary,
            ),
            icon: Icon(
              timer.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            tooltip: timer.isPaused ? l10n.feedingResume : l10n.feedingPause,
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onStop,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.palettePrimary,
            ),
            child: Text(l10n.feedingStop),
          ),
        ],
      ),
    );
  }
}

typedef _TomaIconBuilder = Widget Function(Color iconColor);

/// Pecho / Biberón / Sólidos: misma tarjeta; el cronómetro marca `isActive` en pecho.
class _TomaTypeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final InlineSavePhase confirmPhase;
  final VoidCallback onTap;
  final _TomaIconBuilder iconBuilder;

  const _TomaTypeButton({
    required this.label,
    required this.isActive,
    this.confirmPhase = InlineSavePhase.idle,
    required this.onTap,
    required this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSaved = confirmPhase == InlineSavePhase.saved;
    final isConfirming = confirmPhase != InlineSavePhase.idle;

    final iconColor = isSaved
        ? Colors.white
        : (isActive ? AppTheme.palettePrimary : AppTheme.textLight);
    final surface = isSaved
        ? AppTheme.primaryGreen
        : (isActive ? const Color(0xFFF5F5F5) : Colors.white);
    final borderColor = isSaved
        ? AppTheme.primaryGreen
        : (isActive
              ? AppTheme.palettePrimary.withValues(alpha: 0.55)
              : AppTheme.fieldBorder);
    final borderWidth = isActive || isSaved ? 2.0 : 1.5;
    final labelColor = isSaved
        ? Colors.white
        : (isActive ? AppTheme.textDark : AppTheme.textLight);

    return Material(
      color: surface,
      elevation: isActive || isSaved ? 2 : 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      child: InkWell(
        onTap: isConfirming ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        splashColor: AppTheme.palettePrimary.withValues(alpha: 0.12),
        highlightColor: AppTheme.palettePrimary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: switch (confirmPhase) {
              InlineSavePhase.loading => Column(
                key: const ValueKey(InlineSavePhase.loading),
                children: [
                  SoftSpinner(color: iconColor),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              InlineSavePhase.saved => Column(
                key: const ValueKey(InlineSavePhase.saved),
                children: [
                  Icon(Icons.check_circle_rounded, size: 28, color: iconColor),
                  const SizedBox(height: 8),
                  Text(
                    l10n.commonSaved,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              InlineSavePhase.idle => Column(
                key: const ValueKey(InlineSavePhase.idle),
                children: [
                  iconBuilder(iconColor),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: labelColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _FeedingRecordTile extends ConsumerWidget {
  final FeedingRecord record;
  final VoidCallback? onDelete;

  const _FeedingRecordTile({required this.record, this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs =
        ref.watch(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    final dateCode = dateFormatLanguageCode(context);
    final (icon, label, accentColor, mirrored) = switch (record.type) {
      FeedingType.leftBreast => (
        FontAwesomeIcons.personBreastfeeding,
        l10n.feedingLeft,
        AppTheme.feedingHistoryLeftAccent,
        false,
      ),
      FeedingType.rightBreast => (
        FontAwesomeIcons.personBreastfeeding,
        l10n.feedingRight,
        AppTheme.feedingHistoryRightAccent,
        true,
      ),
      FeedingType.bottle => (
        MdiIcons.babyBottle,
        l10n.feedingBottle,
        AppTheme.feedingHistoryBottleAccent,
        false,
      ),
      FeedingType.solidFood => (
        MdiIcons.silverwareForkKnife,
        '',
        AppTheme.feedingHistorySolidAccent,
        false,
      ),
    };
    final duration =
        record.type != FeedingType.solidFood && record.durationSeconds != null
        ? formatDurationSecondsLocalized(l10n, record.durationSeconds!)
        : null;
    final amount = record.type == FeedingType.bottle && record.amountMl != null
        ? formatVolumeFromMl(record.amountMl!, prefs, l10n)
        : null;
    final secondaryDetail = record.type == FeedingType.solidFood
        ? null
        : [?duration, ?amount].nonNulls.join(' ').isEmpty
        ? null
        : [?duration, ?amount].nonNulls.join(' ');
    final solidNameLine = record.type == FeedingType.solidFood
        ? record.solidName?.trim()
        : null;
    final solidQtyLine = record.type == FeedingType.solidFood
        ? solidFoodQuantityLabel(
            l10n,
            record.solidQuantity,
            record.solidUnit,
            dateFormatLanguageCode(context),
          )
        : null;
    final hasSolidLines =
        record.type == FeedingType.solidFood &&
        ((solidNameLine != null && solidNameLine.isNotEmpty) ||
            solidQtyLine != null);
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
                decoration: AppTheme.historyRecordStripeDecoration(accentColor),
              ),
              Padding(
                padding: AppTheme.historyRecordLeadingPadding,
                child: Center(
                  child: CircleAvatar(
                    radius: AppTheme.historyRecordAvatarRadius,
                    backgroundColor: accentColor.withValues(
                      alpha: AppTheme.historyRecordAvatarAccentOpacity,
                    ),
                    child:
                        record.type == FeedingType.bottle ||
                            record.type == FeedingType.solidFood
                        ? Icon(icon, color: accentColor, size: 22)
                        : (mirrored
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.diagonal3Values(-1, 1, 1),
                                  child: FaIcon(
                                    icon,
                                    color: accentColor,
                                    size: 20,
                                  ),
                                )
                              : FaIcon(icon, color: accentColor, size: 20)),
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
                      if (record.type == FeedingType.solidFood) ...[
                        if (solidNameLine != null &&
                            solidNameLine.isNotEmpty) ...[
                          Text(
                            solidNameLine,
                            style: AppTheme.historyRecordTypeTitleStyle(
                              accentColor,
                            ),
                          ),
                        ],
                        if (solidQtyLine != null) ...[
                          if (solidNameLine != null && solidNameLine.isNotEmpty)
                            SizedBox(
                              height: AppTheme.historyRecordAfterTitleGap,
                            ),
                          Text(
                            solidQtyLine,
                            style: AppTheme.historyRecordPrimaryValueStyle(
                              accentColor,
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          label,
                          style: AppTheme.historyRecordTypeTitleStyle(
                            accentColor,
                          ),
                        ),
                        if (secondaryDetail != null) ...[
                          SizedBox(height: AppTheme.historyRecordAfterTitleGap),
                          Text(
                            secondaryDetail,
                            style: AppTheme.historyRecordPrimaryValueStyle(
                              accentColor,
                            ),
                          ),
                        ],
                      ],
                      SizedBox(
                        height: (secondaryDetail != null || hasSolidLines)
                            ? AppTheme.historyRecordDetailToDateGap
                            : AppTheme.historyRecordAfterTitleGap,
                      ),
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
    FeedingRecord record,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (record.type == FeedingType.solidFood) {
      final localeCode = dateFormatLanguageCode(context);
      final nameController = TextEditingController(
        text: record.solidName ?? '',
      );
      final initialUnit = record.solidUnit ?? SolidQuantityUnit.grams;
      final qtyController = TextEditingController(
        text: formatSolidQuantityForField(
          record.solidQuantity,
          initialUnit,
          localeCode,
        ),
      );
      var solidUnit = initialUnit;
      var selectedAt = record.dateTime;
      final fieldDeco = InputDecoration(
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
      );
      final solidEditFormKey = GlobalKey<FormState>();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (modalContext, setState) {
            final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            );
            return EditBottomSheet(
              title: l10n.feedingEditSolid,
              child: Form(
                key: solidEditFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.solidFoodNameLabel, style: labelStyle),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: fieldDeco.copyWith(
                        hintText: l10n.solidFoodNameHint,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.solidFoodValidatorNameEmpty;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: EditDialogTheme.spacingBetweenSections),
                    Text(l10n.solidFoodQuantityLabel, style: labelStyle),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: qtyController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: solidUnit == SolidQuantityUnit.grams,
                        signed: false,
                      ),
                      inputFormatters: [
                        if (solidUnit == SolidQuantityUnit.grams)
                          SolidGramsQuantityInputFormatter()
                        else
                          SolidUnitsQuantityInputFormatter(),
                      ],
                      decoration: fieldDeco.copyWith(
                        hintText: solidUnit == SolidQuantityUnit.grams
                            ? l10n.solidFoodQuantityHintGrams
                            : l10n.solidFoodQuantityHintUnits,
                      ),
                      validator: (v) =>
                          validateSolidQuantityInput(v, solidUnit, l10n),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<SolidQuantityUnit>(
                      segments: [
                        ButtonSegment(
                          value: SolidQuantityUnit.grams,
                          label: Text(l10n.solidFoodUnitGrams),
                        ),
                        ButtonSegment(
                          value: SolidQuantityUnit.units,
                          label: Text(l10n.solidFoodUnitUnits),
                        ),
                      ],
                      selected: {solidUnit},
                      onSelectionChanged: (s) {
                        final nu = s.first;
                        setState(() {
                          solidUnit = nu;
                          if (nu == SolidQuantityUnit.units) {
                            final raw = qtyController.text.trim();
                            if (raw.contains(',') || raw.contains('.')) {
                              final g = tryParseSolidQuantity(
                                raw,
                                SolidQuantityUnit.grams,
                              );
                              if (g != null) {
                                qtyController.text = g.round().toString();
                              } else {
                                qtyController.clear();
                              }
                            }
                          }
                        });
                      },
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
              ),
              onCancel: () => Navigator.pop(ctx),
              onSave: () async {
                if (solidEditFormKey.currentState?.validate() != true) return;
                final name = nameController.text.trim();
                final q = tryParseSolidQuantity(qtyController.text, solidUnit);
                if (q == null || !q.isFinite) return;
                await IsarService.updateFeedingRecord(
                  record.copyWith(
                    dateTime: selectedAt,
                    solidName: name,
                    solidQuantity: q,
                    solidUnit: solidUnit,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          },
        ),
      );
    } else if (record.type == FeedingType.bottle) {
      final prefs =
          ref.read(measurementPrefsProvider).valueOrNull ??
          MeasurementPrefs.defaultsForDispatcher();
      final ml0 = record.amountMl ?? 0;
      final initialVolumeText = prefs.liquid == LiquidUnitMode.milliliters
          ? '$ml0'
          : trimFlOzDisplay(mlToUsFlOzNum(ml0));
      final controller = TextEditingController(text: initialVolumeText);
      final liquidLabel = prefs.liquid == LiquidUnitMode.milliliters
          ? l10n.feedingAmountMl
          : l10n.liquidFieldLabelFlOz;
      var selectedAt = record.dateTime;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (modalContext, setState) => EditBottomSheet(
            title: l10n.feedingEditBottle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  liquidLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: bottleVolumeHint(prefs, l10n),
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
              final ml = parseVolumeInputToMl(controller.text, prefs);
              if (ml != null && ml > 0 && ml <= kMaxReasonableVolumeMl) {
                await IsarService.updateFeedingRecord(
                  record.copyWith(amountMl: ml, dateTime: selectedAt),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
          ),
        ),
      );
    } else {
      final startDt = record.dateTime;
      final endDt = startDt.add(Duration(seconds: record.durationSeconds ?? 0));
      var selectedStart = startDt;
      var selectedEnd = endDt;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) => EditBottomSheet(
            title: l10n.feedingEditSession,
            child: EditListCard(
              children: [
                EditInstantRow.dateTime(
                  context: context,
                  icon: Icons.play_arrow_rounded,
                  label: l10n.commonTimeStart,
                  value: selectedStart,
                  onTap: () async {
                    final picked = await pickEditDateTime(
                      context,
                      initial: selectedStart,
                    );
                    if (picked == null) return;
                    setState(() {
                      selectedStart = picked;
                      selectedEnd = ensureDateTimeAfter(
                        selectedStart,
                        selectedEnd,
                      );
                    });
                  },
                ),
                EditInstantRow.dateTime(
                  context: context,
                  icon: Icons.stop_rounded,
                  label: l10n.commonTimeEnd,
                  value: selectedEnd,
                  showDivider: false,
                  onTap: () async {
                    final picked = await pickEditDateTime(
                      context,
                      initial: selectedEnd.isAfter(selectedStart)
                          ? selectedEnd
                          : selectedStart.add(const Duration(minutes: 1)),
                      minimumDate: selectedStart,
                    );
                    if (picked == null) return;
                    setState(
                      () => selectedEnd = ensureDateTimeAfter(
                        selectedStart,
                        picked,
                      ),
                    );
                  },
                ),
              ],
            ),
            onCancel: () => Navigator.pop(ctx),
            onSave: () async {
              final end = ensureDateTimeAfter(selectedStart, selectedEnd);
              final durationSec = end.difference(selectedStart).inSeconds;
              if (durationSec <= 0) return;
              await IsarService.updateFeedingRecord(
                record.copyWith(
                  dateTime: selectedStart,
                  durationSeconds: durationSec,
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        ),
      );
    }
  }
}
