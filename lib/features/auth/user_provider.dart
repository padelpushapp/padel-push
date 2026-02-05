import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// ===============================================================
/// 🔥 MODELO DEL USUARIO
/// ===============================================================
class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String gender;
  final String zone;

  final double level;
  final String levelSource;

  final String dominantHand;
  final String playSide;

  final int tokens;
  final bool isPremium;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.gender,
    required this.zone,
    required this.level,
    required this.levelSource,
    required this.dominantHand,
    required this.playSide,
    required this.tokens,
    required this.isPremium,
  });

  /// ------------------------------------------------------------
  /// 🔄 Convertir desde Supabase
  /// Maneja strings, ints, nulls y dobles sin romper nada.
  /// ------------------------------------------------------------
  factory AppUser.fromMap(Map<String, dynamic> map) {
    double parseLevel(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return AppUser(
      id: map["id"],
      fullName: map["full_name"] ?? "",
      email: map["email"] ?? "",
      phone: map["phone"],
      gender: map["gender"] ?? "",
      zone: map["zone"] ?? "",

      level: parseLevel(map["level"]),
      levelSource: map["level_source"] ?? "",

      dominantHand: map["dominant_hand"] ?? "",
      playSide: map["play_side"] ?? "",

      tokens: map["tokens"] is int ? map["tokens"] : 5,
      isPremium: map["is_premium"] == true,
    );
  }
}

/// ===============================================================
/// 🔥 PROVIDER — MANEJA SESIÓN + PERFIL + TOKEN FCM
/// ===============================================================
class UserProvider extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  final SupabaseClient _supabase = Supabase.instance.client;

  /// ------------------------------------------------------------
  /// 🔥 Guarda el token FCM cada vez que inicias sesión
  /// ------------------------------------------------------------
  Future<void> savePushToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      final uid = _supabase.auth.currentUser?.id;

      if (uid == null || token == null) return;

      await _supabase.from("users").update({
        "push_token": token,
      }).eq("id", uid);

      debugPrint("📲 Token FCM actualizado: $token");
    } catch (e) {
      debugPrint("⚠️ Error guardando push_token: $e");
    }
  }

  /// ------------------------------------------------------------
  /// 🔥 Carga perfil completo del usuario logueado
  /// ------------------------------------------------------------
  Future<void> loadUserProfile() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;

      final res = await _supabase
          .from("users")
          .select()
          .eq("id", uid)
          .maybeSingle();

      if (res == null) return;

      _user = AppUser.fromMap(res);
      notifyListeners();

      // Guardar FCM automáticamente
      await savePushToken();
    } catch (e) {
      debugPrint("⚠️ Error cargando perfil: $e");
    }
  }

  /// ------------------------------------------------------------
  /// 🔑 LOGOUT COMPLETO
  /// ------------------------------------------------------------
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _user = null;
    notifyListeners();
  }
}
