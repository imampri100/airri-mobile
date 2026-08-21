import 'package:dio/dio.dart';

import 'device_settings_service.dart';

// Client HTTP tipis untuk REST API firmware Smart Irrigation (ESP32),
// sesuai smart-irrigation-api.postman_collection.json.
//
// Base URL diambil ulang tiap request dari DeviceSettingsService. Jadi
// kalau alamat device diganti lewat menu ⋮, request selanjutnya
// langsung memakai alamat baru, tanpa perlu restart app.
class IrrigationApiClient {
  final Dio _dio;
  final DeviceSettingsService _deviceSettings;

  IrrigationApiClient(this._dio, this._deviceSettings);

  Options get _jsonOptions => Options(
        headers: {'Content-Type': 'application/json'},
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      );

  String _url(String path) => '${_deviceSettings.baseUrl}$path';

  // ---------- Ping ----------
  // Koneksi ringan saja, tidak membaca sensor/SD Card. Timeout sengaja
  // dibuat pendek karena ini dipoll terus-menerus, supaya tidak
  // menumpuk kalau device lambat/mati.
  Future<Response> ping() => _dio.get(
        _url('/api/ping'),
        options: _jsonOptions.copyWith(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

  // ---------- Status ----------
  Future<Response> getStatus() =>
      _dio.get(_url('/api/status'), options: _jsonOptions);

  // ---------- Logs ----------
  Future<Response> getSensorLogs({int lastId = 0, int limit = 50}) => _dio.get(
        _url('/api/logs/sensor'),
        queryParameters: {'lastId': lastId, 'limit': limit},
        options: _jsonOptions,
      );

  Future<Response> getIrrigationLogs({int lastId = 0, int limit = 50}) =>
      _dio.get(
        _url('/api/logs/irrigation'),
        queryParameters: {'lastId': lastId, 'limit': limit},
        options: _jsonOptions,
      );

  Future<Response> deleteAllLogs() =>
      _dio.delete(_url('/api/logs'), options: _jsonOptions);

  // ---------- Sync ----------
  Future<Response> getSyncMetadata() =>
      _dio.get(_url('/api/sync'), options: _jsonOptions);

  // ---------- Settings: Trigger ----------
  Future<Response> getTriggerSetting() =>
      _dio.get(_url('/api/settings/trigger'), options: _jsonOptions);

  Future<Response> updateTriggerSetting(Map<String, dynamic> body) =>
      _dio.put(_url('/api/settings/trigger'), data: body, options: _jsonOptions);

  // ---------- Settings: Language ----------
  Future<Response> updateLanguage(String code) => _dio.put(
        _url('/api/settings/language'),
        data: {'language': code},
        options: _jsonOptions,
      );

  // ---------- Settings: Restriction ----------
  Future<Response> getRestrictionSetting() =>
      _dio.get(_url('/api/settings/restriction'), options: _jsonOptions);

  Future<Response> updateRestrictionSetting(Map<String, dynamic> body) => _dio
      .put(_url('/api/settings/restriction'), data: body, options: _jsonOptions);

  // ---------- Pump ----------
  Future<Response> getPumpInfo() =>
      _dio.get(_url('/api/pump/info'), options: _jsonOptions);

  Future<Response> startPump() =>
      _dio.post(_url('/api/pump/start'), options: _jsonOptions);

  Future<Response> stopPump() =>
      _dio.post(_url('/api/pump/stop'), options: _jsonOptions);

  // Ini blocking, request tertahan selama durasi test berjalan.
  Future<Response> testPump({int durationSecond = 3}) => _dio.post(
        _url('/api/pump/test'),
        data: {'durationSecond': durationSecond},
        options: _jsonOptions.copyWith(
          sendTimeout: const Duration(seconds: 40),
          receiveTimeout: const Duration(seconds: 40),
        ),
      );

  // ---------- Maintenance ----------
  Future<Response> factoryReset() =>
      _dio.post(_url('/api/maintenance/factory-reset'), options: _jsonOptions);
}
