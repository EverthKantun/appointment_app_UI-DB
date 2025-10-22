import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../pages/appointment_page.dart';
import '../pages/tips_page.dart';
import '../pages/messages_page.dart';
import '../pages/calendar_page.dart';
import '../pages/settings_page.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String appointment = '/appointment';
  static const String tips = '/tips';
  static const String messages = '/messages';
  static const String calendar = '/calendar';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginPage(),
    register: (context) => const RegisterPage(),
    forgotPassword: (context) => const ForgotPasswordPage(),
    '/home': (context) => HomePage(userId: FirebaseAuth.instance.currentUser!.uid),
    '/profile': (context) => ProfilePage(userId: FirebaseAuth.instance.currentUser!.uid),
    appointment: (context) => AppointmentPage(userId: FirebaseAuth.instance.currentUser!.uid,),
    tips: (context) => const TipsPage(),
    messages: (context) => const MessagesPage(),
    calendar: (context) => const CalendarPage(),
    settings: (context) => const SettingsPage(),
  };
}
