// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Firebase
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Providers
import 'features/auth/user_provider.dart';

// Screens
import 'features/auth/login/login_screen.dart';
import 'features/auth/signup_step1/signup_step1.dart';
import 'features/auth/signup_step2/signup_step2.dart';
import 'features/auth/signup_step3/signup_step3.dart';
import 'features/home/home_screen.dart';
import 'features/matches/match_detail_screen.dart';
import 'features/matches/create_match_screen.dart';
import 'features/models/match_model.dart';

// Supabase
import 'features/utils/supabase_manager.dart';

// Notifications
import 'features/utils/notification_state.dart';
import 'features/utils/notification_overlay.dart';

import 'features/app/main_app_screen.dart';


/// ============================================================
/// 🔔 BACKGROUND PUSH HANDLER (NO UI)
/// ============================================================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (message.data.isNotEmpty) {
    NotificationState.show(message.data);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ⛔️ NUNCA BLOQUEAMOS runApp
  runApp(const PadelPushBootstrap());
}

/// ============================================================
/// 🚀 BOOTSTRAP APP (CARGA SEGURA)
/// ============================================================
class PadelPushBootstrap extends StatefulWidget {
  const PadelPushBootstrap({super.key});

  @override
  State<PadelPushBootstrap> createState() => _PadelPushBootstrapState();
}

class _PadelPushBootstrapState extends State<PadelPushBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // ✅ Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage m) {
        if (m.data.isNotEmpty) {
          NotificationState.show(m.data);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) {
        if (m.data.isNotEmpty) {
          NotificationState.show(m.data);
        }
      });

      // ✅ Supabase
      await SupabaseManager.init();
    } catch (e) {
      debugPrint("❌ BOOT ERROR → $e");
    }

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ SIEMPRE HAY UI
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(color: Colors.black),
          ),
        ),
      );
    }

    return const PadelPushApp();
  }
}

/// ============================================================
/// 🧱 ROOT APP REAL
/// ============================================================
class PadelPushApp extends StatelessWidget {
  const PadelPushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PadelPush',

        // ✅ PUNTO DE ENTRADA LIMPIO
        home: const LoginScreen(),

        routes: {
          LoginScreen.route: (_) => const LoginScreen(),
          SignupStep1.route: (_) => const SignupStep1(),
          SignupStep2.route: (_) => const SignupStep2(),
          SignupStep3.route: (_) => const SignupStep3(),
          HomeScreen.route: (_) => const HomeScreen(),
          MainAppScreen.route: (_) => const MainAppScreen(),
          CreateMatchScreen.route: (_) => const CreateMatchScreen(),
          MatchDetailScreen.route: (ctx) {
            final match =
                ModalRoute.of(ctx)!.settings.arguments as MatchModel;
            return MatchDetailScreen(match: match);
          },
        },

        builder: (context, child) {
          return Stack(
            children: [
              child!,
              const NotificationOverlay(),
            ],
          );
        },
      ),
    );
  }
}
