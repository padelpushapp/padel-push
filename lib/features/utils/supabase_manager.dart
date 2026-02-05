// lib/features/utils/supabase_manager.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static late SupabaseClient client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: "https://drjpbbdtrlotiozirwdx.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRyanBiYmR0cmxvdGlvemlyd2R4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyMjk0ODksImV4cCI6MjA4MDgwNTQ4OX0.KwxUBNuG_mmS8P2VmbO_0ijfxMBjiCu3WUFQwtjxXLc",

      // La ÚNICA opción válida en 2.10.x
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );

    client = Supabase.instance.client;
  }
}
