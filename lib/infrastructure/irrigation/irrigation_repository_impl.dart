import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:airri_mobile/domain/irrigation/entities.dart';
import 'package:airri_mobile/domain/irrigation/i_irrigation_repository.dart';
import 'package:airri_mobile/domain/irrigation/irrigation_result.dart';

import 'irrigation_api_client.dart';
import 'irrigation_dtos.dart';

// Implementasi IIrrigationRepository lewat HTTP ke firmware ESP32
// (memakai IrrigationApiClient). Tugasnya menerjemahkan response JSON
// mentah (lewat DTO di irrigation_dtos.dart) jadi entity domain, dan
// error HTTP jadi pesan yang bisa dibaca user.
class IrrigationRepositoryImpl implements IIrrigationRepository {
  final IrrigationApiClient _client;

  IrrigationRepositoryImpl(this._client);

  String _friendlyError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'errors.device_timeout'.tr();
        case DioExceptionType.connectionError:
          return 'errors.device_unreachable'.tr();
        default:
          final status = e.response?.statusCode;
          final data = e.response?.data;
          if (data is Map && data['error'] != null) {
            return data['error'].toString();
          }
          if (status != null) {
            return 'errors.device_status_error'.tr(namedArgs: {'status': '$status'});
          }
          return 'errors.device_generic_error'.tr();
      }
    }
    return 'errors.unknown_error'.tr(namedArgs: {'error': '$e'});
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic data, {List<String> listKeys = const ['data', 'logs', 'items']}) {
    if (data is List) return data;
    if (data is Map) {
      for (final k in listKeys) {
        if (data[k] is List) return data[k] as List;
      }
    }
    return const [];
  }

  @override
  Future<IrrigationResult<bool>> ping() async {
    try {
      await _client.ping();
      return IrrigationResult.success(true);
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<DeviceStatus>> getStatus() async {
    try {
      final res = await _client.getStatus();
      return IrrigationResult.success(
          DeviceStatusDto.fromJson(_asMap(res.data)).toDomain());
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<List<SensorLogEntry>>> getSensorLogs({
    int lastId = 0,
    int limit = 50,
  }) async {
    try {
      final res =
          await _client.getSensorLogs(lastId: lastId, limit: limit);
      final list = _asList(res.data)
          .map((e) => SensorLogEntryDto.fromJson(_asMap(e)).toDomain())
          .toList();
      return IrrigationResult.success(list);
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<List<IrrigationLogEntry>>> getIrrigationLogs({
    int lastId = 0,
    int limit = 50,
  }) async {
    try {
      final res =
          await _client.getIrrigationLogs(lastId: lastId, limit: limit);
      final list = _asList(res.data)
          .map((e) => IrrigationLogEntryDto.fromJson(_asMap(e)).toDomain())
          .toList();
      return IrrigationResult.success(list);
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<bool>> deleteAllLogs() async {
    try {
      await _client.deleteAllLogs();
      return IrrigationResult.success(true);
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<SyncMetadata>> getSyncMetadata() async {
    try {
      final res = await _client.getSyncMetadata();
      return IrrigationResult.success(
          SyncMetadataDto.fromJson(_asMap(res.data)).toDomain());
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<TriggerSetting>> getTriggerSetting() async {
    try {
      final res = await _client.getTriggerSetting();
      return IrrigationResult.success(
          TriggerSettingDto.fromJson(_asMap(res.data)).toDomain());
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<bool>> updateTriggerSetting(
      TriggerSetting setting) async {
    try {
      await _client.updateTriggerSetting(
          TriggerSettingDto.fromDomain(setting).toApiJson());
      return IrrigationResult.success(true);
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<double>> getPumpFlowRate() async {
    try {
      final res = await _client.getPumpInfo();
      return IrrigationResult.success(
          PumpInfoDto.fromJson(_asMap(res.data)).flowRateMlPerMinute);
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<bool>> updateDeviceLanguage(String code) async {
    try {
      await _client.updateLanguage(code);
      return IrrigationResult.success(true);
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<RestrictionSetting>> getRestrictionSetting() async {
    try {
      final res = await _client.getRestrictionSetting();
      return IrrigationResult.success(
          RestrictionSettingDto.fromJson(_asMap(res.data)).toDomain());
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<bool>> updateRestrictionSetting(
      RestrictionSetting setting) async {
    try {
      await _client.updateRestrictionSetting(
          RestrictionSettingDto.fromDomain(setting).toApiJson());
      return IrrigationResult.success(true);
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<bool>> startPump() async {
    try {
      await _client.startPump();
      return IrrigationResult.success(true);
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<bool>> stopPump() async {
    try {
      await _client.stopPump();
      return IrrigationResult.success(true);
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<bool>> testPump({int durationSecond = 3}) async {
    try {
      await _client.testPump(durationSecond: durationSecond);
      return IrrigationResult.success(true);
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }

  @override
  Future<IrrigationResult<bool>> factoryReset() async {
    try {
      await _client.factoryReset();
      return IrrigationResult.success(true);
    } catch (e) {
      return IrrigationResult.failure(_friendlyError(e));
    }
  }
}
