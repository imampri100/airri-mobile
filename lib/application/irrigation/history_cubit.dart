import 'package:bloc/bloc.dart';

import 'package:airri_mobile/domain/irrigation/entities.dart';

import 'sync_service.dart';

enum HistoryItemType { irrigation, sensor, gap }

// Satu baris riwayat, hanya data mentah. Title/subtitle dirangkai di
// presentation layer (history_page.dart) supaya gampang diterjemahkan.
class HistoryItem {
  final HistoryItemType type;
  final DateTime? timestamp;

  // type == irrigation
  final int? durationSecond;
  final double? milliliter;

  // type == sensor
  final bool isIrrigationRun;
  final SensorReading? reading;

  // type == gap
  final String? gapLogType; // 'sensor' | 'irrigation'
  final int? gapMissingCount;
  final int? gapFromId;
  final int? gapToId;

  const HistoryItem({
    required this.type,
    required this.timestamp,
    this.durationSecond,
    this.milliliter,
    this.isIrrigationRun = false,
    this.reading,
    this.gapLogType,
    this.gapMissingCount,
    this.gapFromId,
    this.gapToId,
  });
}

enum HistoryPhase { loading, syncing, loaded, error }

class HistoryState {
  final HistoryPhase phase;
  final List<HistoryItem> items;
  final String? errorMessage;

  // Tanggal filter dari date picker. Null berarti tidak difilter,
  // menampilkan linimasa terbaru.
  final DateTime? selectedDate;

  const HistoryState({
    required this.phase,
    this.items = const [],
    this.errorMessage,
    this.selectedDate,
  });

  factory HistoryState.initial() =>
      const HistoryState(phase: HistoryPhase.loading);

  HistoryState copyWith({
    HistoryPhase? phase,
    List<HistoryItem>? items,
    String? errorMessage,
  }) {
    return HistoryState(
      phase: phase ?? this.phase,
      items: items ?? this.items,
      errorMessage: errorMessage,
      selectedDate: selectedDate,
    );
  }

  // Dipisah dari copyWith karena selectedDate perlu bisa di-set balik
  // ke null (clear filter); pola `param ?? this.param` tidak bisa
  // membedakan itu dari "tidak diisi".
  HistoryState withDate(DateTime? date) => HistoryState(
        phase: phase,
        items: items,
        errorMessage: errorMessage,
        selectedDate: date,
      );
}

// History dibaca dari local storage, bukan langsung ke device, jadi
// riwayat lama tetap utuh meski device sudah menghapus (purge) lognya
// sendiri (lihat storage.md). refresh() melakukan sync incremental dulu
// (termasuk deteksi gap), baru membaca ulang dari local. selectDate()
// berbeda, hanya query ulang ke data lokal yang sudah ada tanpa sync,
// jadi instan untuk fitur "lompat ke tanggal" saat datanya sudah ribuan
// baris.
class HistoryCubit extends Cubit<HistoryState> {
  final SyncService _syncService;

  HistoryCubit(this._syncService) : super(HistoryState.initial());

  Future<void> refresh() async {
    emit(state.copyWith(
      phase: state.items.isEmpty ? HistoryPhase.loading : HistoryPhase.syncing,
    ));

    final summary = await _syncService.sync();

    // Baca local store tetap jalan walau sync gagal (device offline
    // misalnya) - data lama yang sudah tersimpan di SQLite tetap harus
    // ditampilkan. Tidak bisa mengecek state.items di memori untuk tahu
    // ada data lokal atau tidak, karena saat cold start itu pasti kosong
    // duluan.
    await _loadFromLocal(
      syncErrorMessage: summary.isSuccess ? null : summary.errorMessage,
    );
  }

  Future<void> selectDate(DateTime? date) async {
    // Kosongkan items dulu, supaya saat ganti tanggal tidak menampilkan
    // sisa baris dari tanggal sebelumnya sambil loading.
    emit(state.withDate(date).copyWith(
          phase: HistoryPhase.loading,
          items: const [],
        ));
    await _loadFromLocal();
  }

  Future<void> _loadFromLocal({String? syncErrorMessage}) async {
    final date = state.selectedDate;
    final from = date == null ? null : DateTime(date.year, date.month, date.day);
    final to = date == null
        ? null
        : DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final irrigationLogs =
        await _syncService.localIrrigationLogs(from: from, to: to);
    final sensorLogs = await _syncService.localSensorLogs(from: from, to: to);
    final gaps = await _syncService.localGaps();
    final relevantGaps = date == null
        ? gaps
        : gaps
            .where((g) =>
                g.anchorAt != null &&
                !g.anchorAt!.isBefore(from!) &&
                !g.anchorAt!.isAfter(to!))
            .toList();

    final items = <HistoryItem>[
      ...irrigationLogs.map(
        (e) => HistoryItem(
          type: HistoryItemType.irrigation,
          timestamp: e.runAt ?? e.createdAt,
          durationSecond: e.durationSecond,
          milliliter: e.milliliter,
        ),
      ),
      ...sensorLogs.map(
        (e) => HistoryItem(
          type: HistoryItemType.sensor,
          timestamp: e.createdAt,
          isIrrigationRun: e.isIrrigationRun,
          reading: e.reading,
        ),
      ),
      ...relevantGaps.map(
        (g) => HistoryItem(
          type: HistoryItemType.gap,
          timestamp: g.anchorAt,
          gapLogType: g.logType,
          gapMissingCount: g.missingCount,
          gapFromId: g.fromId,
          gapToId: g.toId,
        ),
      ),
    ];

    items.sort((a, b) {
      if (a.timestamp == null || b.timestamp == null) return 0;
      return b.timestamp!.compareTo(a.timestamp!);
    });

    // Halaman error penuh hanya muncul kalau benar-benar tidak ada
    // apa-apa untuk ditampilkan DAN sync gagal. Kalau local store masih
    // ada isinya, tetap tampilkan itu; errorMessage tetap dikirim supaya
    // UI bisa memberi notice kecil tanpa menyembunyikan data yang sudah
    // ada.
    emit(state.copyWith(
      phase: items.isEmpty && syncErrorMessage != null
          ? HistoryPhase.error
          : HistoryPhase.loaded,
      items: items,
      errorMessage: syncErrorMessage,
    ));
  }
}
