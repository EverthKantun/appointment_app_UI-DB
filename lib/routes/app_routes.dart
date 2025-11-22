import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/register_doctor_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../pages/appointment_page.dart';
import '../pages/tips_page.dart';
import '../pages/messages_page.dart';
import '../pages/settings_page.dart';
import '../pages/dashboard_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/doctor_appointments_page.dart';
import '../pages/doctor_appointment_details_page.dart';
import '../pages/graphics_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String registerDoctor = '/register-doctor';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String appointment = '/appointment';
  static const String tips = '/tips';
  static const String messages = '/messages';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    registerDoctor: (context) => const RegisterDoctorPage(),
    forgotPassword: (context) => const ForgotPasswordPage(),

    home: (context) {
      final user = FirebaseAuth.instance.currentUser;
      return HomePage(userId: user!.uid);
    },

    // Dashboard del doctor → recibe el userId por arguments
    dashboard: (context) {
      final userId = ModalRoute.of(context)!.settings.arguments as String;
      return DashboardPage(userId: userId);
    },

    profile: (context) {
      final user = FirebaseAuth.instance.currentUser;
      return ProfilePage(userId: user!.uid);
    },

    appointment: (context) {
      final user = FirebaseAuth.instance.currentUser;
      return AppointmentPage(userId: user!.uid);
    },

    tips: (context) => const TipsPage(),
    messages: (context) => const MessagesPage(),
    settings: (context) => const SettingsPage(),

    // Lista de citas del médico
    '/appointments-for-doctor': (context) {
      final doctorId = ModalRoute.of(context)!.settings.arguments as String;
      return DoctorAppointmentsPage(doctorId: doctorId);
    },

    // Detalle de cita del médico
    '/doctor-appointment-details': (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      return DoctorAppointmentDetailsPage(
        appointmentId: args['appointmentId'],
        data: args['data'],
        doctorId: args['doctorId'],
      );
    },
        
      '/graphics': (context) {
      final doctorId = ModalRoute.of(context)!.settings.arguments as String;
      return GraphicsPage(doctorId: doctorId);
    },
  };
}
