import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final AuthService _auth;

  AuthNotifier(this._api, this._auth) : super(AuthState());

  Future<void> checkAuth() async {
    final hasToken = await _api.hasToken();
    if (hasToken) {
      try {
        final response = await _api.get('/auth/profile');
        state = AuthState(
          user: User.fromJson(response.data),
          isAuthenticated: true,
        );
      } catch (_) {
        await _api.clearToken();
        state = AuthState();
      }
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _api.post('/auth/fcm-token', data: {'fcmToken': token});
      }
    } catch (_) {}
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final idToken = await _auth.signInWithGoogle();
      if (idToken == null) {
        state = state.copyWith(isLoading: false, error: 'Sign in cancelled');
        return;
      }

      final response = await _api.post('/auth/firebase', data: {
        'idToken': idToken,
      });

      final data = response.data;
      await _api.setToken(data['accessToken']);
      unawaited(_registerFcmToken());

      state = AuthState(
        user: User.fromJson(data['user']),
        isAuthenticated: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final idToken = await _auth.signInWithApple();
      if (idToken == null) {
        state = state.copyWith(isLoading: false, error: 'Sign in cancelled');
        return;
      }

      final response = await _api.post('/auth/firebase', data: {
        'idToken': idToken,
      });

      final data = response.data;
      await _api.setToken(data['accessToken']);
      unawaited(_registerFcmToken());

      state = AuthState(
        user: User.fromJson(data['user']),
        isAuthenticated: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    state = AuthState();
    try {
      await _auth.signOut();
    } catch (_) {}
    await _api.clearToken();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(authServiceProvider),
  );
});
