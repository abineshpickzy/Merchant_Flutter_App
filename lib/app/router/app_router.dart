import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bayfay_merchant_flutter/app/providers/auth_state_provider.dart';
import 'package:bayfay_merchant_flutter/features/auth/forgot_password/view/forgot_password_screen.dart';
import 'package:bayfay_merchant_flutter/features/auth/forgot_password/view/reset_password_screen.dart';
import 'package:bayfay_merchant_flutter/features/auth/login/view/login_screen.dart';
import 'package:bayfay_merchant_flutter/features/auth/register/view/register_screen.dart';
import 'package:bayfay_merchant_flutter/features/auth/register/view/register_verify_screen.dart';
import 'package:bayfay_merchant_flutter/features/auth/welcome/view/welcome_screen.dart';
import 'package:bayfay_merchant_flutter/features/dashboard/view/dashboard_screen.dart';
import 'package:bayfay_merchant_flutter/features/add_store/view/terms_condition_screen.dart';
import 'package:bayfay_merchant_flutter/features/splash/controller/splash_controller.dart';
import 'package:bayfay_merchant_flutter/features/splash/view/splash_screen.dart';
import 'app_routes.dart';

/// Bridges Riverpod AuthState updates to GoRouter refreshListenable.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authStateProvider,
      (previous, next) {
        if (next is AuthSessionExpired) {
          final context = rootNavigatorKey.currentContext;
          if (context != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session Expired. Please login again.'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );
            });
          }
        }
        if (previous != next) {
          notifyListeners();
        }
      },
    );
    _ref.listen<bool>(
      splashCompletedProvider,
      (previous, next) {
        if (previous != next) {
          notifyListeners();
        }
      },
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerVerify,
        name: 'registerVerify',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RegisterVerifyScreen(
            firstName: extra['firstName'] as String? ?? '',
            lastName: extra['lastName'] as String? ?? '',
            email: extra['email'] as String? ?? '',
            mobileNumber: extra['mobileNumber'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ResetPasswordScreen(
            mobileNumber: extra['mobileNumber'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.termsConditions,
        name: 'termsConditions',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TermsConditionScreen(
            url: extra?['url'] as String?,
            title: extra?['title'] as String? ?? 'Terms & Conditions',
          );
        },
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final location = state.matchedLocation;

      final isSplashing = location == AppRoutes.splash;
      final isAuthScreen = location == AppRoutes.welcome ||
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.registerVerify ||
          location == AppRoutes.forgotPassword ||
          location == AppRoutes.resetPassword;

      final isSplashComplete = ref.read(splashCompletedProvider);

      if (!isSplashComplete || authState is AuthInitializing) {
        return isSplashing ? null : AppRoutes.splash;
      }

      // When splash is complete, route through Welcome Screen
      if (isSplashing) {
        return AppRoutes.welcome;
      }

      // Token expired / session error -> redirect directly to Login Screen
      if (authState is AuthSessionExpired) {
        if (location == AppRoutes.login) {
          return null;
        }
        return AppRoutes.login;
      }

      if (authState is AuthUnauthenticated) {
        if (isAuthScreen) {
          return null;
        }
        return AppRoutes.welcome;
      }

      if (authState is AuthAuthenticated) {
        // Allow WelcomeScreen to display "Welcome Back" & handle token refresh
        if (location == AppRoutes.welcome) {
          return null;
        }
        // Redirect child auth forms (login, register, etc.) to dashboard
        if (isAuthScreen) {
          return AppRoutes.dashboard;
        }
      }

      return null;
    },
  );
});
