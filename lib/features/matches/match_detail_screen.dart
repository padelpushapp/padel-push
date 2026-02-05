import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/user_provider.dart';
import '../models/match_model.dart';
import '../services/match_service.dart';

class MatchDetailScreen extends StatefulWidget {
  static const route = "/match-detail";

  final MatchModel match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final MatchService _matchService = MatchService();

  bool _isInWaitingList = false;
  bool _loadingWaitingList = true;

  bool _hasPendingRequest = false;
  bool _isParticipant = false;

  bool _showNotificationBanner = false;
  DateTime? _bannerExpiresAt;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _loadWaitingListStatus();
    _loadJoinRequestStatus();
    _loadParticipantStatus();

    _bannerTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _refreshBanner());
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  // ===================== DATA =====================

  Future<void> _loadParticipantStatus() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final res = await Supabase.instance.client
        .from("match_participants")
        .select("id")
        .eq("match_id", widget.match.id)
        .eq("user_id", user.id)
        .maybeSingle();

    setState(() => _isParticipant = res != null);
  }

  Future<void> _loadWaitingListStatus() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final exists = await _matchService.isUserInWaitingList(
      matchId: widget.match.id,
      userId: user.id,
    );

    setState(() {
      _isInWaitingList = exists;
      _loadingWaitingList = false;
    });

    await _refreshBanner();
  }

  Future<void> _loadJoinRequestStatus() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final res = await Supabase.instance.client
        .from("match_requests")
        .select("id")
        .eq("match_id", widget.match.id)
        .eq("requester_id", user.id)
        .maybeSingle();

    setState(() => _hasPendingRequest = res != null);
  }

  Future<void> _refreshBanner() async {
    if (!_isInWaitingList) return;

    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final row = await Supabase.instance.client
        .from("waiting_list")
        .select("status, expires_at")
        .eq("match_id", widget.match.id)
        .eq("user_id", user.id)
        .maybeSingle();

    if (row == null) {
      setState(() {
        _isInWaitingList = false;
        _showNotificationBanner = false;
        _bannerExpiresAt = null;
      });
      return;
    }

    final expiresAt = row["expires_at"] != null
        ? DateTime.tryParse(row["expires_at"])
        : null;

    final now = DateTime.now().toUtc();
    final active =
        row["status"] == "notified" && expiresAt != null && expiresAt.isAfter(now);

    setState(() {
      _showNotificationBanner = active;
      _bannerExpiresAt = expiresAt;
    });
  }

  // ===================== ACTIONS =====================

  Future<void> _sendJoinRequest(String userId) async {
    await Supabase.instance.client.from("match_requests").insert({
      "match_id": widget.match.id,
      "requester_id": userId,
      "status": "pending",
    });
    setState(() => _hasPendingRequest = true);
  }

  Future<void> _cancelJoinRequest(String userId) async {
    await Supabase.instance.client
        .from("match_requests")
        .delete()
        .eq("match_id", widget.match.id)
        .eq("requester_id", userId);

    setState(() => _hasPendingRequest = false);
  }

  Future<void> _acceptSlot(String userId) async {
    await Supabase.instance.client.functions.invoke(
      'accept-slot',
      body: {"match_id": widget.match.id, "user_id": userId},
    );

    setState(() {
      _isInWaitingList = false;
      _showNotificationBanner = false;
      _bannerExpiresAt = null;
      _isParticipant = true;
    });
  }

  // ===================== UI HELPERS =====================

  Widget _btn(
    String text, {
    Color? color,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? (color ?? Colors.black) : Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  // ===================== BOTTOM CTA =====================

  Widget _buildBottomButton(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) return const SizedBox();

    final match = widget.match;
    final isOrganizer = user.id == match.creatorId;
    final isCompatible = match.isCompatible(user.level);

    if (isOrganizer) {
      return _btn("ERES EL ORGANIZADOR", enabled: false);
    }

    if (_isParticipant) {
      return _btn("YA ESTÁS DENTRO DEL PARTIDO ✅", enabled: false);
    }

    if (isCompatible) {
      return _btn(
        "UNIRME AL PARTIDO",
        onTap: () async {
          await Supabase.instance.client.rpc(
            'join_match',
            params: {'p_match_id': match.id, 'p_user_id': user.id},
          );
          setState(() => _isParticipant = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Te has unido al partido")),
          );
        },
      );
    }

    if (_hasPendingRequest) {
      return _btn(
        "CANCELAR SOLICITUD",
        color: Colors.red.shade700,
        onTap: () => _cancelJoinRequest(user.id),
      );
    }

    return _btn(
      "SOLICITAR UNIRME",
      onTap: () => _sendJoinRequest(user.id),
    );
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final date = "${match.date.day}/${match.date.month}/${match.date.year}";
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F1F3),
      appBar: AppBar(
        title: Text(match.club ?? "Partido"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: _buildBottomButton(context),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            child: _buildMatchCard(match, date),
          ),
          if (_showNotificationBanner && user != null)
            _buildBanner(context, user),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context, user) {
    return Positioned(
      top: 12,
      left: 18,
      right: 18,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("¡PLAZA DISPONIBLE!",
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text("Se ha liberado una plaza en ${widget.match.club ?? ''}"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptSlot(user.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                      ),
                      child: const Text("ACEPTAR"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _matchService.removeFromWaitingList(
                          matchId: widget.match.id,
                          userId: user.id,
                        );
                        setState(() => _showNotificationBanner = false);
                      },
                      child: const Text("RECHAZAR"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match, String date) {
    final lat = match.latitude;
    final lng = match.longitude;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Información del partido",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _info("Fecha", date),
          _info("Hora", match.time),
          _info("Duración", "${match.duration} min"),
          const SizedBox(height: 16),
          Row(
            children: [
              _chip("Nivel ${match.levelStart}"),
              const SizedBox(width: 8),
              _chip("Nivel ${match.levelEnd}"),
            ],
          ),
          const SizedBox(height: 16),
          _info("Ubicación", match.location ?? "Sin dirección"),
          if (lat != null && lng != null) const SizedBox(height: 12),
          if (lat != null && lng != null)
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: LatLng(lat, lng), zoom: 16),
                  markers: {
                    Marker(
                      markerId: const MarkerId("here"),
                      position: LatLng(lat, lng),
                    ),
                  },
                  liteModeEnabled: true,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ),
      );
}
