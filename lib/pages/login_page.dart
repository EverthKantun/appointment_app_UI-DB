import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  // Expresiones regulares para validación
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }
    if (!_emailRegExp.hasMatch(value)) {
      return 'Por favor ingresa un correo electrónico válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.loginWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (user == null || !mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales incorrectas'), backgroundColor: Colors.red),
        );
        return;
      }

      final uid = user.uid;

      // 1) ¿Existe como médico? Redirigir a dashboard 
      final medicoDoc = await FirebaseFirestore.instance.collection('medicos').doc(uid).get();
      if (medicoDoc.exists) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: uid,
        );
        return;
      }

      // 2) ¿Existe como paciente en 'usuarios'? Redirigir a home
      final usuarioDoc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      if (usuarioDoc.exists) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      // Si no existe en ninguna colección -> advertencia
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credenciales inválidas'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),

                Image.asset(
                  'assets/images/login.png',
                  height: 150,
                ),

                const SizedBox(height: 40),

                const Text(
                  'Iniciar sesión',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  controller: emailController,
                  labelText: 'Correo electrónico',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: passwordController,
                  labelText: 'Contraseña',
                  obscureText: true,
                  prefixIcon: Icons.lock,
                  validator: _validatePassword,
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register-doctor');
                      },
                      child: const Text('¿Eres médico? Regístrate aquí'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: const Text('¿Eres paciente? Regístrate aquí'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _isLoading
                    ? const CircularProgressIndicator(color: Colors.teal)
                    : CustomButton(
                        text: 'Iniciar sesión',
                        onPressed: _login,
                      ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
