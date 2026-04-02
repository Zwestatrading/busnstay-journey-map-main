import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';

  late final SupabaseClient client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    client = Supabase.instance.client;
  }

  // Sign up new user
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.toString().split('.').last,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      
      if (response.user != null) {
        // Store user profile in database
        await client.from('user_profiles').insert({
          'id': response.user!.id,
          'email': email,
          'name': name,
          'role': role.toString().split('.').last,
          'avatar_url': null,
          'member_since': DateTime.now().toIso8601String(),
        });
      }
      
      return response.user;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in existing user
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get current user
  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return client.auth.currentUser != null;
  }

  // Stream of auth state changes
  Stream<AuthState> get authStateStream => client.auth.onAuthStateChange;

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    required String name,
    required String? avatarUrl,
  }) async {
    try {
      await client.from('user_profiles').update({
        'name': name,
        'avatar_url': avatarUrl,
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user by role (for testing/admin purposes)
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final response = await client
          .from('user_profiles')
          .select()
          .eq('role', role);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }
}
