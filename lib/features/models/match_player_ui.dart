class MatchPlayerUI {
  final String userId;
  final String name;
  final double level;
  final bool isOrganizer;
  final double trustScore;

  MatchPlayerUI({
    required this.userId,
    required this.name,
    required this.level,
    required this.isOrganizer,
    required this.trustScore,
  });

  factory MatchPlayerUI.fromJson(Map<String, dynamic> json) {
    return MatchPlayerUI(
      userId: json["user_id"],
      name: json["users"]["full_name"] ?? "Jugador",
      level: (json["users"]["level"] as num).toDouble(),
      isOrganizer: json["role"] == "organizer",
      trustScore: (json["reputation_aggregates"]?["trust_score"] as num?)
              ?.toDouble() ??
          0,
    );
  }
}
