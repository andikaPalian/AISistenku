import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Configuration for Backend REST API endpoints with Smart Auto-Detection.
class ApiConfig {
  static String? _customBaseUrl;

  /// Candidate URLs to probe in order of priority:
  static const List<String> candidateUrls = [
    'http://localhost:3000/api', // USB with adb reverse, iOS, Desktop, Web
  ];

  /// Get current effective API base URL
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    const fromDefine = String.fromEnvironment('API_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    try {
      if (Platform.isAndroid) {
        // Default to Wi-Fi LAN IP or localhost
        return 'http://10.11.4.61:3000/api';
      }
    } catch (_) {}

    return 'http://localhost:3000/api';
  }

  static void setBaseUrl(String url) {
    _customBaseUrl =
        url.trim().endsWith('/api') ? url.trim() : '${url.trim()}/api';
  }

  /// Automatically probe candidate endpoints and pick the fastest responsive one
  static Future<String> autoDetectServer() async {
    if (_customBaseUrl != null) return _customBaseUrl!;

    for (final candidate in candidateUrls) {
      try {
        final healthUrl = candidate.replaceAll('/api', '/health');
        final res = await http
            .get(Uri.parse(healthUrl))
            .timeout(const Duration(milliseconds: 1200));
        if (res.statusCode == 200) {
          debugPrint('✅ Found working backend server: $candidate');
          _customBaseUrl = candidate;
          return candidate;
        }
      } catch (_) {
        // Try next candidate
      }
    }

    return baseUrl;
  }
}

/// Centralized API client for communicating with the Tiga Angkatan Backend.
class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  String? _authToken;
  String? _businessId;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  void setBusinessId(String? id) {
    _businessId = id;
  }

  String? get businessId => _businessId;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (_businessId != null && _businessId!.isNotEmpty) {
      headers['X-Business-Id'] = _businessId!;
    }
    return headers;
  }

  /// Perform a GET request with smart candidate fallback.
  Future<dynamic> get(String path) async {
    try {
      final fullUrl = '${ApiConfig.baseUrl}$path';
      final uri = Uri.parse(fullUrl);
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      debugPrint(
          '⚠️ ApiService.get($path) status: ${res.statusCode} body: ${res.body}');
      return null;
    } catch (e) {
      debugPrint('⚠️ ApiService.get($path) error: $e');
      return null;
    }
  }

  /// Perform a POST request with smart candidate probe.
  Future<dynamic> post(String path, dynamic body) async {
    // If we have not probed a confirmed working server, probe candidates quickly
    if (ApiConfig._customBaseUrl == null) {
      await ApiConfig.autoDetectServer();
    }

    final fullUrl = '${ApiConfig.baseUrl}$path';
    try {
      final uri = Uri.parse(fullUrl);
      final res = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      final errorMsg = data is Map
          ? (data['error'] ?? data['message'] ?? 'Status ${res.statusCode}')
          : 'Error ${res.statusCode}';
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('⚠️ ApiService.post($path) error on $fullUrl: $e');
      rethrow;
    }
  }

  /// Perform a PUT request.
  Future<dynamic> put(String path, dynamic body) async {
    final fullUrl = '${ApiConfig.baseUrl}$path';
    try {
      final uri = Uri.parse(fullUrl);
      final res = await http
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      final errorMsg = data is Map
          ? (data['error'] ?? data['message'] ?? 'Status ${res.statusCode}')
          : 'Error ${res.statusCode}';
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('⚠️ ApiService.put($path) error: $e');
      rethrow;
    }
  }

  /// Perform a PATCH request.
  Future<dynamic> patch(String path, dynamic body) async {
    final fullUrl = '${ApiConfig.baseUrl}$path';
    try {
      final uri = Uri.parse(fullUrl);
      final res = await http
          .patch(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      final errorMsg = data is Map
          ? (data['error'] ?? data['message'] ?? 'Status ${res.statusCode}')
          : 'Error ${res.statusCode}';
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('⚠️ ApiService.patch($path) error: $e');
      rethrow;
    }
  }


  /// Perform a DELETE request.
  Future<dynamic> delete(String path) async {
    final fullUrl = '${ApiConfig.baseUrl}$path';
    try {
      final uri = Uri.parse(fullUrl);
      final res = await http
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return data;
      }

      final errorMsg = data is Map
          ? (data['error'] ?? data['message'] ?? 'Status ${res.statusCode}')
          : 'Error ${res.statusCode}';
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('⚠️ ApiService.delete($path) error: $e');
      rethrow;
    }
  }

  /// Check if backend API server is reachable.
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse(ApiConfig.baseUrl.replaceAll('/api', '/health'));
      final res = await http.get(uri).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
