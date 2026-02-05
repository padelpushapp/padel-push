import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../auth/user_provider.dart';
import '../../app/main_app_screen.dart';
import '../signup_step1/signup_step1.dart';

class LoginScreen extends StatefulWidget {
  static const String route = "/login";

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  
  // 🎨 PALETA BRAND (Gradient Flow)
  static const Color kPurpleBrand = Color(0xFF6200EA); // Deep Purple
  static const Color kCyanBrand = Color(0xFF00B0FF);   // Bright Cyan
  
  // Colores UI
  static const Color kBgColor = Color(0xFFF8FAFC);      
  static const Color kSurfaceColor = Colors.white;
  static const Color kTextPrimary = Color(0xFF0F172A);  
  static const Color kTextSecondary = Color(0xFF64748B); 
  static const Color kInputBg = Color(0xFFF1F5F9);      

  bool rememberMe = false;
  bool loading = false;
  bool _obscurePass = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRememberFlag();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart));

    _animController.forward();
  }

  Future<void> _loadRememberFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        rememberMe = prefs.getBool("rememberMe") ?? false;
      });
    }
  }

  Future<void> _saveRememberFlag() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("rememberMe", rememberMe);
  }

  @override
  void dispose() {
    _animController.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveFcmTokenToSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await Supabase.instance.client.from("users").update({"push_token": token}).eq("id", user.id);
    } catch (_) {}
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showError("Por favor, completa todos los campos.");
      return;
    }

    setState(() => loading = true);

    try {
      final supabase = Supabase.instance.client;
      final res = await supabase.auth.signInWithPassword(email: email, password: pass);

      if (res.user == null) throw Exception("Credenciales incorrectas");

      final userProvider = context.read<UserProvider>();
      await userProvider.loadUserProfile();

      if (userProvider.user == null) {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignupStep1()));
        return;
      }

      await _saveFcmTokenToSupabase();
      if (rememberMe) await _saveRememberFlag();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, MainAppScreen.route);

    } catch (e) {
      _showError("Email o contraseña incorrectos.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, // Centrado Vertical Perfecto
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Spacer dinámico superior (opcional, ayuda en pantallas muy altas)
                        const SizedBox(height: 20),

                        // 1. LOGO & BRANDING
                        _AnimatedLogo(),
                        
                        const SizedBox(height: 24), // Reducido de 32 a 24
                        
                        const Text(
                          "Hola de nuevo",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: kTextPrimary,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Tu comunidad te está esperando.",
                          style: TextStyle(fontSize: 15, color: kTextSecondary),
                        ),

                        const SizedBox(height: 32), // Reducido de 40 a 32

                        // 2. FORMULARIO CARD (Glassy & Clean)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: kSurfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: kPurpleBrand.withOpacity(0.06), // Sombra tintada suave
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              // EMAIL INPUT
                              _NeoInput(
                                controller: emailCtrl,
                                label: "Email",
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16), // Espacio más ajustado
                              
                              // PASS INPUT
                              _NeoInput(
                                controller: passCtrl,
                                label: "Contraseña",
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                obscureText: _obscurePass,
                                onToggleVisibility: () => setState(() => _obscurePass = !_obscurePass),
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _handleLogin(),
                              ),
                              
                              const SizedBox(height: 20),

                              // OPCIONES
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(() => rememberMe = !rememberMe);
                                    },
                                    child: Row(
                                      children: [
                                        _CustomCheckbox(value: rememberMe),
                                        const SizedBox(width: 8),
                                        const Text("Recordarme", style: TextStyle(color: kTextSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [kCyanBrand, kCyanBrand],
                                      ).createShader(bounds),
                                      child: const Text("¿Olvidaste tu contraseña?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  )
                                ],
                              ),

                              const SizedBox(height: 28),

                              // BOTÓN GRADIENTE
                              _GradientButton(
                                text: "Iniciar Sesión",
                                isLoading: loading,
                                onTap: _handleLogin,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // 3. FOOTER
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupStep1()));
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: "¿No tienes cuenta? ",
                              style: TextStyle(color: kTextSecondary, fontSize: 15, fontFamily: 'Roboto'),
                              children: [
                                TextSpan(
                                  text: "Regístrate",
                                  style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Margen inferior para seguridad
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}

// =======================================================
// 🧩 COMPONENTES UI MEJORADOS
// =======================================================

class _AnimatedLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90, // Un poco más compacto
      height: 90,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _LoginScreenState.kPurpleBrand.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _LoginScreenState.kCyanBrand.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(-5, 5),
          ),
        ],
      ),
      child: Image.asset("assets/logo.png", fit: BoxFit.contain,
        errorBuilder: (c, e, s) => const Icon(Icons.all_inclusive_rounded, size: 45, color: _LoginScreenState.kPurpleBrand),
      ),
    );
  }
}

class _NeoInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _NeoInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _LoginScreenState.kTextPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _LoginScreenState.kInputBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            autofillHints: autofillHints,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(fontWeight: FontWeight.w600, color: _LoginScreenState.kTextPrimary),
            decoration: InputDecoration(
              hintText: "Introduce tu $label",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(icon, color: _LoginScreenState.kTextSecondary, size: 20), // Icono más sutil
              suffixIcon: isPassword 
                ? IconButton(
                    icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey, size: 20),
                    onPressed: onToggleVisibility,
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomCheckbox extends StatelessWidget {
  final bool value;
  const _CustomCheckbox({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 22, height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7), // Bordes más suaves
        gradient: value 
          ? const LinearGradient(colors: [_LoginScreenState.kPurpleBrand, _LoginScreenState.kCyanBrand]) 
          : null,
        color: value ? null : Colors.transparent,
        border: value ? null : Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: value ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
    );
  }
}

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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => !widget.isLoading ? _ctrl.forward() : null,
      onTapUp: (_) => !widget.isLoading ? _ctrl.reverse() : null,
      onTapCancel: () => !widget.isLoading ? _ctrl.reverse() : null,
      onTap: widget.isLoading ? null : () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 54, // Altura estándar ergonómica
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [_LoginScreenState.kPurpleBrand, _LoginScreenState.kCyanBrand],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _LoginScreenState.kPurpleBrand.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(
                  widget.text,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
        ),
      ),
    );
  }
}