import 'package:flutter/material.dart';
import 'package:bayfay_merchant_flutter/app/theme/app_colors.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_constants.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/core/errors/exceptions.dart';
import 'package:bayfay_merchant_flutter/core/errors/failures.dart';

/// Centralized SnackBar component and error message sanitizer.
class AppSnackBar {
  AppSnackBar._();

  /// Strips technical prefixes (`ServerException:`, `Exception:`, etc.) and HTTP
  /// status codes (e.g. `(code: 500)`, `[code: 404]`) to return a clean, human-readable message.
  static String cleanErrorMessage(dynamic error) {
    if (error == null) return '';
    String text;
    if (error is AppException) {
      text = error.message;
    } else if (error is Failure) {
      text = error.message;
    } else {
      text = error.toString();
    }

    // 1. Strip technical exception and failure prefixes
    final prefixPattern = RegExp(
      r'^(Exception|ServerException|NetworkException|UnauthorizedException|ForbiddenException|NotFoundException|CacheException|AppException|ServerFailure|NetworkFailure|Failure|DioException):\s*',
      caseSensitive: false,
    );
    while (prefixPattern.hasMatch(text)) {
      text = text.replaceFirst(prefixPattern, '');
    }

    // 2. Strip status codes like "(code: 500)", "(code: null)", "[code: 500]", "code: 500"
    text = text.replaceAll(RegExp(r'\s*\((?:code|status|statusCode):\s*[^)]*\)', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'\s*\[(?:code|status|statusCode):\s*[^\]]*\]', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'\s*,?\s*(?:code|status|statusCode):\s*\d+', caseSensitive: false), '');

    // 3. Strip Failure string wrappers: "ServerFailure(message: ..., code: 500)"
    final failureMatch = RegExp(r'^[A-Za-z]+Failure\s*\(\s*message:\s*(.+?)(?:,\s*code:\s*[^)]*)?\s*\)$').firstMatch(text);
    if (failureMatch != null) {
      text = failureMatch.group(1) ?? text;
    }

    // 4. Strip quotes if server returned wrapped string e.g. "Email-id is taken already"
    text = text.trim();
    if ((text.startsWith('"') && text.endsWith('"')) || (text.startsWith("'") && text.endsWith("'"))) {
      if (text.length >= 2) {
        text = text.substring(1, text.length - 1);
      }
    }

    text = text.trim();
    return text.isEmpty ? AppStrings.serverError : text;
  }

  /// Builds a modern floating SnackBar with a soft red background, rounded borders,
  /// and proper padding for clean error presentation.
  static SnackBar createErrorSnackBar(dynamic error) {
    final cleanMessage = cleanErrorMessage(error);
    return SnackBar(
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cleanMessage,
              style: const TextStyle(
                fontFamily: AppFonts.nunito,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.errorSoft,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      elevation: 4.0,
      duration: const Duration(seconds: 4),
    );
  }

  /// Displays the clean error SnackBar via [ScaffoldMessenger.of(context)].
  static void showError(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(createErrorSnackBar(error));
  }

  /// Displays a clean success SnackBar via [ScaffoldMessenger.of(context)].
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: AppFonts.nunito,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        margin: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        elevation: 4.0,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
