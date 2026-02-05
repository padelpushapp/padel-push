import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login/login_screen.dart';
import '../../home/home_screen.dart';
import '../user_provider.dart';

class SplashScreen extends StatefulWidget {
  static const route = "/splash";

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Micro delay visual

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // HAY SESIÓN → Cargar datos del usuario desde Supabase
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserProfile();

      // Si por algún motivo los datos no existen todavía en DB
      if (userProvider.user == null) {
        Navigator.pushReplacementNamed(context, LoginScreen.route);
        return;
      }

      // Navegar al Home
      Navigator.pushReplacementNamed(context, MainAppScreen.route);

    } else {
      // NO HAY SESIÓN → Login normal
      Navigator.pushReplacementNamed(context, LoginScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 140,
          child: Image(
            image: AssetImage("assets/logo.png"),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
