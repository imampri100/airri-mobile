import 'package:easy_localization/easy_localization.dart';

import 'package:airri_mobile/domain/irrigation/entities.dart';
import 'package:airri_mobile/domain/irrigation/i_irrigation_local_store.dart';
import 'package:airri_mobile/domain/irrigation/i_irrigation_repository.dart';
import 'package:airri_mobile/domain/irrigation/irrigation_result.dart';

class SyncTypeSummary {
  final int fetchedCount;
  final SyncGap? gap;

  // True kalau kena limit _maxPagesPerCall sebelum habis, masih ada
  // halaman berikutnya yang belum terambil. Panggil sync() lagi untuk
  // melanjutkan.
  final bool hasMore;

  const SyncTypeSummary({
    required this.fetchedCount,
    this.gap,
    this.hasMore = false,
  });
}

class SyncSummary {
  final SyncTypeSummary sensor;
  final SyncTypeSummary irrigation;
  final String? errorMessage;

  const SyncSummary({
    required this.sensor,
    required this.irrigation,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;

  factory SyncSummary.failure(String message) => SyncSummary(
        sensor: const SyncTypeSummary(fetchedCount: 0),
        irrigation: const SyncTypeSummary(fetchedCount: 0),
        errorMessage: message,
      );
}

/// Menyinkronkan log sensor & irigasi dari device ke local storage
/// secara incremental. Juga mengurus deteksi gap (lihat storage.md,
/// bagian "Deteksi gap dari sisi mobile app") dan deteksi perubahan
/// storage device (storageId di GET /api/sync berubah kalau SD
/// card/device diganti, artinya skema ID log restart dari nol sehingga
/// lastId lokal sudah tidak nyambung lagi). Hanya bergantung pada
/// interface repository/local store, tidak perlu tahu soal Dio atau
/// sqflite.
class SyncService {
  static const _pageLimit = 200;
  static const _maxPagesPerCall = 20; // ~4000 record/panggilan sync()

  final IIrrigationRepository _repository;
  final IIrrigationLocalStore _store;

  SyncService(this._repository, this._store);

  // Counter, naik tiap local store benar-benar berubah (log baru,
  // storage reset, atau cache dikosongkan). StatistikCubit memantau ini
  // untuk tahu kapan harus invalidate cache agregasinya, tanpa perlu
  // membuat stream/event bus.
  int _dataVersion = 0;
  int get dataVersion => _dataVersion;

  Future<SyncSummary> sync() async {
    final metaResult = await _repository.getSyncMetadata();
    if (!metaResult.isSuccess || metaResult.data == null) {
      return SyncSummary.failure(
          metaResult.errorMessage ?? 'errors.sync_metadata_failed'.tr());
    }
    final meta = metaResult.data!;

    final lastKnownStorageId = await _store.getStorageId();
    final isNewStorage =
        lastKnownStorageId != null && lastKnownStorageId != meta.storageId;
    if (isNewStorage) {
      // Storage terdeteksi berganti (SD card diganti, atau factory
      // reset langsung di device). Skema ID mulai dari nol lagi di sisi
      // device, jadi cache lama harus dikosongkan total; kalau tidak,
      // record baru bisa menumpuk dengan ID lama yang sebenarnya beda
      // data.
      await _store.clearAll();
    }
    if (lastKnownStorageId == null || isNewStorage) {
      await _store.setStorageId(meta.storageId);
    }

    final sensor = await _syncOne<SensorLogEntry>(
      logType: 'sensor',
      deviceFirstId: meta.sensorLogFirstId,
      deviceLastId: meta.sensorLogLastId,
      localMaxId: _store.maxSensorLogId,
      fetchPage: (lastId, limit) =>
          _repository.getSensorLogs(lastId: lastId, limit: limit),
      insert: _store.insertSensorLogs,
      idOf: (e) => e.id,
      createdAtOf: (e) => e.createdAt,
    );

    final irrigation = await _syncOne<IrrigationLogEntry>(
      logType: 'irrigation',
      deviceFirstId: meta.irrigationLogFirstId,
      deviceLastId: meta.irrigationLogLastId,
      localMaxId: _store.maxIrrigationLogId,
      fetchPage: (lastId, limit) =>
          _repository.getIrrigationLogs(lastId: lastId, limit: limit),
      insert: _store.insertIrrigationLogs,
      idOf: (e) => e.id,
      createdAtOf: (e) => e.createdAt,
    );

    if (isNewStorage || sensor.fetchedCount > 0 || irrigation.fetchedCount > 0) {
      _dataVersion++;
    }

    return SyncSummary(sensor: sensor, irrigation: irrigation);
  }

  Future<SyncTypeSummary> _syncOne<T>({
    required String logType,
    required int deviceFirstId,
    required int deviceLastId,
    required Future<int> Function() localMaxId,
    required Future<IrrigationResult<List<T>>> Function(int lastId, int limit)
        fetchPage,
    required Future<void> Function(List<T>) insert,
    required int Function(T) idOf,
    required DateTime? Function(T) createdAtOf,
  }) async {
    if (deviceLastId <= 0) {
      // belum ada log jenis ini sama sekali di device
      return const SyncTypeSummary(fetchedCount: 0);
    }

    final localMax = await localMaxId();

    // Kalau lastSyncedId + 1 masih lebih kecil dari firstId yang
    // dimiliki device sekarang, berarti ada rentang ID yang sudah
    // terhapus di device sebelum sempat diambil.
    SyncGap? gap;
    if (localMax > 0 && localMax + 1 < deviceFirstId) {
      gap =
          SyncGap(logType: logType, fromId: localMax + 1, toId: deviceFirstId - 1);
    } else if (localMax == 0 && deviceFirstId > 1) {
      gap = SyncGap(logType: logType, fromId: 1, toId: deviceFirstId - 1);
    }

    var cursor = localMax < deviceFirstId - 1 ? deviceFirstId - 1 : localMax;
    var fetched = 0;
    var pages = 0;
    DateTime? anchorAt;

    while (cursor < deviceLastId && pages < _maxPagesPerCall) {
      final page = await fetchPage(cursor, _pageLimit);
      pages++;
      if (!page.isSuccess || page.data == null || page.data!.isEmpty) break;

      final items = page.data!;
      if (gap != null && anchorAt == null) {
        for (final item in items) {
          if (idOf(item) == gap.toId + 1) {
            anchorAt = createdAtOf(item);
            break;
          }
        }
      }

      await insert(items);
      fetched += items.length;

      final maxInPage = items.map(idOf).reduce((a, b) => a > b ? a : b);
      if (maxInPage <= cursor) break; // guard: cegah loop macet
      cursor = maxInPage;
    }

    if (gap != null) {
      await _store.recordGap(SyncGap(
        logType: gap.logType,
        fromId: gap.fromId,
        toId: gap.toId,
        anchorAt: anchorAt,
      ));
    }

    return SyncTypeSummary(
      fetchedCount: fetched,
      gap: gap,
      hasMore: cursor < deviceLastId,
    );
  }

  Future<List<SensorLogEntry>> localSensorLogs({
    int limit = 150,
    DateTime? from,
    DateTime? to,
  }) =>
      _store.sensorLogs(limit: limit, from: from, to: to);

  Future<List<IrrigationLogEntry>> localIrrigationLogs({
    int limit = 150,
    DateTime? from,
    DateTime? to,
  }) =>
      _store.irrigationLogs(limit: limit, from: from, to: to);

  Future<List<SyncGap>> localGaps() => _store.gaps();

  Future<List<DailyStat>> dailyStats({
    required DateTime from,
    required DateTime to,
    required StatsGranularity granularity,
  }) =>
      _store.dailyStats(from: from, to: to, granularity: granularity);

  Future<StatisticsSummary> periodSummary({required DateTime from, required DateTime to}) =>
      _store.periodSummary(from: from, to: to);

  Future<void> clearLocal() async {
    await _store.clearAll();
    _dataVersion++;
  }
}
