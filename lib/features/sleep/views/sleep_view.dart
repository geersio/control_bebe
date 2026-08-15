import 'dart:async';

import 'package:control_bebe/l10n/app_date_locale.dart';
import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:control_bebe/l10n/app_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/isar_service.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/sleep_record.dart';
import '../../../core/providers/record_stream_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/history_calendar_window.dart';
import '../../../core/utils/history_highlight.dart';
import '../../../core/utils/infer_sleep_type.dart';
import '../../../core/utils/sleep_history_tree.dart';
import '../../../core/widgets/confirm_delete_record_dialog.dart';
import '../../../core/widgets/history_entry_reveal.dart';
import '../../../core/widgets/main_app_title_bar.dart';
import '../../../core/widgets/stream_record_load_error.dart';
import '../widgets/sleep_edit_sheet.dart';
import '../widgets/sleep_live_session_card.dart';
import '../widgets/sleep_past_sleep_sheet.dart';
import '../widgets/sleep_type_segmented_control.dart';

class SleepView extends ConsumerStatefulWidget {
  final VoidCallback? onTitleTap;
  final VoidCallback onSettingsTap;
  final ScrollController? scrollController;
  final bool isActiveTab;

  const SleepView({
    super.key,
    this.onTitleTap,
    required this.onSettingsTap,
    this.scrollController,
    this.isActiveTab = true,
  });

  @override
  ConsumerState<SleepView> createState() => _SleepViewState();
}

class _SleepViewState extends ConsumerState<SleepView>
    with HistoryHighlightState {
  SleepRecord? _optimisticRecord;
  SleepRecord? _pendingHistoryReveal;
  bool _awaitingHistoryReveal = false;
  DateTime _fallbackAwakeSince = DateTime.now();
  DateTime? _manualAwakeSince;
  DateTime _lastHistoryScrollExpand = DateTime.fromMillisecondsSinceEpoch(0);
  final Set<int> _deletedIds = {};

  List<SleepRecord> _recordsForHistory(List<SleepRecord> records) {
    final filtered = records.where((r) {
      final id = r.id;
      return id == null || !_deletedIds.contains(id);
    }).toList();
    return _mergeOptimistic(
      hidePendingHistoryRecord(
        records: filtered,
        awaitingReveal: _awaitingHistoryReveal,
        pending: _pendingHistoryReveal,
        matchesPending: HistoryHighlightKeys.sleepMatchesPending,
      ),
    );
  }

  /// Registros para el estado live (incluye pendientes de revelar en historial).
  List<SleepRecord> _recordsForLive(List<SleepRecord> records) {
    final filtered = records.where((r) {
      final id = r.id;
      return id == null || !_deletedIds.contains(id);
    }).toList();
    var merged = _mergeOptimistic(filtered);
    final pending = _pendingHistoryReveal;
    if (!_awaitingHistoryReveal || pending == null) return merged;

    // Al cerrar: evita que el stream muestre aún la sesión abierta.
    if (pending.endDateTime != null) {
      merged = merged.where((r) {
        if (!r.isOpen) return true;
        final sameId = pending.id != null && r.id == pending.id;
        final sameStart =
            r.startDateTime.millisecondsSinceEpoch ==
            pending.startDateTime.millisecondsSinceEpoch;
        return !(sameId || sameStart);
      }).toList();
    }

    final already = merged.any(
      (r) => HistoryHighlightKeys.sleepMatchesPending(r, pending),
    );
    if (already) return merged;
    return [pending, ...merged];
  }

  List<SleepRecord> _mergeOptimistic(List<SleepRecord> records) {
    final opt = _optimisticRecord;
    if (opt == null) return records;
    final match = records.any((r) {
      final endMatch = opt.endDateTime == null
          ? r.endDateTime == null
          : r.endDateTime != null &&
                HistoryHighlightKeys.recordsMatchWithinSeconds(
                  r.endDateTime!,
                  opt.endDateTime!,
                );
      return endMatch &&
          HistoryHighlightKeys.recordsMatchWithinSeconds(
            r.startDateTime,
            opt.startDateTime,
          ) &&
          r.type == opt.type;
    });
    if (match) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _optimisticRecord = null);
      });
      return records;
    }
    return [opt, ...records];
  }

  bool _onSleepHistoryScrollNotification(ScrollNotification n) {
    if (n.metrics.extentAfter > 240) return false;
    final now = DateTime.now();
    if (now.difference(_lastHistoryScrollExpand) <
        const Duration(milliseconds: 700)) {
      return false;
    }
    final days = ref.read(sleepHistoryFirestoreDaysProvider);
    if (days >= kHistoryPaginationMaxDays) {
      return false;
    }
    _lastHistoryScrollExpand = now;
    unawaited(_maybeExpandSleepHistoryWindow());
    return false;
  }

  Future<void> _maybeExpandSleepHistoryWindow() async {
    final hasOlder = await ref.read(hasOlderSleepRecordsProvider.future);
    if (!mounted || !hasOlder) return;
    final days = ref.read(sleepHistoryFirestoreDaysProvider);
    if (days >= kHistoryPaginationMaxDays) return;
    ref.read(sleepHistoryFirestoreDaysProvider.notifier).state =
        days + kHistoryPaginationStepDays;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _registerFellAsleep(List<SleepRecord> known) async {
    final open = findOpenSleepSession(known);
    if (open != null) return false;
    final start = DateTime.now();
    final record = SleepRecord(
      startDateTime: start,
      endDateTime: null,
      type: inferSleepType(start: start),
    );
    setState(() {
      _pendingHistoryReveal = record;
      _awaitingHistoryReveal = true;
      _manualAwakeSince = null;
    });
    final id = await IsarService.addSleepRecord(record);
    setState(() {
      _pendingHistoryReveal = record.copyWith(id: id);
    });
    return true;
  }

  Future<bool> _registerWokeUp(
    List<SleepRecord> known,
    AppLocalizations l10n,
  ) async {
    final open = findOpenSleepSession(known);
    if (open == null) {
      _snack(l10n.sleepNoOpenSessionToEnd);
      return false;
    }
    final end = DateTime.now();
    if (!open.startDateTime.isBefore(end)) return false;
    final updated = open.copyWith(
      endDateTime: end,
      type: inferSleepType(start: open.startDateTime, end: end),
    );
    setState(() {
      _pendingHistoryReveal = updated;
      _awaitingHistoryReveal = true;
      _fallbackAwakeSince = end;
      _manualAwakeSince = null;
    });
    await IsarService.updateSleepRecord(updated);
    return true;
  }

  DateTime? _lastWakeAt(List<SleepRecord> records) {
    DateTime? latest;
    for (final r in records) {
      if (r.isNightWaking || r.isOpen || r.endDateTime == null) continue;
      final end = r.endDateTime!;
      if (latest == null || end.isAfter(latest)) latest = end;
    }
    return latest;
  }

  Future<void> _editAnchorTime(
    DateTime at, {
    required SleepRecord? open,
    required List<SleepRecord> known,
  }) async {
    if (open != null) {
      if (!at.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
        return;
      }
      final updated = open.copyWith(
        startDateTime: at,
        type: inferSleepType(start: at, end: open.endDateTime),
      );
      await IsarService.updateSleepRecord(updated);
      return;
    }

    final lastClosed =
        known
            .where((r) => r.isSleepBlock && !r.isOpen && r.endDateTime != null)
            .toList()
          ..sort((a, b) => b.endDateTime!.compareTo(a.endDateTime!));
    if (lastClosed.isNotEmpty) {
      final prev = lastClosed.first;
      if (!prev.startDateTime.isBefore(at)) return;
      final updated = prev.copyWith(
        endDateTime: at,
        type: inferSleepType(start: prev.startDateTime, end: at),
      );
      await IsarService.updateSleepRecord(updated);
      setState(() => _manualAwakeSince = null);
      return;
    }

    setState(() => _manualAwakeSince = at);
  }

  Future<void> _saveManualRecord(SleepRecord record) async {
    setState(() {
      _pendingHistoryReveal = record;
      _awaitingHistoryReveal = true;
    });
    final id = await IsarService.addSleepRecord(record);
    if (!mounted) return;
    setState(() => _pendingHistoryReveal = record.copyWith(id: id));
    _revealSleepHistory();
  }

  Future<void> _showAddNightWakingSheet(List<SleepRecord> known) async {
    final range = await showNightWakingSheet(context);
    if (!mounted || range == null) return;
    if (!range.start.isBefore(range.end)) return;
    final parent = findParentSleepForWaking(
      records: known,
      start: range.start,
      end: range.end,
    );
    await _saveManualRecord(
      SleepRecord(
        startDateTime: range.start,
        endDateTime: range.end,
        type: SleepType.nightWaking,
        parentSleepId: parent?.id,
      ),
    );
  }

  Future<void> _showAddPastSleepSheet() async {
    final range = await showPastSleepSheet(context);
    if (!mounted || range == null) return;
    if (!range.start.isBefore(range.end)) return;
    await _saveManualRecord(
      SleepRecord(
        startDateTime: range.start,
        endDateTime: range.end,
        type: inferSleepType(start: range.start, end: range.end),
      ),
    );
  }

  void _revealSleepHistory() {
    final record = _pendingHistoryReveal;
    if (record == null) return;
    markHistoryHighlight(HistoryHighlightKeys.sleep(record));
    setState(() {
      _optimisticRecord = record;
      _awaitingHistoryReveal = false;
      _pendingHistoryReveal = null;
    });
  }

  Future<void> _deleteSleepAndChildren(SleepRecord record) async {
    final ok = await confirmDeleteRecord(context);
    if (!mounted || !ok || record.id == null) return;
    final all = ref.read(sleepRecordsStreamProvider).valueOrNull ?? [];
    final children = all
        .where((r) => r.parentSleepId == record.id)
        .map((r) => r.id)
        .whereType<int>();
    final ids = {record.id!, ...children};
    setState(() => _deletedIds.addAll(ids));
    for (final id in ids) {
      await IsarService.deleteSleepRecord(id);
    }
  }

  DateTime _dayKeyForRecord(SleepRecord r) {
    final d = r.endDateTime ?? r.startDateTime;
    return DateTime(d.year, d.month, d.day);
  }

  /// Segundos dormidos del día (bloque − despertares anidados; sin huérfanos).
  int _daySleepSeconds(List<SleepHistoryEntry> entries) {
    var total = 0;
    for (final entry in entries) {
      if (entry.sleep.isNightWaking) continue;
      total += entry.sleep.durationSeconds();
      for (final w in entry.wakings) {
        total -= w.durationSeconds();
      }
    }
    return total < 0 ? 0 : total;
  }

  Widget _sleepHistoryColumn(BuildContext context, List<SleepRecord> records) {
    final l10n = AppLocalizations.of(context)!;
    final dateCode = dateFormatLanguageCode(context);
    final entries = buildSleepHistoryEntries(records);
    final napNumbers = napNumbersByDay(records);
    final grouped = <String, List<SleepHistoryEntry>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final entry in entries) {
      final day = _dayKeyForRecord(entry.sleep);
      final String key;
      if (day == today) {
        key = l10n.today;
      } else if (day == yesterday) {
        key = l10n.yesterday;
      } else {
        key = DateFormat('d/M', dateCode).format(day);
      }
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    final titleStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    if (entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.historyTitle, style: titleStyle),
          const SizedBox(height: 12),
          Text(
            l10n.sleepHistoryEmpty,
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
                  formatMinutesLocalized(l10n, _daySleepSeconds(e.value) ~/ 60),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textLight),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...e.value.map(
              (entry) => HistoryEntryReveal(
                highlighted: isHistoryHighlighted(
                  HistoryHighlightKeys.sleep(entry.sleep),
                ),
                accentColor: sleepHistoryAccent(entry.sleep.type),
                child: _SleepHistoryCard(
                  entry: entry,
                  napNumber: napNumbers[sleepRecordIdentity(entry.sleep)],
                  onDelete: () => _deleteSleepAndChildren(entry.sleep),
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
    final sleepRecordsAsync = widget.isActiveTab
        ? ref.watch(sleepRecordsStreamProvider)
        : ref.read(sleepRecordsStreamProvider);
    final knownForLive = _recordsForLive(sleepRecordsAsync.valueOrNull ?? []);
    final openSession = findOpenSleepSession(knownForLive);
    final awakeSince = _manualAwakeSince ?? _lastWakeAt(knownForLive);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onSleepHistoryScrollNotification,
                child: SingleChildScrollView(
                  controller: widget.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
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
                              Icon(
                                Icons.nightlight_round,
                                color: AppTheme.pageTitleIconSleep,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.sleepTitle,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SleepLiveSessionCard(
                            sleepingSince: openSession?.startDateTime,
                            awakeSince: awakeSince,
                            fallbackAwakeSince: _fallbackAwakeSince,
                            onFellAsleep: () =>
                                _registerFellAsleep(knownForLive),
                            onWokeUp: () => _registerWokeUp(knownForLive, l10n),
                            onEditAnchorTime: (at) => _editAnchorTime(
                              at,
                              open: openSession,
                              known: knownForLive,
                            ),
                            onSavedVisible: _revealSleepHistory,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _SleepManualActionButton(
                                  icon: Icons.visibility_outlined,
                                  label: l10n.sleepAddNightWaking,
                                  onTap: () =>
                                      _showAddNightWakingSheet(knownForLive),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _SleepManualActionButton(
                                  icon: Icons.history_rounded,
                                  label: l10n.sleepRegisterPastSleep,
                                  onTap: _showAddPastSleepSheet,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          sleepRecordsAsync.when(
                            skipLoadingOnReload: true,
                            data: (records) {
                              final truncateDays = ref.watch(
                                sleepHistoryFirestoreDaysProvider,
                              );
                              final visible = historyRecordsOnOrAfter(
                                records,
                                (r) => r.endDateTime ?? r.startDateTime,
                                historyWindowStartForDays(truncateDays),
                              );
                              final merged = _recordsForHistory(visible);
                              return _sleepHistoryColumn(context, merged);
                            },
                            loading: () {
                              if (_optimisticRecord != null) {
                                return _sleepHistoryColumn(context, [
                                  _optimisticRecord!,
                                ]);
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            error: (e, _) => StreamRecordLoadError(
                              message: l10n.sleepStreamError,
                              onRetry: () =>
                                  ref.invalidate(sleepRecordsStreamProvider),
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

class _SleepManualActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SleepManualActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.palettePrimary;
    final labelStyle = TextStyle(
      color: accent,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: accent),
              const SizedBox(height: 8),
              SizedBox(
                height: labelStyle.fontSize! * labelStyle.height! * 2,
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SleepHistoryCard extends StatefulWidget {
  final SleepHistoryEntry entry;
  final int? napNumber;
  final VoidCallback onDelete;

  const _SleepHistoryCard({
    required this.entry,
    required this.onDelete,
    this.napNumber,
  });

  @override
  State<_SleepHistoryCard> createState() => _SleepHistoryCardState();
}

class _SleepHistoryCardState extends State<_SleepHistoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final CurvedAnimation _pulseCurve;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseCurve = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
    if (widget.entry.sleep.isOpen) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _SleepHistoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final open = widget.entry.sleep.isOpen;
    if (open && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!open && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCurve.dispose();
    _pulse.dispose();
    super.dispose();
  }

  String _wakingsSummaryLabel(BuildContext context, SleepHistoryEntry entry) {
    final l10n = AppLocalizations.of(context)!;
    if (entry.wakingCount == 1) {
      return l10n.sleepWakingsSummaryOne(entry.wakingMinutes);
    }
    return l10n.sleepWakingsSummary(entry.wakingCount, entry.wakingMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final record = entry.sleep;
    final accent = sleepHistoryAccent(record.type);
    final radius = BorderRadius.circular(AppTheme.homeCardRadius);

    final body = _SleepRecordRow(
      record: record,
      napNumber: widget.napNumber,
      wakings: entry.wakings,
      wakingsSummary: entry.wakings.isEmpty
          ? null
          : _wakingsSummaryLabel(context, entry),
      onDelete: widget.onDelete,
    );

    if (!record.isOpen) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: AppTheme.cardShapeRounded(),
        child: body,
      );
    }

    return AnimatedBuilder(
      animation: _pulseCurve,
      builder: (context, child) {
        final t = _pulseCurve.value;
        final borderColor = Color.lerp(
          AppTheme.cardOutline,
          accent.withValues(alpha: 0.38),
          t,
        )!;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: borderColor, width: 1),
          ),
          child: child,
        );
      },
      child: body,
    );
  }
}

class _SleepRecordRow extends StatelessWidget {
  final SleepRecord record;
  final int? napNumber;
  final List<SleepRecord> wakings;
  final String? wakingsSummary;
  final VoidCallback onDelete;

  const _SleepRecordRow({
    required this.record,
    required this.onDelete,
    this.wakings = const [],
    this.napNumber,
    this.wakingsSummary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateCode = dateFormatLanguageCode(context);
    final accent = sleepHistoryAccent(record.type);
    final n = napNumber;
    final typeLabel = switch (record.type) {
      SleepType.night => l10n.sleepTypeNight,
      SleepType.nap =>
        n != null ? l10n.sleepTypeNapNumbered(n) : l10n.sleepTypeNap,
      SleepType.nightWaking => l10n.sleepNightWakingLabel,
    };
    final durationLabel = formatMinutesLocalized(
      l10n,
      record.durationSeconds() ~/ 60,
    );
    final startStr = DateFormat('HH:mm', dateCode).format(record.startDateTime);
    final endStr = record.endDateTime == null
        ? l10n.sleepEndPending
        : DateFormat('HH:mm', dateCode).format(record.endDateTime!);
    final rangeLabel = '$startStr - $endStr';
    final stamp = record.endDateTime ?? record.startDateTime;

    return IntrinsicHeight(
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
                child: switch (record.type) {
                  SleepType.nap => SleepNapZzzIcon(size: 15, color: accent),
                  SleepType.nightWaking => Icon(
                    Icons.visibility_outlined,
                    color: accent,
                    size: 20,
                  ),
                  SleepType.night => Icon(
                    Icons.nightlight_round,
                    color: accent,
                    size: 22,
                  ),
                },
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
                    typeLabel,
                    style: AppTheme.historyRecordTypeTitleStyle(accent),
                  ),
                  SizedBox(height: AppTheme.historyRecordAfterTitleGap),
                  Text(
                    durationLabel,
                    style: AppTheme.historyRecordPrimaryValueStyle(accent),
                  ),
                  if (wakingsSummary != null) ...[
                    SizedBox(height: AppTheme.historyRecordDetailToDateGap),
                    Text(
                      wakingsSummary!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  SizedBox(height: AppTheme.historyRecordDetailToDateGap),
                  Text(
                    '${DateFormat('d MMM', dateCode).format(stamp)}, $rangeLabel',
                    style: AppTheme.historyRecordDateTimeStyle(context),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: AppTheme.historyRecordTrailingOuterPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => showSleepEditSheet(
                    context,
                    record: record,
                    wakings: wakings,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
