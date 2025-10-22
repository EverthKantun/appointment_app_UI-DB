import 'package:flutter/material.dart';
import 'profile_page.dart';

class SettingsPage extends StatelessWidget {
  final String? userId; 
  const SettingsPage({super.key, this.userId});

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Aquí va tu lógica de logout
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesión cerrada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Navegar al login page
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/login', 
                  (route) => false
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = [
      {
        "icon": Icons.person, 
        "title": "Editar Perfil",
        "onTap": () {
          if (userId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(userId: userId!),
              ),
            );
          }
        }
      },
      {
        "icon": Icons.notifications, 
        "title": "Notificaciones",
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuración de notificaciones'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      },
      {
        "icon": Icons.lock, 
        "title": "Privacidad y Seguridad",
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuración de privacidad'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      },
      {
        "icon": Icons.language, 
        "title": "Idioma",
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuración de idioma'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      },
      {
        "icon": Icons.help, 
        "title": "Ayuda",
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Centro de ayuda'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      },
      {
        "icon": Icons.info, 
        "title": "Acerca de la aplicación",
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Información de la aplicación'),
              backgroundColor: Colors.blueAccent,
            ),
          );
        }
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajustes"),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.settings,
                  size: 48,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configuración',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),

          // Lista de opciones
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: settings.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        settings[index]["icon"] as IconData,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      settings[index]["title"] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.blueAccent,
                      ),
                    ),
                    onTap: settings[index]["onTap"] as VoidCallback,
                  ),
                );
              },
            ),
          ),

          // Botón de cerrar sesión
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  "Cerrar Sesión",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}