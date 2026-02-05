import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../auth/user_provider.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';
import 'map_cluster_engine.dart';

class HomeScreen extends StatefulWidget {
  static const String route = "/home";

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // 🗺️ Mapa
  GoogleMapController? _mapController;
  Set<Marker> markers = {};
  double _currentZoom = 13;
  final MatchService _service = MatchService();
  bool _isClustering = false;

  // ✨ UI State
  bool _popupOpen = false;
  int _selectedFilterIndex = 0;
  late AnimationController _entryAnim;

  // 🏷️ Filtros
  final List<String> _filters = ["Todos", "Competitivo", "Amistoso", "Nivel Alto", "Cerca"];

  // 🎨 PALETA PROFESIONAL
  final Color _brandColor = const Color(0xFF4F46E5); // Indigo
  final Color _activeFilterColor = const Color(0xFF0F172A); // Slate 900
  final Color _inactiveText = const Color(0xFF64748B); // Slate 500

  // 🌍 Estilo Mapa "Pure Canvas"
  // Diseñado específicamente para ocultar TODO el ruido de Google (POIs, Tiendas, Museos)
  final String _mapStyle = '''
  [
    {
      "featureType": "poi",
      "stylers": [{ "visibility": "off" }]
    },
    {
      "featureType": "transit",
      "stylers": [{ "visibility": "off" }]
    },
    {
      "featureType": "road",
      "elementType": "labels.icon",
      "stylers": [{ "visibility": "off" }]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [{ "visibility": "off" }]
    },
    {
      "featureType": "landscape",
      "elementType": "labels",
      "stylers": [{ "visibility": "off" }]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{ "color": "#e9eaf0" }]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{ "color": "#9e9e9e" }]
    },
    {
      "featureType": "landscape",
      "elementType": "geometry",
      "stylers": [{ "color": "#f5f6fa" }]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{ "color": "#ffffff" }]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{ "color": "#dadada" }]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{ "color": "#616161" }]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{ "color": "#f5f5f5" }, { "visibility": "on" }]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _entryAnim.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGICA MAPA
  // ============================================================
  Future<List<ClusterItem>> _getViewportMatches() async {
    if (_mapController == null) return [];
    final bounds = await _mapController!.getVisibleRegion();
    final matches = await _service.getMatchesInBounds(
      minLat: bounds.southwest.latitude,
      maxLat: bounds.northeast.latitude,
      minLng: bounds.southwest.longitude,
      maxLng: bounds.northeast.longitude,
    );
    return matches.map((m) => ClusterItem(id: m.id, lat: m.latitude!, lng: m.longitude!, data: m)).toList();
  }

  Future<void> _updateClusters() async {
    if (_mapController == null || _isClustering) return;
    _isClustering = true;
    final items = await _getViewportMatches();
    final clusters = MapClusterEngine.clusterItems(items: items, zoom: _currentZoom);
    final user = context.read<UserProvider>().user;
    final Set<Marker> newMarkers = {};

    for (final c in clusters) {
      if (c.items.length == 1) {
        final match = c.items.first.data as MatchModel;
        bool compatible = true;
        if (user != null) compatible = match.isCompatible(user.level);
        double hue = !compatible ? BitmapDescriptor.hueBlue 
            : (match.neededPlayers == 3 ? BitmapDescriptor.hueRed 
            : (match.neededPlayers == 2 ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueGreen));

        newMarkers.add(Marker(
          markerId: MarkerId(match.id),
          position: LatLng(match.latitude!, match.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          onTap: () => Navigator.pushNamed(context, "/match-detail", arguments: match),
        ));
      }
    }
    setState(() => markers = newMarkers);
    _isClustering = false;
  }

  void _onMove(CameraPosition pos) => _currentZoom = pos.zoom;
  void _onIdle() => _updateClusters();

  // ============================================================
  // UI BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: const Color(0xFFF1F5F9), 
      body: Stack(
        children: [
          // 1. MAPA (LIMPIO SIN ICONOS)
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(39.4702, -0.376805),
              zoom: 13,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, 
            zoomControlsEnabled: false,
            mapToolbarEnabled: false, 
            compassEnabled: false,
            indoorViewEnabled: false,
            trafficEnabled: false,
            // Bloqueamos la inclinación para mantener el look 2D limpio
            tiltGesturesEnabled: false, 
            onMapCreated: (c) {
              _mapController = c;
              c.setMapStyle(_mapStyle);
              Future.delayed(const Duration(milliseconds: 500), _updateClusters);
            },
            onCameraMove: _onMove,
            onCameraIdle: _onIdle,
            padding: const EdgeInsets.only(bottom: 100),
          ),

          // 2. HEADER CON LOGO & NOTIFICACIONES (Glass)
          Positioned(
            top: topPadding + 10,
            left: 20,
            right: 20,
            child: FadeTransition(
              opacity: _entryAnim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
                    .animate(CurvedAnimation(parent: _entryAnim, curve: Curves.easeOutBack)),
                
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // LOGO DE LA APP + UBICACIÓN
                          Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: _brandColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.sports_tennis_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "PadelPush",
                                    style: TextStyle(
                                      fontFamily: 'Roboto', 
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      height: 1.0,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 10, color: _inactiveText),
                                      const SizedBox(width: 2),
                                      Text(
                                        "Valencia",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _inactiveText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // CAMPANA
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              InkWell(
                                onTap: () => HapticFeedback.lightImpact(),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(Icons.notifications_outlined, color: _activeFilterColor, size: 24),
                                ),
                              ),
                              Positioned(
                                top: 8, right: 8,
                                child: Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. FILTROS COMPACTOS (ANIMACIÓN BOUNCE)
          Positioned(
            top: topPadding + 88, 
            left: 0, 
            right: 0,
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                physics: const BouncingScrollPhysics(),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  return _BouncingChip(
                    label: _filters[index],
                    isSelected: _selectedFilterIndex == index,
                    activeColor: _activeFilterColor,
                    inactiveTextColor: _inactiveText,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilterIndex = index);
                    },
                  );
                },
              ),
            ),
          ),

          // 4. FAB UBICACIÓN (Minimal)
          Positioned(
            right: 20,
            bottom: 110, 
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _mapController?.animateCamera(CameraUpdate.zoomIn());
              },
              backgroundColor: Colors.white,
              foregroundColor: _activeFilterColor,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ✨ WIDGET: BOUNCING FILTER CHIP (ANIMACIÓN FÍSICA)
// ============================================================
class _BouncingChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveTextColor;
  final VoidCallback onTap;

  const _BouncingChip({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveTextColor,
    required this.onTap,
  });

  @override
  State<_BouncingChip> createState() => _BouncingChipState();
}

class _BouncingChipState extends State<_BouncingChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), 
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() async {
    widget.onTap();
    await _controller.forward();
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onTapDown: (_) => _controller.forward(),
      onTapCancel: () => _controller.reverse(),
      child: Padding(
        padding: const EdgeInsets.only(right: 8), 
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
            decoration: BoxDecoration(
              color: widget.isSelected ? widget.activeColor : Colors.white,
              borderRadius: BorderRadius.circular(20), 
              border: Border.all(
                color: widget.isSelected ? Colors.transparent : Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: widget.isSelected
                  ? [BoxShadow(color: widget.activeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                  : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isSelected ? Colors.white : widget.inactiveTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 13, 
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}