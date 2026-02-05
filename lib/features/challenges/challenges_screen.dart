import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with TickerProviderStateMixin {
  
  // 🎨 PALETA UI/UX "FOCUS"
  static const Color kBgColor = Color(0xFFF8FAFC);
  static const Color kTextPrimary = Color(0xFF0F172A);
  static const Color kTextSecondary = Color(0xFF64748B);
  static const Color kBrandIndigo = Color(0xFF4F46E5);
  static const Color kBrandAccent = Color(0xFF818CF8);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kCardWhite = Colors.white;

  // DATOS MOCK (Sin propiedad 'locked' en el constructor, todos abiertos)
  final List<_Challenge> _challenges = [
    _Challenge("c1", "Primer Saque", "Completa tu primer partido", 1.0, 50, false, Icons.check_circle_rounded),
    _Challenge("c2", "Pareja Estable", "5 partidos con el mismo compañero", 1.0, 100, false, Icons.group_rounded), // LISTO
    _Challenge("c3", "Racha Ganadora", "Gana 3 seguidos", 0.45, 150, false, Icons.emoji_events_rounded), // EN PROGRESO
    _Challenge("c4", "Maratón", "Juega 300 minutos esta semana", 0.0, 200, false, Icons.timer_rounded),
    _Challenge("c5", "Leyenda", "Alcanza nivel 5.0", 0.0, 500, false, Icons.workspace_premium_rounded),
    _Challenge("c6", "Social", "Invita a 3 amigos", 0.0, 50, false, Icons.share_rounded),
  ];

  int _level = 12;
  double _currentXp = 4200;
  double _nextLevelXp = 5000;
  
  // ID del reto que el usuario tiene "Fijado"
  String _trackedId = "c3"; 

  late AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000)
    )..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _claimReward(_Challenge c) {
    if (c.claimed || c.progress < 1.0) return;
    
    HapticFeedback.heavyImpact(); 
    
    setState(() {
      c.claimed = true;
      double newXp = _currentXp + c.xpReward;
      
      if (newXp >= _nextLevelXp) {
        _level++;
        _currentXp = newXp - _nextLevelXp;
        _nextLevelXp = _nextLevelXp * 1.1;
        _showLevelUpDialog();
      } else {
        _currentXp = newXp;
      }
    });
  }

  void _showLevelUpDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kTextPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Row(
          children: [
            Icon(Icons.arrow_upward_rounded, color: Colors.greenAccent),
            SizedBox(width: 12),
            Text("¡NIVEL SUBIDO!", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
      )
    );
  }

  void _setTracking(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _trackedId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos el reto fijado
    final _Challenge trackedChallenge = _challenges.firstWhere(
      (c) => c.id == _trackedId, 
      orElse: () => _challenges.first
    );

    // 2. Lista de "Otros Retos"
    final otherChallenges = _challenges.where((c) => c.id != _trackedId).toList();
    
    // Ordenamos: No completados primero
    otherChallenges.sort((a, b) {
      if (a.claimed && !b.claimed) return 1;
      if (!a.claimed && b.claimed) return -1;
      return 0;
    });

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0, top: 12),
          child: Text("Tu Progreso", style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1.0)),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. HERO SECTION: EL ANILLO DE NIVEL
          SliverToBoxAdapter(
            child: _SlideFadeEntry(
              delay: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: _LevelRingHeader(level: _level, current: _currentXp, max: _nextLevelXp),
              ),
            ),
          ),

          // 2. TÍTULO SECCIÓN FOCO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: const [
                  Icon(Icons.push_pin_rounded, size: 16, color: kBrandIndigo),
                  SizedBox(width: 8),
                  Text("OBJETIVO FIJADO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kBrandIndigo, letterSpacing: 1.0)),
                ],
              ),
            ),
          ),

          // 3. TARJETA GRANDE (EL RETO FIJADO)
          SliverToBoxAdapter(
            child: _SlideFadeEntry(
              delay: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
                  child: _FocusChallengeCard(
                    key: ValueKey(trackedChallenge.id),
                    challenge: trackedChallenge,
                    onClaim: () => _claimReward(trackedChallenge),
                  ),
                ),
              ),
            ),
          ),

          // 4. LISTA DEL RESTO DE MISIONES
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
              child: const Text("TODAS LAS MISIONES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kTextSecondary, letterSpacing: 1.0)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final c = otherChallenges[index];
                  return _SlideFadeEntry(
                    delay: 2 + (index % 3),
                    child: _MissionListTile(
                      challenge: c,
                      onTrack: () => _setTracking(c.id),
                      onClaim: () => _claimReward(c),
                    ),
                  );
                },
                childCount: otherChallenges.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// =======================================================
// 🎯 FOCUS CARD (TARJETA GRANDE DE SEGUIMIENTO)
// =======================================================
class _FocusChallengeCard extends StatelessWidget {
  final _Challenge challenge;
  final VoidCallback onClaim;

  const _FocusChallengeCard({super.key, required this.challenge, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final bool canClaim = challenge.progress >= 1.0 && !challenge.claimed;
    final bool isDone = challenge.claimed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _ChallengesScreenState.kBrandIndigo.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(color: _ChallengesScreenState.kBrandIndigo.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _ChallengesScreenState.kBgColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isDone ? Icons.check_circle : challenge.icon, 
                  size: 32, 
                  color: isDone ? Colors.green : _ChallengesScreenState.kBrandIndigo
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ChallengesScreenState.kTextPrimary)),
                    const SizedBox(height: 4),
                    Text(challenge.subtitle, style: const TextStyle(fontSize: 14, color: _ChallengesScreenState.kTextSecondary, height: 1.4)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          
          if (canClaim)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ChallengesScreenState.kTextPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text("RECLAMAR AHORA", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
              ),
            )
          else if (isDone)
             Container(
               width: double.infinity,
               padding: const EdgeInsets.symmetric(vertical: 12),
               decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
               child: const Center(child: Text("¡Misión Completada!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
             )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Progreso", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                    Text("${(challenge.progress * 100).toInt()}%", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _ChallengesScreenState.kBrandIndigo)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: challenge.progress,
                    minHeight: 12,
                    backgroundColor: _ChallengesScreenState.kBgColor,
                    valueColor: const AlwaysStoppedAnimation(_ChallengesScreenState.kBrandIndigo),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }
}

// =======================================================
// 📋 LIST TILE (CON BOTÓN DE "FIJAR")
// =======================================================
class _MissionListTile extends StatelessWidget {
  final _Challenge challenge;
  final VoidCallback onTrack;
  final VoidCallback onClaim;

  const _MissionListTile({required this.challenge, required this.onTrack, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final bool canClaim = challenge.progress >= 1.0 && !challenge.claimed;
    final bool isDone = challenge.claimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.transparent), 
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDone ? Colors.green.withOpacity(0.1) : _ChallengesScreenState.kBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDone ? Icons.check : challenge.icon, 
              color: isDone ? Colors.green : _ChallengesScreenState.kTextSecondary, 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Opacity(
              opacity: isDone ? 0.5 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title, 
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _ChallengesScreenState.kTextPrimary),
                  ),
                  const SizedBox(height: 2),
                  if (!isDone)
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(value: challenge.progress, minHeight: 4, backgroundColor: Colors.grey.shade100, color: _ChallengesScreenState.kBrandIndigo),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text("+${challenge.xpReward} XP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                      ],
                    )
                  else
                    Text("Recompensa obtenida", style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Acciones
          if (canClaim)
            GestureDetector(
              onTap: onClaim,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: _ChallengesScreenState.kTextPrimary, borderRadius: BorderRadius.circular(10)),
                child: const Text("Reclamar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
              ),
            )
          else if (!isDone)
            // Botón de Fijar (Pin)
            IconButton(
              onPressed: onTrack,
              icon: const Icon(Icons.push_pin_outlined, color: _ChallengesScreenState.kBrandIndigo),
              tooltip: "Fijar como objetivo",
              style: IconButton.styleFrom(
                backgroundColor: _ChallengesScreenState.kBrandIndigo.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
        ],
      ),
    );
  }
}

// =======================================================
// 🧬 ANILLO DE NIVEL (CORREGIDO)
// =======================================================
class _LevelRingHeader extends StatelessWidget {
  final int level;
  final double current, max;

  const _LevelRingHeader({required this.level, required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200, height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(200, 200),
              painter: _RingPainter(progress: 1.0, color: Colors.grey.shade200, width: 15),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: (current / max).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (ctx, val, _) {
                return CustomPaint(
                  size: const Size(200, 200),
                  painter: _RingPainter(progress: val, color: _ChallengesScreenState.kBrandIndigo, width: 15, isGradient: true),
                );
              },
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, size: 28, color: _ChallengesScreenState.kBrandIndigo),
                const SizedBox(height: 4),
                Text("$level", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: _ChallengesScreenState.kTextPrimary, height: 1.0)),
                Text("NIVEL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ChallengesScreenState.kTextSecondary.withOpacity(0.6), letterSpacing: 1.0)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double width;
  final bool isGradient;

  _RingPainter({required this.progress, required this.color, required this.width, this.isGradient = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - width) / 2;
    // ✅ CORREGIDO: Variables locales 'final', no 'const'
    final startAngle = 0.75 * math.pi;
    final sweepAngle = 1.5 * math.pi; 

    final paint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = width;

    if (isGradient) {
      paint.shader = SweepGradient(
        colors: [color.withOpacity(0.5), color],
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        // ✅ CORREGIDO: Sin 'const'
        transform: GradientRotation(math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    } else {
      paint.color = color;
    }

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * progress, false, paint);
  }
  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

// Animación de entrada
class _SlideFadeEntry extends StatelessWidget {
  final int delay;
  final Widget child;
  const _SlideFadeEntry({required this.child, required this.delay});
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (delay * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, val, child) {
        return Opacity(
          opacity: val,
          child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child),
        );
      },
      child: child,
    );
  }
}

// Modelo
class _Challenge {
  final String id, title, subtitle;
  final double progress;
  final int xpReward;
  bool claimed; // Mutable
  final IconData icon;
  
  _Challenge(this.id, this.title, this.subtitle, this.progress, this.xpReward, this.claimed, this.icon);
  
  // Getter de compatibilidad (siempre falso)
  bool get locked => false; 
}