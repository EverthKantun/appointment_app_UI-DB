import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';

class AppointmentPage extends StatefulWidget {
  final String userId;
  final String? doctorId; 
  final String? doctorName; 
  final String? especialidad; 

  const AppointmentPage({
    super.key, 
    required this.userId,
    this.doctorId,
    this.doctorName,
    this.especialidad,
  });

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  final DatabaseService _db = DatabaseService();

  String? selectedEspecialidad;
  String? selectedMedicoId;
  String? selectedMedicoNombre;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    // 🔹 Si vienen parámetros desde DoctorsPage, los asignamos automáticamente
    if (widget.especialidad != null) {
      selectedEspecialidad = widget.especialidad;
    }
    if (widget.doctorId != null) {
      selectedMedicoId = widget.doctorId;
    }
    if (widget.doctorName != null) {
      selectedMedicoNombre = widget.doctorName;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year, now.month + 1, now.day),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _bookAppointment() async {
    if (selectedEspecialidad == null ||
        selectedMedicoId == null ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los campos"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final fecha =
        "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
    final hora =
        "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

    await _db.addAppointment({
      'fecha': fecha,
      'hora': hora,
      'id_paciente': widget.userId,
      'id_medico': selectedMedicoId,
      'nombre_medico': selectedMedicoNombre,
      'especialidad': selectedEspecialidad,
      'estado': 'pendiente',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cita agendada correctamente"),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Cita'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la sección
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Programar Nueva Cita',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),

              // 🔹 MOSTRAR INFORMACIÓN PRECARGADA SI VIENE DESDE DOCTORSPAGE
              if (widget.doctorName != null && widget.especialidad != null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.medical_services, 
                                 size: 20, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Información médica a agendar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPredefinedInfo(
                          'Médico seleccionado:',
                          widget.doctorName!,
                        ),
                        const SizedBox(height: 8),
                        _buildPredefinedInfo(
                          'Especialidad:',
                          widget.especialidad!,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Card para Especialidad (SOLO si NO viene predefinida)
              if (widget.especialidad == null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.medical_services, 
                                 size: 20, color: Colors.blueAccent),
                            SizedBox(width: 8),
                            Text(
                              'Especialidad',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('especialidades')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blueAccent),
                                ),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Text('No hay especialidades disponibles');
                            }
                            final especialidades = snapshot.data!.docs;
                            return DropdownButtonFormField<String>(
                              value: selectedEspecialidad,
                              items: especialidades
                                  .map<DropdownMenuItem<String>>((doc) {
                                final nombre = doc['nombre'] as String;
                                return DropdownMenuItem<String>(
                                  value: nombre,
                                  child: Text(
                                    nombre,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedEspecialidad = value;
                                  selectedMedicoId = null;
                                  selectedMedicoNombre = null;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Selecciona una especialidad',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              isExpanded: true,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Card para Médicos (solo se muestra si hay especialidad seleccionada Y NO viene predefinido)
              if (selectedEspecialidad != null && widget.doctorId == null)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person, size: 20, color: Colors.blueAccent),
                            SizedBox(width: 8),
                            Text(
                              'Médico',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('medicos')
                              .where('especialidad', 
                                    isEqualTo: selectedEspecialidad)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blueAccent),
                                ),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Text('Cargando médicos...');
                            }
                            final medicos = snapshot.data!.docs;
                            if (medicos.isEmpty) {
                              return const Text(
                                "No hay médicos en esta especialidad",
                                style: TextStyle(color: Colors.grey),
                              );
                            }
                            return DropdownButtonFormField<String>(
                              value: selectedMedicoId,
                              decoration: const InputDecoration(
                                labelText: "Selecciona un médico",
                                border: OutlineInputBorder(
                                  borderRadius: 
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              items: medicos.map((doc) {
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                    doc['nombre'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                final medico = medicos.firstWhere(
                                    (doc) => doc.id == value);
                                setState(() {
                                  selectedMedicoId = value;
                                  selectedMedicoNombre = medico['nombre'];
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Card para Fecha y Hora
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.calendar_today, 
                               size: 20, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text(
                            'Fecha y Hora',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Selector de Fecha
                      _buildDateTimeSelector(
                        icon: Icons.calendar_today,
                        label: 'Fecha',
                        value: selectedDate == null
                            ? "Seleccionar fecha"
                            : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                        onTap: _pickDate,
                      ),

                      const SizedBox(height: 12),

                      // Selector de Hora
                      _buildDateTimeSelector(
                        icon: Icons.access_time,
                        label: 'Hora',
                        value: selectedTime == null
                            ? "Seleccionar hora"
                            : selectedTime!.format(context),
                        onTap: _pickTime,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón de confirmación
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _bookAppointment,
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: const Text(
                    "Confirmar Cita",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: value.startsWith('Seleccionar') 
                          ? Colors.grey 
                          : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, 
                 size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildPredefinedInfo(String label, String value) {
    return Row(
      children: [
        Icon(Icons.check_circle, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}