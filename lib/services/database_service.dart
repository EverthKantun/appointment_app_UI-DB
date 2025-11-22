import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addUser(String uid, Map<String, dynamic> userData) async {
    await _db.collection('usuarios').doc(uid).set(userData);
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await _db.collection('usuarios').doc(uid).get();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('usuarios').doc(uid).update(data);
  }

  Future<void> addAppointment(Map<String, dynamic> appointmentData) async {
    await _db.collection('citas').add(appointmentData);
  }

  Stream<QuerySnapshot> getAppointments(String userId) {
    return _db
        .collection('citas')
        .where('id_paciente', isEqualTo: userId)
        .snapshots();
  }

  Future<void> updateAppointment(String citaId, Map<String, dynamic> data) async {
    await _db.collection('citas').doc(citaId).update(data);
  }

  Future<void> deleteAppointment(String citaId) async {
    await _db.collection('citas').doc(citaId).delete();
  }

  Stream<QuerySnapshot> getAvailableDoctors(String date) {
    return _db
        .collection('disponibilidad_medicos')
        .where('fecha', isEqualTo: date)
        .where('esta_disponible', isEqualTo: true)
        .snapshots();
  }

  Future<void> updateAvailability(String docId, bool available) async {
    await _db.collection('disponibilidad_medicos').doc(docId).update({
      'esta_disponible': available,
    });
  }

  // Total de citas del médico
  Stream<int> streamTotalAppointmentsForDoctor(String doctorId) {
    return _db
        .collection('citas')
        .where('id_medico', isEqualTo: doctorId)
        .snapshots()
        .map((snap) => snap.size);
  }

  // Total de citas pendientes del médico.
  Stream<int> streamPendingAppointmentsForDoctor(String doctorId) {
    return _db
        .collection('citas')
        .where('id_medico', isEqualTo: doctorId)
        .where('estado', isEqualTo: 'pendiente')
        .snapshots()
        .map((snap) => snap.size);
  }

  // Total de pacientes registrados.
  Stream<int> streamTotalPatients() {
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'paciente')
        .snapshots()
        .map((snap) => snap.size);
  }

  Future<List<String>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    final doctorDoc = await _db.collection('medicos').doc(doctorId).get();
    if (!doctorDoc.exists) return [];

    final disponibilidad = doctorDoc['disponibilidad'] as Map<String, dynamic>;
    final duracionCita = doctorDoc['duracion_cita'] ?? 30;

    final diasSemana = [
      'domingo',
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado'
    ];
    final diaSemana = diasSemana[date.weekday % 7];

    if (!disponibilidad.containsKey(diaSemana)) {
      return [];
    }

    final horarioDia = disponibilidad[diaSemana];
    final horaInicio = _timeToMinutes(horarioDia['inicio']);
    final horaFin = _timeToMinutes(horarioDia['fin']);

    final citasSnapshot = await _db
        .collection('citas')
        .where('id_medico', isEqualTo: doctorId)
        .where('fecha', isEqualTo: _formatDate(date))
        .where('estado', whereIn: ['pendiente', 'confirmada'])
        .get();

    final citasOcupadas = citasSnapshot.docs.map((doc) {
      return _timeToMinutes(doc['hora']);
    }).toList();

    final slotsDisponibles = <String>[];
    for (var time = horaInicio; time < horaFin; time += (duracionCita as int)) {
      if (!citasOcupadas.contains(time)) {
        slotsDisponibles.add(_minutesToTime(time));
      }
    }

    return slotsDisponibles;
  }

  Future<bool> isSlotAvailable({
    required String doctorId,
    required DateTime date,
    required String time,
  }) async {
    final availableSlots = await getAvailableSlots(
      doctorId: doctorId,
      date: date,
    );
    return availableSlots.contains(time);
  }

  Future<DocumentSnapshot> getDoctorById(String doctorId) async {
    return await _db.collection('medicos').doc(doctorId).get();
  }

  Future<List<QueryDocumentSnapshot>> getAppointmentsForDoctorOnDate(
      String doctorId, String fecha) async {
    final snapshot = await _db
        .collection('citas')
        .where('id_medico', isEqualTo: doctorId)
        .where('fecha', isEqualTo: fecha)
        .get();
    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot>> getAppointmentsForUserInRange(
      String userId, DateTime from, DateTime to) async {
    final snapshot = await _db
        .collection('citas')
        .where('id_paciente', isEqualTo: userId)
        .where('fecha', isGreaterThanOrEqualTo: _formatDate(from))
        .where('fecha', isLessThanOrEqualTo: _formatDate(to))
        .get();
    return snapshot.docs;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _minutesToTime(int minutes) {
    final hours = (minutes ~/ 60).toString().padLeft(2, '0');
    final mins = (minutes % 60).toString().padLeft(2, '0');
    return '$hours:$mins';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> addDoctor(String uid, Map<String, dynamic> doctorData) async {
    await _db.collection('medicos').doc(uid).set(doctorData);
  }

  Future<List<QueryDocumentSnapshot>> getAppointmentsForDoctor(
      String doctorId) async {
    final snapshot = await _db
        .collection('citas')
        .where('id_medico', isEqualTo: doctorId)
        .get();

    return snapshot.docs;
  }

  // Citas por estado (PieChart).
  Stream<Map<String, int>> streamAppointmentsCountByState(String doctorId) {
    return _db
        .collection('citas')
        .where('id_medico', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final map = {
        'pendiente': 0,
        'reagendada': 0,
        'cancelada': 0,
        'atendida': 0,
      };

      for (var doc in snap.docs) {
        final estado = doc['estado'] ?? '';
        if (map.containsKey(estado)) {
          map[estado] = map[estado]! + 1;
        }
      }
      return map;
    });
  }

  // Citas por mes (BarChart).
  Stream<Map<String, int>> streamAppointmentsPerMonth(
    String doctorId, {
    int monthsBack = 6,
  }) {
    final now = DateTime.now();
    final months = <String>[];

    for (int i = monthsBack - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      months.add(key);
    }

    return _db
        .collection('citas')
        .where('id_medico', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final result = {for (var m in months) m: 0};

      for (var doc in snap.docs) {
        final fecha = doc['fecha'];
        if (fecha != null && fecha.length >= 7) {
          final monthKey = fecha.substring(0, 7);
          if (result.containsKey(monthKey)) {
            result[monthKey] = result[monthKey]! + 1;
          }
        }
      }

      return result;
    });
  }

  // Citas por semana.
  Stream<Map<String, int>> streamAppointmentsPerWeek(
    String doctorId, {
    int weeksBack = 8,
  }) {
    final now = DateTime.now();
    final weekKeys = <String>[];

    for (int i = weeksBack - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i * 7));
      final week = isoWeekNumber(date);
      final key = '${date.year}-W${week.toString().padLeft(2, '0')}';
      weekKeys.add(key);
    }

    return _db
        .collection('citas')
        .where('id_medico', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final result = {for (var k in weekKeys) k: 0};

      for (var doc in snap.docs) {
        final fechaStr = doc['fecha'];
        if (fechaStr != null) {
          final date = DateTime.parse(fechaStr);
          final week = isoWeekNumber(date);
          final key = '${date.year}-W${week.toString().padLeft(2, '0')}';

          if (result.containsKey(key)) {
            result[key] = result[key]! + 1;
          }
        }
      }

      return result;
    });
  }

  /// Semana.
  int isoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat("D").format(date));
    final w = ((dayOfYear - date.weekday + 10) / 7).floor();
    return w;
  }

  /// Pacientes únicos del doctor.
  Future<int> getUniquePatientsCountForDoctor(String doctorId) async {
    final snap = await _db
        .collection('citas')
        .where('id_medico', isEqualTo: doctorId)
        .get();

    final setPacientes = <String>{};

    for (var doc in snap.docs) {
      final idPaciente = doc['id_paciente'];
      if (idPaciente != null) {
        setPacientes.add(idPaciente);
      }
    }

    return setPacientes.length;
  }
}
