import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class DoctorAppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> data;
  final String doctorId;

  const DoctorAppointmentDetailsPage({
    super.key,
    required this.appointmentId,
    required this.data,
    required this.doctorId,
  });

  @override
  State<DoctorAppointmentDetailsPage> createState() =>
      _DoctorAppointmentDetailsPageState();
}

class _DoctorAppointmentDetailsPageState
    extends State<DoctorAppointmentDetailsPage> {
  final DatabaseService _db = DatabaseService();

  String? selectedStatus;
  String? pacienteNombre;
  String? especialidadMedico;
  TextEditingController notaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.data['estado'];
    notaController.text = widget.data['nota_medica'] ?? "";
    _loadPatientName();
    _loadDoctorSpecialty(); 
  }

  Future<void> _loadPatientName() async {
    final pacienteId = widget.data['id_paciente'];
    final snap = await _db.getUser(pacienteId);

    setState(() {
      pacienteNombre = snap['nombre'] ?? "Paciente";
    });
  }

  // Cargar la especialidad del médico
  Future<void> _loadDoctorSpecialty() async {
    final doctorSnap = await _db.getDoctorById(widget.doctorId);

    if (doctorSnap.exists) {
      setState(() {
        especialidadMedico = doctorSnap['especialidad'] ?? "No definida";
      });
    }
  }

  Future<void> _updateAppointment() async {
    await _db.updateAppointment(widget.appointmentId, {
      'estado': selectedStatus,
      'nota_medica': notaController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cita actualizada correctamente"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles de Cita"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Paciente:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(pacienteNombre ?? "Cargando..."),
            const SizedBox(height: 20),

            const Text(
              "Especialidad:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(especialidadMedico ?? "Cargando..."), 
            const SizedBox(height: 20),

            const Text(
              "Fecha:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(d['fecha']),
            const SizedBox(height: 20),

            const Text(
              "Hora:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(d['hora']),
            const SizedBox(height: 20),

            const Text(
              "Motivo de consulta:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(d['motivo_consulta']),
            const SizedBox(height: 20),

            const Text(
              "Nota médica:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),

            TextField(
              controller: notaController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Escribe tu nota médica...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              "Cambiar estado:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),

            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'reagendada', child: Text('Reagendada')),
                DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                DropdownMenuItem(value: 'atendida', child: Text('Atendida')),
              ],
              onChanged: (v) => setState(() => selectedStatus = v),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateAppointment,
                icon: const Icon(Icons.check_circle),
                label: const Text("Guardar Cambios"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
