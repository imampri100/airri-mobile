// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:airri_mobile/common/di/dio_di.dart' as _i146;
import 'package:airri_mobile/common/di/shared_preferences_di.dart' as _i25;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final sharedPreferencesDi = _$SharedPreferencesDi();
    final dioDi = _$DioDi();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => sharedPreferencesDi.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i361.Dio>(() => dioDi.dio);
    return this;
  }
}

class _$SharedPreferencesDi extends _i25.SharedPreferencesDi {}

class _$DioDi extends _i146.DioDi {}
