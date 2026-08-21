import 'package:bloc/bloc.dart';

import 'package:airri_mobile/domain/irrigation/entities.dart';

import 'sync_service.dart';

enum StatistikPeriod { sevenDays, thirtyDays, oneYear, threeYears, all }

class StatistikState {
  final StatistikPeriod period;
  final bool loading;
  final StatisticsSummary summary;
  final List<DailyStat> dailyStats;

  const StatistikState({
    required this.period,
    required this.loading,
    required this.summary,
    required this.dailyStats,
  });

  factory StatistikState.initial() => const StatistikState(
        period: StatistikPeriod.sevenDays,
        loading: true,
        summary: StatisticsSummary.zero,
        dailyStats: [],
      );

  StatistikState copyWith({
    StatistikPeriod? period,
    bool? loading,
    StatisticsSummary? summary,
    List<DailyStat>? dailyStats,
  }) {
    return StatistikState(
      period: period ?? this.period,
      loading: loading ?? this.loading,
      summary: summary ?? this.summary,
      dailyStats: dailyStats ?? this.dailyStats,
    );
  }
}

// Halaman ini hanya membaca & mengagregasi dari local store, tidak
// memicu sync baru ke device. Sync sudah ditangani Dashboard/History
// tiap kali dibuka.
class StatistikCubit extends Cubit<StatistikState> {
  final SyncService _syncService;

  StatistikCubit(this._syncService) : super(StatistikState.initial());

  // Cache query per-periode supaya tidak query ulang tiap ganti tab
  // kalau data belum berubah. Kalau dataVersion di SyncService naik,
  // berarti ada perubahan, cache di-clear semua.
  int _cachedDataVersion = -1;
  final Map<StatistikPeriod, _CachedStats> _cache = {};

  Future<void> load({bool forceReload = false}) async {
    if (_syncService.dataVersion != _cachedDataVersion) {
      _cache.clear();
      _cachedDataVersion = _syncService.dataVersion;
    }

    // Rentang tanggal ikut dicek, tidak hanya dataVersion, karena
    // _rangeFor memakai DateTime.now(). Kalau app dibuka melewati
    // tengah malam, rentangnya ikut bergeser walau dataVersion tetap
    // sama.
    final range = _rangeFor(state.period);
    final cached = _cache[state.period];
    if (!forceReload &&
        cached != null &&
        cached.from == range.from &&
        cached.to == range.to) {
      emit(state.copyWith(
        loading: false,
        summary: cached.summary,
        dailyStats: cached.dailyStats,
      ));
      return;
    }

    emit(state.copyWith(loading: true));
    final summary =
        await _syncService.periodSummary(from: range.from, to: range.to);
    final daily = await _syncService.dailyStats(
      from: range.from,
      to: range.to,
      granularity: _granularityFor(state.period),
    );
    _cache[state.period] = _CachedStats(
      from: range.from,
      to: range.to,
      summary: summary,
      dailyStats: daily,
    );
    emit(state.copyWith(loading: false, summary: summary, dailyStats: daily));
  }

  Future<void> selectPeriod(StatistikPeriod period) async {
    if (period == state.period) return;
    emit(state.copyWith(period: period));
    await load();
  }

  ({DateTime from, DateTime to}) _rangeFor(StatistikPeriod period) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday =
        DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    switch (period) {
      case StatistikPeriod.sevenDays:
        return (
          from: startOfToday.subtract(const Duration(days: 6)),
          to: endOfToday,
        );
      case StatistikPeriod.thirtyDays:
        return (
          from: startOfToday.subtract(const Duration(days: 29)),
          to: endOfToday,
        );
      case StatistikPeriod.oneYear:
        return (
          from: startOfToday.subtract(const Duration(days: 365)),
          to: endOfToday,
        );
      case StatistikPeriod.threeYears:
        return (
          from: startOfToday.subtract(const Duration(days: 365 * 3)),
          to: endOfToday,
        );
      case StatistikPeriod.all:
        return (from: DateTime(2000), to: endOfToday);
    }
  }

  // Makin panjang periode, titik chart makin kasar (harian, mingguan,
  // bulanan), supaya tidak jadi noise saat rentangnya sudah tahunan.
  StatsGranularity _granularityFor(StatistikPeriod period) => switch (period) {
        StatistikPeriod.sevenDays || StatistikPeriod.thirtyDays =>
          StatsGranularity.day,
        StatistikPeriod.oneYear => StatsGranularity.week,
        StatistikPeriod.threeYears || StatistikPeriod.all =>
          StatsGranularity.month,
      };
}

class _CachedStats {
  final DateTime from;
  final DateTime to;
  final StatisticsSummary summary;
  final List<DailyStat> dailyStats;

  const _CachedStats({
    required this.from,
    required this.to,
    required this.summary,
    required this.dailyStats,
  });
}
