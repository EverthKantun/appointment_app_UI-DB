import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomePage extends StatelessWidget {
  final AuthService _authService = AuthService();

  HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            
          ),
        ],
      ),
body: Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(
        'assets/images/home.png',
        height: 250,
      ),
      const SizedBox(height: 20),
      const Text(
        'Esto aún está en construcción...',
        style: TextStyle(
          fontSize: 18,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  ),
),
    );
  }
}
