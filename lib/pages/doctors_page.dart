import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointment_page.dart'; 

class DoctorsPage extends StatelessWidget {
  final String especialidad;
  final String userId;

  const DoctorsPage({
    super.key,
    required this.especialidad,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Médicos de $especialidad'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medicos')
            .where('especialidad', isEqualTo: especialidad)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay médicos en esta especialidad',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final nombre = doc['nombre'] ?? 'Nombre no disponible';
              final disponibilidad = doc['disponibilidad'] ?? 'Horario no especificado';
              final foto = doc['foto_url'] ?? '';
              final cedula = doc['cedula'] ?? 'Sin cédula';
              final telefono = doc['telefono'] ?? 'Sin teléfono';
              final email = doc['email'] ?? 'Sin correo';
              final ubicacion = doc['ubicacion'] ?? 'Sin ubicación';
              final experiencia = doc['experiencia'] ?? 'Experiencia no especificada';
              final calificacion = doc['calificacion'] ?? 0.0;
              final descripcion = doc['descripcion'] ?? 'Sin descripción disponible';

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado con foto e información principal
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Foto del médico
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[100],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: foto.isNotEmpty
                                  ? Image.network(
                                      foto,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.grey[400],
                                        );
                                      },
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Información principal
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  especialidad,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                
                                // Calificación y experiencia
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      calificacion.toString(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.work,
                                      size: 16,
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      experiencia,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Colors.grey),

                      // Descripción
                      const SizedBox(height: 12),
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        descripcion,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),

                      // 🔹 Disponibilidad
                      const SizedBox(height: 12),
                      const Text(
                        'Disponibilidad',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        disponibilidad,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),

                      // Información de contacto
                      const SizedBox(height: 12),
                      const Text(
                        'Información de Contacto',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Ubicación
                      _buildContactInfo(
                        icon: Icons.location_on,
                        label: 'Ubicación',
                        value: ubicacion,
                      ),
                      
                      // Teléfono
                      _buildContactInfo(
                        icon: Icons.phone,
                        label: 'Teléfono',
                        value: telefono,
                      ),
                      
                      // Email
                      _buildContactInfo(
                        icon: Icons.email,
                        label: 'Email',
                        value: email,
                      ),
                      
                      // Cédula
                      _buildContactInfo(
                        icon: Icons.badge,
                        label: 'Cédula Profesional',
                        value: cedula,
                      ),

                      const SizedBox(height: 16),

                      // Botón para agendar cita
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AppointmentPage(
                                  userId: userId,
                                  doctorId: doc.id,
                                  doctorName: nombre,
                                  especialidad: especialidad,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today, size: 20),
                          label: const Text(
                            'Agendar Cita',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Widget auxiliar para información de contacto
  Widget _buildContactInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.blueAccent,
          ),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}