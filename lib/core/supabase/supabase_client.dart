// lib/core/supabase/supabase_client.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'keys.dart';

class SupabaseManager {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseKeys.url,
      anonKey: SupabaseKeys.anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
