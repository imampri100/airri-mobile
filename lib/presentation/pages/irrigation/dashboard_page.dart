import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:airri_mobile/application/irrigation/dashboard_cubit.dart';
import 'package:airri_mobile/domain/irrigation/entities.dart';
import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

import 'widgets/irrigation_buttons.dart';
import 'widgets/irrigation_card.dart';
import 'widgets/sensor_row.dart';
import 'widgets/stat_tile.dart';
import 'widgets/status_banner.dart';

String _fieldLabel(SensorField f) => switch (f) {
      SensorField.soilMoisture => 'condition.soil_moisture_label'.tr(),
      SensorField.airHumidity => 'condition.humidity_label'.tr(),
      SensorField.airTemperature => 'condition.temperature_label'.tr(),
      SensorField.lightIntensity => 'condition.light_label'.tr(),
    };

// Satuan menempel langsung ke angka (26%, 25°C), kecuali lux yang
// memakai spasi (10 lx) - mengikuti pola yang sudah ada di SensorRow &
// prototype HTML.
String _fieldUnitSuffix(SensorField f) => switch (f) {
      SensorField.soilMoisture => '%',
      SensorField.airHumidity => '%',
      SensorField.airTemperature => '°C',
      SensorField.lightIntensity => ' lx',
    };

String _formatCondition(ConditionEval c) {
  final unit = _fieldUnitSuffix(c.field);
  final value = c.sensorValue.toStringAsFixed(0);
  final threshold = c.thresholdValue.toStringAsFixed(0);
  return '${_fieldLabel(c.field)} $value$unit ${c.operatorSymbol} $threshold$unit';
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().refresh();
  }

  Future<void> _testPump() async {
    final error = await context.read<DashboardCubit>().testPump();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'snackbar.test_pump_done'.tr()),
        backgroundColor:
            error == null ? IrrigationColors.green600 : IrrigationColors.red600,
      ),
    );
  }

  String _lastSyncLabel(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('d MMM yyyy HH:mm', context.locale.toString()).format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().refresh(),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final status = state.status;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 12, color: IrrigationColors.ink500),
                    children: [
                      TextSpan(text: '${'dashboard.last_sync'.tr()}  '),
                      TextSpan(
                        text: _lastSyncLabel(state.lastSyncedAt),
                        style: const TextStyle(
                            color: IrrigationColors.ink900,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              if (state.phase == DashboardPhase.syncing)
                StatusBanner(
                  tint: CardTint.blue,
                  iconColor: IrrigationColors.blue600,
                  icon: '↻',
                  title: 'dashboard.syncing_title'.tr(),
                  subtitle: 'dashboard.syncing_subtitle'.tr(),
                  progress: 0.65,
                ),

              if (state.phase == DashboardPhase.offline)
                StatusBanner(
                  tint: CardTint.red,
                  iconColor: IrrigationColors.red600,
                  icon: '✕',
                  title: 'dashboard.offline_title'.tr(),
                  subtitle: state.errorMessage ?? 'dashboard.offline_subtitle'.tr(),
                  trailing: TextButton(
                    onPressed: () => context.read<DashboardCubit>().refresh(),
                    child: Text('common.retry'.tr(),
                        style: const TextStyle(
                            color: IrrigationColors.red600,
                            fontWeight: FontWeight.w700)),
                  ),
                ),

              if (state.phase == DashboardPhase.loading && status == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),

              if (status != null) ...[
                if (!status.timeSynchronized)
                  StatusBanner(
                    tint: CardTint.amber,
                    iconColor: IrrigationColors.amber600,
                    icon: '⏱',
                    title: 'dashboard.time_not_synced_title'.tr(),
                    subtitle: 'dashboard.time_not_synced_subtitle'.tr(),
                  ),

                IrrigationCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardTitle('dashboard.today_summary'.tr()),
                      Row(
                        children: [
                          StatTile(
                            iconColor: IrrigationColors.blue600,
                            emoji: '💧',
                            label: 'dashboard.stat_irrigation'.tr(),
                            value: '${state.todayIrrigationCount}',
                            unit: '×',
                          ),
                          const SizedBox(width: 8),
                          StatTile(
                            iconColor: const Color(0xFF2E86DE),
                            emoji: '🪣',
                            label: 'dashboard.stat_water'.tr(),
                            value: NumberFormat('#,##0').format(state.todayWaterMl),
                            unit: 'ml',
                          ),
                          const SizedBox(width: 8),
                          StatTile(
                            iconColor: const Color(0xFF8B6A45),
                            emoji: '🌱',
                            label: 'dashboard.stat_soil'.tr(),
                            value: status.sensor.soilMoisture.toStringAsFixed(0),
                            unit: '%',
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
                      CardTitle('dashboard.sensor_status'.tr()),
                      SensorRow(
                        kind: SensorKind.moisture,
                        label: 'sensor.soil_moisture'.tr(),
                        value: '${status.sensor.soilMoisture.toStringAsFixed(0)} %',
                        showDivider: false,
                      ),
                      SensorRow(
                        kind: SensorKind.humidity,
                        label: 'sensor.air_humidity'.tr(),
                        value: '${status.sensor.airHumidity.toStringAsFixed(0)} %',
                      ),
                      SensorRow(
                        kind: SensorKind.temperature,
                        label: 'sensor.temperature'.tr(),
                        value: '${status.sensor.airTemperature.toStringAsFixed(0)} °C',
                      ),
                      SensorRow(
                        kind: SensorKind.light,
                        label: 'sensor.light_intensity'.tr(),
                        value:
                            '${NumberFormat('#,##0').format(status.sensor.lightIntensity)} lx',
                      ),
                    ],
                  ),
                ),
                IrrigationCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CardTitle('dashboard.pump_status'.tr()),
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: IrrigationColors.green100,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text('💧', style: TextStyle(fontSize: 13)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.pumpRunning
                                      ? 'dashboard.pump_running'.tr()
                                      : 'dashboard.pump_ready'.tr(),
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  status.pumpRunning
                                      ? 'dashboard.pump_running_subtitle'.tr()
                                      : status.decision.reason,
                                  style: const TextStyle(
                                      fontSize: 11.5, color: IrrigationColors.ink500),
                                ),
                              ],
                            ),
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
                      CardTitle('dashboard.condition_eval'.tr()),
                      _EvalBlock(
                        label: 'dashboard.trigger_label'.tr(),
                        ok: status.isTriggerMet,
                        okText: 'dashboard.trigger_met'.tr(),
                        badText: 'dashboard.trigger_not_met'.tr(),
                        description: _formatCondition(status.triggerCondition),
                      ),
                      const SizedBox(height: 10),
                      _EvalBlock(
                        label: 'dashboard.restriction_label'.tr(),
                        // untuk restriction, "active" berarti sedang membatasi (bad)
                        ok: !status.isRestricted,
                        okText: 'dashboard.no_restriction'.tr(),
                        badText: 'dashboard.restricted'.tr(),
                        description: status.isRestricted
                            ? status.activeRestrictions.map(_formatCondition).join(' · ')
                            : 'condition.no_restriction_active'.tr(),
                      ),
                      const Divider(height: 22, color: IrrigationColors.line100),
                      _EvalBlock(
                        label: 'dashboard.decision_label'.tr(),
                        ok: status.decision.shouldRunPump,
                        okText: 'dashboard.pump_will_run'.tr(),
                        badText: 'dashboard.pump_not_running'.tr(),
                        description: status.decision.reason,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryPillButton(
                        label: 'dashboard.synchronize'.tr(),
                        onTap: () => context.read<DashboardCubit>().refresh(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinePillButton(
                        label: 'dashboard.test_pump'.tr(),
                        onTap: state.isBusy ? null : _testPump,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EvalBlock extends StatelessWidget {
  final String label;
  final bool ok;
  final String okText;
  final String badText;
  final String description;

  const _EvalBlock({
    required this.label,
    required this.ok,
    required this.okText,
    required this.badText,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: IrrigationColors.ink500,
              letterSpacing: 0.4),
        ),
        const SizedBox(height: 6),
        Text(
          ok ? okText : badText,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ok ? IrrigationColors.green600 : IrrigationColors.red600,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 22, top: 2),
          child: Text(description,
              style:
                  const TextStyle(fontSize: 11.5, color: IrrigationColors.ink500)),
        ),
      ],
    );
  }
}
