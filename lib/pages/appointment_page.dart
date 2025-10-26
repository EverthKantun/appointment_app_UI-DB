import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../utils/schedule_utils.dart';

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
  final TextEditingController _motivoController = TextEditingController();

  String? selectedEspecialidad;
  String? selectedMedicoId;
  String? selectedMedicoNombre;
  DateTime? selectedDate;
  String? selectedTime; 
  Map<String, dynamic>? disponibilidad;
  List<String> availableSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.especialidad != null) selectedEspecialidad = widget.especialidad;
    if (widget.doctorId != null) {
      selectedMedicoId = widget.doctorId;
      _loadDisponibilidad(widget.doctorId!);
    }
    if (widget.doctorName != null) selectedMedicoNombre = widget.doctorName;
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  // Carga la disponibilidad del médico
  Future<void> _loadDisponibilidad(String medicoId) async {
    final doc = await FirebaseFirestore.instance
        .collection('medicos')
        .doc(medicoId)
        .get();

    if (doc.exists && doc.data()!.containsKey('disponibilidad')) {
      setState(() {
        disponibilidad = doc['disponibilidad'] as Map<String, dynamic>;
      });
    }
  }

  // Mapea día numérico a texto
  String _diaSemana(int weekday) {
    switch (weekday) {
      case 1: return 'lunes';
      case 2: return 'martes';
      case 3: return 'miercoles';
      case 4: return 'jueves';
      case 5: return 'viernes';
      case 6: return 'sabado';
      case 7: return 'domingo';
      default: return '';
    }
  }

  // VALIDACIÓN: Verifica si el slot está disponible
  Future<bool> _isSlotAvailable(String time) async {
    if (selectedMedicoId == null || selectedDate == null) return false;
    
    final fecha = formatFecha(selectedDate!);
    
    try {
      final citas = await _db.getAppointmentsForDoctorOnDate(selectedMedicoId!, fecha);
      final citasOcupadas = citas.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['hora'] as String;
      }).toList();
      
      return !citasOcupadas.contains(time);
    } catch (e) {
      return true; 
    }
  }

  // Carga los slots disponibles con validación
  Future<void> _loadAvailableSlots() async {
    if (selectedDate == null || disponibilidad == null || selectedMedicoId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      availableSlots = [];
      selectedTime = null;
    });

    final dia = _diaSemana(selectedDate!.weekday);
    if (!disponibilidad!.containsKey(dia)) {
      setState(() {
        _isLoading = false;
        availableSlots = [];
      });
      return;
    }

    final horario = disponibilidad![dia];
    if (horario == null) {
      setState(() {
        _isLoading = false;
        availableSlots = [];
      });
      return;
    }

    final inicio = horario['inicio'] as String? ?? '09:00';
    final fin = horario['fin'] as String? ?? '17:00';

    // Generar todos los slots 
    final allSlots = generateSlots(inicio, fin);

    // Filtrar slots ocupados
    final fecha = formatFecha(selectedDate!);
    final citas = await _db.getAppointmentsForDoctorOnDate(selectedMedicoId!, fecha);
    final slotsOcupados = citas.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['hora'] as String;
    }).toSet();

    final slotsDisponibles = allSlots.where((slot) => !slotsOcupados.contains(slot)).toList();

    setState(() {
      availableSlots = slotsDisponibles;
      _isLoading = false;
    });
  }

  // Pickers
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year, now.month + 1, now.day),
    );
    
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTime = null;
      });
      await _loadAvailableSlots();
    }
  }

  // Agendar cita con validación
  Future<void> _bookAppointment() async {
    if (selectedEspecialidad == null ||
        selectedMedicoId == null ||
        selectedDate == null ||
        selectedTime == null ||
        _motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los campos"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // VALIDACIÓN FINAL: Verificar que el slot siga disponible
    final isAvailable = await _isSlotAvailable(selectedTime!);
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Este horario ya no está disponible. Por favor selecciona otro."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadAvailableSlots(); 
      return;
    }

    final fecha = formatFecha(selectedDate!);
    
    setState(() => _isLoading = true);

    try {
      await _db.addAppointment({
        'fecha': fecha,
        'hora': selectedTime!,
        'id_paciente': widget.userId,
        'id_medico': selectedMedicoId,
        'nombre_medico': selectedMedicoNombre,
        'especialidad': selectedEspecialidad,
        'estado': 'pendiente',
        'motivo_consulta': _motivoController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cita agendada correctamente"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al agendar cita: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Programar Nueva Cita',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Información médica precargada
                    if (widget.doctorName != null && widget.especialidad != null)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.medical_services, size: 20, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Información médica',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildPredefinedInfo('Médico:', widget.doctorName!),
                              const SizedBox(height: 8),
                              _buildPredefinedInfo('Especialidad:', widget.especialidad!),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Dropdown Especialidad
                    if (widget.especialidad == null)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Especialidad',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                              ),
                              const SizedBox(height: 12),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('especialidades').snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData) return const Text('No hay especialidades');
                                  final docs = snapshot.data!.docs;
                                  return DropdownButtonFormField<String>(
                                    value: selectedEspecialidad,
                                    items: docs.map((doc) {
                                      final nombre = doc['nombre'] as String;
                                      return DropdownMenuItem<String>(value: nombre, child: Text(nombre));
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedEspecialidad = value;
                                        selectedMedicoId = null;
                                        selectedMedicoNombre = null;
                                        disponibilidad = null;
                                        selectedDate = null;
                                        selectedTime = null;
                                        availableSlots = [];
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Selecciona especialidad',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Dropdown Médicos
                    if (selectedEspecialidad != null && widget.doctorId == null)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Médico',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                              ),
                              const SizedBox(height: 12),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('medicos')
                                    .where('especialidad', isEqualTo: selectedEspecialidad)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData) return const SizedBox();
                                  final docs = snapshot.data!.docs;
                                  if (docs.isEmpty) {
                                    return const Text('No hay médicos disponibles', style: TextStyle(color: Colors.grey));
                                  }
                                  return DropdownButtonFormField<String>(
                                    value: selectedMedicoId,
                                    items: docs.map((doc) {
                                      return DropdownMenuItem<String>(value: doc.id, child: Text(doc['nombre']));
                                    }).toList(),
                                    onChanged: (value) {
                                      final medico = docs.firstWhere((doc) => doc.id == value);
                                      setState(() {
                                        selectedMedicoId = value;
                                        selectedMedicoNombre = medico['nombre'];
                                        disponibilidad = medico['disponibilidad'] as Map<String, dynamic>?;
                                        selectedDate = null;
                                        selectedTime = null;
                                        availableSlots = [];
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Selecciona médico',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Campo para motivo de consulta
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Motivo de consulta',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _motivoController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Describe brevemente tu motivo...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Fecha y Hora
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha y Hora',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                            ),
                            const SizedBox(height: 16),
                            
                            // Selector de Fecha
                            _buildDateTimeSelector(
                              icon: Icons.calendar_today,
                              label: 'Fecha',
                              value: selectedDate == null
                                  ? 'Seleccionar fecha'
                                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                              onTap: _pickDate,
                            ),
                            
                            const SizedBox(height: 16),

                            // Se muestra la hora seleccionada
                            if (selectedTime != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, color: Colors.blueAccent, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Hora seleccionada: $selectedTime',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 16),

                            // SLOTS DISPONIBLES
                            if (selectedDate != null && disponibilidad != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Horarios Disponibles:',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  if (_isLoading)
                                    const Center(child: CircularProgressIndicator())
                                  else if (availableSlots.isEmpty)
                                    const Text(
                                      'No hay horarios disponibles para esta fecha',
                                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                    )
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: availableSlots.map((slot) {
                                        final isSelected = selectedTime == slot;
                                        return GestureDetector(
                                          onTap: () => setState(() => selectedTime = slot),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.blueAccent : Colors.grey[50],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSelected ? Colors.blueAccent : Colors.grey[300]!,
                                              ),
                                            ),
                                            child: Text(
                                              slot,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botón Confirmar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _bookAppointment,
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Confirmar Cita"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        padding: const EdgeInsets.all(12),
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: value.startsWith('Seleccionar') ? Colors.grey : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildPredefinedInfo(String label, String value) {
    return Row(
      children: [
        const Icon(Icons.check_circle, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}