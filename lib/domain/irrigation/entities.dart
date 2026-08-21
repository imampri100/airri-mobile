// Entity domain untuk fitur Smart Irrigation, murni model bisnis saja.
// Tidak boleh ada yang tahu soal JSON/HTTP/SQLite di sini. Konversi
// dari/ke data mentah (JSON API, row SQLite) ada di
// infrastructure/irrigation.

import 'value_objects.dart';

/// Pembacaan sensor: soil moisture, air humidity, air temperature, light.
/// Dipakai baik untuk status device saat ini maupun tiap baris log sensor.
class SensorReading {
  final double soilMoisture; // %
  final double airHumidity; // %
  final double airTemperature; // °C
  final double lightIntensity; // lux

  const SensorReading({
    required this.soilMoisture,
    required this.airHumidity,
    required this.airTemperature,
    required this.lightIntensity,
  });

  static const zero = SensorReading(
    soilMoisture: 0,
    airHumidity: 0,
    airTemperature: 0,
    lightIntensity: 0,
  );
}

// Aturan trigger penyiraman (GET/PUT /api/settings/trigger). Dipakai
// juga untuk menunjukkan rule yang sedang aktif di device, tapi bukan
// hasil evaluasinya - itu dihitung terpisah di
// DeviceStatus.isTriggerMet.
class TriggerSetting {
  final String soilMoistureOperator; // "<", "<=", ">", ">=", "="
  final double soilMoistureValue;

  // Read-only, dari GET /api/pump/info terpisah. Ini konstanta
  // kompilasi firmware, bukan bagian trigger setting yang sebenarnya.
  // Null kalau belum termuat atau device tidak terjangkau.
  final double? pumpFlowRateMlPerMin;

  const TriggerSetting({
    required this.soilMoistureOperator,
    required this.soilMoistureValue,
    this.pumpFlowRateMlPerMin,
  });

  TriggerSetting copyWith({
    String? soilMoistureOperator,
    double? soilMoistureValue,
    double? pumpFlowRateMlPerMin,
  }) {
    return TriggerSetting(
      soilMoistureOperator: soilMoistureOperator ?? this.soilMoistureOperator,
      soilMoistureValue: soilMoistureValue ?? this.soilMoistureValue,
      pumpFlowRateMlPerMin:
          pumpFlowRateMlPerMin ?? this.pumpFlowRateMlPerMin,
    );
  }

  static const fallback = TriggerSetting(
    soilMoistureOperator: '<',
    soilMoistureValue: 30,
    pumpFlowRateMlPerMin: 200,
  );
}

// Kondisi yang membuat pompa tidak boleh menyala meski trigger sudah
// terpenuhi (GET/PUT /api/settings/restriction). Sama seperti
// TriggerSetting, ini menunjukkan rule aktif di device, bukan hasil
// evaluasinya.
class RestrictionSetting {
  final bool airHumidityEnabled;
  final String airHumidityOperator;
  final double airHumidityValue;

  final bool airTemperatureEnabled;
  final String airTemperatureOperator;
  final double airTemperatureValue;

  final bool lightIntensityEnabled;
  final String lightIntensityOperator;
  final double lightIntensityValue;

  // Safety net, detik maksimal pompa boleh menyala nonstop sebelum
  // firmware memaksa mati. Berbeda dari 3 kondisi di atas, ini tidak
  // punya operator/enabled, selalu aktif.
  final double maxPumpRuntimeSecond;

  const RestrictionSetting({
    required this.airHumidityEnabled,
    required this.airHumidityOperator,
    required this.airHumidityValue,
    required this.airTemperatureEnabled,
    required this.airTemperatureOperator,
    required this.airTemperatureValue,
    required this.lightIntensityEnabled,
    required this.lightIntensityOperator,
    required this.lightIntensityValue,
    required this.maxPumpRuntimeSecond,
  });

  RestrictionSetting copyWith({
    bool? airHumidityEnabled,
    String? airHumidityOperator,
    double? airHumidityValue,
    bool? airTemperatureEnabled,
    String? airTemperatureOperator,
    double? airTemperatureValue,
    bool? lightIntensityEnabled,
    String? lightIntensityOperator,
    double? lightIntensityValue,
    double? maxPumpRuntimeSecond,
  }) {
    return RestrictionSetting(
      airHumidityEnabled: airHumidityEnabled ?? this.airHumidityEnabled,
      airHumidityOperator: airHumidityOperator ?? this.airHumidityOperator,
      airHumidityValue: airHumidityValue ?? this.airHumidityValue,
      airTemperatureEnabled:
          airTemperatureEnabled ?? this.airTemperatureEnabled,
      airTemperatureOperator:
          airTemperatureOperator ?? this.airTemperatureOperator,
      airTemperatureValue: airTemperatureValue ?? this.airTemperatureValue,
      lightIntensityEnabled:
          lightIntensityEnabled ?? this.lightIntensityEnabled,
      lightIntensityOperator:
          lightIntensityOperator ?? this.lightIntensityOperator,
      lightIntensityValue: lightIntensityValue ?? this.lightIntensityValue,
      maxPumpRuntimeSecond:
          maxPumpRuntimeSecond ?? this.maxPumpRuntimeSecond,
    );
  }

  // Dipakai sebelum data asli termuat dari device (initial state /
  // gagal fetch). Semua kondisi disabled, sama seperti default firmware
  // (restriction_setting.h), jadi app tidak menebak-nebak rule yang
  // aktif.
  static const fallback = RestrictionSetting(
    airHumidityEnabled: false,
    airHumidityOperator: '>=',
    airHumidityValue: 80,
    airTemperatureEnabled: false,
    airTemperatureOperator: '>=',
    airTemperatureValue: 35,
    lightIntensityEnabled: false,
    lightIntensityOperator: '<=',
    lightIntensityValue: 100,
    maxPumpRuntimeSecond: 15,
  );
}

// Sensor mana yang sedang dievaluasi di sebuah ConditionEval.
// Presentation layer memakai ini untuk memilih label & satuan
// terjemahan, jadi domain tidak perlu tahu apa-apa soal translation
// key.
enum SensorField { soilMoisture, airHumidity, airTemperature, lightIntensity }

// Satu kondisi trigger/restriction yang sudah dievaluasi ke sensor saat
// ini. Isinya data mentah saja, teksnya dirangkai & diterjemahkan di
// presentation layer.
class ConditionEval {
  final SensorField field;
  final double sensorValue;
  final String operatorSymbol;
  final double thresholdValue;

  const ConditionEval({
    required this.field,
    required this.sensorValue,
    required this.operatorSymbol,
    required this.thresholdValue,
  });
}

/// Hasil keputusan firmware apakah pompa akan/sedang berjalan.
class PumpDecision {
  final bool shouldRunPump;
  final String reason;

  const PumpDecision({required this.shouldRunPump, required this.reason});

  static const empty = PumpDecision(shouldRunPump: false, reason: '-');
}

/// Status device saat ini: sensor, aturan trigger/restriction yang
/// sedang aktif, keputusan pompa, dan status running-nya.
class DeviceStatus {
  final SensorReading sensor;
  final TriggerSetting trigger;
  final RestrictionSetting restriction;
  final PumpDecision decision;
  final bool pumpRunning;
  final bool timeSynchronized;

  const DeviceStatus({
    required this.sensor,
    required this.trigger,
    required this.restriction,
    required this.decision,
    required this.pumpRunning,
    required this.timeSynchronized,
  });

  // Cek rule soil moisture terpenuhi atau tidak, membandingkan sensor
  // vs trigger di sini karena backend hanya mengirim rule-nya saja,
  // bukan hasil evaluasi.
  bool get isTriggerMet => evaluateOperator(
        sensor.soilMoisture,
        trigger.soilMoistureOperator,
        trigger.soilMoistureValue,
      );

  ConditionEval get triggerCondition => ConditionEval(
        field: SensorField.soilMoisture,
        sensorValue: sensor.soilMoisture,
        operatorSymbol: trigger.soilMoistureOperator,
        thresholdValue: trigger.soilMoistureValue,
      );

  /// Daftar kondisi restriction yang AKTIF (enabled & rule-nya terpenuhi)
  /// saat ini.
  List<ConditionEval> get activeRestrictions {
    final active = <ConditionEval>[];
    if (restriction.airHumidityEnabled &&
        evaluateOperator(sensor.airHumidity, restriction.airHumidityOperator,
            restriction.airHumidityValue)) {
      active.add(ConditionEval(
        field: SensorField.airHumidity,
        sensorValue: sensor.airHumidity,
        operatorSymbol: restriction.airHumidityOperator,
        thresholdValue: restriction.airHumidityValue,
      ));
    }
    if (restriction.airTemperatureEnabled &&
        evaluateOperator(sensor.airTemperature,
            restriction.airTemperatureOperator, restriction.airTemperatureValue)) {
      active.add(ConditionEval(
        field: SensorField.airTemperature,
        sensorValue: sensor.airTemperature,
        operatorSymbol: restriction.airTemperatureOperator,
        thresholdValue: restriction.airTemperatureValue,
      ));
    }
    if (restriction.lightIntensityEnabled &&
        evaluateOperator(sensor.lightIntensity,
            restriction.lightIntensityOperator, restriction.lightIntensityValue)) {
      active.add(ConditionEval(
        field: SensorField.lightIntensity,
        sensorValue: sensor.lightIntensity,
        operatorSymbol: restriction.lightIntensityOperator,
        thresholdValue: restriction.lightIntensityValue,
      ));
    }
    return active;
  }

  bool get isRestricted => activeRestrictions.isNotEmpty;
}

/// Satu baris log sensor.
class SensorLogEntry {
  final int id;
  final DateTime? createdAt;
  final SensorReading reading;
  final bool isIrrigationRun;

  const SensorLogEntry({
    required this.id,
    required this.createdAt,
    required this.reading,
    required this.isIrrigationRun,
  });
}

/// Satu baris log siklus irigasi.
class IrrigationLogEntry {
  final int id;
  final DateTime? createdAt;
  final DateTime? runAt;
  final DateTime? stopAt;
  final int durationSecond;
  final double milliliter;

  const IrrigationLogEntry({
    required this.id,
    required this.createdAt,
    required this.runAt,
    required this.stopAt,
    required this.durationSecond,
    required this.milliliter,
  });
}

// Granularitas bucket waktu untuk DailyStat di halaman Statistik. Makin
// panjang periode, makin kasar (harian jadi mingguan jadi bulanan)
// supaya chart tidak penuh noise.
enum StatsGranularity { day, week, month }

// Ringkasan satu bucket waktu (hari/minggu/bulan tergantung
// granularity) untuk halaman Statistik: rata-rata soil moisture, total
// air & jumlah siklus irigasi dalam bucket itu. Date diambil dari
// tanggal data pertama yang tercatat, bukan selalu awal bucket
// kalendernya.
class DailyStat {
  final DateTime date;
  final double avgSoilMoisture;
  final double totalWaterMl;
  final int irrigationCount;

  const DailyStat({
    required this.date,
    required this.avgSoilMoisture,
    required this.totalWaterMl,
    required this.irrigationCount,
  });
}

/// Ringkasan agregat satu rentang periode penuh (bukan per-hari) untuk
/// kartu "Ringkasan" di halaman Statistik.
class StatisticsSummary {
  final double avgSoilMoisture;
  final double totalWaterMl;
  final int irrigationCount;

  const StatisticsSummary({
    required this.avgSoilMoisture,
    required this.totalWaterMl,
    required this.irrigationCount,
  });

  static const zero =
      StatisticsSummary(avgSoilMoisture: 0, totalWaterMl: 0, irrigationCount: 0);
}

/// Metadata sinkronisasi (GET /api/sync).
class SyncMetadata {
  final String storageId;
  final int sensorLogLastId;
  final int irrigationLogLastId;
  final int sensorLogCount;
  final int irrigationLogCount;

  // ID paling lama yang masih ada di device (ikut naik kalau
  // LogRetentionTask menghapus file lama). Dipakai untuk deteksi gap:
  // kalau lastSyncedId + 1 lebih kecil dari firstId, berarti ada data
  // yang sudah hilang sebelum sempat disinkron. Lihat storage.md.
  final int sensorLogFirstId;
  final int irrigationLogFirstId;

  const SyncMetadata({
    required this.storageId,
    required this.sensorLogLastId,
    required this.irrigationLogLastId,
    required this.sensorLogCount,
    required this.irrigationLogCount,
    required this.sensorLogFirstId,
    required this.irrigationLogFirstId,
  });
}

// Rentang ID log yang sudah hilang dari device sebelum sempat
// disinkron, lihat "Deteksi gap dari sisi mobile app" di storage.md.
// logType-nya 'sensor' atau 'irrigation'.
class SyncGap {
  final String logType;
  final int fromId;
  final int toId;

  // Timestamp perkiraan untuk menaruh gap ini di linimasa History.
  // Diambil dari createdAt record pertama setelah gap (id == toId + 1)
  // saat record itu sudah tersinkron.
  final DateTime? anchorAt;

  const SyncGap({
    required this.logType,
    required this.fromId,
    required this.toId,
    this.anchorAt,
  });

  int get missingCount => toId - fromId + 1;
}
