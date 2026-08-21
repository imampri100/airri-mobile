import 'entities.dart';

// Interface penyimpanan lokal untuk log yang sudah disinkron, gap
// yang terdeteksi, dan identitas storage device terakhir. SyncService
// hanya bergantung pada interface ini; implementasi SQLite-nya ada di
// infrastructure/irrigation/local/irrigation_local_store.dart
abstract class IIrrigationLocalStore {
  Future<int> maxSensorLogId();
  Future<void> insertSensorLogs(List<SensorLogEntry> logs);

  // Kalau from/to diisi, ambil semua record di rentang itu (limit
  // diabaikan) - ini untuk filter "lompat ke tanggal" di History. Kalau
  // tidak, ambil limit record terbaru untuk linimasa biasa.
  Future<List<SensorLogEntry>> sensorLogs({
    int limit = 100,
    DateTime? from,
    DateTime? to,
  });

  Future<int> maxIrrigationLogId();
  Future<void> insertIrrigationLogs(List<IrrigationLogEntry> logs);

  Future<List<IrrigationLogEntry>> irrigationLogs({
    int limit = 100,
    DateTime? from,
    DateTime? to,
  });

  Future<void> recordGap(SyncGap gap);
  Future<List<SyncGap>> gaps({String? logType});

  // Ringkasan per-bucket (rata-rata soil moisture, total ml, jumlah
  // siklus irigasi) untuk chart Statistik. Rentang from..to, bucket
  // sesuai granularity. Bucket kosong tidak ikut muncul.
  Future<List<DailyStat>> dailyStats({
    required DateTime from,
    required DateTime to,
    required StatsGranularity granularity,
  });

  // Sama seperti dailyStats tapi diringkas jadi satu angka saja untuk
  // kartu "Ringkasan" di halaman Statistik.
  Future<StatisticsSummary> periodSummary({required DateTime from, required DateTime to});

  Future<String?> getStorageId();
  Future<void> setStorageId(String value);

  // hapus semua cache lokal: log, gap, storageId
  Future<void> clearAll();
}
