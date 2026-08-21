import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@module
abstract class DioDi {
  @lazySingleton
  Dio get dio => Dio(
        BaseOptions(
          // Supaya tidak hang lama saat device sama sekali tidak
          // terhubung (sendTimeout/receiveTimeout tidak menutup fase
          // koneksi TCP).
          connectTimeout: const Duration(seconds: 8),
        ),
      );
}
