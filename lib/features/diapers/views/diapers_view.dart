import 'dart:async';

import 'package:control_bebe/l10n/app_date_locale.dart';
import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
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
import '../../../core/widgets/stream_record_load_error.dart';
import '../../../core/widgets/confirm_delete_record_dialog.dart';
import '../../../core/models/diaper_record.dart';
import '../../../core/models/enums.dart';
import '../../../core/utils/history_calendar_window.dart';
import '../../../core/utils/history_highlight.dart';
import '../../../core/widgets/history_entry_reveal.dart';
import '../widgets/diaper_type_segmented_control.dart';

class DiapersView extends ConsumerStatefulWidget {
  final VoidCallback? onTitleTap;
  final VoidCallback onSettingsTap;
  final ScrollController? scrollController;
  final bool isActiveTab;

  const DiapersView({
    super.key,
    this.onTitleTap,
    required this.onSettingsTap,
    this.scrollController,
    this.isActiveTab = true,
  });

  @override
  ConsumerState<DiapersView> createState() => _DiapersViewState();
}

class _DiapersViewState extends ConsumerState<DiapersView>
    with HistoryHighlightState {
  DiaperType _selectedType = DiaperType.wet;
  DiaperRecord? _optimisticRecord;
  DiaperRecord? _pendingHistoryReveal;
  bool _awaitingHistoryReveal = false;
  DateTime _lastHistoryScrollExpand = DateTime.fromMillisecondsSinceEpoch(0);

  List<DiaperRecord> _recordsForHistory(List<DiaperRecord> records) {
    return _mergeOptimistic(
      hidePendingHistoryRecord(
        records: records,
        awaitingReveal: _awaitingHistoryReveal,
        pending: _pendingHistoryReveal,
        matchesPending: HistoryHighlightKeys.diaperMatchesPending,
      ),
    );
  }

  List<DiaperRecord> _mergeOptimistic(List<DiaperRecord> records) {
    final opt = _optimisticRecord;
    if (opt == null) return records;
    final match = records.any(
      (r) =>
          r.type == opt.type &&
          r.dateTime.difference(opt.dateTime).inSeconds.abs() < 2,
    );
    if (match) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _optimisticRecord = null);
      });
      return records;
    }
    return [opt, ...records];
  }

  bool _onDiaperHistoryScrollNotification(ScrollNotification n) {
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
    final days = ref.read(diaperHistoryFirestoreDaysProvider);
    if (days >= kHistoryPaginationMaxDays) {
      return false;
    }
    _lastHistoryScrollExpand = now;
    unawaited(_maybeExpandDiaperHistoryWindow());
    return false;
  }

  Future<void> _maybeExpandDiaperHistoryWindow() async {
    final hasOlder = await ref.read(hasOlderDiaperRecordsProvider.future);
    if (!mounted || !hasOlder) return;
    final days = ref.read(diaperHistoryFirestoreDaysProvider);
    if (days >= kHistoryPaginationMaxDays) return;
    ref.read(diaperHistoryFirestoreDaysProvider.notifier).state =
        days + kHistoryPaginationStepDays;
  }

  Widget _diaperHistoryColumn(
    BuildContext context,
    List<DiaperRecord> records,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final dateCode = dateFormatLanguageCode(context);
    final sorted = List<DiaperRecord>.from(records)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final grouped = <String, List<DiaperRecord>>{};
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
            l10n.diapersHistoryEmpty,
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
                  e.value.length == 1
                      ? l10n.diaperChangeCountOne
                      : l10n.diaperChangeCountN(e.value.length),
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
                  HistoryHighlightKeys.diaper(r),
                ),
                accentColor: diaperHistoryAccent(r.type),
                child: _DiaperRecordTile(
                  record: r,
                  onDelete: () async {
                    final ok = await confirmDeleteRecord(context);
                    if (!context.mounted || !ok || r.id == null) return;
                    IsarService.deleteDiaperRecord(r.id!);
                  },
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
    final diaperRecordsAsync = widget.isActiveTab
        ? ref.watch(diaperRecordsStreamProvider)
        : ref.read(diaperRecordsStreamProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onDiaperHistoryScrollNotification,
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
                              Icon(
                                MdiIcons.humanBabyChangingTable,
                                color: AppTheme.pageTitleIconDiapers,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.diapersTitle,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.diapersChangeType,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(color: AppTheme.textLight),
                          ),
                          const SizedBox(height: 12),
                          DiaperTypeSegmentedControl(
                            value: _selectedType,
                            onChanged: (type) =>
                                setState(() => _selectedType = type),
                            wetLabel: l10n.diaperWet,
                            dirtyLabel: l10n.diaperDirty,
                            bothLabel: l10n.diaperBoth,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: InlineConfirmingButton(
                              onPressed: _registerDiaper,
                              onSavedVisible: _revealDiaperHistory,
                              child: Text(l10n.diapersRegisterButton),
                            ),
                          ),
                          const SizedBox(height: 32),
                          diaperRecordsAsync.when(
                            skipLoadingOnReload: true,
                            data: (records) {
                              final truncateDays = ref.watch(
                                diaperHistoryFirestoreDaysProvider,
                              );
                              final visible = historyRecordsOnOrAfter(
                                records,
                                (r) => r.dateTime,
                                historyWindowStartForDays(truncateDays),
                              );
                              final merged = _recordsForHistory(visible);
                              return _diaperHistoryColumn(context, merged);
                            },
                            loading: () {
                              if (_optimisticRecord != null) {
                                return _diaperHistoryColumn(context, [
                                  _optimisticRecord!,
                                ]);
                              }
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            error: (e, _) => StreamRecordLoadError(
                              message: l10n.diapersStreamError,
                              onRetry: () =>
                                  ref.invalidate(diaperRecordsStreamProvider),
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

  Future<bool> _registerDiaper() async {
    final record = DiaperRecord(type: _selectedType, dateTime: DateTime.now());
    setState(() {
      _pendingHistoryReveal = record;
      _awaitingHistoryReveal = true;
    });
    await IsarService.addDiaperRecord(record);
    return true;
  }

  void _revealDiaperHistory() {
    final record = _pendingHistoryReveal;
    if (record == null) return;
    markHistoryHighlight(HistoryHighlightKeys.diaper(record));
    setState(() {
      _optimisticRecord = record;
      _awaitingHistoryReveal = false;
      _pendingHistoryReveal = null;
    });
  }
}

class _DiaperRecordTile extends StatelessWidget {
  final DiaperRecord record;
  final VoidCallback onDelete;

  const _DiaperRecordTile({required this.record, required this.onDelete});

  void _showEditDialog(
    BuildContext context,
    DiaperRecord record,
    VoidCallback onDelete,
  ) {
    final l10n = AppLocalizations.of(context)!;
    var selectedType = record.type;
    var selectedAt = record.dateTime;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => EditBottomSheet(
          title: l10n.diapersEditRecord,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.diapersTypeLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              DiaperTypeSegmentedControl(
                value: selectedType,
                onChanged: (type) => setState(() => selectedType = type),
                wetLabel: l10n.diaperWet,
                dirtyLabel: l10n.diaperDirty,
                bothLabel: l10n.diaperBoth,
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
            await IsarService.updateDiaperRecord(
              record.copyWith(type: selectedType, dateTime: selectedAt),
            );
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateCode = dateFormatLanguageCode(context);
    final (icon, label, isFa, accentColor) = switch (record.type) {
      DiaperType.wet => (
        Icons.water_drop,
        l10n.diaperWet,
        false,
        AppTheme.diaperHistoryWetAccent,
      ),
      DiaperType.dirty => (
        FontAwesomeIcons.poo,
        l10n.diaperDirty,
        true,
        AppTheme.diaperHistoryDirtyAccent,
      ),
      DiaperType.both => (
        Icons.sync,
        l10n.diaperBoth,
        false,
        AppTheme.diaperHistoryBothAccent,
      ),
    };
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
                    child: isFa
                        ? FaIcon(icon, color: accentColor, size: 20)
                        : Icon(icon, color: accentColor, size: 22),
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
                        label,
                        style: AppTheme.historyRecordTypeTitleStyle(
                          accentColor,
                        ),
                      ),
                      SizedBox(height: AppTheme.historyRecordAfterTitleGap),
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
                              _showEditDialog(context, record, onDelete),
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
}
