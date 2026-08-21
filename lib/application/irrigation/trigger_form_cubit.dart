import 'package:bloc/bloc.dart';

import 'package:airri_mobile/domain/irrigation/entities.dart';
import 'package:airri_mobile/domain/irrigation/i_irrigation_repository.dart';

enum FormPhase { loading, ready, saving, error }

class TriggerFormState {
  final FormPhase phase;
  final TriggerSetting setting;
  final String? errorMessage;
  final bool savedSuccessfully;

  const TriggerFormState({
    required this.phase,
    required this.setting,
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  factory TriggerFormState.initial() => const TriggerFormState(
        phase: FormPhase.loading,
        setting: TriggerSetting.fallback,
      );

  TriggerFormState copyWith({
    FormPhase? phase,
    TriggerSetting? setting,
    String? errorMessage,
    bool? savedSuccessfully,
  }) {
    return TriggerFormState(
      phase: phase ?? this.phase,
      setting: setting ?? this.setting,
      errorMessage: errorMessage,
      savedSuccessfully: savedSuccessfully ?? false,
    );
  }
}

class TriggerFormCubit extends Cubit<TriggerFormState> {
  final IIrrigationRepository _repo;

  TriggerFormCubit(this._repo) : super(TriggerFormState.initial());

  Future<void> load() async {
    emit(state.copyWith(phase: FormPhase.loading));
    final triggerFuture = _repo.getTriggerSetting();
    final flowRateFuture = _repo.getPumpFlowRate();
    final result = await triggerFuture;
    final flowRateResult = await flowRateFuture;

    if (result.isSuccess && result.data != null) {
      emit(state.copyWith(
        phase: FormPhase.ready,
        setting: result.data!.copyWith(
          pumpFlowRateMlPerMin:
              flowRateResult.isSuccess ? flowRateResult.data : null,
        ),
      ));
    } else {
      // Form tetap ditampilkan dengan default value, supaya bisa diisi manual.
      emit(state.copyWith(
        phase: FormPhase.error,
        errorMessage: result.errorMessage,
      ));
    }
  }

  void changeOperator(String operator) {
    emit(state.copyWith(
      setting: state.setting.copyWith(soilMoistureOperator: operator),
    ));
  }

  void changeSoilMoistureValue(double value) {
    emit(state.copyWith(
      setting: state.setting.copyWith(soilMoistureValue: value),
    ));
  }

  void changePumpFlowRate(double value) {
    emit(state.copyWith(
      setting: state.setting.copyWith(pumpFlowRateMlPerMin: value),
    ));
  }

  Future<bool> save() async {
    emit(state.copyWith(phase: FormPhase.saving));
    final result = await _repo.updateTriggerSetting(state.setting);
    if (result.isSuccess) {
      emit(state.copyWith(phase: FormPhase.ready, savedSuccessfully: true));
      return true;
    }
    emit(state.copyWith(
      phase: FormPhase.ready,
      errorMessage: result.errorMessage,
    ));
    return false;
  }
}
