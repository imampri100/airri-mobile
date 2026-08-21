import 'package:shared_preferences/shared_preferences.dart';

// Menyimpan base URL ESP32 secara lokal. Berbeda dari aplikasi RVM
// sebelumnya, base URL di sini tidak tetap karena device bisa punya
// IP berbeda-beda tergantung WiFi yang sedang tersambung.
class DeviceSettingsService {
  static const _key = 'irrigation_device_base_url';
  static const defaultBaseUrl = 'http://192.168.4.1';

  final SharedPreferences _prefs;

  DeviceSettingsService(this._prefs);

  String get baseUrl => _prefs.getString(_key) ?? defaultBaseUrl;

  Future<void> setBaseUrl(String value) async {
    final trimmed = value.trim();
    final normalized =
        trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    await _prefs.setString(_key, normalized.isEmpty ? defaultBaseUrl : normalized);
  }
}
