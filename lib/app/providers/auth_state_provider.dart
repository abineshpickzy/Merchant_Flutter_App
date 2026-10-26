import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_constants.dart';
import 'package:bayfay_merchant_flutter/core/storage/secure_storage_service.dart';
import 'package:bayfay_merchant_flutter/features/auth/login/model/login_response.dart';
import 'package:bayfay_merchant_flutter/features/auth/login/repository/login_repository.dart';

/// Represents centralized authentication states.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial check / splash screen state.
class AuthInitializing extends AuthState {
  const AuthInitializing();
}

/// User is not logged in.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User is actively logged in.
class AuthAuthenticated extends AuthState {
  final String token;
  final MerchantProfile? profile;

  const AuthAuthenticated({required this.token, this.profile});

  @override
  List<Object?> get props => [token, profile];
}

/// Token is expired or unauthorized (401).
class AuthSessionExpired extends AuthState {
  const AuthSessionExpired();
}

/// Centralized AuthStateNotifier.
class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkInitialAuth();
    return const AuthInitializing();
  }

  Future<void> _checkInitialAuth() async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final token = await storage.getAccessToken();

      if (token != null && token.isNotEmpty) {
        MerchantProfile? profile;
        final profileJson = await storage.read(AppConstants.userProfileKey);
        if (profileJson != null && profileJson.isNotEmpty) {
          try {
            profile = MerchantProfile.fromJson(
              jsonDecode(profileJson) as Map<String, dynamic>,
            );
          } catch (_) {
            // Ignore corrupted cached profile
          }
        }
        state = AuthAuthenticated(token: token, profile: profile);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> setAuthenticated({
    required String token,
    String? refreshToken,
    String? accessSchema,
    String? refreshSchema,
    MerchantProfile? profile,
  }) async {
    final storage = ref.read(secureStorageServiceProvider);
    await storage.saveTokens(
      accessToken: token,
      refreshToken: refreshToken,
      accessSchema: accessSchema,
      refreshSchema: refreshSchema,
    );
    if (profile != null) {
      await storage.write(
        AppConstants.userProfileKey,
        jsonEncode(profile.toJson()),
      );
    }
    state = AuthAuthenticated(token: token, profile: profile);
  }

  /// Replicates WelcomeActivity callRefreshToken flow
  Future<bool> refreshToken() async {
    try {
      final repository = ref.read(loginRepositoryProvider);
      final response = await repository.refreshToken();

      if (response.tokens.accessToken.isNotEmpty) {
        final profile = response.profile ??
            (state is AuthAuthenticated
                ? (state as AuthAuthenticated).profile
                : null);

        if (profile != null) {
          final storage = ref.read(secureStorageServiceProvider);
          await storage.write(
            AppConstants.userProfileKey,
            jsonEncode(profile.toJson()),
          );
        }

        state = AuthAuthenticated(
          token: response.tokens.accessToken,
          profile: profile,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setSessionExpired() async {
    final storage = ref.read(secureStorageServiceProvider);
    await storage.clearTokens();
    state = const AuthSessionExpired();
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageServiceProvider);
    await storage.clearTokens();
    state = const AuthUnauthenticated();
  }
}

/// Application-wide AuthState provider.
final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(() {
  return AuthStateNotifier();
});
