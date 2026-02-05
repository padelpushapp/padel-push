import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/user_provider.dart';
import '../models/match_model.dart';

class MyMatchesScreen extends StatefulWidget {
  static const route = "/my-matches";

  const MyMatchesScreen({super.key});

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  bool _loading = true;
  List<MatchModel> _allMatches = [];
  late TabController _tabController;

  // 🎨 PALETA "NEO-SWISS"
  static const Color kBgColor = Color(0xFFF2F4F7);
  static const Color kTextPrimary = Color(0xFF101828);
  static const Color kTextSecondary = Color(0xFF667085);
  static const Color kAccentColor = Color(0xFF0055FF);
  static const Color kSuccessColor = Color(0xFF12B76A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDemoData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDemoData() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final now = DateTime.now();

    final List<MatchModel> demoMatches = [
      MatchModel(
        id: 'demo1',
        creatorId: 'user1',
        date: now.add(const Duration(days: 1)), 
        time: '19:30',
        club: 'Club Padel Premium',
        price: 6.50,
        levelStart: 3.5,
        levelEnd: 4.0,
        environment: 'Competitivo', 
        latitude: 0, longitude: 0, duration: 90, neededPlayers: 4,
        matchType: 'partido', wallType: 'Cristal', category: 'Mixto', extraBalls: true, extraBeer: false,
      ),
      MatchModel(
        id: 'demo2',
        creatorId: 'user1',
        date: now.add(const Duration(days: 2)), 
        time: '10:00',
        club: 'Indoor Padel Zone',
        price: 5.00,
        levelStart: 2.0,
        levelEnd: 2.5,
        environment: 'Amistoso',
        latitude: 0, longitude: 0, duration: 60, neededPlayers: 4,
        matchType: 'clase', wallType: 'Muro', category: 'Masculino', extraBalls: false, extraBeer: false,
      ),
      MatchModel(
        id: 'demo3',
        creatorId: 'user1',
        date: now.subtract(const Duration(days: 1)), 
        time: '20:00',
        club: 'Polideportivo Central',
        price: 4.50,
        levelStart: 4.0,
        levelEnd: 5.0,
        environment: 'Torneo',
        latitude: 0, longitude: 0, duration: 90, neededPlayers: 4,
        matchType: 'torneo', wallType: 'Cristal', category: 'Abierto', extraBalls: true, extraBeer: true,
      ),
    ];

    if (mounted) {
      setState(() {
        _allMatches = demoMatches;
        _loading = false;
      });
    }
  }

  List<MatchModel> get _confirmedMatches {
    final now = DateTime.now();
    return _allMatches.where((m) => m.date.isAfter(now) && m.environment == 'Competitivo').toList();
  }

  List<MatchModel> get _pendingMatches {
    final now = DateTime.now();
    return _allMatches.where((m) => m.date.isAfter(now) && m.environment == 'Amistoso').toList();
  }

  List<MatchModel> get _pastMatches {
    final now = DateTime.now();
    return _allMatches.where((m) => m.date.isBefore(now)).toList();
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await _loadDemoData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: 8.0, top: 12),
          child: Text(
            "Agenda",
            style: TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 30,
              letterSpacing: -1.2,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          _ModernTabBar(controller: _tabController),
          const SizedBox(height: 20),
          Expanded(
            child: _loading 
            ? _buildSkeletonList()
            : TabBarView(
              controller: _tabController,
              children: [
                _MatchListView(matches: _confirmedMatches, isPast: false),
                _MatchListView(matches: _pendingMatches, isPast: false, isPending: true),
                _MatchListView(matches: _pastMatches, isPast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

class _ModernTabBar extends StatelessWidget {
  final TabController controller;

  const _ModernTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: _MyMatchesScreenState.kTextPrimary,
          borderRadius: BorderRadius.circular(22),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _MyMatchesScreenState.kTextSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Roboto'),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        tabs: const [
          Tab(text: "Próximos"),
          Tab(text: "Pendientes"),
          Tab(text: "Historial"),
        ],
      ),
    );
  }
}

class _MatchListView extends StatelessWidget {
  final List<MatchModel> matches;
  final bool isPast;
  final bool isPending;

  const _MatchListView({required this.matches, this.isPast = false, this.isPending = false});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return _EmptyState(isPast: isPast);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        return _SlideEntry(
          index: index,
          child: _PressableCard(
            onTap: () {
               Navigator.pushNamed(context, "/match-detail", arguments: matches[index]);
            },
            child: _MatchContent(
              match: matches[index],
              isPast: isPast,
              isPending: isPending,
            ),
          ),
        );
      },
    );
  }
}

class _PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableCard({required this.child, required this.onTap});

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
         _ctrl.reverse();
         HapticFeedback.selectionClick();
         widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.transparent, 
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF101828).withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}

// =======================================================
// 🎟️ CONTENIDO DE LA TARJETA (NUEVAS FUNCIONES)
// =======================================================
class _MatchContent extends StatelessWidget {
  final MatchModel match;
  final bool isPast;
  final bool isPending;

  const _MatchContent({required this.match, required this.isPast, required this.isPending});

  @override
  Widget build(BuildContext context) {
    final Color dateBg = isPast ? Colors.grey.shade100 : _MyMatchesScreenState.kAccentColor.withOpacity(0.08);
    final Color dateText = isPast ? Colors.grey : _MyMatchesScreenState.kAccentColor;
    
    final day = match.date.day.toString().padLeft(2, '0');
    final month = _getMonthName(match.date.month);

    return Container(
      // Aumentamos altura para acomodar la fila extra de acciones
      height: 155, 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Row(
        children: [
          // 1. COLUMNA FECHA
          Container(
            width: 85,
            decoration: BoxDecoration(
              color: dateBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: dateText,
                    height: 1.0,
                  ),
                ),
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPast ? Colors.grey : _MyMatchesScreenState.kTextPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                // Icono clima decorativo
                Icon(
                  isPast ? Icons.cloud_done_outlined : Icons.wb_sunny_rounded,
                  size: 20,
                  color: isPast ? Colors.grey.shade400 : Colors.orangeAccent,
                )
              ],
            ),
          ),

          // 2. CONTENIDO PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER: Hora + Estado ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: _MyMatchesScreenState.kTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            match.time,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _MyMatchesScreenState.kTextPrimary),
                          ),
                        ],
                      ),
                      
                      if (isPending)
                        _StatusBadge(text: "Pendiente", color: Colors.orange.shade800)
                      else if (isPast)
                        _StatusBadge(text: "Finalizado", color: Colors.grey.shade600)
                      else
                        _StatusBadge(text: "Confirmado", color: _MyMatchesScreenState.kSuccessColor)
                    ],
                  ),

                  const SizedBox(height: 8),

                  // --- CLUB NAME ---
                  Text(
                    match.club ?? "Club Padel Norte",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isPast ? Colors.grey : _MyMatchesScreenState.kTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // --- 📍 ACCIÓN MAPA (NUEVO) ---
                  if (!isPast) 
                    GestureDetector(
                      onTap: () {
                        // Evita que el tap se propague a la tarjeta
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Abriendo Google Maps..."),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF0055FF)),
                            const SizedBox(width: 4),
                            Text(
                              "Cómo llegar",
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.w600, 
                                color: const Color(0xFF0055FF),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF0055FF).withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Spacer(),

                  // --- FOOTER: AVATARES + PRECIO (NUEVO) ---
                  Row(
                    children: [
                      // Stack de jugadores (Social Proof)
                      _AvatarStack(count: 3),
                      
                      const Spacer(),
                      
                      Text(
                        "6.00€",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isPast ? Colors.grey : _MyMatchesScreenState.kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getMonthName(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    if(month < 1 || month > 12) return "";
    return months[month - 1];
  }
}

// 👥 WIDGET DE AVATARES APILADOS
class _AvatarStack extends StatelessWidget {
  final int count;
  const _AvatarStack({required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70, // Espacio para los círculos
      height: 24,
      child: Stack(
        children: [
          _circle(0, Colors.blue.shade200, "A"),
          _circle(16, Colors.red.shade200, "M"),
          _circle(32, Colors.green.shade200, "J"),
        ],
      ),
    );
  }

  Widget _circle(double left, Color color, String text) {
    return Positioned(
      left: left,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54)),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color; 

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.1)),
        color: color.withOpacity(0.08),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _SlideEntry extends StatefulWidget {
  final int index;
  final Widget child;

  const _SlideEntry({required this.index, required this.child});

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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if(mounted) _ctrl.forward();
    });

    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isPast;
  const _EmptyState({required this.isPast});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0,10))
              ],
            ),
            child: Icon(
              isPast ? Icons.history_rounded : Icons.calendar_today_rounded,
              size: 32,
              color: _MyMatchesScreenState.kTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPast ? "Sin historial" : "Todo despejado",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _MyMatchesScreenState.kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPast 
              ? "Tus partidos finalizados aparecerán aquí." 
              : "No tienes partidos programados.",
            style: const TextStyle(color: _MyMatchesScreenState.kTextSecondary),
          ),
        ],
      ),
    );
  }
}