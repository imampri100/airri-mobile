import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:airri_mobile/application/irrigation/history_cubit.dart';
import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

import 'widgets/irrigation_card.dart';
import 'widgets/status_banner.dart';

sealed class _Row {}

class _DateHeaderRow extends _Row {
  final String label;
  _DateHeaderRow(this.label);
}

class _ItemRow extends _Row {
  final HistoryItem item;
  _ItemRow(this.item);
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryCubit>().refresh();
  }

  Future<void> _pickDate(DateTime? current) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked != null && mounted) {
      context.read<HistoryCubit>().selectDate(picked);
    }
  }

  // Buat daftar row (header tanggal + item) sebagai data ringan dulu,
  // widget-nya baru dibuat lazy lewat ListView.builder di build().
  // Supaya tetap ringan walau datanya ribuan baris.
  List<_Row> _buildRowModels(List<HistoryItem> items) {
    final rows = <_Row>[];
    String? lastDateLabel;

    for (final item in items) {
      final dateLabel = item.timestamp == null
          ? ''
          : DateFormat('d MMM yyyy', context.locale.toString())
              .format(item.timestamp!);

      if (dateLabel.isNotEmpty && dateLabel != lastDateLabel) {
        rows.add(_DateHeaderRow(dateLabel));
        lastDateLabel = dateLabel;
      }
      rows.add(_ItemRow(item));
    }

    return rows;
  }

  ({String title, String subtitle}) _describe(HistoryItem item) {
    switch (item.type) {
      case HistoryItemType.irrigation:
        final volume = item.milliliter ?? 0;
        return (
          title: 'history.irrigation_started'.tr(),
          subtitle: volume > 0
              ? 'history.duration_volume'.tr(namedArgs: {
                  'duration': '${item.durationSecond}',
                  'volume': volume.toStringAsFixed(0),
                })
              : 'history.duration_only'
                  .tr(namedArgs: {'duration': '${item.durationSecond}'}),
        );
      case HistoryItemType.sensor:
        final r = item.reading!;
        return (
          title: item.isIrrigationRun
              ? 'history.sensor_reading_irrigating'.tr()
              : 'history.sensor_reading'.tr(),
          subtitle: 'history.sensor_reading_subtitle'.tr(namedArgs: {
            'soil': r.soilMoisture.toStringAsFixed(0),
            'humidity': r.airHumidity.toStringAsFixed(0),
            'temp': r.airTemperature.toStringAsFixed(0),
            'light': r.lightIntensity.toStringAsFixed(0),
          }),
        );
      case HistoryItemType.gap:
        final logType = item.gapLogType == 'irrigation'
            ? 'history.log_type_irrigation'.tr()
            : 'history.log_type_sensor'.tr();
        return (
          title: 'history.incomplete_data'.tr(),
          subtitle: 'history.incomplete_data_subtitle'.tr(namedArgs: {
            'count': '${item.gapMissingCount}',
            'logType': logType,
            'from': '${item.gapFromId}',
            'to': '${item.gapToId}',
          }),
        );
    }
  }

  Widget _buildItemRow(HistoryItem item) {
    // Swatch + tint per jenis event, warnanya reuse dari SensorRow dan
    // token IrrigationColors. Supaya event penting (irigasi, gap)
    // langsung terlihat jelas di antara sensor log yang jauh lebih
    // banyak.
    final Color? tintBg;
    final Color swatchColor;
    final String swatchEmoji;
    var titleColor = IrrigationColors.ink900;

    switch (item.type) {
      case HistoryItemType.irrigation:
        tintBg = IrrigationColors.blue50;
        swatchColor = IrrigationColors.blue600;
        swatchEmoji = '💧';
      case HistoryItemType.sensor:
        tintBg = null;
        swatchColor = const Color(0xFF8B6A45); // sama dengan swatch moisture di SensorRow
        swatchEmoji = '🌱';
      case HistoryItemType.gap:
        tintBg = IrrigationColors.amber50;
        swatchColor = IrrigationColors.amber600;
        swatchEmoji = '⚠️';
        titleColor = IrrigationColors.amber600;
    }

    final text = _describe(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: tintBg,
        borderRadius: BorderRadius.circular(IrrigationColors.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.timestamp == null
                    ? '-'
                    : DateFormat('HH:mm').format(item.timestamp!),
                style:
                    const TextStyle(fontSize: 10.5, color: IrrigationColors.ink500),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Container(
            width: 21,
            height: 21,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: swatchColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(swatchEmoji, style: const TextStyle(fontSize: 10)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text.title,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: titleColor)),
                Text(text.subtitle,
                    style: const TextStyle(
                        fontSize: 10.5, color: IrrigationColors.ink500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateFilterBar(DateTime? selectedDate) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickDate(selectedDate),
              icon: const Icon(Icons.calendar_today, size: 15),
              label: Text(
                selectedDate == null
                    ? 'history.all_dates'.tr()
                    : DateFormat('d MMM yyyy', context.locale.toString())
                        .format(selectedDate),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: IrrigationColors.ink900,
                side: const BorderSide(color: IrrigationColors.line200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(IrrigationColors.radiusSm),
                ),
              ),
            ),
          ),
          if (selectedDate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'history.clear_date_tooltip'.tr(),
              onPressed: () => context.read<HistoryCubit>().selectDate(null),
              icon: const Icon(Icons.close, size: 18, color: IrrigationColors.ink500),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<HistoryCubit>().refresh(),
      child: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state.phase == HistoryPhase.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.phase == HistoryPhase.error && state.items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                StatusBanner(
                  tint: CardTint.red,
                  iconColor: IrrigationColors.red600,
                  icon: '✕',
                  title: 'history.load_failed_title'.tr(),
                  subtitle: state.errorMessage,
                  trailing: TextButton(
                    onPressed: () => context.read<HistoryCubit>().refresh(),
                    child: Text('common.retry'.tr(),
                        style: const TextStyle(
                            color: IrrigationColors.red600,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            );
          }

          final rowModels = _buildRowModels(state.items);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: rowModels.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) return _dateFilterBar(state.selectedDate);

              if (index == 1) {
                if (state.phase == HistoryPhase.loading) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Center(
                        child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    )),
                  );
                }
                if (state.phase == HistoryPhase.syncing) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: StatusBanner(
                      tint: CardTint.green,
                      iconColor: IrrigationColors.green500,
                      icon: '↻',
                      title: 'history.syncing_title'.tr(),
                      subtitle: 'history.syncing_subtitle'.tr(),
                    ),
                  );
                }
                if (state.phase == HistoryPhase.loaded &&
                    state.errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: StatusBanner(
                      tint: CardTint.amber,
                      iconColor: IrrigationColors.amber600,
                      icon: '!',
                      title: 'history.sync_failed_title'.tr(),
                      subtitle: 'history.sync_failed_subtitle'
                          .tr(namedArgs: {'error': state.errorMessage!}),
                    ),
                  );
                }
                if (rowModels.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Center(
                      child: Text('history.empty'.tr(),
                          style: const TextStyle(color: IrrigationColors.ink500)),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final row = rowModels[index - 2];
              return switch (row) {
                _DateHeaderRow(:final label) => Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: IrrigationColors.ink500)),
                  ),
                _ItemRow(:final item) => _buildItemRow(item),
              };
            },
          );
        },
      ),
    );
  }
}
