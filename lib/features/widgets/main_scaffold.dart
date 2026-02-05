import 'package:flutter/material.dart';

// ✅ IMPORTA TUS PANTALLAS
// Asegúrate de que estas rutas sean correctas en tu proyecto
import '../home/home_screen.dart';
import '../matches/my_matches_screen.dart';
import '../challenges/challenges_screen.dart'; 
import '../profile/profile_screen.dart'; // Si no tienes esta, comenta la importación

import 'curved_bottom_bar.dart';

class MainScaffold extends StatefulWidget {
  // Ya no pedimos 'pages' en el constructor. Las definimos dentro.
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    // 🛠 CONFIGURACIÓN DE PÁGINAS
    // El orden coincide con los iconos de la CurvedBottomBar:
    // 0: Dashboard (Mapa)
    // 1: Calendar (Mis Partidos)
    // 2: Awards/Trophy (Retos)
    // 3: Person (Perfil)
    _pages = [
      const HomeScreen(),
      const MyMatchesScreen(),
      const ChallengesScreen(), 
      // Si aún no tienes ProfileScreen, usa: const Center(child: Text("Perfil")),
      const ProfileScreen(), 
    ];

    // Configuración de animación suave al cambiar de pestaña
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.value = 1.0;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    // Reinicia la animación de fade para la nueva pantalla
    _animController.forward(from: 0);
  }

  void _onCreateMatch() {
    // Acción del botón central (+)
    Navigator.pushNamed(context, '/create-match');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Permite que la barra curva flote sobre el contenido
      extendBody: true,
      
      // Evita errores de renderizado cuando sale el teclado (Pixel Overflow)
      resizeToAvoidBottomInset: false,

      body: FadeTransition(
        opacity: _fadeAnim,
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),

      bottomNavigationBar: CurvedBottomBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
        onCreateTap: _onCreateMatch,
      ),
    );
  }
}