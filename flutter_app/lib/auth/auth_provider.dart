import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

// Give app access to AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Listen to Firebase auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.read(authServiceProvider).authstatechanges;
});