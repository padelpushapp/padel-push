import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../features/models/signup_data.dart';
import '../signup_step3/signup_step3.dart';

// 🎨 PALETA GLOBAL
const Color kBgColor = Color(0xFFF8FAFC);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF64748B);
const Color kInputBg = Color(0xFFF1F5F9);
const Color kBrandColor = Color(0xFF4F46E5);

class SignupStep2 extends StatefulWidget {
  static const route = "/signup-step2";

  const SignupStep2({super.key});

  @override
  State<SignupStep2> createState() => _SignupStep2State();
}

class _SignupStep2State extends State<SignupStep2> {
  String gender = "";
  String zone = "";
  double level = 3.0;
  String levelSource = "";

  void _handleContinue() {
    HapticFeedback.mediumImpact();
    if (gender.isEmpty || zone.isEmpty || levelSource.isEmpty) {
      _showError("Completa todos los campos para continuar.");
      return;
    }

    signupData.gender = gender;
    signupData.zone = zone;
    signupData.level = level;
    signupData.levelSource = levelSource;

    Navigator.pushNamed(context, SignupStep3.route);
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
          "Paso 2 de 3",
          style: TextStyle(color: kTextSecondary, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 4,
            width: double.infinity,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
            child: FractionallySizedBox(
              widthFactor: 0.66,
              child: Container(
                decoration: BoxDecoration(color: kBrandColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tu perfil de jugador",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kTextPrimary, letterSpacing: -0.8),
              ).animate().fadeIn().slideY(begin: 0.3, curve: Curves.easeOut),

              const SizedBox(height: 10),

              const Text(
                "Define tu nivel para encontrar partidos equilibrados.",
                style: TextStyle(fontSize: 16, color: kTextSecondary, height: 1.4),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),

              const SizedBox(height: 40),

              // 1. SEXO
              const _SectionLabel("SEXO").animate().fadeIn(delay: 200.ms).slideX(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _SelectableCard(label: "Hombre", icon: Icons.male_rounded, isSelected: gender == "Hombre", onTap: () => setState(() => gender = "Hombre"))),
                  const SizedBox(width: 16),
                  Expanded(child: _SelectableCard(label: "Mujer", icon: Icons.female_rounded, isSelected: gender == "Mujer", onTap: () => setState(() => gender = "Mujer"))),
                ],
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              // 2. ZONA
              const _SectionLabel("ZONA DE JUEGO").animate().fadeIn(delay: 300.ms).slideX(),
              const SizedBox(height: 12),
              _ZoneInput(value: zone, onTap: _showZoneSelector).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              // 3. NIVEL MINIMALISTA (NUEVO) ✨
              _MinimalPadelSlider(
                level: level,
                onChanged: (v) => setState(() => level = v),
              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),

              const SizedBox(height: 32),

              // 4. ORIGEN NIVEL
              const _SectionLabel("¿QUIÉN VALIDA TU NIVEL?").animate().fadeIn(delay: 500.ms).slideX(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _SelectableChip(label: "Club", isSelected: levelSource == "Club", onTap: () => setState(() => levelSource = "Club"))),
                  const SizedBox(width: 10),
                  Expanded(child: _SelectableChip(label: "Playtomic", isSelected: levelSource == "Playtomic", onTap: () => setState(() => levelSource = "Playtomic"))),
                  const SizedBox(width: 10),
                  Expanded(child: _SelectableChip(label: "Otro", isSelected: levelSource == "Otro", onTap: () => setState(() => levelSource = "Otro"))),
                ],
              ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1),

              const SizedBox(height: 50),

              // 5. BOTÓN
              _GradientButton(text: "Continuar", onTap: _handleContinue).animate().fadeIn(delay: 600.ms).scale(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showZoneSelector() {
    // (Mismo código del selector de zona)
    HapticFeedback.lightImpact();
    final zonas = ["Valencia Capital", "L'Horta Nord", "L'Horta Sud", "Paterna / Camp del Turia", "Zona Universitaria"];
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 4, width: 40, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ...zonas.map((z) => ListTile(title: Text(z, style: const TextStyle(fontWeight: FontWeight.w600, color: kTextPrimary)), trailing: zone == z ? const Icon(Icons.check_circle_rounded, color: kBrandColor) : const Icon(Icons.radio_button_unchecked, color: Colors.grey), onTap: () { setState(() => zone = z); Navigator.pop(context); })),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// 🎾 WIDGET: SLIDER FINO & DELICADO
// =======================================================
class _MinimalPadelSlider extends StatelessWidget {
  final double level;
  final ValueChanged<double> onChanged;

  const _MinimalPadelSlider({required this.level, required this.onChanged});

  Color _getLevelColor(double val) {
    if (val < 2.0) return Colors.blue.shade400; 
    if (val < 3.5) return Colors.teal.shade400; 
    if (val < 5.0) return Colors.orange.shade400; 
    return Colors.redAccent.shade400; 
  }

  String _getLevelTitle(double val) {
    if (val < 1.5) return "Iniciación";
    if (val < 2.5) return "Principiante";
    if (val < 3.5) return "Intermedio";
    if (val < 4.5) return "Avanzado";
    if (val < 5.5) return "Competición";
    return "Profesional";
  }

  double _getRacketAngle(double val) {
    return -0.2 + (val / 6.0) * 0.6; 
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getLevelColor(level);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Sombra muy sutil, casi imperceptible
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // CABECERA: Etiqueta + Valor + Icono
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Texto fijo a la izquierda
              const Text(
                "TU NIVEL", 
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 0.5)
              ),
              
              // Valor dinámico y Pala a la derecha
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Texto del Nivel (Ej: Intermedio)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _getLevelTitle(level),
                        key: ValueKey(_getLevelTitle(level)),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: activeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Separador
                    Container(height: 12, width: 1, color: activeColor.withOpacity(0.3)),
                    const SizedBox(width: 8),
                    // Pala Rotatoria Pequeña
                    Transform.rotate(
                      angle: _getRacketAngle(level),
                      child: Icon(Icons.sports_tennis_rounded, size: 16, color: activeColor),
                    ),
                    const SizedBox(width: 6),
                    // Número
                    Text(
                      level.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // SLIDER FINO
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 10, // Muy fino
              activeTrackColor: activeColor,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: Colors.white,
              // Thumb pequeño y limpio
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
              overlayColor: activeColor.withOpacity(0.1),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: level,
              min: 0.0,
              max: 6.0,
              divisions: 24,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                onChanged(double.parse(value.toStringAsFixed(2)));
              },
            ),
          ),
          
          // Etiquetas min/max
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("0.0", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade300, fontSize: 11)),
                Text("6.0", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade300, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// 🧩 OTROS WIDGETS (Sin cambios, solo diseño limpio)
// =======================================================

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 0.5));
}

class _SelectableCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _SelectableCard({required this.label, required this.icon, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: 200.ms, height: 80,
        decoration: BoxDecoration(
          color: isSelected ? kBrandColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? kBrandColor : Colors.grey.shade200, width: 2),
          boxShadow: isSelected ? [BoxShadow(color: kBrandColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : kTextPrimary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : kTextPrimary)),
          ],
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SelectableChip({required this.label, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: 200.ms, padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kBrandColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? kBrandColor : Colors.grey.shade200),
        ),
        child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Colors.white : kTextSecondary))),
      ),
    );
  }
}

class _ZoneInput extends StatelessWidget {
  final String value;
  final VoidCallback onTap;
  const _ZoneInput({required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: kInputBg, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, color: kTextSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(value.isEmpty ? "Selecciona tu zona habitual" : value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: value.isEmpty ? Colors.grey.shade400 : kTextPrimary))),
            const Icon(Icons.keyboard_arrow_down_rounded, color: kTextSecondary),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _GradientButton({required this.text, required this.onTap});
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
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity, height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6200EA), Color(0xFF00B0FF)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF6200EA).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}