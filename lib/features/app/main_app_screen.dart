import 'package:flutter/material.dart';
import '../widgets/main_scaffold.dart';

class MainAppScreen extends StatelessWidget {
  static const route = '/app';

  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECCIÓN:
    // Llamamos a MainScaffold sin parámetros.
    // Él ya tiene la lista de páginas (Home, Calendar, Matches, Profile) configurada por dentro.
    return const MainScaffold();
  }
}