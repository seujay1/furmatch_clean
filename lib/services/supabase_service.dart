// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _supabaseUrl = 'https://kybzldrzgyzkfxtfxtbo.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5YnpsZHJ6Z3l6a2Z4dGZ4dGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyOTMwNjksImV4cCI6MjA3NTg2OTA2OX0.idLam59_a8Hk8G8P-AZI9I4Ev1wdM-XBrhVsCb3Qc7o';

//---------initialize Supabase only once
  static Future<void> initializeIfNeeded() async {
    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );
    }
  }

//can safely get supabase client
  static Future<SupabaseClient> getClient() async {
    await initializeIfNeeded();
    return Supabase.instance.client;
  }

// direct sync
  static SupabaseClient get client => Supabase.instance.client;

//  pang help sa auth
  static User? get currentUser {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static bool get isLoggedIn {
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  static RealtimeChannel getChannel(String name) {
    final client = Supabase.instance.client;
    return client.channel(name);
  }
}
