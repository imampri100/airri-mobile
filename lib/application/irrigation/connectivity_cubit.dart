import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:airri_mobile/domain/irrigation/i_irrigation_repository.dart';

enum ConnectivityPhase { checking, connected, offline }

class ConnectivityState {
  final ConnectivityPhase phase;
  const ConnectivityState(this.phase);
}

/// Badge koneksi di header, muncul di semua tab. Poll GET /api/ping
/// sendiri tiap beberapa detik, tidak menumpang ke DashboardCubit karena
/// cubit itu hanya refresh saat halaman Beranda dibuka.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  static const _interval = Duration(seconds: 15);

  final IIrrigationRepository _repo;
  Timer? _timer;
  bool _checking = false;

  ConnectivityCubit(this._repo)
      : super(const ConnectivityState(ConnectivityPhase.checking)) {
    _check();
    _timer = Timer.periodic(_interval, (_) => _check());
  }

  Future<void> _check() async {
    if (_checking || isClosed) return;
    _checking = true;
    final result = await _repo.ping();
    _checking = false;
    if (isClosed) return;
    emit(ConnectivityState(
      result.isSuccess ? ConnectivityPhase.connected : ConnectivityPhase.offline,
    ));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
