import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// LoggingInterceptor logs Dio network requests, responses, and errors
/// directly to the console in a clear, formatted style.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['ts_request_start'] = DateTime.now().millisecondsSinceEpoch;

    final buffer = StringBuffer();
    buffer.writeln('┌──────────────────────── [DIO REQUEST] ────────────────────────');
    buffer.writeln('│ Method  : ${options.method.toUpperCase()}');
    buffer.writeln('│ URL     : ${options.uri}');

    if (options.headers.isNotEmpty) {
      buffer.writeln('│ Headers :');
      options.headers.forEach((key, value) {
        // Redact sensitive authorization tokens in console logs
        final displayValue = (key.toLowerCase() == 'authorization')
            ? _maskToken(value.toString())
            : value;
        buffer.writeln('│   $key: $displayValue');
      });
    }

    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('│ Query   : ${_formatPayload(options.queryParameters)}');
    }

    if (options.data != null) {
      buffer.writeln('│ Body    :');
            // buffer.writeln(_indentString(_formatPayload(_sanitizeData(options.data)), '│   '));
      buffer.writeln(_indentString(_formatPayload(options.data), '│   '));
    }

    buffer.writeln('└───────────────────────────────────────────────────────────────');
    _printLog(buffer.toString());

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTs = response.requestOptions.extra['ts_request_start'] as int?;
    final duration = startTs != null
        ? '${DateTime.now().millisecondsSinceEpoch - startTs} ms'
        : 'N/A';

    final buffer = StringBuffer();
    buffer.writeln('┌──────────────────────── [DIO RESPONSE] ───────────────────────');
    buffer.writeln('│ Status  : ${response.statusCode} ${response.statusMessage ?? ''}');
    buffer.writeln('│ URL     : ${response.requestOptions.uri}');
    buffer.writeln('│ Time    : $duration');

    if (response.data != null) {
      buffer.writeln('│ Body    :');
      buffer.writeln(_indentString(_formatPayload(response.data), '│   '));
    }

    buffer.writeln('└───────────────────────────────────────────────────────────────');
    _printLog(buffer.toString());

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra['ts_request_start'] as int?;
    final duration = startTime != null
        ? '${DateTime.now().millisecondsSinceEpoch - startTime} ms'
        : 'N/A';

    final buffer = StringBuffer();
    buffer.writeln('┌───────────────────────── [DIO ERROR] ─────────────────────────');
    buffer.writeln('│ Status  : ${err.response?.statusCode ?? 'NO_RESPONSE'}');
    buffer.writeln('│ Duration: $duration');
    buffer.writeln('│ URL     : ${err.requestOptions.uri}');
    buffer.writeln('│ Type    : ${err.type.name}');
    buffer.writeln('│ Message : ${err.message}');

    if (err.response?.data != null) {
      buffer.writeln('│ Error Data:');
      buffer.writeln(_indentString(_formatPayload(err.response!.data), '│   '));
    }

    buffer.writeln('└───────────────────────────────────────────────────────────────');
    _printLog(buffer.toString());

    handler.next(err);
  }

  /// Formats JSON/Map/List/String data with 2-space indentation
  static String _formatPayload(dynamic data) {
    if (data == null) return 'null';
    try {
      if (data is Map || data is List) {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(data);
      }
      if (data is FormData) {
        final fields = data.fields.map((f) => '${f.key}: ${f.value}').toList();
        final files = data.files.map((f) => '${f.key}: ${f.value.filename}').toList();
        return 'FormData(fields: $fields, files: $files)';
      }
      if (data is String) {
        try {
          final decoded = jsonDecode(data);
          const encoder = JsonEncoder.withIndent('  ');
          return encoder.convert(decoded);
        } catch (_) {
          return data;
        }
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }

  static String _maskToken(String token) {
    if (token.isEmpty) return token;
    if (token.length <= 15) return '[REDACTED]';
    return '${token.substring(0, 10)}...[REDACTED]';
  }


  static String _indentString(String text, String prefix) {
    return text.split('\n').map((line) => '$prefix$line').join('\n');
  }

  static void _printLog(String message) {
    // Print lines using debugPrint to prevent logcat line length truncations
    message.split('\n').forEach((line) {
      debugPrint(line);
    });
  }
}

