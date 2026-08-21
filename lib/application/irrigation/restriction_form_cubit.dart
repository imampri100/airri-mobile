import 'package:bloc/bloc.dart';

import 'package:airri_mobile/domain/irrigation/entities.dart';
import 'package:airri_mobile/domain/irrigation/i_irrigation_repository.dart';

import 'trigger_form_cubit.dart' show FormPhase;

class RestrictionFormState {
  final FormPhase phase;
  final RestrictionSetting setting;
  final String? errorMessage;
  final bool savedSuccessfully;

  const RestrictionFormState({
    required this.phase,
    required this.setting,
    this.errorMessage,
    this.savedSuccessfully = false,
  });

  factory RestrictionFormState.initial() => const RestrictionFormState(
        phase: FormPhase.loading,
        setting: RestrictionSetting.fallback,
      );

  RestrictionFormState copyWith({
    FormPhase? phase,
    RestrictionSetting? setting,
    String? errorMessage,
    bool? savedSuccessfully,
  }) {
    return RestrictionFormState(
      phase: phase ?? this.phase,
      setting: setting ?? this.setting,
      errorMessage: errorMessage,
      savedSuccessfully: savedSuccessfully ?? false,
    );
  }
}

class RestrictionFormCubit extends Cubit<RestrictionFormState> {
  final IIrrigationRepository _repo;

  RestrictionFormCubit(this._repo) : super(RestrictionFormState.initial());

  Future<void> load() async {
    emit(state.copyWith(phase: FormPhase.loading));
    final result = await _repo.getRestrictionSetting();
    if (result.isSuccess && result.data != null) {
      emit(state.copyWith(phase: FormPhase.ready, setting: result.data));
    } else {
      emit(state.copyWith(
        phase: FormPhase.error,
        errorMessage: result.errorMessage,
      ));
    }
  }

  void changeTemperature({String? operator, double? value, bool? enabled}) {
    emit(state.copyWith(
      setting: state.setting.copyWith(
        airTemperatureOperator: operator,
        airTemperatureValue: value,
        airTemperatureEnabled: enabled,
      ),
    ));
  }

  void changeHumidity({String? operator, double? value, bool? enabled}) {
    emit(state.copyWith(
      setting: state.setting.copyWith(
        airHumidityOperator: operator,
        airHumidityValue: value,
        airHumidityEnabled: enabled,
      ),
    ));
  }

  void changeLight({String? operator, double? value, bool? enabled}) {
    emit(state.copyWith(
      setting: state.setting.copyWith(
        lightIntensityOperator: operator,
        lightIntensityValue: value,
        lightIntensityEnabled: enabled,
      ),
    ));
  }

  void changeMaxPumpRuntime(double value) {
    emit(state.copyWith(
      setting: state.setting.copyWith(maxPumpRuntimeSecond: value),
    ));
  }

  Future<bool> save() async {
    emit(state.copyWith(phase: FormPhase.saving));
    final result = await _repo.updateRestrictionSetting(state.setting);
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
