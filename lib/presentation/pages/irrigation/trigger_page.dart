import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:airri_mobile/application/irrigation/trigger_form_cubit.dart';
import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

import 'widgets/condition_field.dart';
import 'widgets/info_box.dart';
import 'widgets/irrigation_buttons.dart';
import 'widgets/irrigation_card.dart';
import 'widgets/status_banner.dart';

class TriggerPage extends StatefulWidget {
  const TriggerPage({super.key});

  @override
  State<TriggerPage> createState() => _TriggerPageState();
}

class _TriggerPageState extends State<TriggerPage> {
  @override
  void initState() {
    super.initState();
    context.read<TriggerFormCubit>().load();
  }

  Future<void> _save() async {
    final ok = await context.read<TriggerFormCubit>().save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'trigger_page.saved'.tr()
            : context.read<TriggerFormCubit>().state.errorMessage ??
                'trigger_page.save_failed'.tr()),
        backgroundColor: ok ? IrrigationColors.green600 : IrrigationColors.red600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TriggerFormCubit, TriggerFormState>(
      builder: (context, state) {
        if (state.phase == FormPhase.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final cubit = context.read<TriggerFormCubit>();

        if (state.phase == FormPhase.error) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StatusBanner(
                tint: CardTint.red,
                iconColor: IrrigationColors.red600,
                icon: '✕',
                title: 'trigger_page.load_failed_title'.tr(),
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
              'trigger_page.intro'.tr(),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: IrrigationColors.ink900),
            ),
            const SizedBox(height: 16),
            ConditionField(
              label: 'trigger_page.soil_moisture'.tr(),
              unit: '%',
              operatorValue: setting.soilMoistureOperator,
              numberValue: setting.soilMoistureValue,
              onOperatorChanged: cubit.changeOperator,
              onValueChanged: cubit.changeSoilMoistureValue,
            ),
            InfoBox(text: 'trigger_page.info'.tr()),
            const SizedBox(height: 16),
            ConditionField(
              label: 'trigger_page.pump_flow_rate'.tr(),
              unit: 'trigger_page.flow_rate_unit'.tr(),
              operatorValue: '=',
              numberValue: setting.pumpFlowRateMlPerMin ?? 200,
              showOperator: false,
              enabled: false,
              onValueChanged: cubit.changePumpFlowRate,
            ),
            InfoBox(text: 'trigger_page.info_fixed'.tr()),
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
