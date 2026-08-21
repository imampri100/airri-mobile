import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:airri_mobile/application/irrigation/restriction_form_cubit.dart';
import 'package:airri_mobile/application/irrigation/trigger_form_cubit.dart' show FormPhase;
import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

import 'widgets/condition_field.dart';
import 'widgets/info_box.dart';
import 'widgets/irrigation_buttons.dart';
import 'widgets/irrigation_card.dart';
import 'widgets/status_banner.dart';

class RestrictionPage extends StatefulWidget {
  const RestrictionPage({super.key});

  @override
  State<RestrictionPage> createState() => _RestrictionPageState();
}

class _RestrictionPageState extends State<RestrictionPage> {
  @override
  void initState() {
    super.initState();
    context.read<RestrictionFormCubit>().load();
  }

  Future<void> _save() async {
    final ok = await context.read<RestrictionFormCubit>().save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'restriction_page.saved'.tr()
            : context.read<RestrictionFormCubit>().state.errorMessage ??
                'restriction_page.save_failed'.tr()),
        backgroundColor: ok ? IrrigationColors.green600 : IrrigationColors.red600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestrictionFormCubit, RestrictionFormState>(
      builder: (context, state) {
        if (state.phase == FormPhase.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final cubit = context.read<RestrictionFormCubit>();

        if (state.phase == FormPhase.error) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StatusBanner(
                tint: CardTint.red,
                iconColor: IrrigationColors.red600,
                icon: '✕',
                title: 'restriction_page.load_failed_title'.tr(),
                subtitle: state.errorMessage,
                trailing: TextButton(
                  onPressed: cubit.load,
                  child: Text('common.retry'.tr(),
                      style: const TextStyle(
                          color: IrrigationColors.red600,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          );
        }

        final setting = state.setting;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'restriction_page.intro'.tr(),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: IrrigationColors.ink900),
            ),
            const SizedBox(height: 16),
            ConditionField(
              label: 'restriction_page.temperature'.tr(),
              unit: '°C',
              operatorValue: setting.airTemperatureOperator,
              numberValue: setting.airTemperatureValue,
              enabled: setting.airTemperatureEnabled,
              onEnabledChanged: (v) => cubit.changeTemperature(enabled: v),
              onOperatorChanged: (v) => cubit.changeTemperature(operator: v),
              onValueChanged: (v) => cubit.changeTemperature(value: v),
            ),
            ConditionField(
              label: 'restriction_page.humidity'.tr(),
              unit: '%',
              operatorValue: setting.airHumidityOperator,
              numberValue: setting.airHumidityValue,
              enabled: setting.airHumidityEnabled,
              onEnabledChanged: (v) => cubit.changeHumidity(enabled: v),
              onOperatorChanged: (v) => cubit.changeHumidity(operator: v),
              onValueChanged: (v) => cubit.changeHumidity(value: v),
            ),
            ConditionField(
              label: 'restriction_page.light_intensity'.tr(),
              unit: 'lx',
              operatorValue: setting.lightIntensityOperator,
              numberValue: setting.lightIntensityValue,
              enabled: setting.lightIntensityEnabled,
              onEnabledChanged: (v) => cubit.changeLight(enabled: v),
              onOperatorChanged: (v) => cubit.changeLight(operator: v),
              onValueChanged: (v) => cubit.changeLight(value: v),
            ),
            InfoBox(text: 'restriction_page.info'.tr()),
            const SizedBox(height: 20),
            Text(
              'restriction_page.pump_safety_net'.tr(),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: IrrigationColors.ink900),
            ),
            const SizedBox(height: 16),
            ConditionField(
              label: 'restriction_page.max_pump_runtime'.tr(),
              unit: 'restriction_page.seconds_unit'.tr(),
              operatorValue: '',
              numberValue: setting.maxPumpRuntimeSecond,
              showOperator: false,
              onValueChanged: (v) => cubit.changeMaxPumpRuntime(v),
            ),
            InfoBox(
              amber: true,
              text: 'restriction_page.info_safety'.tr(),
            ),
            const SizedBox(height: 6),
            PrimaryPillButton(
              label: 'common.save'.tr(),
              loading: state.phase == FormPhase.saving,
              onTap: _save,
            ),
          ],
        );
      },
    );
  }
}
