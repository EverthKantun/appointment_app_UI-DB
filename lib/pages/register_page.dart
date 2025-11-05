import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../services/auth_service.dart';
import '../services/database_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool _isLoading = false;
  bool _acceptTerms = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es obligatorio';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es obligatorio';
    }
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{8,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Ingresa un número de teléfono válido';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        _showCupertinoDialog(
          'Términos y Condiciones',
          'Debes aceptar los términos y condiciones para registrarte',
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final user = await _authService.registerWithEmail(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

        if (user != null && mounted) {
          await _databaseService.addUser(user.uid, {
            'nombre': nameController.text.trim(),
            'email': user.email,
            'telefono': phoneController.text.trim(),
            'foto_url': '',
            'historial_medico': '',
            'fecha_registro': DateTime.now(),
          });

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home', arguments: user.uid);
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String errorMessage;
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'Este correo electrónico ya está registrado';
              break;
            case 'invalid-email':
              errorMessage = 'El correo electrónico no es válido';
              break;
            case 'operation-not-allowed':
              errorMessage = 'El registro con email y contraseña no está habilitado';
              break;
            case 'weak-password':
              errorMessage = 'La contraseña es demasiado débil';
              break;
            default:
              errorMessage = 'Error al registrarse: ${e.message}';
          }
          _showCupertinoDialog('Error de registro', errorMessage);
        }
      } catch (e) {
        if (mounted) {
          _showCupertinoDialog('Error inesperado', 'Ocurrió un error inesperado: $e');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showCupertinoDialog(String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            child: const Text('Aceptar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Términos y Condiciones'),
        message: const Text(
          'Al registrarte en nuestra plataforma médica, aceptas que:\n\n'
          '• La información proporcionada es verídica\n'
          '• Respetarás las citas programadas\n'
          '• Notificarás con anticipación cualquier cancelación\n'
          '• Mantendrás la confidencialidad de tu información\n\n'
          'Tu privacidad es importante para nosotros.',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _acceptTerms = true;
              });
            },
            child: const Text('Aceptar Términos'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: CupertinoColors.destructiveRed),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBlue.withOpacity(0.1),
        middle: const Text(
          'Crear Cuenta',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: CupertinoColors.systemBlue,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.maybePop(context),
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.systemBlue,
          ),
        ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 20),
              // Imagen médica
              Image.asset(
                'assets/images/newuser.png',
                height: 120,
              ),
              const SizedBox(height: 30),
              
              // Nombre completo
              _buildCupertinoTextField(
                controller: nameController,
                placeholder: 'Nombre completo',
                prefix: CupertinoIcons.person,
                validator: _validateName,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              
              // Email
              _buildCupertinoTextField(
                controller: emailController,
                placeholder: 'Correo electrónico',
                prefix: CupertinoIcons.mail,
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // Teléfono
              _buildCupertinoTextField(
                controller: phoneController,
                placeholder: 'Teléfono',
                prefix: CupertinoIcons.phone,
                validator: _validatePhone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              // Contraseña
              _buildPasswordField(
                controller: passwordController,
                placeholder: 'Contraseña',
                isPassword: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              
              // Confirmar contraseña
              _buildPasswordField(
                controller: confirmPasswordController,
                placeholder: 'Confirmar contraseña',
                isPassword: true,
                isConfirmPassword: true,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 24),
              
              // Términos y condiciones
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    CupertinoSwitch(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value;
                        });
                      },
                      activeColor: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showTermsDialog,
                        child: Text(
                          'Acepto los términos y condiciones',
                          style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            color: CupertinoColors.systemBlue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Botón de registro
              _isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        color: CupertinoColors.systemBlue,
                        radius: 16,
                      ),
                    )
                  : CupertinoButton.filled(
                      onPressed: _register,
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              
              // Enlace para iniciar sesión
              CupertinoButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(
                  '¿Ya tienes cuenta? Inicia sesión',
                  style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemBlue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData prefix,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.extraLightBackgroundGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.systemGrey4,
        ),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Icon(
            prefix,
            color: CupertinoColors.systemGrey,
            size: 20,
          ),
        ),
        keyboardType: keyboardType,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        style: CupertinoTheme.of(context).textTheme.textStyle,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String placeholder,
    required bool isPassword,
    required String? Function(String?) validator,
    bool isConfirmPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.extraLightBackgroundGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.systemGrey4,
        ),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Icon(
            isConfirmPassword ? CupertinoIcons.lock : CupertinoIcons.lock_fill,
            color: CupertinoColors.systemGrey,
            size: 20,
          ),
        ),
        obscureText: isConfirmPassword ? !_showConfirmPassword : !_showPassword,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        suffix: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          onPressed: () {
            setState(() {
              if (isConfirmPassword) {
                _showConfirmPassword = !_showConfirmPassword;
              } else {
                _showPassword = !_showPassword;
              }
            });
          },
          child: Icon(
            isConfirmPassword
                ? (_showConfirmPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye)
                : (_showPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye),
            color: CupertinoColors.systemGrey,
            size: 20,
          ),
        ),
        style: CupertinoTheme.of(context).textTheme.textStyle,
      ),
    );
  }
}