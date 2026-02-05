import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/signup_data.dart';
import '../../home/home_screen.dart';
import '../../app/main_app_screen.dart'; // Asegúrate de importar tu MainAppScreen si es a donde vas

// 🎨 PALETA GLOBAL (Coherente con Step 2)
const Color kBgColor = Color(0xFFF9FAFB);
const Color kTextPrimary = Color(0xFF111827);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kBrandColor = Color(0xFF4F46E5);
const Color kSurfaceColor = Colors.white;

class SignupStep3 extends StatefulWidget {
  static const route = "/signup-step3";

  const SignupStep3({super.key});

  @override
  State<SignupStep3> createState() => _SignupStep3State();
}

class _SignupStep3State extends State<SignupStep3> {
  String dominantHand = "";
  String playSide = "";
  bool isLoading = false;

  void _handleFinish() async {
    HapticFeedback.heavyImpact();
    
    if (dominantHand.isEmpty || playSide.isEmpty) {
      _showError("Por favor, completa tu perfil de jugador.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // 1) Crear usuario en Auth
      final authRes = await supabase.auth.signUp(
        email: signupData.email,
        password: signupData.password,
      );

      if (authRes.user == null) throw "Error al crear usuario auth.";

      // 2) Login automático para obtener sesión válida
      // A veces signUp no loguea automáticamente si requiere confirmación, 
      // pero asumimos flujo directo o que supabase maneja la sesión.
      // Si tu configuración requiere email confirm, esto podría fallar aquí.
      // Intentamos login por seguridad:
      final loginRes = await supabase.auth.signInWithPassword(
        email: signupData.email,
        password: signupData.password,
      );

      final userId = loginRes.user?.id;
      if (userId == null) throw "No se pudo obtener el ID de usuario.";

      // 3) Token de notificaciones (Opcional, no bloqueante)
      String? pushToken;
      try {
        pushToken = await FirebaseMessaging.instance.getToken();
      } catch (_) {}

      // 4) Insertar datos en tabla 'users'
      await supabase.from("users").insert({
        "id": userId,
        "full_name": signupData.fullName,
        "email": signupData.email,
        "phone": signupData.phone, // Asegúrate de que tu modelo tenga phone
        "gender": signupData.gender,
        "zone": signupData.zone,
        "level": signupData.level,
        "level_source": signupData.levelSource,
        
        // Datos nuevos
        "dominant_hand": dominantHand,
        "play_side": playSide,

        // Defaults
        "tokens": 5,
        "is_premium": false,
        "trust_score": 1.00, // Empezamos con 100% de confianza :)
        "push_token": pushToken,
        
        "created_at": DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      
      // Navegar al Home (o MainAppScreen) y limpiar historial
      // Asumiendo que MainAppScreen es tu ruta raíz autenticada
      Navigator.pushNamedAndRemoveUntil(context, '/app', (route) => false);

    } catch (e) {
      _showError("Error en el registro: ${e.toString()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPrimary, size: 20),
        ),
        centerTitle: true,
        title: const Text(
          "Paso 3 de 3",
          style: TextStyle(color: kTextSecondary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 4,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              widthFactor: 1.0, // 100% completado
              child: Container(
                decoration: BoxDecoration(color: kBrandColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Define tu estilo",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: kTextPrimary, letterSpacing: -0.8),
              ).animate().fadeIn().slideY(begin: 0.3, curve: Curves.easeOut),

              const SizedBox(height: 10),

              const Text(
                "Para emparejarte con el compañero ideal.",
                style: TextStyle(fontSize: 16, color: kTextSecondary, height: 1.4),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),

              const SizedBox(height: 40),

              // 1. MANO DOMINANTE
              const _SectionLabel("MANO DOMINANTE").animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _HandCard(
                      label: "Izquierda",
                      icon: Icons.back_hand_rounded, // Icono mano
                      isSelected: dominantHand == "Izquierda",
                      onTap: () => setState(() => dominantHand = "Izquierda"),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _HandCard(
                      label: "Derecha",
                      icon: Icons.front_hand_rounded, // Icono mano variante
                      isSelected: dominantHand == "Derecha",
                      onTap: () => setState(() => dominantHand = "Derecha"),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

              const SizedBox(height: 40),

              // 2. POSICIÓN EN PISTA (VISUALIZADOR ÚNICO) 🎾
              const _SectionLabel("¿DÓNDE TE SIENTES CÓMODO?").animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
              
              _CourtSideSelector(
                selectedSide: playSide,
                onSideSelected: (side) => setState(() => playSide = side),
              ).animate().fadeIn(delay: 350.ms).scale(),

              const SizedBox(height: 60),

              // 3. BOTÓN FINALIZAR
              _GradientButton(
                text: "Finalizar Registro",
                isLoading: isLoading,
                onTap: _handleFinish,
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================
// 🏟️ WIDGET ÚNICO: SELECTOR DE PISTA VISUAL
// =======================================================
class _CourtSideSelector extends StatelessWidget {
  final String selectedSide;
  final ValueChanged<String> onSideSelected;

  const _CourtSideSelector({required this.selectedSide, required this.onSideSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Fondo de la pista (Sutil)
            Positioned.fill(
              child: Container(
                color: const Color(0xFFEFF6FF), // Azul pista muy suave
              ),
            ),
            
            // Línea central
            Center(
              child: Container(
                width: 2,
                height: double.infinity,
                color: Colors.white,
              ),
            ),
            
            // Línea de saque (Horizontal)
            Positioned(
              top: 40, left: 0, right: 0,
              child: Container(height: 2, color: Colors.white),
            ),

            Row(
              children: [
                // LADO IZQUIERDO (REVÉS)
                Expanded(
                  child: _CourtSideButton(
                    label: "Revés",
                    description: "Lado Izquierdo",
                    isSelected: selectedSide == "Revés",
                    onTap: () => onSideSelected("Revés"),
                  ),
                ),
                // LADO DERECHO (DRIVE)
                Expanded(
                  child: _CourtSideButton(
                    label: "Drive",
                    description: "Lado Derecho",
                    isSelected: selectedSide == "Drive",
                    onTap: () => onSideSelected("Drive"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourtSideButton extends StatelessWidget {
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _CourtSideButton({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? kBrandColor.withOpacity(0.9) : Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isSelected 
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 28),
                    const SizedBox(height: 8),
                    Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: TextStyle(color: kTextPrimary.withOpacity(0.6), fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(color: kTextSecondary.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

// =======================================================
// 🤚 WIDGET: TARJETA DE MANO
// =======================================================
class _HandCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _HandCard({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: 200.ms,
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? kBrandColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kBrandColor : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: kBrandColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isSelected ? Colors.white : kTextPrimary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isSelected ? Colors.white : kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// 🧩 OTROS WIDGETS
// =======================================================

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: kTextSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

// Botón Gradiente con Estado de Carga
class _GradientButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onTap;

  const _GradientButton({required this.text, required this.isLoading, required this.onTap});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => !widget.isLoading ? _ctrl.forward() : null,
      onTapUp: (_) => !widget.isLoading ? _ctrl.reverse() : null,
      onTapCancel: () => !widget.isLoading ? _ctrl.reverse() : null,
      onTap: widget.isLoading ? null : () {
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6200EA), Color(0xFF00B0FF)], // Gradiente de marca
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6200EA).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading 
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
        ),
      ),
    );
  }
}