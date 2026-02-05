class ParticipantRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, String>> loadMyStatuses(List<String> matchIds) async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('match_participants')
        .select('match_id, status')
        .eq('user_id', userId)
        .in_('match_id', matchIds);

    final Map<String, String> result = {};
    for (final row in response) {
      result[row['match_id']] = row['status'];
    }
    return result;
  }

  Future<Map<String, int>> loadJoinedCounts(List<String> matchIds) async {
    final response = await _client
        .from('match_participants')
        .select('match_id')
        .eq('status', 'joined')
        .in_('match_id', matchIds);

    final Map<String, int> counts = {};
    for (final row in response) {
      final id = row['match_id'];
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }
}
