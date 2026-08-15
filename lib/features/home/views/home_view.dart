import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:control_bebe/l10n/app_date_locale.dart';
import 'package:control_bebe/l10n/app_localizations.dart';
import 'package:control_bebe/l10n/app_time_format.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/baby_insight_status_line.dart';
import '../../../core/widgets/home_card_title_row.dart';
import '../../../core/widgets/main_app_title_bar.dart';
import '../../../core/widgets/premium_features_card.dart';
import '../../../core/widgets/sleep_insight_day_timeline.dart';
import '../../../core/widgets/sleep_insight_week_chart.dart';
import '../../../core/utils/feeding_interval_labels.dart';
import '../../../core/utils/photo_picker.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/models/baby_profile.dart';
import '../../../core/models/diaper_record.dart';
import '../../../core/models/feeding_record.dart';
import '../../../core/models/height_record.dart';
import '../../../core/models/sleep_record.dart';
import '../../../core/models/weight_record.dart';
import '../../settings/views/settings_page.dart';
import '../../../core/models/enums.dart';
import '../../../core/utils/baby_age_calendar.dart';
import '../../../core/utils/diaper_cost_localization.dart';
import '../../../core/utils/diaper_spend_insight.dart';
import '../../../core/utils/home_insight_windows.dart';
import '../../../core/utils/sleep_home_summary.dart';
import '../../../core/utils/sleep_insight.dart';
import '../../../core/utils/history_calendar_window.dart';
import '../../../core/utils/next_sleep_prediction.dart';
import '../../../core/utils/sleep_usual_pattern.dart';
import '../../../core/services/monthiversary_confetti_service.dart';
import '../../../core/services/sabias_que_service.dart';
import '../../../core/providers/baby_profile_provider.dart';
import '../../../core/providers/measurement_prefs_provider.dart';
import '../../../core/providers/premium_provider.dart';
import '../../../core/providers/record_stream_providers.dart';
import '../../../core/models/measurement_units.dart';
import '../../../core/utils/measurement_display.dart';
import '../../../core/utils/solid_food_display.dart';
import '../../../core/services/next_feeding_notification_service.dart';
import '../../weight/widgets/growth_evolution_chart_card.dart';

class HomeView extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final void Function(int index)? onNavigateToTab;
  final VoidCallback? onTitleTap;

  /// Cuando es true, la pestaña Inicio está visible (p. ej. reloj en vivo de la última toma).
  final bool isActiveTab;

  const HomeView({
    super.key,
    required this.scrollController,
    this.onNavigateToTab,
    this.onTitleTap,
    this.isActiveTab = true,
  });

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with WidgetsBindingObserver {
  BabyProfile? _cachedBaby;

  /// Perfil mostrado en la cabecera tras cambiar solo la foto (sin recargar todo el home).
  BabyProfile? _babyProfileOverride;
  late Future<Map<String, dynamic>> _homeDataFuture;
  final _sabiasQueService = SabiasQueServiceDefault();
  Timer? _homeRefreshDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _homeDataFuture = _loadHomeData();
    unawaited(_scheduleAutoMilestoneConfetti(_homeDataFuture));
  }

  @override
  void dispose() {
    _homeRefreshDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActiveTab) {
      _scheduleHomeDataRefresh();
    }
  }

  @override
  void didUpdateWidget(HomeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveTab && !oldWidget.isActiveTab) {
      setState(() {
        _homeDataFuture = _loadHomeData();
      });
      unawaited(_scheduleAutoMilestoneConfetti(_homeDataFuture));
    } else if (!widget.isActiveTab && oldWidget.isActiveTab) {
      _homeRefreshDebounce?.cancel();
    }
  }

  /// Recarga el resumen cuando cambian peso, tomas, pañales o sueño mientras Inicio está visible.
  void _scheduleHomeDataRefresh() {
    if (!widget.isActiveTab) return;
    _homeRefreshDebounce?.cancel();
    _homeRefreshDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        _homeDataFuture = _loadHomeData();
      });
    });
  }

  void _listenForRecordChanges() {
    ref.listen<AsyncValue<BabyProfile?>>(babyProfileProvider, (prev, next) {
      final baby = next.valueOrNull;
      if (baby == null) return;
      if (prev?.valueOrNull?.name == baby.name &&
          prev?.valueOrNull?.birthDate == baby.birthDate) {
        return;
      }
      _scheduleHomeDataRefresh();
    });
    ref.listen<AsyncValue<List<FeedingRecord>>>(feedingRecordsStreamProvider, (
      prev,
      next,
    ) {
      if (prev is AsyncData && next is AsyncData) {
        _scheduleHomeDataRefresh();
      }
    });
    ref.listen<AsyncValue<List<DiaperRecord>>>(diaperRecordsStreamProvider, (
      prev,
      next,
    ) {
      if (prev is AsyncData && next is AsyncData) {
        _scheduleHomeDataRefresh();
      }
    });
    ref.listen<AsyncValue<List<WeightRecord>>>(
      weightRecordsForChartStreamProvider,
      (prev, next) {
        if (prev is AsyncData && next is AsyncData) {
          _scheduleHomeDataRefresh();
        }
      },
    );
    ref.listen<AsyncValue<List<HeightRecord>>>(heightRecordsStreamProvider, (
      prev,
      next,
    ) {
      if (prev is AsyncData && next is AsyncData) {
        _scheduleHomeDataRefresh();
      }
    });
    ref.listen<AsyncValue<List<SleepRecord>>>(sleepRecordsStreamProvider, (
      prev,
      next,
    ) {
      if (prev is AsyncData && next is AsyncData) {
        _scheduleHomeDataRefresh();
      }
    });
  }

  Future<void> _scheduleAutoMilestoneConfetti(
    Future<Map<String, dynamic>> future,
  ) async {
    final data = await future;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final baby = data['baby'] as BabyProfile?;
      MonthiversaryConfettiService.tryPlayAutomatic(context, baby?.birthDate);
    });
  }

  Future<void> _handlePhotoTap(BabyProfile? baby) async {
    if (baby == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.homeConfigureProfileFirst,
            ),
          ),
        );
      }
      return;
    }

    final hasPhoto = baby.photoUrl != null && baby.photoUrl!.isNotEmpty;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: AppTheme.safeBottomPadding(sheetCtx),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(AppLocalizations.of(sheetCtx)!.homePickPhoto),
                  onTap: () => Navigator.pop(sheetCtx, 'pick'),
                ),
                if (hasPhoto)
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: Theme.of(sheetCtx).colorScheme.error,
                    ),
                    title: Text(
                      AppLocalizations.of(sheetCtx)!.homeRemovePhoto,
                      style: TextStyle(
                        color: Theme.of(sheetCtx).colorScheme.error,
                      ),
                    ),
                    onTap: () => Navigator.pop(sheetCtx, 'remove'),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || choice == null) return;

    if (choice == 'remove') {
      try {
        final updated = baby.copyWith(setPhotoUrl: true, photoUrl: null);
        await IsarService.saveBabyProfile(updated);
        if (mounted) {
          ref.invalidate(babyProfileProvider);
          setState(() {
            _babyProfileOverride = updated;
            _cachedBaby = updated;
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.homePhotoRemoved),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.homePhotoRemoveError(e.toString()),
              ),
            ),
          );
        }
      }
      return;
    }

    if (choice != 'pick') return;

    try {
      final photoUrl = await pickAndProcessBabyPhoto();
      if (photoUrl == null || !mounted) return;
      final updated = baby.copyWith(photoUrl: photoUrl);
      await IsarService.saveBabyProfile(updated);
      if (mounted) {
        ref.invalidate(babyProfileProvider);
        setState(() {
          _babyProfileOverride = updated;
          _cachedBaby = updated;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.homePhotoUpdated),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.homePhotoUploadError(e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _navigateTo(String screen) {
    if (widget.onNavigateToTab != null) {
      switch (screen) {
        case 'weight':
          widget.onNavigateToTab!(4);
          break;
        case 'feeding':
          widget.onNavigateToTab!(2);
          break;
        case 'diapers':
          widget.onNavigateToTab!(1);
          break;
        case 'sleep':
          widget.onNavigateToTab!(3);
          break;
      }
    }
  }

  Future<void> _openSettings(
    BuildContext context, {
    BabyProfile? currentBaby,
  }) async {
    BabyProfile? initial = currentBaby ?? _cachedBaby;
    initial ??= await ref.read(babyProfileProvider.future);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          initialBaby: initial,
          onProfileSaved: (profile) {
            if (!mounted) return;
            ref.invalidate(babyProfileProvider);
            setState(() {
              _cachedBaby = profile;
              _babyProfileOverride = null;
              _homeDataFuture = _loadHomeData();
            });
          },
        ),
      ),
    );
    if (mounted) {
      resetRecordHistoryFirestoreDays(ref);
      ref.invalidate(weightRecordsForChartStreamProvider);
      ref.invalidate(heightRecordsStreamProvider);
      ref.invalidate(diaperRecordsStreamProvider);
      ref.invalidate(feedingRecordsStreamProvider);
      ref.invalidate(sleepRecordsStreamProvider);
      await NextFeedingNotificationService.syncFromStorage();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isActiveTab) {
      _listenForRecordChanges();
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _homeDataFuture,
                builder: (context, snapshot) {
                  final l10n = AppLocalizations.of(context)!;
                  final isPremium = ref.watch(isPremiumProvider);
                  final data = snapshot.data;
                  final babyFromFuture = data != null
                      ? data['baby'] as BabyProfile?
                      : null;
                  final baby = _babyProfileOverride ??
                      ref.watch(babyProfileProvider).valueOrNull ??
                      babyFromFuture;
                  final showSkeleton = !snapshot.hasData ||
                      (baby == null && snapshot.connectionState != ConnectionState.done);
                  return CustomScrollView(
                    controller: widget.scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          AppTheme.screenEdgePadding + AppTheme.cardOuterMargin,
                          MainAppTitleBar.totalHeight +
                              AppTheme.contentPaddingTopAfterTitleBar +
                              AppTheme.cardOuterMargin,
                          AppTheme.screenEdgePadding + AppTheme.cardOuterMargin,
                          100 + AppTheme.extraBottomSpacing,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (showSkeleton) ...[
                              const _HomeCardsSkeleton(),
                            ] else ...[
                              _StaggeredFadeSlideIn(
                                delay: Duration.zero,
                                child: _ProfileSummaryCard(
                                  baby: baby,
                                  weightKg: (data!['weight'] as _WeightData)
                                      .currentKg,
                                  heightCm: data['heightCm'] as double?,
                                  isSleeping:
                                      (data['sleep'] as SleepHomeSummary)
                                          .isSleeping,
                                  onPhotoTap: () => _handlePhotoTap(baby),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _StaggeredFadeSlideIn(
                                delay: const Duration(milliseconds: 60),
                                child: _ResumenDeHoyBlock(
                                  sleep: data['sleep'] as SleepHomeSummary,
                                  feeding: data['feeding'] as _FeedingData,
                                  diapers: data['diapers'] as _DiapersData,
                                  onTapSleep: () => _navigateTo('sleep'),
                                  onTapFeeding: () => _navigateTo('feeding'),
                                  onTapDiapers: () => _navigateTo('diapers'),
                                  liveFeedingClock: widget.isActiveTab,
                                  dateFormatCode:
                                      data['dateFmtCode'] as String? ?? 'es',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _StaggeredFadeSlideIn(
                                delay: const Duration(milliseconds: 120),
                                child: _ConsejoDelDiaCard(
                                  factText: data['sabiasQue'] as String?,
                                  missingBirthDate:
                                      data['sabiasQueMissingBirth'] as bool? ??
                                      false,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (!isPremium)
                                _StaggeredFadeSlideIn(
                                  delay: const Duration(milliseconds: 180),
                                  child: PremiumFeaturesCard(
                                    babyName:
                                        baby?.name ??
                                        l10n.profileDefaultBabyName,
                                    moreCount: _premiumTeaserMoreCount,
                                    items: _premiumTeaserItems(
                                      l10n,
                                      babyName:
                                          baby?.name ??
                                          l10n.profileDefaultBabyName,
                                      counts:
                                          data['premiumTeaserCounts']
                                              as _PremiumTeaserCounts,
                                    ),
                                  ),
                                )
                              else ...[
                                _StaggeredFadeSlideIn(
                                  delay: const Duration(milliseconds: 180),
                                  child: _AlimentacionHoyTrendCard(
                                    data:
                                        data['feedingTrend']
                                            as _FeedingTrendData,
                                    babyName:
                                        baby?.name ??
                                        l10n.profileDefaultBabyName,
                                    onTap: () => _navigateTo('feeding'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _StaggeredFadeSlideIn(
                                  delay: const Duration(milliseconds: 210),
                                  child: _TodaysSleepCard(
                                    data:
                                        data['sleepInsight']
                                            as SleepInsightStats,
                                    dateFormatCode:
                                        data['dateFmtCode'] as String,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _StaggeredFadeSlideIn(
                                  delay: const Duration(milliseconds: 240),
                                  child: _HomeSectionTitle(
                                    title: l10n.homeInsightsTitle,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _StaggeredFadeSlideIn(
                                  delay: const Duration(milliseconds: 300),
                                  child: _HomeInfoResumenRow(
                                    feedingDistribution:
                                        data['feedingDistribution']
                                            as _FeedingDistributionData,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _StaggeredFadeSlideIn(
                                  delay: const Duration(milliseconds: 360),
                                  child: _DiaperSpendInsightCard(
                                    data:
                                        data['diaperSpendInsight']
                                            as DiaperSpendInsightStats,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _StaggeredFadeSlideIn(
                                  delay: const Duration(milliseconds: 390),
                                  child: _SleepAnalysisCard(
                                    data:
                                        data['sleepInsight']
                                            as SleepInsightStats,
                                    dateFormatCode:
                                        data['dateFmtCode'] as String,
                                    babyName:
                                        baby?.name ??
                                        l10n.profileDefaultBabyName,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _StaggeredFadeSlideIn(
                                  delay: const Duration(milliseconds: 420),
                                  child: GrowthEvolutionChartCard(
                                    baby: baby,
                                    isActive: widget.isActiveTab,
                                  ),
                                ),
                              ],
                            ],
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: MainAppTitleBar(
                onTitleTap: widget.onTitleTap,
                onSettingsTap: () =>
                    _openSettings(context, currentBaby: _babyProfileOverride),
              ),
            ),
            const TitleBarScrollFade(),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadHomeData() async {
    // No usar InheritedWidget (Localizations, etc.) de forma síncrona: esta
    // future se arranca en initState y el cuerpo async corre antes de que termine.
    await Future<void>.value();
    if (!mounted) return <String, dynamic>{};
    final locale = Localizations.localeOf(context);
    final l10n = lookupAppLocalizations(locale);
    final dateFmtCode = dateFormatLanguageCode(context);

    final cachedBaby = _cachedBaby;
    _cachedBaby = null;
    final baby = cachedBaby ?? await ref.read(babyProfileProvider.future);
    if (!mounted) return <String, dynamic>{};
    final birth = baby?.birthDate;
    final sabiasFuture = birth == null
        ? Future<String?>.value(null)
        : _sabiasQueService.getFact(
            birthDate: birth,
            languageCode: locale.languageCode,
          );
    final now = DateTime.now();
    final justCreated = baby?.createdAt != null &&
        now.difference(baby!.createdAt!) < const Duration(seconds: 45);
    final todayStart = DateTime(now.year, now.month, now.day);
    final feedingLoadStart = todayStart.subtract(
      const Duration(days: kHomeFeedingTrendLookbackDays),
    );
    final diaperSpendStart = todayStart.subtract(
      const Duration(days: kDiaperSpendWindowDays * 2 - 1),
    );
    final sleepWindowStart = todayStart.subtract(
      Duration(days: kHomeSleepLookbackDays),
    );

    Future<List<T>> takeRecords<T>(
      StreamProvider<List<T>> provider, {
      bool waitForLocalOutbox = false,
    }) async {
      final async = ref.read(provider);
      if (async.hasValue) return async.requireValue;
      if (!justCreated) return ref.read(provider.future);
      if (!waitForLocalOutbox) return <T>[];
      try {
        return await ref
            .read(provider.future)
            .timeout(const Duration(milliseconds: 80));
      } on TimeoutException {
        return <T>[];
      }
    }

    final results = await Future.wait([
      takeRecords(
        weightRecordsForChartStreamProvider,
        waitForLocalOutbox: true,
      ),
      takeRecords(heightRecordsStreamProvider, waitForLocalOutbox: true),
      sabiasFuture,
      takeRecords(feedingRecordsStreamProvider),
      takeRecords(diaperRecordsStreamProvider),
      takeRecords(sleepRecordsStreamProvider),
    ]);
    final weightRecords = results[0] as List<WeightRecord>;
    final heightRecords = results[1] as List<HeightRecord>;
    final sabiasQue = results[2] as String?;
    final feedingStreamRecords = results[3] as List<FeedingRecord>;
    final diaperStreamRecords = results[4] as List<DiaperRecord>;
    final sleepStreamRecords = results[5] as List<SleepRecord>;

    final lastFeeding = feedingStreamRecords.isEmpty
        ? null
        : feedingStreamRecords.reduce(
            (a, b) => a.dateTime.isAfter(b.dateTime) ? a : b,
          );
    final lastDiaperRecord = diaperStreamRecords.isEmpty
        ? null
        : diaperStreamRecords.reduce(
            (a, b) => a.dateTime.isAfter(b.dateTime) ? a : b,
          );

    final allFeedingRecords = historyRecordsOnOrAfter(
      feedingStreamRecords,
      (r) => r.dateTime,
      feedingLoadStart,
    );
    final feedingTrendRecords = allFeedingRecords;
    final diaperSpendRecords = historyRecordsOnOrAfter(
      diaperStreamRecords,
      (r) => r.dateTime,
      diaperSpendStart,
    );
    final sleepRecords = historyRecordsOnOrAfter(
      sleepStreamRecords,
      (r) => r.endDateTime ?? r.startDateTime,
      sleepWindowStart,
    );

    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final diapersToday = diaperStreamRecords
        .where(
          (r) =>
              !r.dateTime.isBefore(todayStart) &&
              r.dateTime.isBefore(tomorrowStart),
        )
        .toList();

    final lastWeight = weightRecords.isNotEmpty ? weightRecords.first : null;
    final lastHeight = heightRecords.isNotEmpty ? heightRecords.first : null;

    String? lastFeedingDetail;
    int? lastBottleMl;
    DateTime? lastFeedingAt;
    if (lastFeeding != null) {
      lastFeedingAt = lastFeeding.dateTime;
      switch (lastFeeding.type) {
        case FeedingType.leftBreast:
          final sec = lastFeeding.durationSeconds ?? 0;
          final min = (sec / 60).round();
          lastFeedingDetail = sec > 0
              ? l10n.lastFeedDetailLeftMinutes(min)
              : l10n.lastFeedDetailLeft;
          break;
        case FeedingType.rightBreast:
          final sec = lastFeeding.durationSeconds ?? 0;
          final min = (sec / 60).round();
          lastFeedingDetail = sec > 0
              ? l10n.lastFeedDetailRightMinutes(min)
              : l10n.lastFeedDetailRight;
          break;
        case FeedingType.bottle:
          lastBottleMl = lastFeeding.amountMl ?? 0;
          break;
        case FeedingType.solidFood:
          final sq = lastFeeding.solidQuantity;
          final su = lastFeeding.solidUnit;
          final sn = lastFeeding.solidName?.trim();
          if (sq != null && su != null) {
            final amt = solidFoodQuantityLabel(l10n, sq, su, dateFmtCode);
            if (amt != null) {
              lastFeedingDetail = sn != null && sn.isNotEmpty
                  ? '$sn · $amt'
                  : amt;
            } else {
              lastFeedingDetail = l10n.lastFeedDetailSolid;
            }
          } else {
            lastFeedingDetail = l10n.lastFeedDetailSolid;
          }
          break;
      }
    }

    var wetCount = 0;
    var dirtyCount = 0;
    for (final d in diapersToday) {
      switch (d.type) {
        case DiaperType.wet:
          wetCount++;
          break;
        case DiaperType.dirty:
          dirtyCount++;
          break;
        case DiaperType.both:
          wetCount++;
          dirtyCount++;
          break;
      }
    }

    // Un "cambio" = un registro desde 00:00 local (como el bloque "Hoy" en pañales).
    // No sumar moj+suc: un tipo "ambos" es un solo cambio.
    final totalToday = diapersToday.length;

    return {
      'baby': baby,
      'sabiasQue': sabiasQue,
      'sabiasQueMissingBirth': birth == null,
      'dateFmtCode': dateFmtCode,
      'heightCm': lastHeight?.heightCm,
      'weight': _WeightData(
        currentKg: lastWeight?.weightKg,
        lastRecordedAt: lastWeight?.dateTime,
      ),
      'feeding': _FeedingData(
        lastFeedingDetail: lastFeedingDetail,
        lastBottleMl: lastBottleMl,
        lastFeedingAt: lastFeedingAt,
        expectedFeedingIntervalMinutes:
            baby?.expectedFeedingIntervalMinutes ??
            kDefaultFeedingIntervalMinutes,
      ),
      'feedingTrend': _FeedingTrendData.fromRecords(
        records: feedingTrendRecords,
        now: now,
      ),
      'feedingDistribution': _FeedingDistributionData.fromRecords(
        records: allFeedingRecords,
        now: now,
      ),
      'diaperSpendInsight': DiaperSpendInsightStats.fromRecords(
        records: diaperSpendRecords,
        now: now,
      ),
      'diapers': _DiapersData(
        wetCount: wetCount,
        dirtyCount: dirtyCount,
        totalToday: totalToday,
        lastRecordedAt: lastDiaperRecord?.dateTime,
      ),
      'sleep': buildSleepHomeSummary(records: sleepRecords, now: now),
      'sleepInsight': SleepInsightStats.fromRecords(
        records: sleepRecords,
        now: now,
        birthDate: birth,
      ),
      'premiumTeaserCounts': _PremiumTeaserCounts(
        nights: _distinctDayCount(
          sleepStreamRecords.map((r) => r.startDateTime),
        ),
        feedingDays: _distinctDayCount(
          allFeedingRecords.map((r) => r.dateTime),
        ),
        weights: weightRecords.length,
        heights: heightRecords.length,
      ),
    };
  }

  /// Listado que sustituye a las pastillas premium del home. Solo 3 filas
  /// visibles; el resto se resume en «Y X análisis más».
  List<PremiumFeatureItem> _premiumTeaserItems(
    AppLocalizations l10n, {
    required String babyName,
    required _PremiumTeaserCounts counts,
  }) {
    final nights = counts.nights >= 2
        ? l10n.premiumTeaserBasedOnNights(counts.nights)
        : null;
    final feedingDays = counts.feedingDays >= 2
        ? l10n.premiumTeaserBasedOnFeedingDays(counts.feedingDays)
        : null;
    final growthCount = counts.weights + counts.heights;
    final growth = growthCount >= 2
        ? l10n.premiumTeaserBasedOnWeights(growthCount)
        : null;

    return [
      PremiumFeatureItem(
        icon: Icons.bedtime_outlined,
        title: l10n.premiumTeaserSleepTitle,
        subtitle: nights ?? l10n.premiumTeaserSleepSubtitle,
        paywallHeadline: l10n.premiumTeaserSleepHeadline(babyName),
      ),
      PremiumFeatureItem(
        icon: Icons.restaurant_outlined,
        title: l10n.premiumTeaserFeedingTrendTitle,
        subtitle: feedingDays ?? l10n.premiumTeaserFeedingTrendSubtitle,
        paywallHeadline: l10n.premiumTeaserFeedingTrendHeadline(babyName),
      ),
      PremiumFeatureItem(
        icon: Icons.show_chart_outlined,
        title: l10n.premiumTeaserGrowthTitle,
        subtitle: growth ?? l10n.premiumTeaserGrowthSubtitle,
        paywallHeadline: l10n.premiumTeaserGrowthHeadline(babyName),
      ),
    ];
  }

  /// Análisis premium del home que no aparecen como fila propia (hay 7
  /// pastillas al desbloquear; el listado muestra 3 → quedan 4).
  static const int _premiumTeaserMoreCount = 4;

  /// Días naturales distintos con al menos un registro.
  int _distinctDayCount(Iterable<DateTime> dates) {
    final days = <int>{};
    for (final d in dates) {
      days.add(DateTime(d.year, d.month, d.day).millisecondsSinceEpoch);
    }
    return days.length;
  }
}

// --- Animación de entrada escalonada (fade + slide) ---

/// Envuelve un hijo con una entrada *fade-in* + *slide* hacia arriba.
/// El parámetro [delay] permite escalonar la animación entre tarjetas.
/// Mantiene el hijo "fuera de pantalla" (opacity 0 + translación) durante
/// el delay y luego lo trae hasta su posición con [Curves.easeOutCubic].
class _StaggeredFadeSlideIn extends StatelessWidget {
  static const Duration _animDuration = Duration(milliseconds: 420);
  static const double _translateY = 18;

  final Widget child;
  final Duration delay;

  const _StaggeredFadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final totalMs = delay.inMilliseconds + _animDuration.inMilliseconds;
    final intervalStart = totalMs == 0 ? 0.0 : delay.inMilliseconds / totalMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: totalMs),
      curve: Interval(intervalStart, 1.0, curve: Curves.easeOutCubic),
      builder: (context, t, c) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * _translateY),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

// --- Tarjeta perfil central ---

class _MonthiversaryBanner extends StatelessWidget {
  final int months;

  const _MonthiversaryBanner({required this.months});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final msg = months == 1
        ? l10n.monthiversaryOne
        : l10n.monthiversaryN(months);
    return Semantics(
      button: true,
      label: msg,
      hint: l10n.monthiversarySemanticsHint,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () =>
              unawaited(MonthiversaryConfettiService.playManual(context)),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(AppTheme.paletteTertiary, Colors.white, 0.72)!,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Color.lerp(
                  AppTheme.paletteTertiary,
                  AppTheme.paletteSecondary,
                  0.5,
                )!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.paletteTertiary.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.celebration_rounded,
                  size: 20,
                  color: AppTheme.palettePrimary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textHeading,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar con anillo degradado (azul o rosa según sexo), halo blanco y sombra.
class _ProfileGradientAvatarRing extends StatelessWidget {
  /// Diámetro exterior del anillo (degradado + halo).
  static const double outerDiameter = 108;
  static const double _ringThickness = 4;
  static const double _whiteInset = 2;

  final bool? isMale;
  final Widget child;

  const _ProfileGradientAvatarRing({required this.isMale, required this.child});

  @override
  Widget build(BuildContext context) {
    final accent = isMale == false
        ? AppTheme.genderFemalePink
        : AppTheme.palettePrimary;
    final topTint = Color.lerp(Colors.white, accent, 0.42)!;
    return SizedBox(
      width: outerDiameter,
      height: outerDiameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topTint, accent],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.28),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(_ringThickness),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(_whiteInset),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    child,
                    // Sombra interior suave en la parte superior del recorte
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withValues(alpha: 0.07),
                              Colors.black.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Interior del avatar vacío (solo fondo + cara Material).
class _BabyPhotoPlaceholderInner extends StatelessWidget {
  final bool? isMale;

  const _BabyPhotoPlaceholderInner({required this.isMale});

  @override
  Widget build(BuildContext context) {
    final accent = isMale == false
        ? AppTheme.genderFemalePink
        : AppTheme.palettePrimary;
    return ColoredBox(
      color: const Color(0xFFF2F4F5),
      child: Center(
        child: Icon(
          isMale == false ? Icons.face_3 : Icons.face,
          size: 40,
          color: accent,
        ),
      ),
    );
  }
}

/// Botón “+” que sobresale del círculo, en esquina inferior derecha.
class _AddPhotoBadgeOutside extends StatelessWidget {
  final Color accentColor;

  const _AddPhotoBadgeOutside({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: accentColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.add, size: 15, color: Colors.white),
    );
  }
}

/// Tres «z» en cascada que aparecen/desaparecen con suavidad (durmiendo).
class _SleepingZzzIndicator extends StatefulWidget {
  const _SleepingZzzIndicator();

  @override
  State<_SleepingZzzIndicator> createState() => _SleepingZzzIndicatorState();
}

class _SleepingZzzIndicatorState extends State<_SleepingZzzIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _opacityFor(int index) {
    // Cada z entra con desfase; curva suave en seno.
    final phase = (_controller.value + index * 0.22) % 1.0;
    final wave = math.sin(phase * math.pi);
    return (0.15 + 0.75 * wave).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.homeSleepInsightSleepingLabel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < 3; i++)
                  Positioned(
                    left: 2.0 + i * 8,
                    bottom: 2.0 + i * 9,
                    child: Opacity(
                      opacity: _opacityFor(i),
                      child: Text(
                        'z',
                        style: TextStyle(
                          fontSize: 11.0 + i * 2.5,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.sleepPurpleDeep.withValues(
                            alpha: 0.55 + i * 0.12,
                          ),
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Anillo de avatar con indicador zzz arriba-derecha (fuera del círculo) si duerme.
class _ProfileAvatarStack extends StatelessWidget {
  final bool? isMale;
  final bool isSleeping;
  final Widget avatarChild;
  final Widget? trailingBadge;

  const _ProfileAvatarStack({
    required this.isMale,
    required this.isSleeping,
    required this.avatarChild,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ProfileGradientAvatarRing.outerDiameter,
      height: _ProfileGradientAvatarRing.outerDiameter,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _ProfileGradientAvatarRing(isMale: isMale, child: avatarChild),
          if (trailingBadge != null)
            Positioned(right: 4, bottom: 4, child: trailingBadge!),
          if (isSleeping)
            const Positioned(
              right: -6,
              top: -8,
              child: _SleepingZzzIndicator(),
            ),
        ],
      ),
    );
  }
}

/// Placeholder completo: anillo + cara; el “+” va fuera del recorte oval (sobrepuesto al redondel).
class _AvatarPlaceholderWithOutsideBadge extends StatelessWidget {
  final bool? isMale;
  final bool isSleeping;

  const _AvatarPlaceholderWithOutsideBadge({
    required this.isMale,
    this.isSleeping = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isMale == false
        ? AppTheme.genderFemalePink
        : AppTheme.palettePrimary;
    return _ProfileAvatarStack(
      isMale: isMale,
      isSleeping: isSleeping,
      avatarChild: _BabyPhotoPlaceholderInner(isMale: isMale),
      trailingBadge: _AddPhotoBadgeOutside(accentColor: accent),
    );
  }
}

class _ProfileSummaryCard extends ConsumerWidget {
  final BabyProfile? baby;
  final double? weightKg;
  final double? heightCm;
  final bool isSleeping;
  final VoidCallback onPhotoTap;

  const _ProfileSummaryCard({
    required this.baby,
    required this.weightKg,
    required this.heightCm,
    required this.onPhotoTap,
    this.isSleeping = false,
  });

  static String _formatAgeLine(
    BuildContext context,
    ({int months, int days}) age,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (age.months == 1 && age.days == 1) {
      return l10n.babyAgeMonthsOneDaysOne;
    }
    if (age.months == 1) {
      return l10n.babyAgeMonthsOneDaysN(age.days);
    }
    if (age.days == 1) {
      return l10n.babyAgeMonthsNDaysOne(age.months);
    }
    return l10n.babyAgeMonthsNDaysN(age.days, age.months);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final prefs =
        ref.watch(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    final isMale = baby?.isMale;
    final name = baby?.name ?? l10n.profileDefaultBabyName;
    final now = DateTime.now();
    final ({int months, int days})? age = baby != null
        ? BabyAgeCalendar.monthsAndDaysAt(baby!.birthDate, now)
        : null;
    final monthiversary = age != null && age.months >= 1 && age.days == 0;

    return Material(
      color: AppTheme.cardBackground,
      elevation: AppTheme.cardElevation,
      shadowColor: Colors.black12,
      shape: AppTheme.homeCardShapeRounded,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          children: [
            GestureDetector(
              onTap: onPhotoTap,
              child: baby?.photoUrl != null && baby!.photoUrl!.isNotEmpty
                  ? _ProfileAvatarStack(
                      isMale: isMale,
                      isSleeping: isSleeping,
                      avatarChild: _LargeAvatarImage(
                        photoUrl: baby!.photoUrl!,
                        isMale: isMale,
                      ),
                    )
                  : _AvatarPlaceholderWithOutsideBadge(
                      isMale: isMale,
                      isSleeping: isSleeping,
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Misma anchura que gap + icono: el nombre queda centrado sin contar el símbolo.
                if (isMale != null) const SizedBox(width: 20),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    height: 1.15,
                  ),
                ),
                if (isMale != null) ...[
                  const SizedBox(width: 2),
                  Transform.translate(
                    offset: const Offset(0, -3),
                    child: Icon(
                      isMale == true ? Icons.male : Icons.female,
                      color: isMale == true
                          ? AppTheme.genderMaleBabyBlue
                          : AppTheme.genderFemalePink,
                      size: 19,
                    ),
                  ),
                ],
              ],
            ),
            if (age != null) ...[
              const SizedBox(height: 4),
              if (monthiversary)
                Center(child: _MonthiversaryBanner(months: age.months))
              else
                Text(
                  _formatAgeLine(context, age),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textLight,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Center(
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weightKg != null
                              ? formatWeightFromKg(weightKg!, prefs, l10n)
                              : '—',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.palettePrimary,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.profileWeightLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.textLight,
                                letterSpacing: 1.25,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppTheme.fieldBorder,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          heightCm != null
                              ? formatHeightFromCm(heightCm!, l10n)
                              : '—',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.palettePrimary,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.profileHeightLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.textLight,
                                letterSpacing: 1.25,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LargeAvatarImage extends StatelessWidget {
  final String photoUrl;
  final bool? isMale;

  const _LargeAvatarImage({required this.photoUrl, required this.isMale});

  @override
  Widget build(BuildContext context) {
    final placeholderColor = isMale == false
        ? AppTheme.genderFemalePink
        : AppTheme.textLight;
    final faceIcon = isMale == false ? Icons.face_3 : Icons.face;
    if (photoUrl.startsWith('data:')) {
      try {
        final base64 = photoUrl.split(',').last;
        final bytes = base64Decode(base64);
        return Image.memory(
          bytes,
          key: ValueKey(photoUrl),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) =>
              Icon(faceIcon, color: placeholderColor, size: 40),
        );
      } catch (_) {
        return Icon(faceIcon, color: placeholderColor, size: 40);
      }
    }
    return Image.network(
      photoUrl,
      key: ValueKey(photoUrl),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) =>
          Icon(faceIcon, color: placeholderColor, size: 40),
    );
  }
}

class _HomeSectionTitle extends StatelessWidget {
  final String title;

  const _HomeSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: Colors.black,
        height: 1.2,
      ),
    );
  }
}

// --- Resumen ---

class _ResumenDeHoyBlock extends StatelessWidget {
  final SleepHomeSummary sleep;
  final _FeedingData feeding;
  final _DiapersData diapers;
  final VoidCallback onTapSleep;
  final VoidCallback onTapFeeding;
  final VoidCallback onTapDiapers;
  final bool liveFeedingClock;
  final String dateFormatCode;

  const _ResumenDeHoyBlock({
    required this.sleep,
    required this.feeding,
    required this.diapers,
    required this.onTapSleep,
    required this.onTapFeeding,
    required this.onTapDiapers,
    this.liveFeedingClock = true,
    required this.dateFormatCode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel = DateFormat(
      'd MMM',
      dateFormatCode,
    ).format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n.homeSummaryTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.softPrimaryFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                dateLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.palettePrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _UltimaTomaCard(
          data: feeding,
          onTap: onTapFeeding,
          liveClockActive: liveFeedingClock,
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SuenoResumenCard(
                  data: sleep,
                  onTap: onTapSleep,
                  dateFormatCode: dateFormatCode,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PanalesResumenCard(
                  data: diapers,
                  onTap: onTapDiapers,
                  dateFormatCode: dateFormatCode,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UltimaTomaCard extends ConsumerStatefulWidget {
  final _FeedingData data;
  final VoidCallback onTap;
  final bool liveClockActive;

  const _UltimaTomaCard({
    required this.data,
    required this.onTap,
    this.liveClockActive = true,
  });

  @override
  ConsumerState<_UltimaTomaCard> createState() => _UltimaTomaCardState();
}

class _UltimaTomaCardState extends ConsumerState<_UltimaTomaCard>
    with WidgetsBindingObserver {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _UltimaTomaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liveClockActive != widget.liveClockActive ||
        oldWidget.data.lastFeedingAt != widget.data.lastFeedingAt ||
        oldWidget.data.lastBottleMl != widget.data.lastBottleMl ||
        oldWidget.data.expectedFeedingIntervalMinutes !=
            widget.data.expectedFeedingIntervalMinutes) {
      _syncTimer();
      if (mounted) setState(() {});
    }
  }

  void _syncTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;
    if (!widget.liveClockActive) return;
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  String _nextFeedingHint(
    AppLocalizations l10n,
    DateTime? lastAt,
    int intervalMinutes,
  ) {
    if (lastAt == null) return '';
    final next = lastAt.add(Duration(minutes: intervalMinutes));
    final diff = next.difference(DateTime.now());
    if (diff.inMinutes <= 0) return l10n.homeNextFeedSoon;
    return l10n.homeNextFeedIn(formatMinutesLocalized(l10n, diff.inMinutes));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.data;
    final prefs =
        ref.watch(measurementPrefsProvider).valueOrNull ??
        MeasurementPrefs.defaultsForDispatcher();
    final hasLast =
        data.lastFeedingAt != null &&
        (data.lastFeedingDetail != null || data.lastBottleMl != null);
    final detailLine = data.lastBottleMl != null
        ? l10n.lastFeedDetailBottleVolume(
            formatVolumeFromMl(data.lastBottleMl!, prefs, l10n),
          )
        : data.lastFeedingDetail;
    final minutesAgo = data.lastFeedingAt != null
        ? DateTime.now().difference(data.lastFeedingAt!).inMinutes
        : null;
    final subHint = _nextFeedingHint(
      l10n,
      data.lastFeedingAt,
      data.expectedFeedingIntervalMinutes,
    );

    return Material(
      color: AppTheme.palettePrimary,
      elevation: AppTheme.cardElevation,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28), width: 1),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: hasLast
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.homeLastFeedLabel,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.homeLastFeedAgo(
                              formatMinutesLocalized(l10n, minutesAgo!),
                            ),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            detailLine!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          if (subHint.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subHint,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ],
                      )
                    : Text(
                        l10n.homeNoFeedingsYet,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.schedule_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle? _homeMetricTitleStyle(BuildContext context) =>
    HomeCardTitleRow.titleStyle(context);

class _SuenoResumenCard extends StatelessWidget {
  final SleepHomeSummary data;
  final VoidCallback onTap;
  final String dateFormatCode;

  const _SuenoResumenCard({
    required this.data,
    required this.onTap,
    required this.dateFormatCode,
  });

  String? _formatLastRecorded(DateTime? dt) {
    if (dt == null) return null;
    return DateFormat('d MMM · HH:mm', dateFormatCode).format(dt);
  }

  String _formatHoursFromSeconds(AppLocalizations l10n, int totalSeconds) {
    final totalMinutes = totalSeconds ~/ 60;
    return formatMinutesLocalized(l10n, totalMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lastLabel = _formatLastRecorded(data.lastRecordedAt);
    final todayLabel = _formatHoursFromSeconds(l10n, data.todaySeconds);
    final nights = data.todayNightCount.clamp(0, 99);
    final naps = data.todayNapCount.clamp(0, 99);
    return Material(
      color: AppTheme.cardBackground,
      elevation: AppTheme.cardElevation,
      shadowColor: Colors.black12,
      shape: AppTheme.homeCardShapeRounded,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -12,
                child: Icon(
                  Icons.nightlight_round,
                  size: 72,
                  color: AppTheme.sleepPurple.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.navSleep, style: _homeMetricTitleStyle(context)),
                    const SizedBox(height: 8),
                    Text(
                      todayLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.homeSleepPattern(nights, naps),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    if (lastLabel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.homeWeightLast(lastLabel),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
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

class _PanalesResumenCard extends StatelessWidget {
  final _DiapersData data;
  final VoidCallback onTap;
  final String dateFormatCode;

  const _PanalesResumenCard({
    required this.data,
    required this.onTap,
    required this.dateFormatCode,
  });

  String? _formatLastRecorded(DateTime? dt) {
    if (dt == null) return null;
    return DateFormat('d MMM · HH:mm', dateFormatCode).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lastLabel = _formatLastRecorded(data.lastRecordedAt);
    return Material(
      color: AppTheme.cardBackground,
      elevation: AppTheme.cardElevation,
      shadowColor: Colors.black12,
      shape: AppTheme.homeCardShapeRounded,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
          child: Stack(
            children: [
              Positioned(
                right: -6,
                bottom: -10,
                child: Icon(
                  MdiIcons.humanBabyChangingTable,
                  size: 70,
                  color: AppTheme.navDiapersSelectedFg.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navDiapers,
                      style: _homeMetricTitleStyle(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.totalToday == 1
                          ? l10n.homeDiaperChangesOne
                          : l10n.homeDiaperChangesN(data.totalToday),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.homeDiapersWetDirty(data.dirtyCount, data.wetCount),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    if (lastLabel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.homeWeightLast(lastLabel),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
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

class _HomeInfoResumenRow extends StatelessWidget {
  final _FeedingDistributionData feedingDistribution;

  const _HomeInfoResumenRow({required this.feedingDistribution});

  @override
  Widget build(BuildContext context) {
    return _FeedingDistributionResumenCard(data: feedingDistribution);
  }
}

class _DiaperSpendInsightCard extends ConsumerWidget {
  final DiaperSpendInsightStats data;

  const _DiaperSpendInsightCard({required this.data});

  void _showInfoSheet(BuildContext context, String unitCostText) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final maxHeight = MediaQuery.sizeOf(sheetCtx).height * 0.85;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.dialogRadius),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.viewInsetsOf(sheetCtx).bottom +
                      AppTheme.extraBottomSpacing,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 24),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textLight.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeDiaperSpendInsightInfoTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeDiaperSpendInsightInfoBody(unitCostText),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textLight,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardRadius,
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: Text(
                          l10n.homeFeedingTrendInfoButton,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = l10n.localeName;
    final prefs = ref.watch(measurementPrefsProvider).valueOrNull;
    final money = resolveDiaperCostConfig(
      moneyLocale: moneyLocaleForContext(context),
      currencyCode: prefs?.currencyCode,
    );
    final averageText = NumberFormat.decimalPatternDigits(
      locale: localeName,
      decimalDigits: 1,
    ).format(data.currentDailyAverage);
    final costText = money.format(money.dailyCost(data.currentDailyAverage));
    final monthlyCostText = money.format(
      money.monthlyCost(data.currentDailyAverage),
    );
    final unitCostText = money.format(money.unitCost);
    final deltaFormat = NumberFormat.decimalPatternDigits(
      locale: localeName,
      decimalDigits: 1,
    );
    final signedDeltaText = switch (data.comparison) {
      DiaperSpendWeekComparison.same => deltaFormat.format(0),
      DiaperSpendWeekComparison.more =>
        '+${deltaFormat.format(data.averageDelta)}',
      DiaperSpendWeekComparison.less => deltaFormat.format(data.averageDelta),
    };
    final comparisonLabel = l10n.homeDiaperSpendInsightWeekDelta(
      signedDeltaText,
    );
    final comparisonIcon = switch (data.comparison) {
      DiaperSpendWeekComparison.more => Icons.trending_up_rounded,
      DiaperSpendWeekComparison.less => Icons.trending_down_rounded,
      DiaperSpendWeekComparison.same => Icons.drag_handle_rounded,
    };
    final comparisonColor = switch (data.comparison) {
      DiaperSpendWeekComparison.more => AppTheme.trendPositiveGreen,
      DiaperSpendWeekComparison.less => const Color(0xFFEF5350),
      DiaperSpendWeekComparison.same => AppTheme.textLight,
    };
    final comparisonFill = switch (data.comparison) {
      DiaperSpendWeekComparison.more => AppTheme.paletteSecondary.withValues(
        alpha: 0.42,
      ),
      DiaperSpendWeekComparison.less => const Color(0xFFFFEBEE),
      DiaperSpendWeekComparison.same => AppTheme.fieldBackground,
    };

    return Material(
      color: AppTheme.cardBackground,
      elevation: AppTheme.cardElevation,
      shadowColor: Colors.black12,
      shape: AppTheme.homeCardShapeRounded,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeCardTitleRow(
              title: l10n.homeDiaperSpendInsightTitle.toUpperCase(),
              infoTooltip: l10n.homeDiaperSpendInsightInfoTitle,
              onInfoPressed: () => _showInfoSheet(context, unitCostText),
            ),
            const SizedBox(height: HomeCardTitleRow.gapAfter),
            if (!data.hasAnyRecord)
              Text(
                l10n.homeDiaperSpendInsightAddFirst,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.4,
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    averageText,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.palettePrimary,
                      fontWeight: FontWeight.w800,
                      height: 0.95,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      l10n.homeDiaperSpendInsightDiapersPerDay,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: comparisonFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(comparisonIcon, size: 16, color: comparisonColor),
                    const SizedBox(width: 5),
                    Text(
                      comparisonLabel,
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(
                            color: comparisonColor,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DiaperCostMiniCard(
                    icon: Icons.wb_sunny_outlined,
                    label: l10n.homeDiaperSpendInsightPerDay,
                    value: costText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DiaperCostMiniCard(
                    icon: Icons.calendar_month_outlined,
                    label: l10n.homeDiaperSpendInsightPerMonth,
                    value: monthlyCostText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaperCostMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DiaperCostMiniCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.fieldBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: AppTheme.palettePrimary.withValues(alpha: 0.72),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaysSleepCard extends StatefulWidget {
  final SleepInsightStats data;
  final String dateFormatCode;

  const _TodaysSleepCard({required this.data, required this.dateFormatCode});

  @override
  State<_TodaysSleepCard> createState() => _TodaysSleepCardState();
}

class _TodaysSleepCardState extends State<_TodaysSleepCard> {
  Timer? _tickTimer;

  SleepInsightStats get data => widget.data;
  String get dateFormatCode => widget.dateFormatCode;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _TodaysSleepCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.isSleeping != data.isSleeping) _syncTimer();
  }

  void _syncTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;
    if (!data.isSleeping) return;
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _showInfoSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = <({String title, String body})>[
      (
        title: l10n.homeSleepInsightInfoPredictTitle,
        body: l10n.homeSleepInsightInfoPredictBody,
      ),
      (
        title: l10n.homeSleepInsightInfoLoggingTitle,
        body: l10n.homeSleepInsightInfoLoggingBody,
      ),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final maxHeight = MediaQuery.sizeOf(sheetCtx).height * 0.85;
        final bodyStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.textLight,
          fontWeight: FontWeight.w600,
          height: 1.45,
        );
        final sectionTitleStyle = Theme.of(context).textTheme.titleSmall
            ?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
              height: 1.2,
            );
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.dialogRadius),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.viewInsetsOf(sheetCtx).bottom +
                      AppTheme.extraBottomSpacing,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textLight.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeSleepInsightInfoTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeSleepInsightInfoIntro,
                        style: bodyStyle,
                      ),
                    ),
                    for (final section in sections) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(section.title, style: sectionTitleStyle),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(section.body, style: bodyStyle),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardRadius,
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: Text(
                          l10n.homeFeedingTrendInfoButton,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(AppLocalizations l10n, int totalSeconds) {
    return formatMinutesLocalized(l10n, totalSeconds ~/ 60);
  }

  String _formatTimeWindow(DateTime start, DateTime end) {
    final fmt = DateFormat('HH:mm', dateFormatCode);
    return '${fmt.format(start)}–${fmt.format(end)}';
  }

  /// Progreso del anillo: 0 al despertar → 1 al llegar a la ventana de sueño.
  double _moonProgress({
    required SleepRecord? open,
    required NextSleepPrediction? prediction,
  }) {
    if (open != null) return 1;
    if (prediction == null) return 0;
    final window = prediction.adjustedWindowMinutes;
    if (window <= 0) return 0;
    return (prediction.awakeMinutesNow / window).clamp(0.0, 1.0);
  }

  String _nextSleepLabel(
    AppLocalizations l10n,
    NextSleepPrediction prediction,
  ) {
    return switch (prediction.kind) {
      NextSleepKind.nextNap => l10n.homeSleepInsightNextSleepLabel,
      NextSleepKind.bedtime => l10n.homeSleepInsightBedtimeLabel,
    };
  }

  List<InlineSpan> _sleepRelativeSpans(
    String source,
    String? highlight,
    TextStyle? base,
    TextStyle? emph,
  ) {
    if (highlight == null || highlight.isEmpty || !source.contains(highlight)) {
      return [TextSpan(text: source, style: base)];
    }
    final i = source.indexOf(highlight);
    return [
      if (i > 0) TextSpan(text: source.substring(0, i), style: base),
      TextSpan(text: highlight, style: emph),
      if (i + highlight.length < source.length)
        TextSpan(text: source.substring(i + highlight.length), style: base),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prediction = data.nextSleep;

    String? nextLabel;
    String? nextValue;
    String? nextRelative;
    String? relativeHighlight;
    final open = data.openSession;
    final hasNextSleepHeadline = open != null ||
        (data.hasAnySleepRecord && prediction != null);
    if (open != null) {
      nextLabel = l10n.homeSleepInsightSleepingLabel;
      nextValue = _formatDuration(l10n, open.durationSeconds());
      final time = DateFormat(
        'HH:mm',
        dateFormatCode,
      ).format(open.startDateTime);
      nextRelative = l10n.homeSleepInsightSleepingSince(time);
      relativeHighlight = time;
    } else if (!data.hasAnySleepRecord) {
      nextValue = l10n.homeSleepInsightAddFirstSleep;
    } else if (prediction != null) {
      nextLabel = _nextSleepLabel(l10n, prediction);
      nextValue = _formatTimeWindow(
        prediction.windowStart,
        prediction.windowEnd,
      );
      final minutes = prediction.minutesFromNow;
      final durationText = formatMinutesLocalized(l10n, minutes.abs());
      nextRelative = minutes >= 0
          ? l10n.homeSleepInsightNextSleepRelative(durationText)
          : l10n.homeSleepInsightNextSleepRelativePast(durationText);
      relativeHighlight = durationText;
    } else {
      nextLabel = l10n.homeSleepInsightNextSleepLabel;
      nextValue = l10n.homeSleepInsightNoBirthDate;
    }

    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppTheme.textLight,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );
    final valueStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: AppTheme.textDark,
      fontWeight: FontWeight.w800,
      height: 1.1,
      letterSpacing: -0.4,
    );
    final relativeBaseStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppTheme.textLight,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    final relativeHighlightStyle = relativeBaseStyle?.copyWith(
      color: AppTheme.sleepPurple,
      fontWeight: FontWeight.w800,
    );

    return Material(
      color: AppTheme.cardBackground,
      elevation: AppTheme.cardElevation,
      shadowColor: Colors.black12,
      shape: AppTheme.homeCardShapeRounded,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeCardTitleRow(
              title: l10n.homeTodaysSleepTitle.toUpperCase(),
              infoTooltip: l10n.homeSleepInsightInfoTitle,
              onInfoPressed: () => _showInfoSheet(context),
            ),
            const SizedBox(height: HomeCardTitleRow.gapAfter),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SleepInsightMoonProgress(
                  progress: _moonProgress(
                    open: open,
                    prediction: data.hasAnySleepRecord ? prediction : null,
                  ),
                  icon: open != null
                      ? Icons.bedtime_rounded
                      : Icons.nightlight_round,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasNextSleepHeadline) ...[
                        Text(
                          nextLabel ?? l10n.homeSleepInsightNextSleepLabel,
                          style: labelStyle,
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        nextValue ?? l10n.homeSleepInsightNoBirthDate,
                        style: valueStyle,
                      ),
                      if (nextRelative != null) ...[
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: _sleepRelativeSpans(
                              nextRelative,
                              relativeHighlight,
                              relativeBaseStyle,
                              relativeHighlightStyle,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SleepInsightDayTimeline(
              records: data.todayTimelineRecords,
              todayLabel: l10n.homeSleepInsightDayTimelineToday,
              formatTotal: (secs) => l10n.homeSleepInsightDayTimelineTotal(
                _formatDuration(l10n, secs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barras «últimos 7 días» + horario habitual en Insights.
class _SleepAnalysisCard extends StatelessWidget {
  final SleepInsightStats data;
  final String dateFormatCode;
  final String babyName;

  const _SleepAnalysisCard({
    required this.data,
    required this.dateFormatCode,
    required this.babyName,
  });

  void _showInfoSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final maxHeight = MediaQuery.sizeOf(sheetCtx).height * 0.85;
        final bodyStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.textLight,
          fontWeight: FontWeight.w600,
          height: 1.45,
        );
        final sectionTitleStyle = Theme.of(context).textTheme.titleSmall
            ?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
              height: 1.2,
            );
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.dialogRadius),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.viewInsetsOf(sheetCtx).bottom +
                      AppTheme.extraBottomSpacing,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textLight.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeSleepInsightInfoTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeSleepInsightInfoIntro,
                        style: bodyStyle,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeSleepInsightInfoMetricsTitle,
                        style: sectionTitleStyle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeSleepInsightInfoMetricsBody,
                        style: bodyStyle,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeSleepInsightInfoScheduleTitle,
                        style: sectionTitleStyle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeSleepInsightInfoScheduleBody,
                        style: bodyStyle,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardRadius,
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: Text(
                          l10n.homeFeedingTrendInfoButton,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(AppLocalizations l10n, int totalSeconds) {
    return formatMinutesLocalized(l10n, totalSeconds ~/ 60);
  }

  List<String> _sleepWeekDayLabels(
    AppLocalizations l10n,
    String dateFormatCode,
  ) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final isEs = dateFormatCode.toLowerCase().startsWith('es');
    return List<String>.generate(7, (i) {
      final day = todayStart.subtract(Duration(days: 6 - i));
      if (i == 6) return l10n.homeSleepInsightChartToday;
      return _weekdayLetter(day.weekday, spanish: isEs);
    });
  }

  List<String> _sleepWeekDayTitles(
    AppLocalizations l10n,
    String dateFormatCode,
  ) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final fmt = DateFormat('EEEE d MMM', dateFormatCode);
    return List<String>.generate(7, (i) {
      final day = todayStart.subtract(Duration(days: 6 - i));
      if (i == 6) return l10n.homeSleepInsightDayTimelineToday;
      final raw = fmt.format(day);
      if (raw.isEmpty) return raw;
      return raw[0].toUpperCase() + raw.substring(1);
    });
  }

  String _weekdayLetter(int weekday, {required bool spanish}) {
    if (spanish) {
      const letters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
      return letters[weekday - 1];
    }
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return letters[weekday - 1];
  }

  String _formatClockMinutes(int minutesOfDay) {
    final normalized = ((minutesOfDay % (24 * 60)) + (24 * 60)) % (24 * 60);
    final h = normalized ~/ 60;
    final m = normalized % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _slotTitle(
    AppLocalizations l10n,
    UsualSleepSlotKind kind, {
    int occurrenceIndex = 1,
  }) {
    final baseTitle = switch (kind) {
      UsualSleepSlotKind.morningNap => l10n.homeSleepSlotMorningNap,
      UsualSleepSlotKind.middayNap => l10n.homeSleepSlotMiddayNap,
      UsualSleepSlotKind.afternoonNap => l10n.homeSleepSlotAfternoonNap,
      UsualSleepSlotKind.catnap => l10n.homeSleepSlotCatnap,
      UsualSleepSlotKind.night => l10n.homeSleepSlotNightSleep,
    };
    if (kind == UsualSleepSlotKind.night || occurrenceIndex <= 1) {
      return baseTitle;
    }
    return '$baseTitle ($occurrenceIndex)';
  }

  String _slotWindow(UsualSleepSlot slot) {
    return '${_formatClockMinutes(slot.medianStartMinutesOfDay)} – '
        '${_formatClockMinutes(slot.medianEndMinutesOfDay)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final usualValue = data.hasUsualEstimate
        ? _formatDuration(l10n, data.usualDailySeconds!)
        : '—';
    final pattern = data.usualPattern;
    final hasSlots =
        pattern.slots.isNotEmpty || pattern.abandonedNaps.isNotEmpty;
    final showEmpty = !data.hasAnySleepRecord;

    return Material(
      color: AppTheme.cardBackground,
      elevation: AppTheme.cardElevation,
      shadowColor: Colors.black12,
      shape: AppTheme.homeCardShapeRounded,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeCardTitleRow(
              title: l10n.homeSleepInsightTitle.toUpperCase(),
              infoTooltip: l10n.homeSleepInsightInfoTitle,
              onInfoPressed: () => _showInfoSheet(context),
            ),
            const SizedBox(height: HomeCardTitleRow.gapAfter),
            SleepInsightWeekChart(
              daySeconds: data.last7DaysSeconds,
              averageSeconds: data.usualDailySeconds ?? 0,
              dayLabels: _sleepWeekDayLabels(l10n, dateFormatCode),
              dayTitles: _sleepWeekDayTitles(l10n, dateFormatCode),
              formatDuration: (secs) => _formatDuration(l10n, secs),
              emptyDurationLabel: l10n.homeSleepInsightBarNoData,
              averageDurationLabel: usualValue,
              headerTitle: l10n.homeSleepInsightLast7Days,
              averagePrefix: l10n.homeSleepInsightAveragePrefix,
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: AppTheme.fieldBorder),
            const SizedBox(height: 12),
            Text(
              l10n.homeSleepPatternHeaderLast14.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF9CA6AE),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                fontSize: 11,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            if (showEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.homeSleepInsightAddFirstSleep,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.4,
                  ),
                ),
              )
            else if (hasSlots) ...[
              for (var i = 0; i < pattern.slots.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppTheme.fieldBorder),
                _UsualSleepSlotRow(
                  title: _slotTitle(
                    l10n,
                    pattern.slots[i].kind,
                    occurrenceIndex: pattern.slots[i].occurrenceIndex,
                  ),
                  windowLabel: _slotWindow(pattern.slots[i]),
                  durationLabel: _formatDuration(
                    l10n,
                    pattern.slots[i].medianDurationSeconds,
                  ),
                  durationCaption: l10n.homeSleepDurationLabel,
                  frequencyLabel: pattern.slots[i].isNap
                      ? l10n.homeSleepSlotFrequencyCount(
                          pattern.slots[i].sampleCount,
                          pattern.slots[i].lookbackDays,
                        )
                      : null,
                ),
              ],
              for (final abandoned in pattern.abandonedNaps) ...[
                Divider(height: 1, color: AppTheme.fieldBorder),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '${_slotTitle(l10n, abandoned.kind, occurrenceIndex: abandoned.occurrenceIndex)} · ${l10n.homeSleepAbandonedNap(babyName)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.homeSleepInsightNoData,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UsualSleepSlotRow extends StatelessWidget {
  final String title;
  final String windowLabel;
  final String durationLabel;
  final String durationCaption;
  final String? frequencyLabel;

  const _UsualSleepSlotRow({
    required this.title,
    required this.windowLabel,
    required this.durationLabel,
    required this.durationCaption,
    this.frequencyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (frequencyLabel != null) ...[
                      const SizedBox(width: 8),
                      _SleepFrequencyPill(label: frequencyLabel!),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  windowLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                durationCaption,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                durationLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SleepFrequencyPill extends StatelessWidget {
  final String label;

  const _SleepFrequencyPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.sleepPurpleSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.sleepPurpleDeep,
          fontWeight: FontWeight.w700,
          height: 1.1,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Luna centrada en un anillo que se llena al acercarse la hora de sueño.
class _SleepInsightMoonProgress extends StatelessWidget {
  static const double _size = 68;
  static const double _strokeWidth = 5;

  final double progress;
  final IconData icon;

  const _SleepInsightMoonProgress({required this.progress, required this.icon});

  @override
  Widget build(BuildContext context) {
    const accent = AppTheme.sleepHistoryNightAccent;
    return SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _SleepInsightMoonProgressPainter(
          progress: progress.clamp(0.0, 1.0),
          progressColor: accent,
          trackColor: accent.withValues(alpha: 0.18),
          strokeWidth: _strokeWidth,
        ),
        child: Center(child: Icon(icon, size: 28, color: accent)),
      ),
    );
  }
}

class _SleepInsightMoonProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _SleepInsightMoonProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SleepInsightMoonProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _FeedingDistributionResumenCard extends StatelessWidget {
  final _FeedingDistributionData data;

  const _FeedingDistributionResumenCard({required this.data});

  static const _breastColor = Color(0xFF234C5E);
  static const _breastRightColor = Color(0xFF6FA2B6);
  static const _bottleColor = Color(0xFFA7D8F0);
  static const _solidColor = AppTheme.paletteTertiary;
  static const _donutSize = 122.0;

  void _showInfoSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final maxHeight = MediaQuery.sizeOf(sheetCtx).height * 0.85;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.dialogRadius),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.viewInsetsOf(sheetCtx).bottom +
                      AppTheme.extraBottomSpacing,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 24),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textLight.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeFeedingDistributionInfoTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeFeedingDistributionSevenDayAverage,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeFeedingDistributionInfoBody,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textLight,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardRadius,
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: Text(
                          l10n.homeFeedingTrendInfoButton,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // El donut solo pinta tramos > 0. Sin historial: anillo vacío + pecho y
    // biberón a 0%. Con historial, la leyenda sigue everHad* (solo lo que toma).
    final segments = <_FeedingDistributionSegment>[
      if (data.leftBreastMl > 0)
        _FeedingDistributionSegment(
          label: l10n.feedingLeft,
          value: data.leftBreastMl,
          color: _breastColor,
        ),
      if (data.rightBreastMl > 0)
        _FeedingDistributionSegment(
          label: l10n.feedingRight,
          value: data.rightBreastMl,
          color: _breastRightColor,
        ),
      if (data.bottleMl > 0)
        _FeedingDistributionSegment(
          label: l10n.feedingBottle,
          value: data.bottleMl,
          color: _bottleColor,
        ),
      if (data.solidMl > 0)
        _FeedingDistributionSegment(
          label: l10n.feedingSolidFood,
          value: data.solidMl,
          color: _solidColor,
        ),
    ]..sort((a, b) => b.value.compareTo(a.value));

    return Material(
      color: AppTheme.cardBackground,
      elevation: AppTheme.cardElevation,
      shadowColor: Colors.black12,
      shape: AppTheme.homeCardShapeRounded,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeCardTitleRow(
                title: l10n.homeFeedingDistributionTitle.toUpperCase(),
                infoTooltip: l10n.homeFeedingDistributionInfoTitle,
                onInfoPressed: () => _showInfoSheet(context),
              ),
              const SizedBox(height: HomeCardTitleRow.gapAfter),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: _FeedingDistributionDonut(segments: segments),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildSortedLegend(l10n),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSortedLegend(AppLocalizations l10n) {
    if (!data.everHadBreast && !data.everHadBottle && !data.everHadSolid) {
      return [
        _FeedingDistributionLegendItem(
          label: l10n.feedingBreast,
          percent: 0,
          color: _breastColor,
          secondaryColor: _breastRightColor,
        ),
        const _FeedingDistributionLegendDivider(),
        _FeedingDistributionLegendItem(
          label: l10n.feedingBottle,
          percent: 0,
          color: _bottleColor,
        ),
      ];
    }

    // Orden por ml reales (no % redondeado) para que 100% biberón
    // quede siempre por encima de 0% pecho/sólidos.
    final entries = <({double ml, List<Widget> widgets})>[];

    if (data.everHadBreast) {
      final breastPercent = _FeedingDistributionSegment.percentOfValue(
        data.breastMl,
        data.totalMl,
      );
      final breastWidgets = <Widget>[
        _FeedingDistributionLegendItem(
          label: l10n.feedingBreast,
          percent: breastPercent,
          color: _breastColor,
          secondaryColor: _breastRightColor,
        ),
      ];
      // Sin ml de pecho en la ventana, no desglosar L/R a 0%.
      if (data.breastMl > 0 &&
          (data.everHadLeftBreast || data.everHadRightBreast)) {
        final sideItems = <({double ml, Widget widget})>[];
        if (data.everHadLeftBreast) {
          final percent = _FeedingDistributionSegment.percentOfValue(
            data.leftBreastMl,
            data.totalMl,
          );
          sideItems.add((
            ml: data.leftBreastMl,
            widget: _FeedingDistributionLegendItem(
              label: l10n.feedingLeft,
              percent: percent,
              color: _breastColor,
              isSubitem: true,
            ),
          ));
        }
        if (data.everHadRightBreast) {
          final percent = _FeedingDistributionSegment.percentOfValue(
            data.rightBreastMl,
            data.totalMl,
          );
          sideItems.add((
            ml: data.rightBreastMl,
            widget: _FeedingDistributionLegendItem(
              label: l10n.feedingRight,
              percent: percent,
              color: _breastRightColor,
              isSubitem: true,
            ),
          ));
        }
        sideItems.sort((a, b) => b.ml.compareTo(a.ml));
        breastWidgets.add(
          _FeedingDistributionLegendSubGroup(
            lineColor: _breastRightColor,
            children: sideItems.map((e) => e.widget).toList(),
          ),
        );
      }
      entries.add((ml: data.breastMl, widgets: breastWidgets));
    }

    if (data.everHadBottle) {
      final percent = _FeedingDistributionSegment.percentOfValue(
        data.bottleMl,
        data.totalMl,
      );
      entries.add((
        ml: data.bottleMl,
        widgets: [
          _FeedingDistributionLegendItem(
            label: l10n.feedingBottle,
            percent: percent,
            color: _bottleColor,
          ),
        ],
      ));
    }

    if (data.everHadSolid) {
      final percent = _FeedingDistributionSegment.percentOfValue(
        data.solidMl,
        data.totalMl,
      );
      entries.add((
        ml: data.solidMl,
        widgets: [
          _FeedingDistributionLegendItem(
            label: l10n.feedingSolidFood,
            percent: percent,
            color: _solidColor,
          ),
        ],
      ));
    }

    entries.sort((a, b) => b.ml.compareTo(a.ml));

    final children = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) children.add(const _FeedingDistributionLegendDivider());
      children.addAll(entries[i].widgets);
    }
    return children;
  }
}

class _FeedingDistributionLegendSubGroup extends StatelessWidget {
  final Color lineColor;
  final List<Widget> children;

  const _FeedingDistributionLegendSubGroup({
    required this.lineColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5, right: 7),
            child: Container(
              width: 1.5,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: lineColor.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedingDistributionLegendDivider extends StatelessWidget {
  const _FeedingDistributionLegendDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 1,
        color: AppTheme.textLight.withValues(alpha: 0.22),
      ),
    );
  }
}

class _FeedingDistributionLegendItem extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;
  final Color? secondaryColor;
  final bool isSubitem;

  const _FeedingDistributionLegendItem({
    required this.label,
    required this.percent,
    required this.color,
    this.secondaryColor,
    this.isSubitem = false,
  });

  @override
  Widget build(BuildContext context) {
    final dotSize = isSubitem ? 7.0 : 12.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _FeedingDistributionLegendDot(
            size: dotSize,
            color: color,
            secondaryColor: secondaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textLight,
                fontWeight: isSubitem ? FontWeight.w600 : FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percent%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isSubitem ? AppTheme.textLight : AppTheme.textDark,
              fontWeight: isSubitem ? FontWeight.w700 : FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedingDistributionLegendDot extends StatelessWidget {
  final double size;
  final Color color;
  final Color? secondaryColor;

  const _FeedingDistributionLegendDot({
    required this.size,
    required this.color,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FeedingDistributionLegendDotPainter(
          primaryColor: color,
          secondaryColor: secondaryColor,
          outlineColor: AppTheme.cardOutline,
        ),
      ),
    );
  }
}

class _FeedingDistributionLegendDotPainter extends CustomPainter {
  final Color primaryColor;
  final Color? secondaryColor;
  final Color outlineColor;

  _FeedingDistributionLegendDotPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (secondaryColor == null) {
      canvas.drawCircle(center, radius, Paint()..color = primaryColor);
    } else {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
      canvas.drawCircle(center, radius, Paint()..color = primaryColor);
      canvas.restore();
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
      );
      canvas.drawCircle(center, radius, Paint()..color = secondaryColor!);
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(
    covariant _FeedingDistributionLegendDotPainter oldDelegate,
  ) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.outlineColor != outlineColor;
  }
}

class _FeedingDistributionDonut extends StatelessWidget {
  final List<_FeedingDistributionSegment> segments;

  const _FeedingDistributionDonut({required this.segments});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _FeedingDistributionResumenCard._donutSize,
      height: _FeedingDistributionResumenCard._donutSize,
      child: CustomPaint(
        size: const Size.square(_FeedingDistributionResumenCard._donutSize),
        painter: _FeedingDistributionDonutPainter(segments),
      ),
    );
  }
}

class _FeedingDistributionSegment {
  final String label;
  final double value;
  final Color color;

  const _FeedingDistributionSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  int percentOf(double total) {
    return percentOfValue(value, total);
  }

  static int percentOfValue(double value, double total) {
    if (total <= 0 || value <= 0) return 0;
    return ((value / total) * 100).round();
  }
}

class _FeedingDistributionDonutPainter extends CustomPainter {
  final List<_FeedingDistributionSegment> segments;

  _FeedingDistributionDonutPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, item) => sum + item.value);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = math.max(14.0, radius * 0.38);
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final backgroundPaint = Paint()
      ..color = AppTheme.softPrimaryFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);

    if (total <= 0) return;

    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _FeedingDistributionDonutPainter oldDelegate) =>
      oldDelegate.segments != segments;
}

class _ConsejoDelDiaCard extends StatelessWidget {
  final String? factText;
  final bool missingBirthDate;

  const _ConsejoDelDiaCard({this.factText, required this.missingBirthDate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final raw = missingBirthDate
        ? l10n.sabiasQueNoBirthDate
        : (factText ?? l10n.homeTipFallback);

    final cardColor = Color.lerp(AppTheme.paletteTertiary, Colors.white, 0.62)!;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
        border: Border.all(color: AppTheme.cardOutline),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -8,
            bottom: -6,
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 84,
              color: AppTheme.tipText.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeTipTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.tipText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  raw,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.tipText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlimentacionHoyTrendCard extends StatelessWidget {
  final _FeedingTrendData data;
  final String babyName;
  final VoidCallback onTap;

  const _AlimentacionHoyTrendCard({
    required this.data,
    required this.babyName,
    required this.onTap,
  });

  void _showInfoSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final maxHeight = MediaQuery.sizeOf(sheetCtx).height * 0.85;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.dialogRadius),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.viewInsetsOf(sheetCtx).bottom +
                      AppTheme.extraBottomSpacing,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 24),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textLight.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeFeedingTrendInfoTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        l10n.homeFeedingTrendInfoBody,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textLight,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.cardRadius,
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: Text(
                          l10n.homeFeedingTrendInfoButton,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AppTheme.cardBackground,
      elevation: AppTheme.cardElevation,
      shadowColor: Colors.black12,
      shape: AppTheme.homeCardShapeRounded,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.homeCardRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeCardTitleRow(
                title: l10n.homeFeedingTrendTitle,
                infoTooltip: l10n.homeFeedingTrendInfoTitle,
                onInfoPressed: () => _showInfoSheet(context),
              ),
              const SizedBox(height: HomeCardTitleRow.gapAfter),
              data.status == _FeedingTrendStatus.learning
                  ? BabyInsightStatusLine(
                      leadingEmphasis: l10n.homeFeedingTrendStatusLearning,
                      connector: '',
                    )
                  : _FeedingTrendStatusLine(
                      babyName: babyName,
                      status: data.status,
                    ),
              const SizedBox(height: 10),
              SizedBox(
                height: 28,
                width: double.infinity,
                child: CustomPaint(painter: _FeedingTrendGaugePainter(data)),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ChartHintLabel(
                    text: l10n.homeFeedingTrendHintBelow,
                    alignment: TextAlign.left,
                  ),
                  _ChartHintLabel(
                    text: l10n.homeFeedingTrendHintUsual,
                    alignment: TextAlign.center,
                  ),
                  _ChartHintLabel(
                    text: l10n.homeFeedingTrendHintAbove,
                    alignment: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: AppTheme.fieldBorder),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _FeedingTrendMetric(
                        value: '${data.todayMl.round()} ml',
                        label: l10n.homeFeedingTrendTodayTotal,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppTheme.fieldBorder,
                      ),
                    ),
                    Expanded(
                      child: _FeedingTrendMetric(
                        value: data.remainingMedianMl == null
                            ? '—'
                            : '≈${data.remainingMedianMl!.round()} ml',
                        label: l10n.homeFeedingTrendUsuallyStill,
                      ),
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

class _FeedingTrendStatusLine extends StatelessWidget {
  final String babyName;
  final _FeedingTrendStatus status;

  const _FeedingTrendStatusLine({required this.babyName, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phrase = switch (status) {
      _FeedingTrendStatus.below => l10n.homeFeedingTrendStatusPhraseBelow,
      _FeedingTrendStatus.above => l10n.homeFeedingTrendStatusPhraseAbove,
      _ => l10n.homeFeedingTrendStatusPhraseUsual,
    };
    return BabyInsightStatusLine(leadingEmphasis: babyName, connector: phrase);
  }
}

class _ChartHintLabel extends StatelessWidget {
  final String text;
  final TextAlign alignment;

  const _ChartHintLabel({required this.text, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        text,
        textAlign: alignment,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.textLight,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class _FeedingTrendMetric extends StatelessWidget {
  final String value;
  final String label;

  const _FeedingTrendMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.palettePrimary,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.textLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FeedingTrendGaugePainter extends CustomPainter {
  final _FeedingTrendData data;

  _FeedingTrendGaugePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Marcador tipo tick fijo (no thumb circular): no invita a arrastrar.
    const markerWidth = 4.0;
    const markerHeight = 18.0;
    const markerInset = markerWidth / 2 + 1.0;
    const trackHeight = 10.0;
    final trackWidth = math.max(1.0, size.width - markerInset * 2);
    final trackRect = Rect.fromLTWH(
      markerInset,
      (size.height - trackHeight) / 2,
      trackWidth,
      trackHeight,
    );
    final trackRadius = Radius.circular(trackHeight / 2);

    final p25 = data.p25ByHour;
    final p75 = data.p75ByHour;
    final hasBand = data.hasUsualBand && p25 != null && p75 != null;
    final lowNow = hasBand
        ? _FeedingTrendData._valueAtHour(p25, data.nowHour)
        : 0.0;
    final highNow = hasBand
        ? _FeedingTrendData._valueAtHour(p75, data.nowHour)
        : 0.0;
    final bandLow = math.min(lowNow, highNow);
    final bandHigh = math.max(lowNow, highNow);
    final bandSpan = hasBand ? math.max(30.0, bandHigh - bandLow) : 60.0;
    final domainMin = math.max(
      0.0,
      math.min(data.todayMl, hasBand ? bandLow : data.todayMl) -
          bandSpan * 1.15,
    );
    var domainMax =
        math.max(data.todayMl, hasBand ? bandHigh : data.todayMl) +
        bandSpan * 1.15;
    if (domainMax <= domainMin + 1) domainMax = domainMin + 60;

    double xForMl(double ml) {
      final t = ((ml - domainMin) / (domainMax - domainMin)).clamp(0.0, 1.0);
      return trackRect.left + t * trackRect.width;
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, trackRadius),
      Paint()..color = AppTheme.fieldBorder.withValues(alpha: 0.62),
    );

    if (hasBand) {
      var left = xForMl(bandLow);
      var right = xForMl(bandHigh);
      if (right - left < 36) {
        final center = (left + right) / 2;
        left = (center - 18).clamp(trackRect.left, trackRect.right);
        right = (center + 18).clamp(trackRect.left, trackRect.right);
      }
      final usualRect = Rect.fromLTRB(
        left,
        trackRect.top,
        math.max(left, right),
        trackRect.bottom,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(usualRect, trackRadius),
        Paint()..color = AppTheme.textLight.withValues(alpha: 0.36),
      );
    }

    final markerX = xForMl(data.todayMl);
    final markerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(markerX, trackRect.center.dy),
        width: markerWidth,
        height: markerHeight,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      markerRect.inflate(1.5),
      Paint()..color = AppTheme.cardBackground,
    );
    canvas.drawRRect(markerRect, Paint()..color = AppTheme.palettePrimary);
  }

  @override
  bool shouldRepaint(covariant _FeedingTrendGaugePainter oldDelegate) =>
      oldDelegate.data != data;
}

/// Franja luminosa animada encima de cada ficha (skeleton).
class _ShimmerWrap extends StatelessWidget {
  final Animation<double> animation;
  final BorderRadius borderRadius;
  final Widget child;

  const _ShimmerWrap({
    required this.animation,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  return LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      if (w <= 0) return const SizedBox.shrink();
                      final dx = (animation.value * 2 - 1) * w * 0.95;
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: Container(
                          width: w * 0.42,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.5),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0.32, 0.5, 0.68],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Esqueleto del home: mismas fichas que con datos, con shimmer individual.
class _HomeCardsSkeleton extends StatefulWidget {
  const _HomeCardsSkeleton();

  @override
  State<_HomeCardsSkeleton> createState() => _HomeCardsSkeletonState();
}

class _HomeCardsSkeletonState extends State<_HomeCardsSkeleton>
    with SingleTickerProviderStateMixin {
  static const _bar = Color(0xFFE4E6EA);

  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rr = BorderRadius.circular(AppTheme.homeCardRadius);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _profileCard(rr),
        const SizedBox(height: 20),
        _resumenBlock(rr),
        const SizedBox(height: 12),
        _consejoCard(rr),
        const SizedBox(height: 12),
        _feedingTrendCard(rr),
      ],
    );
  }

  Widget _profileCard(BorderRadius rr) {
    return Material(
      color: AppTheme.cardBackground,
      elevation: AppTheme.cardElevation,
      shadowColor: Colors.black12,
      shape: AppTheme.homeCardShapeRounded,
      child: _ShimmerWrap(
        animation: _shimmer,
        borderRadius: rr,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            children: [
              Container(
                width: _ProfileGradientAvatarRing.outerDiameter,
                height: _ProfileGradientAvatarRing.outerDiameter,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _bar,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 24,
                width: 148,
                decoration: BoxDecoration(
                  color: _bar,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 14,
                width: 118,
                decoration: BoxDecoration(
                  color: _bar,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _statColumn(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: AppTheme.fieldBorder,
                        ),
                      ),
                      _statColumn(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 20,
          width: 64,
          decoration: BoxDecoration(
            color: _bar,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          width: 38,
          decoration: BoxDecoration(
            color: _bar,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _resumenBlock(BorderRadius rr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  color: _bar,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 26,
              width: 88,
              decoration: BoxDecoration(
                color: AppTheme.softPrimaryFill,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: Color.lerp(AppTheme.palettePrimary, Colors.white, 0.62)!,
          elevation: AppTheme.cardElevation,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: rr,
            side: AppTheme.cardOutlineSide,
          ),
          child: _ShimmerWrap(
            animation: _shimmer,
            borderRadius: rr,
            child: const SizedBox(height: 80, width: double.infinity),
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _metricSkeleton(rr)),
              const SizedBox(width: 10),
              Expanded(child: _metricSkeleton(rr)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricSkeleton(BorderRadius rr) {
    return Material(
      color: AppTheme.cardBackground,
      elevation: AppTheme.cardElevation,
      shadowColor: Colors.black12,
      shape: AppTheme.homeCardShapeRounded,
      child: _ShimmerWrap(
        animation: _shimmer,
        borderRadius: rr,
        child: const SizedBox(height: 108, width: double.infinity),
      ),
    );
  }

  Widget _consejoCard(BorderRadius rr) {
    final cardColor = Color.lerp(AppTheme.paletteTertiary, Colors.white, 0.62)!;
    return Material(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: rr,
        side: AppTheme.cardOutlineSide,
      ),
      child: _ShimmerWrap(
        animation: _shimmer,
        borderRadius: rr,
        child: ClipRRect(
          borderRadius: rr,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -8,
                bottom: -6,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20,
                      width: 152,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 15,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 15,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 15,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
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

  Widget _feedingTrendCard(BorderRadius rr) {
    return Material(
      color: AppTheme.cardBackground,
      elevation: AppTheme.cardElevation,
      shadowColor: Colors.black12,
      shape: AppTheme.homeCardShapeRounded,
      child: _ShimmerWrap(
        animation: _shimmer,
        borderRadius: rr,
        child: const SizedBox(height: 184, width: double.infinity),
      ),
    );
  }
}

const int _feedingDistributionDays = 7;
const int _feedingTrendMinHistoryDays = 2;
const double _feedingTrendBreastAsymptoteMl = 140;
const double _feedingTrendBreastSaturationTauMinutes = 9;
const int _feedingTrendHourlyPointCount = 25;

enum _FeedingTrendStatus { learning, below, usual, above }

class _FeedingTrendData {
  final _FeedingTrendStatus status;
  final int historyDayCount;
  final double todayMl;
  final double? remainingMedianMl;
  final double nowHour;
  final List<double> todayByHour;
  final List<double>? p25ByHour;
  final List<double>? medianByHour;
  final List<double>? p75ByHour;

  bool get hasUsualBand =>
      historyDayCount >= _feedingTrendMinHistoryDays &&
      p25ByHour != null &&
      medianByHour != null &&
      p75ByHour != null;

  const _FeedingTrendData({
    required this.status,
    required this.historyDayCount,
    required this.todayMl,
    required this.remainingMedianMl,
    required this.nowHour,
    required this.todayByHour,
    required this.p25ByHour,
    required this.medianByHour,
    required this.p75ByHour,
  });

  factory _FeedingTrendData.fromRecords({
    required List<FeedingRecord> records,
    required DateTime now,
  }) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final nowHour = (now.hour + now.minute / 60 + now.second / 3600).clamp(
      0.0,
      24.0,
    );

    final todayRecords = <FeedingRecord>[];
    final historyByDay = <DateTime, List<FeedingRecord>>{};
    final seenRecordKeys = <String>{};
    for (final record in records) {
      if (!seenRecordKeys.add(_recordKey(record))) continue;
      final ml = _countableMl(record);
      if (ml <= 0) continue;

      final local = record.dateTime;
      if (!local.isBefore(todayStart) &&
          local.isBefore(tomorrowStart) &&
          !local.isAfter(now)) {
        todayRecords.add(record);
        continue;
      }

      if (local.isBefore(todayStart)) {
        final key = DateTime(local.year, local.month, local.day);
        historyByDay.putIfAbsent(key, () => <FeedingRecord>[]).add(record);
      }
    }

    final historyDays = historyByDay.entries
        .map((entry) => _hourlyCumulative(entry.value, entry.key))
        .where((points) => points.last > 0)
        .toList();
    final todayByHour = _hourlyCumulative(todayRecords, todayStart);
    final todayMl = todayRecords.fold<double>(
      0,
      (sum, record) => sum + _countableMl(record),
    );

    List<double>? p25;
    List<double>? median;
    List<double>? p75;
    if (historyDays.isNotEmpty) {
      p25 = _percentilesByHour(historyDays, 0.25);
      median = _percentilesByHour(historyDays, 0.5);
      p75 = _percentilesByHour(historyDays, 0.75);
    }

    final remainingMedianMl = median == null
        ? null
        : math.max(0.0, median.last - todayMl);

    var status = _FeedingTrendStatus.learning;
    if (historyDays.length >= _feedingTrendMinHistoryDays &&
        p25 != null &&
        p75 != null) {
      final lowNow = _valueAtHour(p25, nowHour);
      final highNow = _valueAtHour(p75, nowHour);
      status = todayMl < lowNow
          ? _FeedingTrendStatus.below
          : todayMl > highNow
          ? _FeedingTrendStatus.above
          : _FeedingTrendStatus.usual;
    }

    return _FeedingTrendData(
      status: status,
      historyDayCount: historyDays.length,
      todayMl: todayMl,
      remainingMedianMl: remainingMedianMl,
      nowHour: nowHour,
      todayByHour: todayByHour,
      p25ByHour: p25,
      medianByHour: median,
      p75ByHour: p75,
    );
  }

  static double _countableMl(
    FeedingRecord record, {
    bool includeSolids = false,
  }) {
    switch (record.type) {
      case FeedingType.bottle:
        return (record.amountMl ?? 0).toDouble();
      case FeedingType.leftBreast:
      case FeedingType.rightBreast:
        final minutes = (record.durationSeconds ?? 0) / 60.0;
        return _breastMinutesToMl(minutes);
      case FeedingType.solidFood:
        return includeSolids ? math.max(0.0, record.solidQuantity ?? 0.0) : 0;
    }
  }

  static double _breastMinutesToMl(double minutes) {
    if (minutes <= 0) return 0;
    return _feedingTrendBreastAsymptoteMl *
        (1 - math.exp(-minutes / _feedingTrendBreastSaturationTauMinutes));
  }

  static String _recordKey(FeedingRecord record) {
    final id = record.id;
    if (id != null) return 'id:$id';
    return [
      record.type.index,
      record.dateTime.microsecondsSinceEpoch,
      record.durationSeconds,
      record.amountMl,
      record.solidName,
      record.solidQuantity,
      record.solidUnit?.index,
    ].join('|');
  }

  static List<double> _hourlyCumulative(
    List<FeedingRecord> records,
    DateTime dayStart,
  ) {
    final sorted = List<FeedingRecord>.from(records)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final points = List<double>.filled(_feedingTrendHourlyPointCount, 0);
    var total = 0.0;
    var recordIndex = 0;

    for (var hour = 0; hour < _feedingTrendHourlyPointCount; hour++) {
      final cutoff = dayStart.add(Duration(hours: hour));
      while (recordIndex < sorted.length &&
          !sorted[recordIndex].dateTime.isAfter(cutoff)) {
        total += _countableMl(sorted[recordIndex]);
        recordIndex++;
      }
      points[hour] = total;
    }
    return points;
  }

  static List<double> _percentilesByHour(
    List<List<double>> days,
    double percentile,
  ) {
    return List<double>.generate(_feedingTrendHourlyPointCount, (hour) {
      final values = days.map((day) => day[hour]).toList()..sort();
      return _percentile(values, percentile);
    });
  }

  static double _percentile(List<double> sortedValues, double percentile) {
    if (sortedValues.isEmpty) return 0;
    if (sortedValues.length == 1) return sortedValues.first;
    final position = (sortedValues.length - 1) * percentile;
    final lower = position.floor();
    final upper = position.ceil();
    if (lower == upper) return sortedValues[lower];
    final t = position - lower;
    return sortedValues[lower] +
        (sortedValues[upper] - sortedValues[lower]) * t;
  }

  static double _valueAtHour(List<double> values, double hour) {
    final clampedHour = hour.clamp(0.0, 24.0);
    final lower = clampedHour.floor();
    final upper = clampedHour.ceil();
    if (lower == upper || upper >= values.length) return values[lower];
    final t = clampedHour - lower;
    return values[lower] + (values[upper] - values[lower]) * t;
  }
}

class _FeedingDistributionData {
  final double leftBreastMl;
  final double rightBreastMl;
  final double breastMl;
  final double bottleMl;
  final double solidMl;
  final bool everHadLeftBreast;
  final bool everHadRightBreast;
  final bool everHadBottle;
  final bool everHadSolid;

  double get totalMl => breastMl + bottleMl + solidMl;
  double get averageDailyMl => totalMl / _feedingDistributionDays;
  bool get everHadBreast => everHadLeftBreast || everHadRightBreast;

  const _FeedingDistributionData({
    required this.leftBreastMl,
    required this.rightBreastMl,
    required this.breastMl,
    required this.bottleMl,
    required this.solidMl,
    required this.everHadLeftBreast,
    required this.everHadRightBreast,
    required this.everHadBottle,
    required this.everHadSolid,
  });

  factory _FeedingDistributionData.fromRecords({
    required List<FeedingRecord> records,
    required DateTime now,
  }) {
    final start = now.subtract(const Duration(days: _feedingDistributionDays));
    final seenRecordKeys = <String>{};

    var leftBreastMl = 0.0;
    var rightBreastMl = 0.0;
    var bottleMl = 0.0;
    var solidMl = 0.0;
    var everHadLeftBreast = false;
    var everHadRightBreast = false;
    var everHadBottle = false;
    var everHadSolid = false;

    for (final record in records) {
      if (!seenRecordKeys.add(_FeedingTrendData._recordKey(record))) continue;

      switch (record.type) {
        case FeedingType.leftBreast:
          everHadLeftBreast = true;
          break;
        case FeedingType.rightBreast:
          everHadRightBreast = true;
          break;
        case FeedingType.bottle:
          everHadBottle = true;
          break;
        case FeedingType.solidFood:
          everHadSolid = true;
          break;
      }

      final local = record.dateTime;
      if (local.isBefore(start) || local.isAfter(now)) {
        continue;
      }

      final ml = _FeedingTrendData._countableMl(record, includeSolids: true);
      if (ml <= 0) continue;

      switch (record.type) {
        case FeedingType.leftBreast:
          leftBreastMl += ml;
          break;
        case FeedingType.rightBreast:
          rightBreastMl += ml;
          break;
        case FeedingType.bottle:
          bottleMl += ml;
          break;
        case FeedingType.solidFood:
          solidMl += ml;
          break;
      }
    }

    final breastMl = leftBreastMl + rightBreastMl;
    return _FeedingDistributionData(
      leftBreastMl: leftBreastMl,
      rightBreastMl: rightBreastMl,
      breastMl: breastMl,
      bottleMl: bottleMl,
      solidMl: solidMl,
      everHadLeftBreast: everHadLeftBreast,
      everHadRightBreast: everHadRightBreast,
      everHadBottle: everHadBottle,
      everHadSolid: everHadSolid,
    );
  }
}

class _WeightData {
  final double? currentKg;
  final DateTime? lastRecordedAt;

  _WeightData({this.currentKg, this.lastRecordedAt});
}

class _FeedingData {
  final String? lastFeedingDetail;
  final int? lastBottleMl;
  final DateTime? lastFeedingAt;
  final int expectedFeedingIntervalMinutes;

  _FeedingData({
    this.lastFeedingDetail,
    this.lastBottleMl,
    this.lastFeedingAt,
    this.expectedFeedingIntervalMinutes = kDefaultFeedingIntervalMinutes,
  });
}

/// Volumen de datos ya registrados, para que el listado premium diga sobre qué
/// se calcularía cada análisis («Basado en 34 noches registradas»).
class _PremiumTeaserCounts {
  final int nights;
  final int feedingDays;
  final int weights;
  final int heights;

  const _PremiumTeaserCounts({
    required this.nights,
    required this.feedingDays,
    required this.weights,
    required this.heights,
  });
}

class _DiapersData {
  final int wetCount;
  final int dirtyCount;
  final int totalToday;
  final DateTime? lastRecordedAt;

  _DiapersData({
    required this.wetCount,
    required this.dirtyCount,
    required this.totalToday,
    this.lastRecordedAt,
  });
}
