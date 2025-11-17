import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/database_service.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DatabaseService _db;
  final String doctorId;

  StreamSubscription<int>? _totalSub;
  StreamSubscription<int>? _pendingSub;
  StreamSubscription<int>? _patientsSub;

  DashboardCubit({required DatabaseService databaseService, required this.doctorId})
      : _db = databaseService,
        super(DashboardState.initial()) {
    _startListening();
  }

  void _startListening() {
    // total citas para doctor
    _totalSub = _db.streamTotalAppointmentsForDoctor(doctorId).listen((count) {
      emit(state.copyWith(totalAppointments: count, loading: false));
    });

    // citas pendientes
    _pendingSub = _db.streamPendingAppointmentsForDoctor(doctorId).listen((count) {
      emit(state.copyWith(pendingAppointments: count, loading: false));
    });

    // total pacientes (global)
    _patientsSub = _db.streamTotalPatients().listen((count) {
      emit(state.copyWith(totalPatients: count, loading: false));
    });
  }

  @override
  Future<void> close() {
    _totalSub?.cancel();
    _pendingSub?.cancel();
    _patientsSub?.cancel();
    return super.close();
  }
}
