// DTO untuk fitur Smart Irrigation. File ini yang tahu bentuk JSON
// mentah dari firmware ESP32 (smart-irrigation-api_postman_collection.json)
// dan cara mem-parsingnya, lalu dikonversi ke entity domain lewat
// toDomain(). Domain layer (entities.dart) sendiri tidak tahu apa-apa
// soal JSON, supaya tetap independen dari format data luar.

import 'package:airri_mobile/domain/irrigation/entities.dart';

double _num(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

int _int(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

bool _bool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  return s == 'true' || s == '1';
}

String _str(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

// createdAt/irrigationRunAt dari firmware itu epoch detik (contoh:
// 1737350400), bukan milidetik
DateTime? _epochSeconds(dynamic v) {
  if (v == null) return null;
  final n = v is num ? v.toInt() : int.tryParse(v.toString());
  if (n == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(n * 1000);
}

class SensorReadingDto {
  final double soilMoisture;
  final double airHumidity;
  final double airTemperature;
  final double lightIntensity;

  const SensorReadingDto({
    required this.soilMoisture,
    required this.airHumidity,
    required this.airTemperature,
    required this.lightIntensity,
  });

  factory SensorReadingDto.fromJson(Map<String, dynamic> json) {
    return SensorReadingDto(
      soilMoisture: _num(json['soilMoisture']),
      airHumidity: _num(json['airHumidity']),
      airTemperature: _num(json['airTemperature']),
      lightIntensity: _num(json['lightIntensity']),
    );
  }

  SensorReading toDomain() => SensorReading(
        soilMoisture: soilMoisture,
        airHumidity: airHumidity,
        airTemperature: airTemperature,
        lightIntensity: lightIntensity,
      );
}

class TriggerSettingDto {
  final String soilMoistureOperator;
  final double soilMoistureValue;

  const TriggerSettingDto({
    required this.soilMoistureOperator,
    required this.soilMoistureValue,
  });

  factory TriggerSettingDto.fromJson(Map<String, dynamic> json) {
    return TriggerSettingDto(
      soilMoistureOperator: _str(json['soilMoistureOperator'], '<'),
      soilMoistureValue: _num(json['soilMoistureValue'], 30),
    );
  }

  factory TriggerSettingDto.fromDomain(TriggerSetting entity) {
    return TriggerSettingDto(
      soilMoistureOperator: entity.soilMoistureOperator,
      soilMoistureValue: entity.soilMoistureValue,
    );
  }

  TriggerSetting toDomain({double? pumpFlowRateMlPerMin}) => TriggerSetting(
        soilMoistureOperator: soilMoistureOperator,
        soilMoistureValue: soilMoistureValue,
        pumpFlowRateMlPerMin: pumpFlowRateMlPerMin,
      );

  // Hanya 2 field ini yang diterima backend, sesuai contoh di Postman
  // collection.
  Map<String, dynamic> toApiJson() => {
        'soilMoistureOperator': soilMoistureOperator,
        'soilMoistureValue': soilMoistureValue,
      };
}

// GET /api/pump/info, info statis pompa (konstanta firmware, bukan
// setting yang bisa di-PUT)
class PumpInfoDto {
  final double flowRateMlPerMinute;

  const PumpInfoDto({required this.flowRateMlPerMinute});

  factory PumpInfoDto.fromJson(Map<String, dynamic> json) {
    return PumpInfoDto(
      flowRateMlPerMinute: _num(json['flowRateMlPerMinute'], 200),
    );
  }
}

class RestrictionSettingDto {
  final bool airHumidityEnabled;
  final String airHumidityOperator;
  final double airHumidityValue;
  final bool airTemperatureEnabled;
  final String airTemperatureOperator;
  final double airTemperatureValue;
  final bool lightIntensityEnabled;
  final String lightIntensityOperator;
  final double lightIntensityValue;
  final double maxPumpRuntimeSecond;

  const RestrictionSettingDto({
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

  factory RestrictionSettingDto.fromJson(Map<String, dynamic> json) {
    return RestrictionSettingDto(
      airHumidityEnabled: _bool(json['airHumidityEnabled'], true),
      airHumidityOperator: _str(json['airHumidityOperator'], '<'),
      airHumidityValue: _num(json['airHumidityValue'], 40),
      airTemperatureEnabled: _bool(json['airTemperatureEnabled'], false),
      airTemperatureOperator: _str(json['airTemperatureOperator'], '>'),
      airTemperatureValue: _num(json['airTemperatureValue'], 35),
      lightIntensityEnabled: _bool(json['lightIntensityEnabled'], false),
      lightIntensityOperator: _str(json['lightIntensityOperator'], '<'),
      lightIntensityValue: _num(json['lightIntensityValue'], 100),
      maxPumpRuntimeSecond: _num(json['maxPumpRuntimeSecond'], 15),
    );
  }

  factory RestrictionSettingDto.fromDomain(RestrictionSetting entity) {
    return RestrictionSettingDto(
      airHumidityEnabled: entity.airHumidityEnabled,
      airHumidityOperator: entity.airHumidityOperator,
      airHumidityValue: entity.airHumidityValue,
      airTemperatureEnabled: entity.airTemperatureEnabled,
      airTemperatureOperator: entity.airTemperatureOperator,
      airTemperatureValue: entity.airTemperatureValue,
      lightIntensityEnabled: entity.lightIntensityEnabled,
      lightIntensityOperator: entity.lightIntensityOperator,
      lightIntensityValue: entity.lightIntensityValue,
      maxPumpRuntimeSecond: entity.maxPumpRuntimeSecond,
    );
  }

  RestrictionSetting toDomain() => RestrictionSetting(
        airHumidityEnabled: airHumidityEnabled,
        airHumidityOperator: airHumidityOperator,
        airHumidityValue: airHumidityValue,
        airTemperatureEnabled: airTemperatureEnabled,
        airTemperatureOperator: airTemperatureOperator,
        airTemperatureValue: airTemperatureValue,
        lightIntensityEnabled: lightIntensityEnabled,
        lightIntensityOperator: lightIntensityOperator,
        lightIntensityValue: lightIntensityValue,
        maxPumpRuntimeSecond: maxPumpRuntimeSecond,
      );

  Map<String, dynamic> toApiJson() => {
        'airHumidityEnabled': airHumidityEnabled,
        'airHumidityOperator': airHumidityOperator,
        'airHumidityValue': airHumidityValue,
        'airTemperatureEnabled': airTemperatureEnabled,
        'airTemperatureOperator': airTemperatureOperator,
        'airTemperatureValue': airTemperatureValue,
        'lightIntensityEnabled': lightIntensityEnabled,
        'lightIntensityOperator': lightIntensityOperator,
        'lightIntensityValue': lightIntensityValue,
        'maxPumpRuntimeSecond': maxPumpRuntimeSecond,
      };
}

class PumpDecisionDto {
  final bool shouldRunPump;
  final String reason;

  const PumpDecisionDto({required this.shouldRunPump, required this.reason});

  factory PumpDecisionDto.fromJson(Map<String, dynamic> json) {
    return PumpDecisionDto(
      shouldRunPump: _bool(json['shouldRunPump']),
      reason: _str(json['reason']),
    );
  }

  PumpDecision toDomain() =>
      PumpDecision(shouldRunPump: shouldRunPump, reason: reason);
}

class DeviceStatusDto {
  final SensorReadingDto sensor;
  final TriggerSettingDto trigger;
  final RestrictionSettingDto restriction;
  final PumpDecisionDto decision;
  final bool pumpRunning;
  final bool timeSynchronized;

  const DeviceStatusDto({
    required this.sensor,
    required this.trigger,
    required this.restriction,
    required this.decision,
    required this.pumpRunning,
    required this.timeSynchronized,
  });

  factory DeviceStatusDto.fromJson(Map<String, dynamic> json) {
    return DeviceStatusDto(
      sensor: json['sensor'] is Map
          ? SensorReadingDto.fromJson(Map<String, dynamic>.from(json['sensor']))
          : const SensorReadingDto(
              soilMoisture: 0, airHumidity: 0, airTemperature: 0, lightIntensity: 0),
      trigger: json['trigger'] is Map
          ? TriggerSettingDto.fromJson(Map<String, dynamic>.from(json['trigger']))
          : const TriggerSettingDto(soilMoistureOperator: '<', soilMoistureValue: 30),
      restriction: json['restriction'] is Map
          ? RestrictionSettingDto.fromJson(
              Map<String, dynamic>.from(json['restriction']))
          : RestrictionSettingDto.fromDomain(RestrictionSetting.fallback),
      decision: json['decision'] is Map
          ? PumpDecisionDto.fromJson(Map<String, dynamic>.from(json['decision']))
          : const PumpDecisionDto(shouldRunPump: false, reason: '-'),
      pumpRunning: _bool(json['pumpRunning']),
      // Default true, karena firmware versi lama belum mengirim field
      // ini sama sekali; jangan sampai memicu warning waktu-tidak-sync
      // palsu.
      timeSynchronized: _bool(json['timeSynchronized'], true),
    );
  }

  DeviceStatus toDomain() => DeviceStatus(
        sensor: sensor.toDomain(),
        trigger: trigger.toDomain(),
        restriction: restriction.toDomain(),
        decision: decision.toDomain(),
        pumpRunning: pumpRunning,
        timeSynchronized: timeSynchronized,
      );
}

class SensorLogEntryDto {
  final int id;
  final DateTime? createdAt;
  final SensorReadingDto reading;
  final bool isIrrigationRun;

  const SensorLogEntryDto({
    required this.id,
    required this.createdAt,
    required this.reading,
    required this.isIrrigationRun,
  });

  factory SensorLogEntryDto.fromJson(Map<String, dynamic> json) {
    return SensorLogEntryDto(
      id: _int(json['id']),
      createdAt: _epochSeconds(json['createdAt']),
      reading: SensorReadingDto.fromJson(json),
      isIrrigationRun: _bool(json['isIrrigationRun']),
    );
  }

  SensorLogEntry toDomain() => SensorLogEntry(
        id: id,
        createdAt: createdAt,
        reading: reading.toDomain(),
        isIrrigationRun: isIrrigationRun,
      );
}

class IrrigationLogEntryDto {
  final int id;
  final DateTime? createdAt;
  final DateTime? runAt;
  final DateTime? stopAt;
  final int durationSecond;
  final double milliliter;

  const IrrigationLogEntryDto({
    required this.id,
    required this.createdAt,
    required this.runAt,
    required this.stopAt,
    required this.durationSecond,
    required this.milliliter,
  });

  factory IrrigationLogEntryDto.fromJson(Map<String, dynamic> json) {
    return IrrigationLogEntryDto(
      id: _int(json['id']),
      createdAt: _epochSeconds(json['createdAt']),
      runAt: _epochSeconds(json['irrigationRunAt']),
      stopAt: _epochSeconds(json['irrigationStopAt']),
      durationSecond: _int(json['irrigationDurationSecond']),
      milliliter: _num(json['irrigationMillilitre']),
    );
  }

  IrrigationLogEntry toDomain() => IrrigationLogEntry(
        id: id,
        createdAt: createdAt,
        runAt: runAt,
        stopAt: stopAt,
        durationSecond: durationSecond,
        milliliter: milliliter,
      );
}

class SyncMetadataDto {
  final String storageId;
  final int sensorLogLastId;
  final int irrigationLogLastId;
  final int sensorLogCount;
  final int irrigationLogCount;
  final int sensorLogFirstId;
  final int irrigationLogFirstId;

  const SyncMetadataDto({
    required this.storageId,
    required this.sensorLogLastId,
    required this.irrigationLogLastId,
    required this.sensorLogCount,
    required this.irrigationLogCount,
    required this.sensorLogFirstId,
    required this.irrigationLogFirstId,
  });

  factory SyncMetadataDto.fromJson(Map<String, dynamic> json) {
    return SyncMetadataDto(
      storageId: _str(json['storageId']),
      sensorLogLastId: _int(json['sensorLogLastId']),
      irrigationLogLastId: _int(json['irrigationLogLastId']),
      sensorLogCount: _int(json['sensorLogCount']),
      irrigationLogCount: _int(json['irrigationLogCount']),
      sensorLogFirstId: _int(json['sensorLogFirstId'], 1),
      irrigationLogFirstId: _int(json['irrigationLogFirstId'], 1),
    );
  }

  SyncMetadata toDomain() => SyncMetadata(
        storageId: storageId,
        sensorLogLastId: sensorLogLastId,
        irrigationLogLastId: irrigationLogLastId,
        sensorLogCount: sensorLogCount,
        irrigationLogCount: irrigationLogCount,
        sensorLogFirstId: sensorLogFirstId,
        irrigationLogFirstId: irrigationLogFirstId,
      );
}
