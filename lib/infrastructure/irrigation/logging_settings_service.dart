import 'package:shared_preferences/shared_preferences.dart';

// Preferensi on/off logging request/response HTTP ke firmware ESP32,
// untuk debug konektivitas tanpa perlu rebuild app. Default off, karena
// payload yang terus masuk (misalnya tiap refresh dashboard) bisa
// membanjiri console saat sedang tidak dibutuhkan.
class LoggingSettingsService {
  static const _key = 'irrigation_http_logging_enabled';

  final SharedPreferences _prefs;

  LoggingSettingsService(this._prefs);

  bool get enabled => _prefs.getBool(_key) ?? false;

  Future<void> setEnabled(bool value) => _prefs.setBool(_key, value);
}
