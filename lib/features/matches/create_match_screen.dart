// lib/features/matches/create_match_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/user_provider.dart';
import 'widgets/location_autocomplete_field.dart';

class CreateMatchScreen extends StatefulWidget {
  static const route = "/create-match";

  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final supabase = Supabase.instance.client;

  final _scrollCtrl = ScrollController();
  bool _lockScroll = false;

  final _priceCtrl = TextEditingController();

  // Ubicación
  String? locationName;
  double? pickedLat;
  double? pickedLng;

  GoogleMapController? _mapController;
  Marker? _pinMarker;

  // Fecha / Hora
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Nivel
  double _levelStart = 3.0;
  double _levelEnd = 3.5;

  // Otros campos
  int _duration = 90;
  int _neededPlayers = 2;

  String _environment = "indoor";
  String _wallType = "cristal";
  String _category = "mixto";

  // Tipo de partido (nuevo)
  String _matchType = "amistoso";

  // Extras
  bool _extraBalls = false;
  bool _extraBeer = false;

  bool _loading = false;

  static const CameraPosition _valenciaCam = CameraPosition(
    target: LatLng(39.4702, -0.3768),
    zoom: 13,
  );

  @override
  void dispose() {
    _priceCtrl.dispose();
    _scrollCtrl.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // -----------------------
  // MAP HELPERS
  // -----------------------
  void _moveCameraTo(double lat, double lng, {double zoom = 16}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: zoom),
      ),
    );
  }

  void _setPinnedLocation(double lat, double lng, {String? label}) {
    pickedLat = lat;
    pickedLng = lng;
    locationName = label ?? locationName;

    _pinMarker = Marker(
      markerId: const MarkerId("picked"),
      position: LatLng(lat, lng),
      draggable: true,
      onDragEnd: (pos) {
        setState(() {
          pickedLat = pos.latitude;
          pickedLng = pos.longitude;
        });
      },
    );

    setState(() {});
    _moveCameraTo(lat, lng);
  }

  // -----------------------
  // PICKERS
  // -----------------------
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // -----------------------
  // VALIDACIÓN
  // -----------------------
  bool _validate() {
    if (locationName == null || pickedLat == null || pickedLng == null) {
      _snack("Selecciona una ubicación válida.");
      return false;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _snack("Selecciona fecha y hora.");
      return false;
    }
    if (_levelEnd < _levelStart) {
      _snack("El nivel final no puede ser menor que el inicial.");
      return false;
    }
    return true;
  }

  void _snack(String t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t)),
    );
  }

  // -----------------------
  // SUBMIT
  // -----------------------
  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _loading = true);

    try {
      final user = context.read<UserProvider>().user;
      if (user == null) {
        _snack("No hay sesión activa.");
        return;
      }

      final date = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final price =
          double.tryParse(_priceCtrl.text.replaceAll(",", ".")) ?? 0.0;

      final payload = {
        "creator_id": user.id,
        "club": locationName ?? "",
        "location": locationName ?? "",
        "latitude": pickedLat,
        "longitude": pickedLng,
        "date": date.toIso8601String().split("T")[0],
        "time":
            "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:00",
        "duration": _duration,
        "level_start": _levelStart,
        "level_end": _levelEnd,
        "price": price,
        "environment": _environment,
        "wall_type": _wallType,
        "category": _category,
        "needed_players": _neededPlayers,
        "match_type": _matchType,
        "extra_balls": _extraBalls,
        "extra_beer": _extraBeer,
      };

      final res = await supabase
          .from("matches")
          .insert(payload)
          .select()
          .single();

      Navigator.pop(context, {
        "match": res,
        "lat": pickedLat,
        "lng": pickedLng,
      });
    } catch (e) {
      _snack("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -----------------------
  // UI BUILDER HELPERS
  // -----------------------
  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _chip(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.black : const Color(0xFFF2F3F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // -----------------------
  // BUILD
  // -----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear partido"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      backgroundColor: const Color(0xFFF0F1F3),

      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (_) => _lockScroll,
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            physics: _lockScroll
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),

            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===========================================================
                // TARJETA PRINCIPAL
                // ===========================================================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // UBICACIÓN
                      _section("Ubicación (nombre del club o dirección)"),
                      LocationAutocompleteField(
                        onLocationSelected: (name, lat, lng) =>
                            _setPinnedLocation(lat, lng, label: name),
                        onManualTextChanged: (t) => locationName = t,
                      ),

                      const SizedBox(height: 16),

                      // MAPA
                      Listener(
                        onPointerDown: (_) =>
                            setState(() => _lockScroll = true),
                        onPointerUp: (_) =>
                            setState(() => _lockScroll = false),
                        child: SizedBox(
                          height: 220,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: GoogleMap(
                              initialCameraPosition: _valenciaCam,
                              markers: _pinMarker != null
                                  ? {_pinMarker!}
                                  : <Marker>{},

                              onMapCreated: (c) => _mapController = c,

                              zoomControlsEnabled: true,
                              zoomGesturesEnabled: true,
                              scrollGesturesEnabled: true,
                              rotateGesturesEnabled: true,
                              tiltGesturesEnabled: true,

                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,

                              onTap: (pos) =>
                                  _setPinnedLocation(pos.latitude, pos.longitude),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // FECHA y HORA
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _section("Fecha"),
                                GestureDetector(
                                  onTap: _pickDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F3F5),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      _selectedDate == null
                                          ? "Seleccionar"
                                          : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _section("Hora"),
                                GestureDetector(
                                  onTap: _pickTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F3F5),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      _selectedTime == null
                                          ? "Seleccionar"
                                          : "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // TIPO DE PARTIDO (CHIPS)
                      _section("Tipo de partido"),
                      Wrap(
                        spacing: 10,
                        children: [
                          _chip("Amistoso", _matchType == "amistoso",
                              () => setState(() => _matchType = "amistoso")),
                          _chip("Competitivo", _matchType == "competitivo",
                              () => setState(() => _matchType = "competitivo")),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // NIVEL
                      _section("Nivel"),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(_levelStart.toStringAsFixed(2)),
                                Slider(
                                  value: _levelStart,
                                  min: 0,
                                  max: 6,
                                  divisions: 24,
                                  onChanged: (v) {
                                    setState(() {
                                      _levelStart = v;
                                      if (_levelStart > _levelEnd) {
                                        _levelEnd = _levelStart;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(_levelEnd.toStringAsFixed(2)),
                                Slider(
                                  value: _levelEnd,
                                  min: 0,
                                  max: 6,
                                  divisions: 24,
                                  onChanged: (v) {
                                    setState(() {
                                      _levelEnd = v;
                                      if (_levelEnd < _levelStart) {
                                        _levelStart = _levelEnd;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // DURACIÓN / PRECIO / FALTAN
                      Row(
                        children: [
                          // DURACIÓN
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _section("Duración"),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F3F5),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: DropdownButton<int>(
                                    value: _duration,
                                    isExpanded: true,
                                    underline: const SizedBox.shrink(),
                                    onChanged: (v) =>
                                        setState(() => _duration = v ?? 90),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 60, child: Text("60 min")),
                                      DropdownMenuItem(
                                          value: 75, child: Text("75 min")),
                                      DropdownMenuItem(
                                          value: 90, child: Text("90 min")),
                                      DropdownMenuItem(
                                          value: 105, child: Text("105 min")),
                                      DropdownMenuItem(
                                          value: 120, child: Text("120 min")),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // PRECIO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _section("Precio €"),
                                TextField(
                                  controller: _priceCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF2F3F5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // FALTAN
                          SizedBox(
                            width: 90,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _section("Faltan"),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F3F5),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () => setState(() =>
                                            _neededPlayers =
                                                (_neededPlayers - 1)
                                                    .clamp(1, 10)),
                                        child: const Icon(Icons.remove,
                                            size: 18),
                                      ),
                                      Text("$_neededPlayers"),
                                      GestureDetector(
                                        onTap: () => setState(() =>
                                            _neededPlayers =
                                                (_neededPlayers + 1)
                                                    .clamp(1, 10)),
                                        child:
                                            const Icon(Icons.add, size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // CARACTERÍSTICAS
                      _section("Características"),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _chip("Indoor", _environment == "indoor",
                              () => setState(() => _environment = "indoor")),
                          _chip("Outdoor", _environment == "outdoor",
                              () => setState(() => _environment = "outdoor")),

                          _chip("Cristal", _wallType == "cristal",
                              () => setState(() => _wallType = "cristal")),
                          _chip("Muro", _wallType == "muro",
                              () => setState(() => _wallType = "muro")),

                          _chip("Mixto", _category == "mixto",
                              () => setState(() => _category = "mixto")),
                          _chip("Masculino", _category == "masculino",
                              () => setState(() => _category = "masculino")),
                          _chip("Femenino", _category == "femenino",
                              () => setState(() => _category = "femenino")),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // EXTRAS
                      _section("Extras"),
                      Wrap(
                        spacing: 10,
                        children: [
                          _chip("Bolas 🎾", _extraBalls,
                              () => setState(() => _extraBalls = !_extraBalls)),
                          _chip("Cerveza 🍺", _extraBeer,
                              () => setState(() => _extraBeer = !_extraBeer)),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // BOTÓN
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "CREAR PARTIDO",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Center(
                  child: Text(
                    "Toca el mapa para elegir ubicación.",
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
