import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import 'details_appointment_page.dart';

class MyAppointmentsPage extends StatefulWidget {
  final String userId;
  const MyAppointmentsPage({super.key, required this.userId});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  final DatabaseService _db = DatabaseService();
  bool loading = false;
  List<Map<String, dynamic>> myAppointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => loading = true);

    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
      final to = from.add(const Duration(days: 30));

      final docs = await _db.getAppointmentsForUserInRange(widget.userId, from, to);
      final dataList = docs.map((d) {
        final data = d.data() as Map<String, dynamic>? ?? {};
        return {'id': d.id, 'data': data};
      }).toList();

      setState(() => myAppointments = dataList);
    } catch (e) {
      debugPrint('Error cargando citas: $e');
    }

    setState(() => loading = false);
  }

  Future<void> _deleteAppointment(String citaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: const Text('¿Estás seguro de eliminar esta cita?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteAppointment(citaId);
      _loadAppointments();
    }
  }

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        backgroundColor: Colors.blueAccent,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : myAppointments.isEmpty
              ? const Center(
                  child: Text(
                    'No hay citas agendadas actualmente.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAppointments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: myAppointments.length,
                    itemBuilder: (context, index) {
                      final cita = myAppointments[index];
                      final data = cita['data'] as Map<String, dynamic>;
                      final id = cita['id'];
                      final fecha = data['fecha'] ?? '---';
                      final hora = data['hora'] ?? '--:--';
                      final medico = data['nombre_medico'] ?? 'Médico desconocido';
                      final especialidad = data['especialidad'] ?? '';
                      final estado = data['estado'] ?? 'pendiente';

                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailsAppointmentPage(
                                  appointmentId: id,
                                  data: data,
                                  userId: widget.userId,
                                ),
                              ),
                            );
                            if (updated == true) _loadAppointments();
                          },
                          title: Text(
                            medico,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(especialidad, style: const TextStyle(color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text('📅 $fecha  🕐 $hora'),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.circle, size: 10, color: _estadoColor(estado)),
                                  const SizedBox(width: 6),
                                  Text(
                                    estado.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _estadoColor(estado),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteAppointment(id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
