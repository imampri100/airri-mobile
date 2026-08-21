import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'logging_settings_service.dart';

// Interceptor Dio untuk mencatat request/response & error HTTP ke
// firmware ESP32. Status aktif/nonaktif dicek live tiap request
// (toggle di menu ⋮ Dashboard > Request Logging), jadi ganti setting
// tidak perlu restart app.
//
// Memakai debugPrint, bukan dart:developer log, supaya tetap terekam
// di Logcat Android / console flutter run walaupun app dibuka tanpa
// sesi debug yang terhubung ke VM service.
class HttpLoggingInterceptor extends Interceptor {
  final LoggingSettingsService _settings;

  HttpLoggingInterceptor(this._settings);

  static const _tag = '[HTTP]';

  String _bodyToString(dynamic data) {
    if (data == null) return '';
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_settings.enabled) {
      final body = _bodyToString(options.data);
      debugPrint(
        '$_tag → ${options.method} ${options.uri}${body.isEmpty ? '' : '\n  body: $body'}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_settings.enabled) {
      debugPrint(
        '$_tag ← ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri}\n  body: ${_bodyToString(response.data)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_settings.enabled) {
      final body = _bodyToString(err.response?.data);
      debugPrint(
        '$_tag ✗ ${err.response?.statusCode ?? err.type} ${err.requestOptions.method} '
        '${err.requestOptions.uri}\n  error: ${err.message}'
        '${body.isEmpty ? '' : '\n  body: $body'}',
      );
    }
    handler.next(err);
  }
}
