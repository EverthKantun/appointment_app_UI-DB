import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class DoctorAppointmentsPage extends StatefulWidget {
  final String doctorId;
  const DoctorAppointmentsPage({super.key, required this.doctorId});

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  final DatabaseService _db = DatabaseService();
  bool loading = false;
  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => loading = true);

    try {
      final docs = await _db.getAppointmentsForDoctor(widget.doctorId);

      appointments = [];

      for (var d in docs) {
        final data = d.data() as Map<String, dynamic>;
        final patientId = data['id_paciente'];

        String nombrePaciente = "Paciente desconocido";

        try {
          final userSnap = await _db.getUser(patientId);
          if (userSnap.exists) {
            nombrePaciente = userSnap['nombre'] ?? nombrePaciente;
          }
        } catch (e) {
          debugPrint("Error cargando paciente: $e");
        }

        data['nombre_paciente'] = nombrePaciente;

        appointments.add({'id': d.id, 'data': data});
      }
    } catch (e) {
      debugPrint('Error doctor citas: $e');
    }

    setState(() => loading = false);
  }

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'atendida':
        return Colors.blue;
      case 'cancelada':
        return Colors.red;
      case 'reagendada':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Citas del Médico"),
        backgroundColor: Colors.blueAccent,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
              ? const Center(
                  child: Text(
                    "No hay citas programadas",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final cita = appointments[index];
                    final data = cita['data'];
                    final id = cita['id'];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/doctor-appointment-details',
                            arguments: {
                              'appointmentId': id,
                              'data': data,
                              'doctorId': widget.doctorId,
                            },
                          ).then((value) {
                            if (value == true) _loadAppointments();
                          });
                        },
                        title: Text(
                          data['nombre_paciente'] ?? 'Paciente desconocido',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${data['fecha']} — ${data['hora']}"),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 10,
                                    color: _estadoColor(data['estado'])),
                                const SizedBox(width: 6),
                                Text(
                                  data['estado'].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _estadoColor(data['estado']),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
