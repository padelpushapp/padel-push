import 'package:flutter/material.dart';
import '../theme.dart';

// AUTH
import '../features/auth/login/login_screen.dart';
import '../features/auth/signup_step1/signup_step1.dart';
import '../features/auth/signup_step2/signup_step2.dart';
import '../features/auth/signup_step3/signup_step3.dart';
import '../features/auth/splash/splash_screen.dart';

// HOME
import '../features/home/home_screen.dart';

class PadelPushApp extends StatelessWidget {
  const PadelPushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PadelPush',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),

      // NUEVA PANTALLA INICIAL
      initialRoute: SplashScreen.route,

      routes: {
        SplashScreen.route: (_) => const SplashScreen(),

        LoginScreen.route: (_) => const LoginScreen(),
        SignupStep1.route: (_) => const SignupStep1(),
        SignupStep2.route: (_) => const SignupStep2(),
        SignupStep3.route: (_) => const SignupStep3(),

        HomeScreen.route: (_) => const HomeScreen(),
      },
    );
  }
}
