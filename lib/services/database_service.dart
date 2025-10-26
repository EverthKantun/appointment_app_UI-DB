import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Genera los horarios (slots) disponibles para un médico en una fecha.
  Future<List<String>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    final doctorDoc = await _db.collection('medicos').doc(doctorId).get();
    if (!doctorDoc.exists) return [];

    final disponibilidad = doctorDoc['disponibilidad'] as Map<String, dynamic>;
    final duracionCita = doctorDoc['duracion_cita'] ?? 30;

    // Día de la semana (domingo=0 → sábado=6)
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

    // Verificar si el médico trabaja ese día
    if (!disponibilidad.containsKey(diaSemana)) {
      return [];
    }

    final horarioDia = disponibilidad[diaSemana];
    final horaInicio = _timeToMinutes(horarioDia['inicio']);
    final horaFin = _timeToMinutes(horarioDia['fin']);

    // Citas ya agendadas ese día
    final citasSnapshot = await _db
        .collection('citas')
        .where('id_medico', isEqualTo: doctorId)
        .where('fecha', isEqualTo: _formatDate(date))
        .where('estado', whereIn: ['pendiente', 'confirmada'])
        .get();

    final citasOcupadas = citasSnapshot.docs.map((doc) {
      return _timeToMinutes(doc['hora']);
    }).toList();

    // Generar slots disponibles
    final slotsDisponibles = <String>[];
    for (var time = horaInicio; time < horaFin; time += (duracionCita as int)) {
      if (!citasOcupadas.contains(time)) {
        slotsDisponibles.add(_minutesToTime(time));
      }
    }

    return slotsDisponibles;
  }

  /// Verifica si un horario está disponible para agendar.
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

  /// Obtener un médico por su ID
  Future<DocumentSnapshot> getDoctorById(String doctorId) async {
    return await _db.collection('medicos').doc(doctorId).get();
  }

  /// Obtener citas de un médico en una fecha específica
  Future<List<QueryDocumentSnapshot>> getAppointmentsForDoctorOnDate(
      String doctorId, String fecha) async {
    final snapshot = await _db
        .collection('citas')
        .where('id_medico', isEqualTo: doctorId)
        .where('fecha', isEqualTo: fecha)
        .get();
    return snapshot.docs;
  }

  /// Obtener citas de un usuario dentro de un rango de fechas
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
}
