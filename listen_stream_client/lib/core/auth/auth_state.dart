import 'package:freezed_annotation/freezed_annotation.dart';

// Simple sealed class without freezed to keep deps minimal.

/// Sealed auth state.
abstract class AuthState {
  const AuthState();
  bool get isAuthenticated => this is Authenticated;
}

class Authenticated extends AuthState {
  const Authenticated({required this.userId});
  final String userId;
}

class Unauthenticated extends AuthState {
  const Unauthenticated([this.message]);
  final String? message;
}

class AuthLoading extends AuthState {
  const AuthLoading();
}
