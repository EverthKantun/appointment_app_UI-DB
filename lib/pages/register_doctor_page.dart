import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class RegisterDoctorPage extends StatefulWidget {
  const RegisterDoctorPage({super.key});

  @override
  State<RegisterDoctorPage> createState() => _RegisterDoctorPageState();
}

class _RegisterDoctorPageState extends State<RegisterDoctorPage> {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController especialidadController = TextEditingController();
  final TextEditingController cedulaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool _isLoading = false;

  String? _validateNotEmpty(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo requerido';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Por favor ingresa tu correo';
    final re = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v)) return 'Correo inválido';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa contraseña';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> _registerDoctor() async {
    if (!_formKey.currentState!.validate()) return;
    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1) Crear usuario en Auth
      final user = await _authService.registerWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear la cuenta'), backgroundColor: Colors.red),
        );
        return;
      }

      final uid = user.uid;

      // 2) Preparar datos del doctor
      final Map<String, dynamic> doctorData = {
        'uid': uid,
        'uid_login': uid, // redundante pero claro
        'nombre': nameController.text.trim(),
        'email': emailController.text.trim(),
        'telefono': phoneController.text.trim(),
        'especialidad': especialidadController.text.trim(),
        'cedula': cedulaController.text.trim(),
        'foto_url': '', // puedes pedir url o dejar vacio
        'descripcion': '',
        'experiencia': '',
        'calificacion': 0.0,
        'activo': true,
        // Estructura básica de disponibilidad (puedes dejar vacía o un ejemplo)
        'disponibilidad': {
          'lunes': {'inicio': '08:00', 'fin': '16:00'},
          'martes': {'inicio': '08:00', 'fin': '16:00'},
          'miercoles': {'inicio': '08:00', 'fin': '16:00'},
          'jueves': {'inicio': '08:00', 'fin': '16:00'},
          'viernes': {'inicio': '08:00', 'fin': '16:00'},
        },
        'created_at': FieldValue.serverTimestamp(),
      };

      // 3) Guardar en colección 'medicos' usando el uid como doc id
      await _db.addDoctor(uid, doctorData);

      // Mensaje y redirección al dashboard
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro de médico exitoso'), backgroundColor: Colors.green),
      );

      // Redirigir al dashboard (usamos uid como argumento)
      Navigator.pushReplacementNamed(context, '/dashboard', arguments: uid);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    especialidadController.dispose();
    cedulaController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Médico'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text('Regístrate como Médico', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: nameController,
                  labelText: 'Nombre completo',
                  prefixIcon: Icons.person,
                  validator: _validateNotEmpty,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: especialidadController,
                  labelText: 'Especialidad',
                  prefixIcon: Icons.medical_services,
                  validator: _validateNotEmpty,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: cedulaController,
                  labelText: 'Cédula',
                  prefixIcon: Icons.badge,
                  validator: _validateNotEmpty,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: emailController,
                  labelText: 'Correo electrónico',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: phoneController,
                  labelText: 'Teléfono (opcional)',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: passwordController,
                  labelText: 'Contraseña',
                  prefixIcon: Icons.lock,
                  obscureText: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: confirmController,
                  labelText: 'Confirmar contraseña',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 20),

                _isLoading
                    ? const CircularProgressIndicator(color: Colors.teal)
                    : CustomButton(text: 'Registrarme como Médico', onPressed: _registerDoctor),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
