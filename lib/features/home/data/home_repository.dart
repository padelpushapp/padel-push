import 'package:supabase_flutter/supabase_flutter.dart';

class HomeRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> loadRadarMatches() async {
    final userId = _client.auth.currentUser!.id;

    // 1. Radar (ordenado)
    final radarResponse = await _client.rpc(
      'radar_for_user',
      params: {'p_user_id': userId},
    );

    if (radarResponse == null || radarResponse.isEmpty) {
      return [];
    }

    final matchIds = radarResponse
        .map<String>((e) => e['match_id'] as String)
        .toList();

    // 2. Cargar partidos
    final matches = await _client
        .from('matches_with_datetime')
        .select('''
          id,
          starts_at,
          club,
          location,
          latitude,
          longitude,
          level_start,
          level_end,
          price,
          environment,
          wall_type,
          category,
          match_type,
          needed_players,
          creator_id,
          users!inner(trust_score, is_premium)
        ''')
        .in_('id', matchIds);

    return List<Map<String, dynamic>>.from(matches);
  }
}
