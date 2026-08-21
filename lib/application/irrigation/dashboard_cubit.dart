import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:airri_mobile/domain/irrigation/entities.dart';
import 'package:airri_mobile/domain/irrigation/i_irrigation_repository.dart';

import 'sync_service.dart';

enum DashboardPhase { loading, syncing, loaded, offline }

class DashboardState {
  final DashboardPhase phase;
  final DeviceStatus? status;
  final String? errorMessage;
  final DateTime? lastSyncedAt;
  final bool isBusy; // dipakai untuk disable tombol saat test pump / dsb.

  // Ringkasan hari ini diambil dari local store (SyncService) supaya
  // tidak menambah request ke device tiap kali refresh.
  final int todayIrrigationCount;
  final double todayWaterMl;

  const DashboardState({
    required this.phase,
    this.status,
    this.errorMessage,
    this.lastSyncedAt,
    this.isBusy = false,
    this.todayIrrigationCount = 0,
    this.todayWaterMl = 0,
  });

  factory DashboardState.initial() =>
      const DashboardState(phase: DashboardPhase.loading);

  DashboardState copyWith({
    DashboardPhase? phase,
    DeviceStatus? status,
    String? errorMessage,
    DateTime? lastSyncedAt,
    bool? isBusy,
    int? todayIrrigationCount,
    double? todayWaterMl,
  }) {
    return DashboardState(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      errorMessage: errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isBusy: isBusy ?? this.isBusy,
      todayIrrigationCount: todayIrrigationCount ?? this.todayIrrigationCount,
      todayWaterMl: todayWaterMl ?? this.todayWaterMl,
    );
  }
}

class DashboardCubit extends Cubit<DashboardState> {
  final IIrrigationRepository _repo;
  final SyncService _syncService;

  DashboardCubit(this._repo, this._syncService) : super(DashboardState.initial());

  Future<void> refresh() async {
    emit(state.copyWith(
      phase: state.status == null
          ? DashboardPhase.loading
          : DashboardPhase.syncing,
    ));
    final result = await _repo.getStatus();
    final today = await _loadTodaySummary();
    if (result.isSuccess && result.data != null) {
      emit(state.copyWith(
        phase: DashboardPhase.loaded,
        status: result.data,
        lastSyncedAt: DateTime.now(),
        errorMessage: null,
        todayIrrigationCount: today.$1,
        todayWaterMl: today.$2,
      ));
    } else {
      emit(state.copyWith(
        phase: DashboardPhase.offline,
        errorMessage: result.errorMessage ?? 'errors.status_load_failed'.tr(),
        todayIrrigationCount: today.$1,
        todayWaterMl: today.$2,
      ));
    }
  }

  // Mengembalikan (jumlah irigasi, total ml) hari ini, dibaca dari local store saja.
  Future<(int, double)> _loadTodaySummary() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final logs = await _syncService.localIrrigationLogs(
      from: startOfToday,
      to: now,
    );
    final totalMl = logs.fold<double>(0, (sum, e) => sum + e.milliliter);
    return (logs.length, totalMl);
  }

  Future<String?> testPump({int durationSecond = 3}) async {
    emit(state.copyWith(isBusy: true));
    final result = await _repo.testPump(durationSecond: durationSecond);
    emit(state.copyWith(isBusy: false));
    if (result.isSuccess) {
      unawaited(refresh());
      return null;
    }
    return result.errorMessage;
  }

  Future<String?> deleteLogs() async {
    emit(state.copyWith(isBusy: true));
    final result = await _repo.deleteAllLogs();
    if (result.isSuccess) {
      // Setelah log dihapus, device memulai skema ID dari awal lagi,
      // jadi cache lokal harus ikut dikosongkan supaya tidak bentrok.
      await _syncService.clearLocal();
    }
    emit(state.copyWith(isBusy: false));
    return result.isSuccess ? null : result.errorMessage;
  }

  Future<String?> factoryReset() async {
    emit(state.copyWith(isBusy: true));
    final result = await _repo.factoryReset();
    if (result.isSuccess) {
      await _syncService.clearLocal();
    }
    emit(state.copyWith(isBusy: false));
    if (result.isSuccess) {
      unawaited(refresh());
      return null;
    }
    return result.errorMessage;
  }
}

// Tidak perlu import dart:async hanya demi satu fungsi ini.
void unawaited(Future<void> future) {}
