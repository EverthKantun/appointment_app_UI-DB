import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  final String? userId; 
  const MessagesPage({super.key, this.userId}); 

  @override
  Widget build(BuildContext context) {
    final messages = [
      {
        "title": "Recordatorio de Cita",
        "message": "Recuerda tu cita del 20 de octubre a las 10:00 AM con el Dr. Martínez.",
        "time": "Hace 2 horas",
        "icon": Icons.calendar_today,
        "color": Colors.green,
        "unread": true,
        "sender": "Sistema"
      },
      {
        "title": "Resultados Actualizados",
        "message": "Tu médico ha actualizado tus resultados de laboratorio. Ya puedes revisarlos.",
        "time": "Ayer",
        "icon": Icons.assignment,
        "color": Colors.blue,
        "unread": true,
        "sender": "Dr. González"
      },
      {
        "title": "Promociones Disponibles",
        "message": "Nuevas promociones en exámenes de laboratorio. Consulta los precios especiales.",
        "time": "2 días",
        "icon": Icons.local_offer,
        "color": Colors.orange,
        "unread": false,
        "sender": "Promociones"
      },
      {
        "title": "Confirmación de Cita",
        "message": "Tu cita con el Dr. Rodríguez ha sido confirmada para el 25 de octubre.",
        "time": "3 días",
        "icon": Icons.check_circle,
        "color": Colors.purple,
        "unread": false,
        "sender": "Sistema"
      },
      {
        "title": "Recordatorio de Medicación",
        "message": "No olvides tomar tu medicamento después del desayuno.",
        "time": "1 semana",
        "icon": Icons.medical_services,
        "color": Colors.red,
        "unread": false,
        "sender": "Recordatorio"
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mensajes"),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Búsqueda de mensajes'),
                  backgroundColor: Colors.blueAccent,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con estadísticas
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.message,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Centro de Mensajes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${messages.where((msg) => msg["unread"] == true).length} mensajes no leídos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de mensajes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageCard(message, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message, BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: (message["unread"] as bool)
              ? Border(
                  left: BorderSide(
                    color: Colors.blueAccent,
                    width: 4,
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono del mensaje
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (message["color"] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  message["icon"] as IconData,
                  color: message["color"] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Contenido del mensaje
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          message["title"] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (message["unread"] as bool)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message["sender"] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message["message"] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          message["time"] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (message["unread"] as bool) ? "Nuevo" : "Leído",
                            style: TextStyle(
                              fontSize: 10,
                              color: (message["unread"] as bool)
                                  ? Colors.blueAccent
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}