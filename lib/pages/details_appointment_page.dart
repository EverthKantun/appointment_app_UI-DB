import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../utils/schedule_utils.dart';

class DetailsAppointmentPage extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> data;
  final String userId;

  const DetailsAppointmentPage({
    super.key,
    required this.appointmentId,
    required this.data,
    required this.userId,
  });

  @override
  State<DetailsAppointmentPage> createState() => _DetailsAppointmentPageState();
}

class _DetailsAppointmentPageState extends State<DetailsAppointmentPage> {
  final DatabaseService _db = DatabaseService();
  bool loading = false;
  DateTime? selectedDate;
  List<String> availableSlots = [];
  String? selectedSlot;
  Map<String, dynamic>? doctorData;

  @override
  void initState() {
    super.initState();
    final f = widget.data['fecha'] as String?;
    if (f != null) {
      final parts = f.split('-');
      if (parts.length == 3) {
        selectedDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    }
    selectedSlot = widget.data['hora'] as String?;
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    final docId = widget.data['id_medico'] as String?;
    if (docId == null) return;
    final doc = await _db.getDoctorById(docId);
    if (!doc.exists) return;
    setState(() {
      doctorData = doc.data() as Map<String, dynamic>?;
    });
  }

  Future<void> _pickDateAndLoadSlots() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year, now.month + 3, now.day),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        availableSlots = [];
        selectedSlot = null;
        loading = true;
      });
      await _generateSlots(picked);
    }
  }

  Future<void> _generateSlots(DateTime date) async {
    final doctorId = widget.data['id_medico'] as String?;
    if (doctorId == null) return;

    if (doctorData == null) {
      final doc = await _db.getDoctorById(doctorId);
      doctorData = doc.data() as Map<String, dynamic>?;
    }

    final disp = doctorData?['disponibilidad'];
    if (disp == null || disp is! Map) {
      setState(() {
        availableSlots = [];
        loading = false;
      });
      return;
    }

    final weekdayToName = {
      1: 'lunes',
      2: 'martes',
      3: 'miercoles',
      4: 'jueves',
      5: 'viernes',
      6: 'sabado',
      7: 'domingo',
    };

    final dia = weekdayToName[date.weekday];
    if (dia == null || !disp.containsKey(dia)) {
      setState(() {
        availableSlots = [];
        loading = false;
      });
      return;
    }

    final entry = disp[dia];
    final start = entry['inicio'] as String;
    final end = entry['fin'] as String;
    final allSlots = generateSlots(start, end, minutes: 30);

    final fechaStr = formatFecha(date);
    final takenDocs = await _db.getAppointmentsForDoctorOnDate(doctorId, fechaStr);
    final takenTimes = takenDocs
        .map((d) => (d.data() as Map<String, dynamic>)['hora'] as String)
        .toSet();

    final myHora = widget.data['hora'] as String?;
    final free = allSlots.where((s) => !takenTimes.contains(s) || s == myHora).toList();

    setState(() {
      availableSlots = free;
      loading = false;
    });
  }

  Future<void> _saveChanges() async {
    if (selectedDate == null || selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona fecha y hora'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fecha = formatFecha(selectedDate!);
    final hora = selectedSlot!;
    final doctorId = widget.data['id_medico'] as String;

    final taken = await _db.getAppointmentsForDoctorOnDate(doctorId, fecha);
    final takenTimes = taken
        .where((d) => d.id != widget.appointmentId)
        .map((d) => (d.data() as Map<String, dynamic>)['hora'] as String)
        .toSet();

    if (takenTimes.contains(hora)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este horario ya está ocupado'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _generateSlots(selectedDate!);
      return;
    }

    await _db.updateAppointment(widget.appointmentId, {
      'fecha': fecha,
      'hora': hora,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cita actualizada correctamente'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, true);
  }

  Future<void> _deleteAppointment() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Cancelar Cita',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: const Text(
          '¿Estás seguro que deseas cancelar esta cita? Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Mantener Cita',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _db.deleteAppointment(widget.appointmentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita cancelada correctamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.blueAccent,
          ),
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
                const SizedBox(height: 2),
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
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'pendiente':
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case 'confirmada':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case 'completada':
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        break;
      case 'cancelada':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalles de la Cita',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Información Principal
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con Estado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Información de la Cita',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        _buildStatusBadge(data['estado'] ?? 'pendiente'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Información del Médico
                    _buildInfoItem(
                      Icons.medical_services,
                      'Médico',
                      data['nombre_medico'] ?? 'No especificado',
                    ),
                    
                    _buildInfoItem(
                      Icons.work,
                      'Especialidad',
                      data['especialidad'] ?? 'No especificada',
                    ),
                    
                    _buildInfoItem(
                      Icons.calendar_today,
                      'Fecha',
                      data['fecha'] ?? 'No especificada',
                    ),
                    
                    _buildInfoItem(
                      Icons.access_time,
                      'Hora',
                      data['hora'] ?? 'No especificada',
                    ),

                    // Motivo de consulta (si existe)
                    if (data['motivo_consulta'] != null)
                      _buildInfoItem(
                        Icons.note,
                        'Motivo de Consulta',
                        data['motivo_consulta']!,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Card para Reagendar
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reagendar Cita',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Selecciona una nueva fecha y hora para tu cita',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botón para seleccionar fecha
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _pickDateAndLoadSlots,
                        icon: const Icon(Icons.calendar_today, size: 20),
                        label: const Text(
                          'Seleccionar Nueva Fecha',
                          style: TextStyle(fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Fecha seleccionada
                    if (selectedDate != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.blueAccent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Fecha seleccionada: ${formatFecha(selectedDate!)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Loading indicator
                    if (loading)
                      const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        ),
                      ),

                    // Horarios disponibles
                    if (!loading && availableSlots.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Horarios Disponibles:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableSlots.map((slot) {
                              final isSelected = slot == selectedSlot;
                              return GestureDetector(
                                onTap: () => setState(() => selectedSlot = slot),
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

                    if (!loading && availableSlots.isEmpty && selectedDate != null)
                      const Text(
                        'Seleccione la fecha para ver horarios disponibles',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            //  Botones de Acción
            Row(
              children: [
                // Botón Guardar Cambios
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveChanges,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text(
                      'Guardar Cambios',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Botón Cancelar Cita
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _deleteAppointment,
                    icon: const Icon(Icons.cancel, size: 20),
                    label: const Text(
                      'Cancelar Cita',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}