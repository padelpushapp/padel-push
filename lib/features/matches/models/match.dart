// lib/features/matches/models/match.dart

import 'package:flutter/foundation.dart';

class MatchModel {
  final String id;
  final String creatorId;

  // Datos del partido
  final String? club;
  final String? location;
  final double? latitude;
  final double? longitude;

  // Fecha y hora (la tabla tiene date + time)
  final DateTime date; // fecha (YYYY-MM-DD)
  final String time; // hora (HH:MM:SS) — la guardamos tal cual desde DB
  final int duration; // minutos

  final double levelStart;
  final double levelEnd;

  final double price;
  final String? environment; // indoor/outdoor
  final String? wallType; // cristal/muro
  final String? category; // mixto/masculino/femenino

  final int neededPlayers;
  final bool extraBalls;
  final bool extraBeer;

  final DateTime createdAt;

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
    this.environment,
    this.wallType,
    this.category,
    required this.neededPlayers,
    required this.extraBalls,
    required this.extraBeer,
    required this.createdAt,
  });

  // Construye un DateTime combinando date + time si lo necesitas:
  DateTime get dateTime {
    // time expected "HH:MM:SS" or "HH:MM"
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  // fromJson / fromMap (claves = nombres columnas en Supabase)
  factory MatchModel.fromMap(Map<String, dynamic> map) {
    // date viene como String o DateTime según driver; manejamos ambos
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      return DateTime.parse(d.toString());
    }

    DateTime parseCreatedAt(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      return DateTime.parse(d.toString());
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return MatchModel(
      id: map['id'].toString(),
      creatorId: map['creator_id'].toString(),
      club: map['club'] as String?,
      location: map['location'] as String?,
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      date: parseDate(map['date']),
      time: map['time']?.toString() ?? '00:00:00',
      duration: (map['duration'] is int) ? map['duration'] as int : int.tryParse(map['duration']?.toString() ?? '') ?? 90,
      levelStart: (parseDouble(map['level_start']) ?? 0.0),
      levelEnd: (parseDouble(map['level_end']) ?? 0.0),
      price: (parseDouble(map['price']) ?? 0.0),
      environment: map['environment'] as String?,
      wallType: map['wall_type'] as String?,
      category: map['category'] as String?,
      neededPlayers: (map['needed_players'] is int) ? map['needed_players'] as int : int.tryParse(map['needed_players']?.toString() ?? '') ?? 0,
      extraBalls: (map['extra_balls'] == true || map['extra_balls'] == 1),
      extraBeer: (map['extra_beer'] == true || map['extra_beer'] == 1),
      createdAt: parseCreatedAt(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creator_id': creatorId,
      'club': club,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'date': date.toIso8601String().split('T').first, // YYYY-MM-DD
      'time': time, // assume HH:MM:SS
      'duration': duration,
      'level_start': levelStart,
      'level_end': levelEnd,
      'price': price,
      'environment': environment,
      'wall_type': wallType,
      'category': category,
      'needed_players': neededPlayers,
      'extra_balls': extraBalls,
      'extra_beer': extraBeer,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // copyWith para facilitar cambios
  MatchModel copyWith({
    String? id,
    String? creatorId,
    String? club,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? date,
    String? time,
    int? duration,
    double? levelStart,
    double? levelEnd,
    double? price,
    String? environment,
    String? wallType,
    String? category,
    int? neededPlayers,
    bool? extraBalls,
    bool? extraBeer,
    DateTime? createdAt,
  }) {
    return MatchModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      club: club ?? this.club,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      date: date ?? this.date,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      levelStart: levelStart ?? this.levelStart,
      levelEnd: levelEnd ?? this.levelEnd,
      price: price ?? this.price,
      environment: environment ?? this.environment,
      wallType: wallType ?? this.wallType,
      category: category ?? this.category,
      neededPlayers: neededPlayers ?? this.neededPlayers,
      extraBalls: extraBalls ?? this.extraBalls,
      extraBeer: extraBeer ?? this.extraBeer,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MatchModel(id: $id, club: $club, zone: $location, date: $date, time: $time)';
  }
}
