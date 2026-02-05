// lib/features/matches/models/match_player.dart

class MatchPlayer {
  final String id;
  final String matchId;
  final String userId;
  final String status; // joined / pending / rejected / cancelled / waitlist
  final DateTime createdAt;

  MatchPlayer({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.status,
    required this.createdAt,
  });

  factory MatchPlayer.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      return DateTime.parse(d.toString());
    }

    return MatchPlayer(
      id: map['id'].toString(),
      matchId: map['match_id'].toString(),
      userId: map['user_id'].toString(),
      status: map['status']?.toString() ?? 'joined',
      createdAt: parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'match_id': matchId,
      'user_id': userId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MatchPlayer copyWith({
    String? id,
    String? matchId,
    String? userId,
    String? status,
    DateTime? createdAt,
  }) {
    return MatchPlayer(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MatchPlayer(id: $id, matchId: $matchId, userId: $userId, status: $status)';
  }
}
