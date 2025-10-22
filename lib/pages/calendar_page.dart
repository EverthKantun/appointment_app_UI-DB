import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final events = [
      {"fecha": "20/10/2025", "evento": "Cita con Dr. García"},
      {"fecha": "25/10/2025", "evento": "Chequeo general"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendario de Citas"),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
              title: Text(events[index]["evento"]!),
              subtitle: Text("Fecha: ${events[index]["fecha"]!}"),
            ),
          );
        },
      ),
    );
  }
}
