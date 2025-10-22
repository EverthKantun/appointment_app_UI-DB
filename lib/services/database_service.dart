import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // USUARIOS
  Future<void> addUser(String uid, Map<String, dynamic> userData) async {
    await _db.collection('usuarios').doc(uid).set(userData);
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await _db.collection('usuarios').doc(uid).get();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('usuarios').doc(uid).update(data);
  }

  // CITAS
  Future<void> addAppointment(Map<String, dynamic> appointmentData) async {
    await _db.collection('citas').add(appointmentData);
  }

  Stream<QuerySnapshot> getAppointments(String userId) {
    return _db
        .collection('citas')
        .where('id_paciente', isEqualTo: userId)
        .snapshots();
  }

  /// DISPONIBILIDAD MÉDICOS
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
}
