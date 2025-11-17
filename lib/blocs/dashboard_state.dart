import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  final int totalAppointments;
  final int pendingAppointments;
  final int totalPatients;
  final bool loading;

  const DashboardState({
    required this.totalAppointments,
    required this.pendingAppointments,
    required this.totalPatients,
    required this.loading,
  });

  factory DashboardState.initial() => const DashboardState(
        totalAppointments: 0,
        pendingAppointments: 0,
        totalPatients: 0,
        loading: true,
      );

  DashboardState copyWith({
    int? totalAppointments,
    int? pendingAppointments,
    int? totalPatients,
    bool? loading,
  }) {
    return DashboardState(
      totalAppointments: totalAppointments ?? this.totalAppointments,
      pendingAppointments: pendingAppointments ?? this.pendingAppointments,
      totalPatients: totalPatients ?? this.totalPatients,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props =>
      [totalAppointments, pendingAppointments, totalPatients, loading];
}
