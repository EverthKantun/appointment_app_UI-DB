import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/home_option.dart';
import '../widgets/specialty_card.dart';
import '../widgets/news_card.dart';
import 'profile_page.dart';
import 'appointment_page.dart';
import 'tips_page.dart';
import 'messages_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? userData;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await _db.getUser(widget.userId);
    setState(() {
      userData = doc.data() as Map<String, dynamic>?;
    });
  }

  @override
  Widget build(BuildContext context) {
    String userName = userData?['nombre'] ?? 'Usuario';

    // Páginas del BottomNavigationBar
    final List<Widget> pages = [
      _buildInicioPage(userName),
      MessagesPage(userId: widget.userId),
      SettingsPage(userId: widget.userId),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Mensajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }

  // Página de inicio
  Widget _buildInicioPage(String userName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con saludo y foto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '¡Hola, $userName!\n¿En qué podemos ayudarte?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: widget.userId),
                  ),
                ),
                child: const CircleAvatar(
                  radius: 26,
                  backgroundImage:
                      AssetImage('assets/images/profile_placeholder.png'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Opciones principales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              HomeOption(
                title: 'Agendar Cita',
                icon: Icons.calendar_today,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AppointmentPage(userId: widget.userId)),
                  );
                },
              ),
              HomeOption(
                title: 'Consejos Médicos',
                icon: Icons.favorite,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TipsPage()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Especialidades
          const Text(
            'Especialidades',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('especialidades')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!.docs;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final doc = data[index];
                    return SpecialtyCard(
                      userId: widget.userId,
                      title: doc['nombre'] ?? 'Especialidad',
                      icon: Icons.medical_services,
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Novedades
          const Text(
            'Novedades',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('novedades')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: docs.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return NewsCard(
                    title: doc['titulo'] ?? 'Novedad',
                    description: doc['descripcion'] ?? '',
                    imageUrl: doc['imagen_url'] ?? '',
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
