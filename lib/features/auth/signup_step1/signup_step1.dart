import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../features/models/signup_data.dart';
import '../signup_step2/signup_step2.dart';

class SignupStep1 extends StatefulWidget {
  static const route = "/signup-step1";

  const SignupStep1({super.key});

  @override
  State<SignupStep1> createState() => _SignupStep1State();
}

class _SignupStep1State extends State<SignupStep1> {
  // 🎨 PALETA CONSISTENTE
  static const Color kBgColor = Color(0xFFF8FAFC);
  static const Color kTextPrimary = Color(0xFF0F172A);
  static const Color kTextSecondary = Color(0xFF64748B);
  static const Color kInputBg = Color(0xFFF1F5F9);
  static const Color kBrandColor = Color(0xFF4F46E5); // Indigo

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passController = TextEditingController();

  bool _obscurePass = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final re = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    return re.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 6;
  }

  void _handleContinue() {
    HapticFeedback.lightImpact();
    FocusManager.instance.primaryFocus?.unfocus();

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final pass = passController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || pass.isEmpty) {
      _showError("Por favor, completa todos los campos.");
      return;
    }

    if (!_isValidEmail(email)) {
      _showError("Introduce un email válido.");
      return;
    }

    if (!_isValidPhone(phone)) {
      _showError("Introduce un teléfono válido.");
      return;
    }

    if (pass.length < 6) {
      _showError("La contraseña debe tener al menos 6 caracteres.");
      return;
    }

    // Guardar datos
    signupData.fullName = name;
    signupData.email = email;
    signupData.phone = phone;
    signupData.password = pass;

    Navigator.pushNamed(context, SignupStep2.route);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
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
          "Paso 1 de 3", // Indicador de progreso
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
              widthFactor: 0.33, // 1/3 del progreso
              child: Container(
                decoration: BoxDecoration(color: kBrandColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TÍTULOS
                const Text(
                  "Crea tu cuenta",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: kTextPrimary,
                    letterSpacing: -0.8,
                  ),
                ).animate().fadeIn().slideY(begin: 0.3, curve: Curves.easeOut),

                const SizedBox(height: 10),

                const Text(
                  "Tus datos básicos para empezar a jugar.",
                  style: TextStyle(
                    fontSize: 16,
                    color: kTextSecondary,
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3, curve: Curves.easeOut),

                const SizedBox(height: 40),

                // 2. FORMULARIO FLOTANTE (Sin Card pesada)
                Column(
                  children: [
                    _ProInput(
                      controller: nameController,
                      label: "Nombre completo",
                      icon: Icons.person_outline_rounded,
                      inputType: TextInputType.name,
                      textAction: TextInputAction.next,
                      autofill: const [AutofillHints.name],
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),

                    const SizedBox(height: 20),

                    _ProInput(
                      controller: emailController,
                      label: "Email",
                      icon: Icons.alternate_email_rounded,
                      inputType: TextInputType.emailAddress,
                      textAction: TextInputAction.next,
                      autofill: const [AutofillHints.email],
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),

                    const SizedBox(height: 20),

                    _ProInput(
                      controller: phoneController,
                      label: "Teléfono",
                      icon: Icons.phone_iphone_rounded,
                      inputType: TextInputType.phone,
                      textAction: TextInputAction.next,
                      autofill: const [AutofillHints.telephoneNumber],
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),

                    const SizedBox(height: 20),

                    _ProInput(
                      controller: passController,
                      label: "Contraseña",
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscurePass,
                      onToggleVisibility: () => setState(() => _obscurePass = !_obscurePass),
                      textAction: TextInputAction.done,
                      autofill: const [AutofillHints.newPassword],
                    ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
                  ],
                ),

                const SizedBox(height: 50),

                // 3. BOTÓN CONTINUAR
                _GradientButton(
                  text: "Continuar",
                  onTap: _handleContinue,
                ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.9, 0.9)),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =======================================================
// 🧩 WIDGETS REUTILIZABLES (Diseño Profesional)
// =======================================================

// Input Moderno
class _ProInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final TextInputType inputType;
  final TextInputAction textAction;
  final Iterable<String>? autofill;

  const _ProInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.inputType = TextInputType.text,
    this.textAction = TextInputAction.next,
    this.autofill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _SignupStep1State.kInputBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _SignupStep1State.kTextSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: inputType,
            textInputAction: textAction,
            autofillHints: autofill,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _SignupStep1State.kTextPrimary,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: _SignupStep1State.kTextSecondary),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: _SignupStep1State.kTextSecondary,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              hintText: "Escribe aquí...",
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

// Botón Gradiente con Física
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
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6200EA), Color(0xFF00B0FF)], // Púrpura -> Cian
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6200EA).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}