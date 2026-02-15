import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

// Provide access to AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Listen to Supabase auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

// Get current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.read(authServiceProvider).currentUser;
});
