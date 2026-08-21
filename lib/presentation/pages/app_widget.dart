import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:airri_mobile/application/irrigation/sync_service.dart';
import 'package:airri_mobile/domain/irrigation/i_irrigation_repository.dart';
import 'package:airri_mobile/infrastructure/irrigation/device_settings_service.dart';
import 'package:airri_mobile/infrastructure/irrigation/http_logging_interceptor.dart';
import 'package:airri_mobile/infrastructure/irrigation/irrigation_api_client.dart';
import 'package:airri_mobile/infrastructure/irrigation/irrigation_repository_impl.dart';
import 'package:airri_mobile/infrastructure/irrigation/local/irrigation_local_store.dart';
import 'package:airri_mobile/infrastructure/irrigation/logging_settings_service.dart';
import 'package:airri_mobile/presentation/pages/irrigation/irrigation_shell.dart';
import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';
import 'package:airri_mobile/injection.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Root widget app, langsung ke IrrigationShell. Tidak ada auth/routing
// multi-halaman karena app ini device companion single-purpose saja
// (lihat storage.md & smart-irrigation-api collection).
//
// Implementasi konkret infrastructure layer dirakit di sini (Dio untuk
// IrrigationRepositoryImpl, SQLite untuk IrrigationLocalStore), baru
// diteruskan ke application/presentation layer lewat interface
// domainnya. Satu-satunya tempat di app yang tahu implementasi
// konkretnya.
class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  late final IIrrigationRepository _repository;
  late final DeviceSettingsService _deviceSettings;
  late final LoggingSettingsService _loggingSettings;
  late final SyncService _syncService;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    _deviceSettings = DeviceSettingsService(getIt<SharedPreferences>());
    _loggingSettings = LoggingSettingsService(getIt<SharedPreferences>());
    final dio = getIt<Dio>()
      ..interceptors.add(HttpLoggingInterceptor(_loggingSettings));
    final apiClient = IrrigationApiClient(dio, _deviceSettings);
    _repository = IrrigationRepositoryImpl(apiClient);
    _syncService = SyncService(_repository, IrrigationLocalStore());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'airri',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: IrrigationColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: IrrigationColors.green600,
          primary: IrrigationColors.green600,
        ),
        fontFamily: 'Roboto',
      ),
      home: IrrigationShell(
        repository: _repository,
        deviceSettings: _deviceSettings,
        loggingSettings: _loggingSettings,
        syncService: _syncService,
      ),
    );
  }
}
