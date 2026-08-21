import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:airri_mobile/injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies(String env) async => await getIt.init(environment: env);
