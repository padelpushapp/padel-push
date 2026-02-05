import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// MOCK DATA
class MockUser {
  final String name = "Alex Padel";
  final String photoUrl = "https://i.pravatar.cc/300?img=5"; 
  final double level = 4.25;
  final String gender = "Masculino";
  final String hand = "Diestro";
  final String position = "Revés"; 
  final String zone = "Valencia Norte";
  final double reputation = 4.9;
  final int trustScore = 92; 
}

class ProfileScreen extends StatefulWidget {
  static const route = "/profile";

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final MockUser user = MockUser(); 
  
  // ESTADO DE SUSCRIPCIÓN (Simulado)
  bool _isPremium = false; 

  // Configuración
  bool _notificationsEnabled = true;
  bool _notTodayMode = false;

  // 🎨 PALETA
  static const Color kBgColor = Color(0xFFF8FAFC);
  static const Color kSurfaceColor = Colors.white;
  static const Color kTextPrimary = Color(0xFF0F172A);
  static const Color kTextSecondary = Color(0xFF64748B);
  static const Color kBrandColor = Color(0xFF4F46E5);
  static const Color kPremiumGold = Color(0xFFD97706); // Amber 600

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // 🚀 LÓGICA DE SUSCRIPCIÓN
  void _handleSubscription() async {
    // 1. Mostrar Modal
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PremiumBenefitsSheet(
        onSubscribe: () async {
          Navigator.pop(context); // Cerrar modal
          
          // 2. Simular Proceso de Pago
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Procesando pago..."),
              duration: Duration(seconds: 1),
            )
          );
          await Future.delayed(const Duration(seconds: 1));

          // 3. Éxito y Cambio de Estado
          setState(() => _isPremium = true);
          HapticFeedback.heavyImpact();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: kSuccessColor,
              content: const Row(
                children: [
                  Icon(Icons.star, color: Colors.white),
                  SizedBox(width: 10),
                  Text("¡Bienvenido al Club Premium!"),
                ],
              ),
            )
          );
        },
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
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Mi Perfil",
                style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  letterSpacing: -0.8,
                ),
              ),
              // Botón Editar Perfil (Limpio)
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Navegar a editar perfil
                },
                icon: const Icon(Icons.edit_rounded, color: kTextPrimary, size: 24),
                tooltip: "Editar Perfil",
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // 1. FICHA DE JUGADOR (Cambia si es Premium)
            _SlideEntry(
              delay: 0,
              child: _PlayerHeader(user: user, isPremium: _isPremium),
            ),
            
            const SizedBox(height: 16),

            // 2. ESTADO PREMIUM (Transición animada entre Free y Pro)
            _SlideEntry(
              delay: 1,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                child: _isPremium 
                  ? _PremiumActiveCard(key: const ValueKey('premium'))
                  : _PremiumUpsellCard(key: const ValueKey('free'), onTap: _handleSubscription),
              ),
            ),

            const SizedBox(height: 16),

            // 3. REPUTACIÓN
            _SlideEntry(
              delay: 2,
              child: _ReputationCard(user: user),
            ),

            const SizedBox(height: 24),

            // 4. OPCIONES DE CUENTA (Nuevo diseño de lista)
            _SlideEntry(
              delay: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text("CUENTA & PAGOS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextSecondary, letterSpacing: 1.0)),
                  ),
                  Container(
                    decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0,4))]),
                    child: Column(
                      children: [
                        _MenuOption(icon: Icons.credit_card_rounded, title: "Métodos de Pago", onTap: () {}),
                        const Divider(height: 1, indent: 56, endIndent: 20),
                        _MenuOption(icon: Icons.history_rounded, title: "Historial de Transacciones", onTap: () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. PREFERENCIAS
            _SlideEntry(
              delay: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text("CONFIGURACIÓN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTextSecondary, letterSpacing: 1.0)),
                  ),
                  Container(
                    decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0,4))]),
                    child: Column(
                      children: [
                        _SettingsRow(
                          label: "Modo 'Hoy no'",
                          icon: Icons.bedtime_rounded,
                          value: _notTodayMode,
                          activeColor: Colors.orange,
                          onChanged: (v) => setState(() => _notTodayMode = v),
                        ),
                        const Divider(height: 1, indent: 56, endIndent: 20),
                        _SettingsRow(
                          label: "Notificaciones",
                          icon: Icons.notifications_active_rounded,
                          value: _notificationsEnabled,
                          activeColor: kBrandColor,
                          onChanged: (v) => setState(() => _notificationsEnabled = v),
                        ),
                        const Divider(height: 1, indent: 56, endIndent: 20),
                        _MenuOption(icon: Icons.help_outline_rounded, title: "Ayuda y Soporte", onTap: () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 6. LOGOUT
            _SlideEntry(
              delay: 5,
              child: TextButton(
                onPressed: () => HapticFeedback.mediumImpact(),
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade400, textStyle: const TextStyle(fontWeight: FontWeight.w700)),
                child: const Text("Cerrar Sesión"),
              ),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// 🪪 HEADER (Sin verificado, con borde dinámico)
// =======================================================
class _PlayerHeader extends StatelessWidget {
  final MockUser user;
  final bool isPremium;

  const _PlayerHeader({required this.user, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    // Si es premium, borde dorado. Si no, color marca.
    final borderColor = isPremium ? const Color(0xFFFFD700) : _ProfileScreenState.kBrandColor;
    final boxShadow = isPremium 
        ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.4), blurRadius: 15, spreadRadius: 1)]
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ProfileScreenState.kSurfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2.5),
                  boxShadow: boxShadow,
                  image: DecorationImage(image: NetworkImage(user.photoUrl), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ProfileScreenState.kTextPrimary, height: 1.1),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 20),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: _ProfileScreenState.kTextSecondary),
                        const SizedBox(width: 4),
                        Text(
                          user.zone,
                          style: const TextStyle(fontSize: 13, color: _ProfileScreenState.kTextSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(label: "NIVEL", value: user.level.toString(), icon: Icons.bar_chart_rounded, color: _ProfileScreenState.kBrandColor),
              _VerticalSep(),
              _StatItem(label: "MANO", value: user.hand, icon: Icons.back_hand_rounded, color: Colors.orange),
              _VerticalSep(),
              _StatItem(label: "POSICIÓN", value: user.position, icon: Icons.sports_tennis_rounded, color: Colors.teal),
            ],
          ),
        ],
      ),
    );
  }
}

// =======================================================
// ⚫ TARJETA PARA USUARIO FREE (Upsell)
// =======================================================
class _PremiumUpsellCard extends StatelessWidget {
  final VoidCallback onTap;

  const _PremiumUpsellCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B), // Slate 900
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.diamond_rounded, color: Color(0xFFFFD700), size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pásate a Premium", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  SizedBox(height: 2),
                  Text("Radar avanzado y 0 esperas", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("VER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            )
          ],
        ),
      ),
    );
  }
}

// =======================================================
// 🟡 TARJETA PARA USUARIO PREMIUM (Active)
// =======================================================
class _PremiumActiveCard extends StatelessWidget {
  const _PremiumActiveCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFFF59E0B)], // Gold Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Eres Premium", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                SizedBox(height: 2),
                Text("Tu suscripción está activa", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}

// =======================================================
// 📜 MODAL DE VENTA (Suscripción)
// =======================================================
class _PremiumBenefitsSheet extends StatelessWidget {
  final VoidCallback onSubscribe;

  const _PremiumBenefitsSheet({required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                  children: [
                    const Text("Nivel PRO 🚀", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    const Text("Desbloquea todo tu potencial.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                    const SizedBox(height: 30),
                    _FeatureRow(icon: Icons.bolt_rounded, title: "Notificaciones Instantáneas", desc: "Sé el primero en entrar a los partidos."),
                    _FeatureRow(icon: Icons.map_rounded, title: "Visibilidad en Mapa", desc: "Tus partidos destacan sobre el resto."),
                    _FeatureRow(icon: Icons.radar_rounded, title: "Modo Radar", desc: "Recomendaciones por compatibilidad."),
                    _FeatureRow(icon: Icons.token_rounded, title: "Tokens Extra", desc: "Recibe tokens mensuales para reservar."),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB), // Amarillo muy claro
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.emoji_events_rounded, color: Colors.orange, size: 32),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Consigue 1 mes GRATIS", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF78350F))),
                                Text("Completa la misión 'Embajador' para probarlo.", style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
                child: ElevatedButton(
                  onPressed: onSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Suscribirse", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(width: 8),
                      Text("•", style: TextStyle(color: Colors.white54)),
                      SizedBox(width: 8),
                      Text("4.99€ / mes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureRow({required this.icon, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF4F46E5), size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))), const SizedBox(height: 2), Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4))])),
        ],
      ),
    );
  }
}

// =======================================================
// WIDGETS AUXILIARES
// =======================================================
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [Icon(icon, size: 20, color: color), const SizedBox(height: 6), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5))]));
  }
}

class _VerticalSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(height: 24, width: 1, color: const Color(0xFFE2E8F0));
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MenuOption({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF0F172A), size: 18)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ReputationCard extends StatelessWidget {
  final MockUser user;
  const _ReputationCard({required this.user});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Row(
        children: [
          Column(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 32), const SizedBox(height: 4), Text(user.reputation.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))]),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Nivel de Confianza", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))), Text("${user.trustScore}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.green))]), const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: user.trustScore / 100, minHeight: 8, backgroundColor: Colors.grey.shade100, valueColor: const AlwaysStoppedAnimation(Colors.green)))]))
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  const _SettingsRow({required this.label, required this.icon, required this.value, required this.activeColor, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: Icon(icon, size: 20, color: Color(0xFF0F172A))), const SizedBox(width: 16), Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))), SizedBox(height: 28, child: Switch.adaptive(value: value, onChanged: onChanged, activeColor: activeColor))]),
    );
  }
}

class _SlideEntry extends StatefulWidget {
  final Widget child;
  final int delay;
  const _SlideEntry({required this.child, required this.delay});
  @override
  State<_SlideEntry> createState() => _SlideEntryState();
}

class _SlideEntryState extends State<_SlideEntry> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    Future.delayed(Duration(milliseconds: widget.delay * 50), () { if(mounted) _ctrl.forward(); });
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) { return FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: widget.child)); }
}

// 🔧 CONSTANTES GLOBALES
const Color kSuccessColor = Color(0xFF10B981);
