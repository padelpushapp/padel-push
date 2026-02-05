// lib/features/models/match_model.dart

class MatchModel {
  final String id;
  final String creatorId;

  final String? club;
  final String? location;

  final double? latitude;
  final double? longitude;

  final DateTime date;
  final String time;

  final int duration;
  final double levelStart;
  final double levelEnd;

  final double price;

  final String environment;
  final String wallType;
  final String category;

  final int neededPlayers;

  final bool extraBalls;
  final bool extraBeer;

  final String matchType;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================
  MatchModel({
    required this.id,
    required this.creatorId,
    this.club,
    this.location,
    this.latitude,
    this.longitude,
    required this.date,
    required this.time,
    required this.duration,
    required this.levelStart,
    required this.levelEnd,
    required this.price,
    required this.environment,
    required this.wallType,
    required this.category,
    required this.neededPlayers,
    required this.extraBalls,
    required this.extraBeer,
    required this.matchType,
  });

  // ============================================================
  // FROM JSON
  // ============================================================
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json["id"].toString(),
      creatorId: json["creator_id"] ?? "",
      club: json["club"],
      location: json["location"],
      latitude: (json["latitude"] is num) ? json["latitude"].toDouble() : null,
      longitude: (json["longitude"] is num) ? json["longitude"].toDouble() : null,
      date: DateTime.parse(json["date"]),
      time: json["time"],
      duration: json["duration"] ?? 90,
      levelStart: (json["level_start"] as num).toDouble(),
      levelEnd: (json["level_end"] as num).toDouble(),
      price: (json["price"] is num)
          ? (json["price"] as num).toDouble()
          : double.tryParse(json["price"] ?? "0") ?? 0.0,
      environment: json["environment"] ?? "-",
      wallType: json["wall_type"] ?? "-",
      category: json["category"] ?? "-",
      neededPlayers: json["needed_players"] ?? 0,
      extraBalls: json["extra_balls"] ?? false,
      extraBeer: json["extra_beer"] ?? false,
      matchType: json["match_type"] ?? "amistoso",
    );
  }

  // ============================================================
  // CHECK COMPATIBILITY
  // ============================================================
  bool isCompatible(double userLevel) {
    final min = levelStart - 0.25;
    final max = levelEnd + 0.25;
    return userLevel >= min && userLevel <= max;
  }
}