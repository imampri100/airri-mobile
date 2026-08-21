import 'entities.dart';
import 'irrigation_result.dart';

// Interface akses data ke firmware ESP32, sesuai
// smart-irrigation-api_postman_collection.json. Cubits & SyncService
// hanya bergantung pada interface ini; implementasi HTTP-nya ada di
// infrastructure/irrigation/irrigation_repository_impl.dart
abstract class IIrrigationRepository {
  // Cek koneksi ringan saja (GET /api/ping), untuk indikator koneksi
  // global, bukan untuk mengambil data.
  Future<IrrigationResult<bool>> ping();

  Future<IrrigationResult<DeviceStatus>> getStatus();

  Future<IrrigationResult<List<SensorLogEntry>>> getSensorLogs({
    int lastId = 0,
    int limit = 50,
  });

  Future<IrrigationResult<List<IrrigationLogEntry>>> getIrrigationLogs({
    int lastId = 0,
    int limit = 50,
  });

  Future<IrrigationResult<bool>> deleteAllLogs();

  Future<IrrigationResult<SyncMetadata>> getSyncMetadata();

  Future<IrrigationResult<TriggerSetting>> getTriggerSetting();

  Future<IrrigationResult<bool>> updateTriggerSetting(TriggerSetting setting);

  // Debit pompa (ml/menit), statis dari GET /api/pump/info. Konstanta
  // firmware, bukan setting yang bisa diubah.
  Future<IrrigationResult<double>> getPumpFlowRate();

  // Mengganti bahasa tampilan device (decision.reason & layar TFT)
  // mengikuti bahasa app. Kodenya "id" atau "en".
  Future<IrrigationResult<bool>> updateDeviceLanguage(String code);

  Future<IrrigationResult<RestrictionSetting>> getRestrictionSetting();

  Future<IrrigationResult<bool>> updateRestrictionSetting(
      RestrictionSetting setting);

  Future<IrrigationResult<bool>> startPump();

  Future<IrrigationResult<bool>> stopPump();

  Future<IrrigationResult<bool>> testPump({int durationSecond = 3});

  Future<IrrigationResult<bool>> factoryReset();
}
