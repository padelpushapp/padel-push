import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../home/home_screen.dart';
import '../login/login_screen.dart';

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
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool("rememberMe") ?? false;

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    if (remember == true) {
      Navigator.pushReplacementNamed(context, MainAppScreen.route);
    } else {
      Navigator.pushReplacementNamed(context, LoginScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          "assets/logo.png",
          width: 130,
        ),
      ),
    );
  }
}
