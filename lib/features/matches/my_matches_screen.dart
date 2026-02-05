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

  // 🎨 PALETA "NEO-SWISS" (Sin Negros Puros)
  static const Color kBgColor = Color(0xFFF1F5F9);      // Slate 100 (Fondo suave)
  static const Color kTextPrimary = Color(0xFF1E293B);  // Slate 800 (Texto principal)
  static const Color kTextSecondary = Color(0xFF64748B); // Slate 500 (Texto secundario)
  static const Color kBrandColor = Color(0xFF4F46E5);   // Indigo (Color de Marca)
  static const Color kSuccessColor = Color(0xFF10B981); // Emerald

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
    await Future.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();

    // Datos Demo con info relevante
    final List<MatchModel> demoMatches = [
      MatchModel(
        id: 'demo1',
        creatorId: 'user1',
        date: now.add(const Duration(days: 1)), 
        time: '19:30',
        club: 'Club Padel Premium',
        price: 6.00,
        levelStart: 3.5,
        levelEnd: 4.0,
        environment: 'Competitivo', 
        latitude: 0, longitude: 0, duration: 90, neededPlayers: 4,
        matchType: 'partido', wallType: 'Cristal', category: 'Indoor', extraBalls: true, extraBeer: false,
      ),
      MatchModel(
        id: 'demo2',
        creatorId: 'user1',
        date: now.add(const Duration(days: 2)), 
        time: '10:00',
        club: 'Indoor Padel Zone',
        price: 5.50,
        levelStart: 2.0,
        levelEnd: 2.5,
        environment: 'Amistoso',
        latitude: 0, longitude: 0, duration: 60, neededPlayers: 4,
        matchType: 'clase', wallType: 'Muro', category: 'Outdoor', extraBalls: false, extraBeer: false,
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
        matchType: 'torneo', wallType: 'Cristal', category: 'Indoor', extraBalls: true, extraBeer: true,
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
              fontSize: 32,
              letterSpacing: -1.0,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Tabs corregidas (Color Vivo y bien centradas)
          _ModernTabBar(controller: _tabController),
          const SizedBox(height: 24),
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

// =======================================================
// 🎛️ MODERN TAB BAR (CORREGIDO)
// =======================================================
class _ModernTabBar extends StatelessWidget {
  final TabController controller;

  const _ModernTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4), // Padding interno para que el indicador "flote"
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TabBar(
        controller: controller,
        // Usamos toda la altura disponible menos el padding
        indicatorSize: TabBarIndicatorSize.tab, 
        indicator: BoxDecoration(
          color: _MyMatchesScreenState.kBrandColor, // Color Vivo (Indigo)
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _MyMatchesScreenState.kBrandColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
              color: const Color(0xFF1E293B).withOpacity(0.06), // Sombra Slate
              blurRadius: 20,
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
// 🎟️ CONTENIDO TARJETA (MINIMAL & MODERNO)
// =======================================================
class _MatchContent extends StatelessWidget {
  final MatchModel match;
  final bool isPast;
  final bool isPending;

  const _MatchContent({required this.match, required this.isPast, required this.isPending});

  @override
  Widget build(BuildContext context) {
    // Configuración de Colores
    final Color dateBg = isPast ? Colors.grey.shade100 : _MyMatchesScreenState.kBrandColor.withOpacity(0.06);
    final Color dateText = isPast ? Colors.grey : _MyMatchesScreenState.kBrandColor;
    final Color textColor = isPast ? Colors.grey.shade500 : _MyMatchesScreenState.kTextPrimary;
    
    final day = match.date.day.toString().padLeft(2, '0');
    final month = _getMonthName(match.date.month);

    return Container(
      height: 140, // Altura ajustada
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1), // Borde limpio
      ),
      child: Row(
        children: [
          // 1. FECHA (Izquierda, limpia, sin sol)
          Container(
            width: 80,
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
                    fontSize: 28,
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
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // 2. INFO DEL PARTIDO
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // --- HEADER: Hora y Estado ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded, size: 14, color: _MyMatchesScreenState.kTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            match.time,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                          ),
                        ],
                      ),
                      
                      // Badges
                      if (isPending)
                        _StatusBadge(text: "Pendiente", color: Colors.orange.shade800)
                      else if (isPast)
                        _StatusBadge(text: "Finalizado", color: Colors.grey.shade500)
                      else
                        _StatusBadge(text: "Confirmado", color: _MyMatchesScreenState.kSuccessColor)
                    ],
                  ),

                  // --- CLUB Y MAPA (FILA CLAVE) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          match.club ?? "Club Padel Norte",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      // Botón Mapa Minimal (Solo icono, sin texto)
                      if (!isPast)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Abriendo mapa...")));
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _MyMatchesScreenState.kBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.map_outlined, size: 18, color: _MyMatchesScreenState.kBrandColor),
                          ),
                        ),
                    ],
                  ),

                  // --- INFO RELEVANTE (TAGS) ---
                  // Sustituye a los avatares
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _DataTag(icon: Icons.roofing_rounded, text: match.category, isGray: isPast), // Indoor/Outdoor
                        const SizedBox(width: 8),
                        _DataTag(icon: Icons.grid_view_rounded, text: match.wallType, isGray: isPast), // Cristal/Muro
                        const SizedBox(width: 8),
                        _DataTag(icon: Icons.timer_outlined, text: "${match.duration}'", isGray: isPast),
                      ],
                    ),
                  ),

                  // --- PRECIO AL FINAL ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "${match.price.toStringAsFixed(2)}€",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
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

// 🏷️ TAG DE DATOS (Minimalist Chip)
class _DataTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isGray;

  const _DataTag({required this.icon, required this.text, required this.isGray});

  @override
  Widget build(BuildContext context) {
    final color = isGray ? Colors.grey.shade400 : _MyMatchesScreenState.kTextSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGray ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
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
        color: color.withOpacity(0.1), // Fondo muy suave
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
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