import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'api_config.dart';

/// Base API Exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.errors, this.data});

  @override
  String toString() => message;
}

/// Network Connection Failure (No internet, DNS failure, SocketException, interface switch)
class NetworkException extends ApiException {
  NetworkException({
    super.message = 'Unable to connect to ENX Money servers. Please check your internet connection.',
    super.statusCode,
    super.errors,
  });
}

/// Timeout Exception (Slow 3G/4G or high server latency)
class ApiTimeoutException extends ApiException {
  ApiTimeoutException({
    super.message = 'Server is taking too long to respond. Please try again.',
    super.statusCode,
    super.errors,
  });
}

/// HTTP 400 Validation Exception
class ValidationException extends ApiException {
  ValidationException({
    required super.message,
    super.statusCode = 400,
    super.errors,
  });
}

/// HTTP 401 / 403 Authentication Exception
class AuthException extends ApiException {
  AuthException({
    super.message = 'Session expired. Please sign in again.',
    super.statusCode = 401,
    super.errors,
  });
}

/// HTTP 404 Not Found Exception
class NotFoundException extends ApiException {
  NotFoundException({
    super.message = 'Requested service was not found.',
    super.statusCode = 404,
    super.errors,
    super.data,
  });
}

/// HTTP 409 Conflict Exception (Duplicate account, already registered)
class ConflictException extends ApiException {
  final String? code;
  final String? field;

  ConflictException({
    required super.message,
    super.statusCode = 409,
    super.errors,
    super.data,
    this.code,
    this.field,
  });
}

/// HTTP 429 Rate Limit Exception
class RateLimitException extends ApiException {
  RateLimitException({
    super.message = 'Too many requests. Please wait a few moments before trying again.',
    super.statusCode = 429,
    super.errors,
  });
}

/// HTTP 500 / 502 / 503 / 504 Server Error Exception
class ServerException extends ApiException {
  ServerException({
    super.message = 'ENX Money server is temporarily unavailable. Please try again later.',
    super.statusCode = 500,
    super.errors,
  });
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  static ApiClient get instance => _instance;
  ApiClient._internal();

  static const _uuid = Uuid();
  http.Client _client = http.Client();
  String? _authToken;
  String? _activeBaseUrl;

  /// Closes and resets the HTTP client socket pool to recover cleanly
  /// from OS network interface switches (e.g. Wi-Fi <-> 4G <-> 5G).
  void _resetClient() {
    try {
      _client.close();
    } catch (_) {}
    _client = http.Client();
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setActiveBaseUrl(String url) {
    _activeBaseUrl = url;
  }

  String? get activeBaseUrl => _activeBaseUrl;

  Map<String, String> _buildHeaders([String? idempotencyKey]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'ENX-Money-Mobile/4.0.0 (Android/Universal)',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['X-Idempotency-Key'] = idempotencyKey;
      headers['Idempotency-Key'] = idempotencyKey;
    }
    return headers;
  }

  /// Sanitized request logging (Never log OTPs, passwords, secrets)
  void _logRequest(String method, Uri url, [Map<String, dynamic>? body]) {
    if (!kDebugMode) return;
    final sanitizedBody = body != null ? _sanitizePayload(body) : null;
    debugPrint('[HTTP Request] $method ${url.scheme}://${url.host}${url.path} '
        '${sanitizedBody != null ? "Body: $sanitizedBody" : ""} '
        '(Auth: ${_authToken != null ? "Token Attached" : "None"})');
  }

  /// Sanitized response logging
  void _logResponse(String method, Uri url, http.Response response, int durationMs) {
    if (!kDebugMode) return;
    final contentType = response.headers['content-type'] ?? 'unknown';
    String bodyPreview = response.body;
    if (bodyPreview.length > 250) {
      bodyPreview = '${bodyPreview.substring(0, 250)}... [truncated]';
    }
    bodyPreview = bodyPreview.replaceAllMapped(
      RegExp(r'"(token|password|otp|jwt|secret|accessToken|refreshToken)":\s*"[^"]*"', caseSensitive: false),
      (match) => '"${match[1]}":"[REDACTED]"',
    );
    debugPrint('[HTTP Response] $method ${url.path} (Base: ${url.scheme}://${url.host}:${url.port}) '
        '-> Status: ${response.statusCode}, Content-Type: $contentType, Time: ${durationMs}ms, Body: $bodyPreview');
  }

  void _logNetworkException(String method, Uri url, dynamic error) {
    if (!kDebugMode) return;
    debugPrint('[HTTP Network Exception] $method ${url.host}${url.path} -> $error');
  }

  Map<String, dynamic> _sanitizePayload(Map<String, dynamic> data) {
    final copy = Map<String, dynamic>.from(data);
    const sensitiveKeys = {
      'password',
      'otp',
      'token',
      'secret',
      'accessToken',
      'refreshToken',
      'jwt',
      'code'
    };
    for (final key in copy.keys) {
      if (sensitiveKeys.any((s) => key.toLowerCase().contains(s))) {
        copy[key] = '[REDACTED]';
      }
    }
    return copy;
  }

  List<String> _getCandidateUrls() {
    final list = <String>[];
    if (_activeBaseUrl != null && _activeBaseUrl!.isNotEmpty) {
      list.add(_activeBaseUrl!);
    }
    for (final u in ApiConfig.candidateBaseUrls) {
      if (!list.contains(u)) list.add(u);
    }
    return list;
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _executeWithFailover('POST', endpoint, body: body);
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    return _executeWithFailover('GET', endpoint);
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _executeWithFailover('PUT', endpoint, body: body);
  }

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _executeWithFailover('PATCH', endpoint, body: body);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    return _executeWithFailover('DELETE', endpoint);
  }

  /// Core HTTP execution pipeline with:
  /// 1. Dynamic interface-switch resilience (Wi-Fi <-> 4G <-> 5G socket reset)
  /// 2. Idempotent retries for financial and state-mutating requests
  /// 3. Exponential backoff for transient packet loss or 3G slow connections
  /// 4. Cloud proxy 502/503/504 fallback handling
  Future<Map<String, dynamic>> _executeWithFailover(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final candidateBases = _getCandidateUrls();
    ApiException? lastApiException;
    dynamic lastError;

    // Mutating methods generate a consistent idempotency key for all retry attempts
    final String? idempotencyKey = (method == 'POST' || method == 'PUT' || method == 'PATCH')
        ? _uuid.v4()
        : null;

    final int maxAttemptsPerBase = (method == 'GET') ? 3 : 2;

    for (final base in candidateBases) {
      String sanitizedEndpoint = endpoint;
      if (base.endsWith('/api') && sanitizedEndpoint.startsWith('/api/')) {
        sanitizedEndpoint = sanitizedEndpoint.substring(4);
      }
      final url = Uri.parse('$base$sanitizedEndpoint');

      for (int attempt = 1; attempt <= maxAttemptsPerBase; attempt++) {
        _logRequest(method, url, body);
        final stopwatch = Stopwatch()..start();

        try {
          final http.Response response;
          final headers = _buildHeaders(idempotencyKey);
          final encodedBody = body != null ? jsonEncode(body) : null;

          // Adaptive 28-second timeout handles slow 3G without locking the interface
          const requestTimeout = Duration(seconds: 28);

          switch (method) {
            case 'POST':
              response = await _client.post(url, headers: headers, body: encodedBody).timeout(requestTimeout);
              break;
            case 'PUT':
              response = await _client.put(url, headers: headers, body: encodedBody).timeout(requestTimeout);
              break;
            case 'PATCH':
              response = await _client.patch(url, headers: headers, body: encodedBody).timeout(requestTimeout);
              break;
            case 'DELETE':
              response = await _client.delete(url, headers: headers).timeout(requestTimeout);
              break;
            case 'GET':
            default:
              response = await _client.get(url, headers: headers).timeout(requestTimeout);
              break;
          }

          stopwatch.stop();
          _logResponse(method, url, response, stopwatch.elapsedMilliseconds);

          final handled = _handleResponse(response, method: method, url: url);
          _activeBaseUrl = base;
          return handled;
        } on SocketException catch (e) {
          _logNetworkException(method, url, e);
          _resetClient();
          lastError = NetworkException(
            message: 'Unable to connect to ENX Money servers. Please check your internet connection.',
          );
          if (attempt < maxAttemptsPerBase) {
            await Future.delayed(Duration(milliseconds: 600 * attempt));
            continue;
          }
        } on TimeoutException catch (e) {
          _logNetworkException(method, url, e);
          _resetClient();
          lastError = ApiTimeoutException(
            message: 'Server is taking too long to respond. Please try again.',
          );
          if (attempt < maxAttemptsPerBase) {
            await Future.delayed(Duration(milliseconds: 800 * attempt));
            continue;
          }
        } on http.ClientException catch (e) {
          _logNetworkException(method, url, e);
          _resetClient();
          lastError = NetworkException(
            message: 'Unable to connect to ENX Money servers. Please check your internet connection.',
          );
          if (attempt < maxAttemptsPerBase) {
            await Future.delayed(Duration(milliseconds: 600 * attempt));
            continue;
          }
        } on HandshakeException catch (e) {
          _logNetworkException(method, url, e);
          _resetClient();
          lastError = NetworkException(
            message: 'Unable to connect to ENX Money servers. Please check your internet connection.',
          );
          if (attempt < maxAttemptsPerBase) {
            await Future.delayed(Duration(milliseconds: 600 * attempt));
            continue;
          }
        } on ServerException catch (e) {
          _logNetworkException(method, url, e);
          _resetClient();
          lastApiException = e;
          // Retry proxy 502/503/504 errors in case the server is momentarily reconnecting
          if (attempt < maxAttemptsPerBase) {
            await Future.delayed(Duration(milliseconds: 1000 * attempt));
            continue;
          }
        } on ApiException catch (e) {
          // Client or business errors (400, 401, 403, 404, 409, 422, 429) should never be retried
          if (e is ValidationException ||
              e is AuthException ||
              e is RateLimitException ||
              e is NotFoundException ||
              (e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500)) {
            _activeBaseUrl = base;
            rethrow;
          }
          lastApiException = e;
          if (attempt < maxAttemptsPerBase) {
            await Future.delayed(Duration(milliseconds: 800 * attempt));
            continue;
          }
        } catch (e) {
          _logNetworkException(method, url, e);
          _resetClient();
          lastError = e;
          if (attempt < maxAttemptsPerBase) {
            await Future.delayed(Duration(milliseconds: 600 * attempt));
            continue;
          }
        }
      }
    }

    if (lastApiException != null) {
      throw lastApiException;
    }

    if (lastError is ApiException) {
      throw lastError;
    }

    throw NetworkException(
      message: 'Unable to connect to ENX Money servers. Please check your internet connection.',
    );
  }

  Map<String, dynamic> _handleResponse(http.Response response, {String? method, Uri? url}) {
    // Detect HTML responses (such as edge proxy error pages, 404, 502 Bad Gateway, 503 Service Unavailable)
    final isHtml = (response.headers['content-type']?.toLowerCase().contains('text/html') ?? false) ||
        response.body.trim().startsWith('<!DOCTYPE') ||
        response.body.trim().startsWith('<html');

    if (isHtml) {
      if (response.statusCode == 404) {
        throw NotFoundException(
          message: 'Requested service was not found.',
          statusCode: 404,
        );
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException(
          message: 'Session expired. Please sign in again.',
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode >= 500) {
        throw ServerException(
          message: 'ENX Money server is temporarily unavailable. Please try again later.',
          statusCode: response.statusCode,
        );
      }
      throw ServerException(
        message: 'ENX Money server returned an unexpected format. Please try again later.',
        statusCode: response.statusCode,
      );
    }

    dynamic body;
    try {
      body = response.body.isNotEmpty ? jsonDecode(response.body) : <String, dynamic>{};
    } catch (_) {
      if (response.statusCode == 404) {
        throw NotFoundException(
          message: 'Requested service was not found.',
          statusCode: 404,
        );
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException(
          message: 'Session expired. Please sign in again.',
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode >= 500) {
        throw ServerException(
          message: 'ENX Money server is temporarily unavailable. Please try again later.',
          statusCode: response.statusCode,
        );
      }
      throw ServerException(
        message: 'ENX Money server is temporarily unavailable. Please try again later.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }

    final message = (body is Map<String, dynamic> &&
            body.containsKey('message') &&
            body['message'] != null &&
            (body['message'] as String).trim().isNotEmpty)
        ? body['message'] as String
        : (response.statusCode == 401 || response.statusCode == 403
            ? 'Session expired. Please sign in again.'
            : response.statusCode == 404
                ? 'Requested service was not found.'
                : response.statusCode >= 500
                    ? 'ENX Money server is temporarily unavailable. Please try again later.'
                    : 'Request failed with status ${response.statusCode}');
    final errors = body is Map<String, dynamic> ? body['errors'] : null;

    switch (response.statusCode) {
      case 400:
        throw ValidationException(message: message, errors: errors);
      case 401:
      case 403:
        throw AuthException(message: message, statusCode: response.statusCode, errors: errors);
      case 404:
        throw NotFoundException(message: message, errors: errors);
      case 409:
        final code = body is Map<String, dynamic> ? body['error'] as String? : null;
        final data = body is Map<String, dynamic> ? body['data'] : null;
        final field = (data is Map<String, dynamic>) ? data['field'] as String? : null;
        throw ConflictException(
          message: message,
          errors: errors,
          code: code,
          data: data,
          field: field,
        );
      case 429:
        throw RateLimitException(message: message, errors: errors);
      case 500:
      case 502:
      case 503:
      case 504:
        throw ServerException(message: message, statusCode: response.statusCode, errors: errors);
      default:
        throw ApiException(
          message: message,
          statusCode: response.statusCode,
          errors: errors,
        );
    }
  }
}
