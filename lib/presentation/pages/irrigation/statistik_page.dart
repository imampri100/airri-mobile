import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:airri_mobile/application/irrigation/statistik_cubit.dart';
import 'package:airri_mobile/domain/irrigation/entities.dart';
import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

import 'widgets/irrigation_card.dart';
import 'widgets/stat_tile.dart';
import 'widgets/statistik_charts.dart';

class StatistikPage extends StatefulWidget {
  const StatistikPage({super.key});

  @override
  State<StatistikPage> createState() => _StatistikPageState();
}

class _StatistikPageState extends State<StatistikPage> {
  @override
  void initState() {
    super.initState();
    context.read<StatistikCubit>().load();
  }

  String _summaryTitle(StatistikPeriod period) => switch (period) {
        StatistikPeriod.sevenDays => 'statistik.summary_7d'.tr(),
        StatistikPeriod.thirtyDays => 'statistik.summary_30d'.tr(),
        StatistikPeriod.oneYear => 'statistik.summary_1y'.tr(),
        StatistikPeriod.threeYears => 'statistik.summary_3y'.tr(),
        StatistikPeriod.all => 'statistik.summary_all'.tr(),
      };

  // duplikat dari StatistikCubit._granularityFor, dipake UI buat milih
  // label unit judul chart & format sumbu-x. inget update dua-duanya
  // kalau mapping periode->granularitas berubah
  StatsGranularity _granularityFor(StatistikPeriod period) => switch (period) {
        StatistikPeriod.sevenDays || StatistikPeriod.thirtyDays =>
          StatsGranularity.day,
        StatistikPeriod.oneYear => StatsGranularity.week,
        StatistikPeriod.threeYears || StatistikPeriod.all =>
          StatsGranularity.month,
      };

  String _unitLabel(StatsGranularity granularity) => switch (granularity) {
        StatsGranularity.day => 'statistik.unit_day'.tr(),
        StatsGranularity.week => 'statistik.unit_week'.tr(),
        StatsGranularity.month => 'statistik.unit_month'.tr(),
      };

  @override
  Widget build(BuildContext context) {
    final localeName = context.locale.toString();
    return RefreshIndicator(
      onRefresh: () =>
          context.read<StatistikCubit>().load(forceReload: true),
      child: BlocBuilder<StatistikCubit, StatistikState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PeriodPill(
                      label: 'statistik.period_7d'.tr(),
                      selected: state.period == StatistikPeriod.sevenDays,
                      onTap: () => context
                          .read<StatistikCubit>()
                          .selectPeriod(StatistikPeriod.sevenDays),
                    ),
                    const SizedBox(width: 8),
                    _PeriodPill(
                      label: 'statistik.period_30d'.tr(),
                      selected: state.period == StatistikPeriod.thirtyDays,
                      onTap: () => context
                          .read<StatistikCubit>()
                          .selectPeriod(StatistikPeriod.thirtyDays),
                    ),
                    const SizedBox(width: 8),
                    _PeriodPill(
                      label: 'statistik.period_1y'.tr(),
                      selected: state.period == StatistikPeriod.oneYear,
                      onTap: () => context
                          .read<StatistikCubit>()
                          .selectPeriod(StatistikPeriod.oneYear),
                    ),
                    const SizedBox(width: 8),
                    _PeriodPill(
                      label: 'statistik.period_3y'.tr(),
                      selected: state.period == StatistikPeriod.threeYears,
                      onTap: () => context
                          .read<StatistikCubit>()
                          .selectPeriod(StatistikPeriod.threeYears),
                    ),
                    const SizedBox(width: 8),
                    _PeriodPill(
                      label: 'statistik.period_all'.tr(),
                      selected: state.period == StatistikPeriod.all,
                      onTap: () => context
                          .read<StatistikCubit>()
                          .selectPeriod(StatistikPeriod.all),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (state.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                IrrigationCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardTitle(_summaryTitle(state.period)),
                      Row(
                        children: [
                          StatTile(
                            iconColor: const Color(0xFF8B6A45),
                            emoji: '🌱',
                            label: 'statistik.stat_soil_avg'.tr(),
                            value: state.summary.avgSoilMoisture.toStringAsFixed(1),
                            unit: '%',
                          ),
                          const SizedBox(width: 8),
                          StatTile(
                            iconColor: const Color(0xFF2E86DE),
                            emoji: '🪣',
                            label: 'statistik.stat_water'.tr(),
                            value: NumberFormat('#,##0')
                                .format(state.summary.totalWaterMl),
                            unit: 'ml',
                          ),
                          const SizedBox(width: 8),
                          StatTile(
                            iconColor: IrrigationColors.blue600,
                            emoji: '💧',
                            label: 'statistik.stat_cycles'.tr(),
                            value: '${state.summary.irrigationCount}',
                            unit: '×',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IrrigationCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardTitle('statistik.chart_soil_trend'.tr(namedArgs: {
                        'unit': _unitLabel(_granularityFor(state.period)),
                      })),
                      SoilMoistureLineChart(
                        data: state.dailyStats,
                        localeName: localeName,
                        granularity: _granularityFor(state.period),
                        emptyMessage: 'statistik.no_data'.tr(),
                      ),
                    ],
                  ),
                ),
                IrrigationCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardTitle('statistik.chart_water_usage'.tr(namedArgs: {
                        'unit': _unitLabel(_granularityFor(state.period)),
                      })),
                      WaterUsageBarChart(
                        data: state.dailyStats,
                        localeName: localeName,
                        granularity: _granularityFor(state.period),
                        emptyMessage: 'statistik.no_data'.tr(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? IrrigationColors.green600 : IrrigationColors.surface,
          border: Border.all(
              color:
                  selected ? IrrigationColors.green600 : IrrigationColors.line200),
          borderRadius: BorderRadius.circular(IrrigationColors.radiusSm),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : IrrigationColors.ink700,
          ),
        ),
      ),
    );
  }
}
