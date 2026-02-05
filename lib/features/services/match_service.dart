import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_model.dart';
import '../models/match_player_ui.dart';

class MatchService {
  final SupabaseClient supabase = Supabase.instance.client;

  // ============================================================
  // CREATE MATCH
  // ============================================================

  Future<bool> createMatch(Map<String, dynamic> payload) async {
    try {
      await supabase.from("matches").insert(payload);
      return true;
    } catch (e) {
      print("❌ ERROR createMatch → $e");
      return false;
    }
  }

  // ============================================================
  // GET MATCHES IN VIEWPORT (RADAR + FALLBACK)
  // ============================================================

  Future<List<MatchModel>> getMatchesInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    try {
      final user = supabase.auth.currentUser;

      // ----------------------------------------------------------
      // 1️⃣ INTENTAMOS RADAR (SI EXISTE)
      // ----------------------------------------------------------
      List<String> radarIds = [];

      if (user != null) {
        final radar = await supabase.rpc(
          'radar_for_user',
          params: {'p_user_id': user.id},
        );

        if (radar != null && radar.isNotEmpty) {
          radarIds =
              radar.map<String>((e) => e['match_id'] as String).toList();
        }
      }

      // ----------------------------------------------------------
      // 2️⃣ QUERY BASE (SIEMPRE)
      // ----------------------------------------------------------
      var query = supabase
          .from("matches_with_datetime")
          .select("*")
          .gte("latitude", minLat)
          .lte("latitude", maxLat)
          .gte("longitude", minLng)
          .lte("longitude", maxLng);

      // ----------------------------------------------------------
      // 3️⃣ SI EL RADAR TIENE DATOS → FILTRAMOS
      // ----------------------------------------------------------
      if (radarIds.isNotEmpty) {
        query = query.inFilter("id", radarIds);
      }

      final data = await query;

      if (data.isEmpty) return [];

      // ----------------------------------------------------------
      // 4️⃣ ORDENAMOS POR RADAR (SI EXISTE)
      // ----------------------------------------------------------
      if (radarIds.isNotEmpty) {
        final Map<String, int> radarOrder = {
          for (int i = 0; i < radarIds.length; i++) radarIds[i]: i,
        };

        data.sort((a, b) {
          final aIndex = radarOrder[a['id']] ?? 9999;
          final bIndex = radarOrder[b['id']] ?? 9999;
          return aIndex.compareTo(bIndex);
        });
      }

      return data.map<MatchModel>((m) => MatchModel.fromJson(m)).toList();
    } catch (e) {
      print("❌ ERROR getMatchesInBounds → $e");
      return [];
    }
  }

  // ============================================================
  // WAITING LIST
  // ============================================================

  Future<bool> addToWaitingList({
    required String matchId,
    required String userId,
  }) async {
    try {
      final exists = await supabase
          .from("waiting_list")
          .select("id")
          .eq("match_id", matchId)
          .eq("user_id", userId)
          .maybeSingle();

      if (exists != null) return true;

      await supabase.from("waiting_list").insert({
        "match_id": matchId,
        "user_id": userId,
        "status": "waiting",
      });

      return true;
    } catch (e) {
      print("❌ ERROR addToWaitingList → $e");
      return false;
    }
  }

  Future<bool> isUserInWaitingList({
    required String matchId,
    required String userId,
  }) async {
    try {
      final res = await supabase
          .from("waiting_list")
          .select("id")
          .eq("match_id", matchId)
          .eq("user_id", userId)
          .maybeSingle();

      return res != null;
    } catch (e) {
      print("❌ ERROR isUserInWaitingList → $e");
      return false;
    }
  }

  Future<bool> removeFromWaitingList({
    required String matchId,
    required String userId,
  }) async {
    try {
      await supabase
          .from("waiting_list")
          .delete()
          .eq("match_id", matchId)
          .eq("user_id", userId);

      return true;
    } catch (e) {
      print("❌ ERROR removeFromWaitingList → $e");
      return false;
    }
  }

  // ============================================================
  // ACCEPT SLOT — EDGE FUNCTION
  // ============================================================

  Future<bool> acceptSlotViaFunction({
    required String matchId,
    required String userId,
    required String? waitingId,
  }) async {
    try {
      final url =
          "https://drjpbbdtrlotiozirwdx.functions.supabase.co/accept-slot";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization":
              "Bearer ${supabase.auth.currentSession?.accessToken}",
        },
        body: jsonEncode({
          "match_id": matchId,
          "user_id": userId,
          "waiting_id": waitingId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ ERROR acceptSlotViaFunction → $e");
      return false;
    }
  }

  // ============================================================
  // MATCH PLAYERS (UI)
  // ============================================================

  Future<List<MatchPlayerUI>> getMatchPlayers(String matchId) async {
    try {
      final data = await supabase
          .from("match_participants")
          .select('''
            user_id,
            role,
            users (
              full_name,
              level
            ),
            reputation_aggregates (
              trust_score
            )
          ''')
          .eq("match_id", matchId);

      if (data.isEmpty) return [];

      return data.map<MatchPlayerUI>((e) {
        return MatchPlayerUI(
          userId: e["user_id"],
          name: e["users"]?["full_name"] ?? "Jugador",
          level: (e["users"]?["level"] as num?)?.toDouble() ?? 0,
          isOrganizer: e["role"] == "organizer",
          trustScore:
              (e["reputation_aggregates"]?["trust_score"] as num?)?.toDouble() ??
                  0,
        );
      }).toList();
    } catch (e) {
      print("❌ ERROR getMatchPlayers → $e");
      return [];
    }
  }

  // ============================================================
  // MARK WAITING NOTIFICATION
  // ============================================================

  Future<void> markWaitingNotificationSent(
    String matchId,
    String userId,
  ) async {
    try {
      await supabase
          .from("waiting_list")
          .update({"notified_at": DateTime.now().toIso8601String()})
          .eq("match_id", matchId)
          .eq("user_id", userId);
    } catch (e) {
      print("❌ ERROR markWaitingNotificationSent → $e");
    }
  }
}
