import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format_duration.dart';
import '../../../core/db/isar_service.dart';
import '../../../core/models/baby_profile.dart';
import '../../../core/models/diaper_record.dart';
import '../../../core/models/feeding_record.dart';
import '../../../core/models/weight_record.dart';
import '../../settings/views/settings_page.dart';
import '../../../core/models/enums.dart';
import '../../../core/percentiles_data.dart';
import '../../../core/services/sabias_que_service.dart';
class HomeView extends ConsumerStatefulWidget {
  final void Function(int index)? onNavigateToTab;
  final VoidCallback? onTitleTap;

  const HomeView({super.key, this.onNavigateToTab, this.onTitleTap});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  List<String> _cardOrder = ['weight', 'feeding', 'diapers'];
  BabyProfile? _cachedBaby;
  final _sabiasQueService = SabiasQueServiceDefault();

  @override
  void initState() {
    super.initState();
    _loadCardOrder();
  }

  Future<void> _loadCardOrder() async {
    final order = await IsarService.getHomeCardOrder();
    if (mounted) setState(() => _cardOrder = order);
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final newOrder = List<String>.from(_cardOrder);
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);
    setState(() => _cardOrder = newOrder);
    await IsarService.setHomeCardOrder(newOrder);
  }

  void _navigateTo(String screen) {
    if (widget.onNavigateToTab != null) {
      switch (screen) {
        case 'weight':
          widget.onNavigateToTab!(3);
          break;
        case 'feeding':
          widget.onNavigateToTab!(2);
          break;
        case 'diapers':
          widget.onNavigateToTab!(1);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: InkWell(
          onTap: widget.onTitleTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AppTheme.titleIconAsset, width: 22, height: 22, fit: BoxFit.contain),
                const SizedBox(width: 6),
                Flexible(child: Text('MiBebé Diario', overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadHomeData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _BabyProfileCard(
                  baby: data['baby'] as BabyProfile?,
                  sabiasQueText: data['sabiasQue'] as String?,
                  onSettingsTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsPage(
                          initialBaby: data['baby'] as BabyProfile?,
                          onProfileSaved: (profile) {
                            if (mounted) setState(() => _cachedBaby = profile);
                          },
                        ),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  children: [
                    ReorderableListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 56),
                  onReorder: _onReorder,
                      proxyDecorator: (child, index, animation) => Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        child: child,
                      ),
                      children: _cardOrder.asMap().entries.map((entry) {
                        final index = entry.key;
                        final id = entry.value;
                        final key = ValueKey(id);
                        switch (id) {
                          case 'weight':
                            return _WeightCard(
                              key: key,
                              index: index,
                              data: data['weight'] as _WeightData,
                              onTap: () => _navigateTo('weight'),
                            );
                          case 'feeding':
                            return _FeedingCard(
                              key: key,
                              index: index,
                              data: data['feeding'] as _FeedingData,
                              onTap: () => _navigateTo('feeding'),
                            );
                          case 'diapers':
                            return _DiapersCard(
                              key: key,
                              index: index,
                              data: data['diapers'] as _DiapersData,
                              onTap: () => _navigateTo('diapers'),
                            );
                          default:
                            return const SizedBox(key: ValueKey('unknown'));
                        }
                      }).toList(),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 48,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.background.withValues(alpha: 0),
                                AppTheme.background,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadHomeData() async {
    final cachedBaby = _cachedBaby;
    _cachedBaby = null;
    final results = await Future.wait([
      cachedBaby != null ? Future.value(cachedBaby) : IsarService.getBabyProfile(),
      IsarService.getWeightRecords(),
      IsarService.getFeedingRecordsToday(),
      IsarService.getLastFeedingRecord(),
      IsarService.getDiaperRecordsToday(),
      IsarService.getDiaperRecordsLast7Days(),
      IsarService.getLastDiaperRecord(),
      _sabiasQueService.getFact(),
    ]);
    final baby = results[0] as BabyProfile?;
    final weightRecords = results[1] as List<WeightRecord>;
    final feedingToday = results[2] as List<FeedingRecord>;
    final lastFeeding = results[3] as FeedingRecord?;
    final diapersToday = results[4] as List<DiaperRecord>;
    final diapersLast7 = results[5] as List<DiaperRecord>;
    final lastDiaper = results[6] as DiaperRecord?;
    final sabiasQue = results[7] as String?;

    final lastWeight = weightRecords.isNotEmpty ? weightRecords.first : null;
    final prevWeight = weightRecords.length > 1 ? weightRecords[1] : null;
    final changeKg = lastWeight != null && prevWeight != null
        ? lastWeight.weightKg - prevWeight.weightKg
        : null;

    var breastMinutes = 0;
    var breastCount = 0;
    var bottleMl = 0;
    var bottleCount = 0;
    for (final f in feedingToday) {
      switch (f.type) {
        case FeedingType.leftBreast:
        case FeedingType.rightBreast:
          breastCount++;
          breastMinutes += f.durationSeconds ?? 0;
          break;
        case FeedingType.bottle:
          bottleCount++;
          bottleMl += f.amountMl ?? 0;
          break;
      }
    }

    int? lastFeedingMinutesAgo;
    String? lastFeedingType;
    if (lastFeeding != null) {
      lastFeedingMinutesAgo = DateTime.now().difference(lastFeeding.dateTime).inMinutes;
      lastFeedingType = switch (lastFeeding.type) {
        FeedingType.leftBreast => 'Teta Izquierda',
        FeedingType.rightBreast => 'Teta Derecha',
        FeedingType.bottle => 'Biberón',
      };
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

    final totalToday = wetCount + dirtyCount;
    final avg7Days = diapersLast7.isNotEmpty ? diapersLast7.length / 7 : 0.0;

    int? lastDiaperMinutesAgo;
    String? lastDiaperType;
    if (lastDiaper != null) {
      lastDiaperMinutesAgo = DateTime.now().difference(lastDiaper.dateTime).inMinutes;
      lastDiaperType = switch (lastDiaper.type) {
        DiaperType.wet => 'Solo Mojado',
        DiaperType.dirty => 'Solo Sucio',
        DiaperType.both => 'Ambos',
      };
    }

    double? diffFromP50;
    if (lastWeight != null && baby != null) {
      final ageMonths = lastWeight.dateTime.difference(baby.birthDate).inDays / 30.44;
      final p50 = PercentilesData.getP50Weight(baby.isMale, ageMonths);
      diffFromP50 = lastWeight.weightKg - p50;
    }

    return {
      'baby': baby,
      'sabiasQue': sabiasQue,
      'weight': _WeightData(
        currentKg: lastWeight?.weightKg,
        changeKg: changeKg,
        weighedDate: lastWeight?.dateTime,
        diffFromP50Kg: diffFromP50,
      ),
      'feeding': _FeedingData(
        breastMinutes: breastMinutes ~/ 60,
        breastCount: breastCount,
        bottleMl: bottleMl,
        bottleCount: bottleCount,
        lastFeedingMinutesAgo: lastFeedingMinutesAgo,
        lastFeedingType: lastFeedingType,
      ),
      'diapers': _DiapersData(
        wetCount: wetCount,
        dirtyCount: dirtyCount,
        totalToday: totalToday,
        avg7Days: avg7Days,
        lastChangeMinutesAgo: lastDiaperMinutesAgo,
        lastChangeType: lastDiaperType,
      ),
    };
  }
}

/// Ficha fija con datos del bebé y "Sabías que...". No es reordenable.
class _BabyProfileCard extends StatelessWidget {
  final BabyProfile? baby;
  final String? sabiasQueText;
  final VoidCallback? onSettingsTap;

  const _BabyProfileCard({
    this.baby,
    this.sabiasQueText,
    this.onSettingsTap,
  });

  String _formatAge(DateTime birthDate) {
    final totalDays = DateTime.now().difference(birthDate).inDays;
    if (totalDays < 30) {
      return '$totalDays día${totalDays != 1 ? 's' : ''}';
    }
    final months = totalDays ~/ 30;
    final days = totalDays % 30;
    return '$months mes${months != 1 ? 'es' : ''} y $days día${days != 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final isMale = baby?.isMale ?? true;
    final accentColor = isMale ? AppTheme.primaryBlue : AppTheme.primaryPink;
    final name = baby?.name ?? 'Bebé';
    final age = baby != null ? _formatAge(baby!.birthDate) : null;
    final fact = sabiasQueText ?? 'Los bebés pueden reconocer la voz de su madre desde el útero.';

    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.fieldBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.fieldBorder, width: 1.5),
                  ),
                  child: Icon(
                    isMale ? Icons.face : Icons.face_3,
                    color: AppTheme.textLight,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isMale ? Icons.male : Icons.female,
                            size: 20,
                            color: accentColor,
                          ),
                        ],
                      ),
                      if (age != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: AppTheme.textLight),
                            const SizedBox(width: 6),
                            Text(
                              age,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textLight,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (onSettingsTap != null)
                  IconButton(
                    onPressed: onSettingsTap,
                    icon: Icon(Icons.settings_outlined, color: AppTheme.textLight),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                    ),
                  ),
              ],
            ),
            if (sabiasQueText != null || fact.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: AppTheme.textDark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SABÍAS QUE...',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                  letterSpacing: 0.5,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fact,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textDark,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WeightData {
  final double? currentKg;
  final double? changeKg;
  final DateTime? weighedDate;
  final double? diffFromP50Kg;

  _WeightData({this.currentKg, this.changeKg, this.weighedDate, this.diffFromP50Kg});
}

class _FeedingData {
  final int breastMinutes;
  final int breastCount;
  final int bottleMl;
  final int bottleCount;
  final int? lastFeedingMinutesAgo;
  final String? lastFeedingType;

  _FeedingData({
    required this.breastMinutes,
    required this.breastCount,
    required this.bottleMl,
    required this.bottleCount,
    this.lastFeedingMinutesAgo,
    this.lastFeedingType,
  });
}

class _DiapersData {
  final int wetCount;
  final int dirtyCount;
  final int totalToday;
  final double avg7Days;
  final int? lastChangeMinutesAgo;
  final String? lastChangeType;

  _DiapersData({
    required this.wetCount,
    required this.dirtyCount,
    required this.totalToday,
    required this.avg7Days,
    this.lastChangeMinutesAgo,
    this.lastChangeType,
  });
}

class _WeightCard extends StatelessWidget {
  final int index;
  final _WeightData data;
  final VoidCallback onTap;

  const _WeightCard({super.key, required this.index, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      key: key,
      cardKey: key,
      index: index,
      icon: Icons.monitor_weight,
      iconColor: AppTheme.primaryGreen,
      title: 'Evolución Peso',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peso Actual',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.currentKg != null
                            ? '${data.currentKg!.toStringAsFixed(3)} kg'
                            : 'Sin datos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                      ),
                    ],
                  ),
                ),
                if (data.changeKg != null) ...[
                  Icon(
                    data.changeKg! >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 20,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${data.changeKg! >= 0 ? '+' : ''}${data.changeKg!.toStringAsFixed(3)} kg',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (data.diffFromP50Kg != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: data.diffFromP50Kg! >= 0
                    ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    data.diffFromP50Kg! >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 18,
                    color: data.diffFromP50Kg! >= 0 ? AppTheme.primaryGreen : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data.diffFromP50Kg! >= 0
                        ? '${data.diffFromP50Kg!.toStringAsFixed(2)} kg por encima del percentil'
                        : '${(-data.diffFromP50Kg!).toStringAsFixed(2)} kg por debajo del percentil',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: data.diffFromP50Kg! >= 0 ? AppTheme.primaryGreen : Colors.orange,
                        ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 18, color: AppTheme.textLight),
                const SizedBox(width: 8),
                Text(
                  data.weighedDate != null
                      ? 'Pesado el: ${DateFormat('d \'de\' MMMM', 'es').format(data.weighedDate!)}'
                      : 'Sin datos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textLight,
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

class _FeedingCard extends StatelessWidget {
  final int index;
  final _FeedingData data;
  final VoidCallback onTap;

  const _FeedingCard({super.key, required this.index, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasData = data.breastCount > 0 || data.bottleCount > 0;
    return _HomeCard(
      key: key,
      cardKey: key,
      index: index,
      icon: Icons.local_drink,
      iconColor: AppTheme.primaryPink,
      title: 'Alimentación Hoy',
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pecho (${data.breastCount} toma${data.breastCount != 1 ? 's' : ''})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                      Text(
                        formatMinutes(data.breastMinutes),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryPink,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biberón (${data.bottleCount} toma${data.bottleCount != 1 ? 's' : ''})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                      Text(
                        '${data.bottleMl} ml',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (data.lastFeedingMinutesAgo != null && data.lastFeedingType != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: AppTheme.textLight),
                  const SizedBox(width: 8),
                  Text(
                    'Última toma: ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textLight,
                        ),
                  ),
                  Text(
                    'Hace ${formatMinutes(data.lastFeedingMinutesAgo!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                  ),
                  Text(
                    ' (${data.lastFeedingType})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textLight,
                        ),
                  ),
                ],
              ),
            ),
          ] else if (!hasData) ...[
            const SizedBox(height: 12),
            Text(
              'Sin registros hoy',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textLight,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiapersCard extends StatelessWidget {
  final int index;
  final _DiapersData data;
  final VoidCallback onTap;

  const _DiapersCard({super.key, required this.index, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      key: key,
      cardKey: key,
      index: index,
      icon: Icons.water_drop,
      iconColor: AppTheme.primaryBlue,
      title: 'Pañales Hoy',
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mojados',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                      Text(
                        '${data.wetCount}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sucios',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                      Text(
                        '${data.dirtyCount}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total hoy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                      Text(
                        '${data.totalToday}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Media 7 días',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                      Text(
                        data.avg7Days.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (data.lastChangeMinutesAgo != null && data.lastChangeType != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: AppTheme.textLight),
                  const SizedBox(width: 8),
                  Text(
                    'Último cambio: ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textLight,
                        ),
                  ),
                  Text(
                    'Hace ${formatMinutes(data.lastChangeMinutesAgo!)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                  ),
                  Text(
                    ' (${data.lastChangeType})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textLight,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final Key? cardKey;
  final int index;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final VoidCallback onTap;

  const _HomeCard({
    super.key,
    required this.cardKey,
    required this.index,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: cardKey,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20, right: 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: iconColor, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      child,
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Center(
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Icon(Icons.drag_handle, color: AppTheme.textLight, size: 24),
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
