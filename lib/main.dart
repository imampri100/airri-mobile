import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:airri_mobile/injection.dart';
import 'package:airri_mobile/presentation/pages/app_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await initializeDateFormatting('en_US');

  // Environment dev/prod/test dipilih sesuai build mode.
  await configureDependencies(
    kReleaseMode ? Environment.prod : Environment.dev,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      fallbackLocale: const Locale('id', 'ID'),
      // Default selalu bahasa Indonesia, tidak mengikuti locale HP.
      // Ganti bahasa manual lewat menu ⋮, lalu tersimpan otomatis untuk
      // sesi berikutnya (preferensi disimpan oleh easy_localization).
      startLocale: const Locale('id', 'ID'),
      path: 'assets/translations',
      child: const AppWidget(),
    ),
  );
}
