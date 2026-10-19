import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analysis.dart';

/// Supabase backend service.
/// 
/// To activate:
/// 1. Create a free project at https://supabase.com
/// 2. Put your URL and anon key in a .env or directly here for development
/// 3. Create tables: analyses, profiles
/// 4. Call SupabaseService.initialize() in main.dart
class SupabaseService {
  static bool _initialized = false;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    if (_initialized) return;
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    _initialized = true;
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw Exception('SupabaseService not initialized. Call initialize() first.');
    }
    return Supabase.instance.client;
  }

  static User? get currentUser => client.auth.currentUser;

  static Future<AuthResponse> signInWithEmail(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp(String email, String password) {
    return client.auth.signUp(email: email, password: password);
  }

  static Future<void> signOut() => client.auth.signOut();

  /// Save analysis to the cloud (when user is logged in).
  static Future<void> saveAnalysis(AnalysisResult analysis) async {
    final user = currentUser;
    if (user == null) return;

    await client.from('analyses').upsert({
      'id': analysis.id,
      'user_id': user.id,
      'created_at': analysis.createdAt.toIso8601String(),
      'data': analysis.toJson(),
    });
  }

  /// Fetch all analyses for the current user.
  static Future<List<AnalysisResult>> fetchAnalyses() async {
    final user = currentUser;
    if (user == null) return [];

    final response = await client
        .from('analyses')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => AnalysisResult.fromJson(row['data'] as Map<String, dynamic>))
        .toList();
  }
}
