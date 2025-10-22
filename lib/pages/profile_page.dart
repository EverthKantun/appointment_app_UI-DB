import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? userData;

  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _historyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await _db.getUser(widget.userId);
    setState(() {
      userData = doc.data() as Map<String, dynamic>?;
      if (userData != null) {
        _nameController.text = userData!['nombre'] ?? '';
        _phoneController.text = userData!['telefono'] ?? '';
        _historyController.text = userData!['historial'] ?? '';
      }
    });
  }

  Future<void> _saveChanges() async {
    final updatedData = {
      'nombre': _nameController.text.trim(),
      'telefono': _phoneController.text.trim(),
      'historial': _historyController.text.trim(),
    };
    await _db.updateUser(widget.userId, updatedData);
    setState(() {
      _isEditing = false;
      userData = updatedData;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar centrado
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: userData!['foto_url'] != null &&
                                  userData!['foto_url'] != ''
                              ? NetworkImage(userData!['foto_url'])
                              : const AssetImage(
                                  'assets/images/profile_placeholder.png') as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              // Abrir picker de imagen
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón editar/guardar
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_isEditing) {
                          _saveChanges();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
                      child: Text(_isEditing ? 'Guardar' : 'Editar'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campos de perfil
                  _buildTextField('Nombre', _nameController),
                  _buildTextField('Teléfono', _phoneController),
                  _buildTextField('Historial médico', _historyController, maxLines: 4),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
