import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _baseUrlKey = 'api_base_url';
  static const String _tokenKey = 'access_token';
  static const String _remotePrefsKey = 'remote_api_base_url';
  static String get defaultBaseUrl => kReleaseMode
      ? "https://split-now-production.up.railway.app/api"
      : "https://f6c1-202-166-205-90.ngrok-free.app/api";

  ApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        debugPrint('[API] --> ${options.method} ${options.baseUrl}${options.path}');
        if (options.data != null) {
          debugPrint('[API] Body: ${options.data}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[API] <-- ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.baseUrl}${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) async {
        debugPrint('[API] <-- ERROR ${error.response?.statusCode} ${error.requestOptions.method} ${error.requestOptions.baseUrl}${error.requestOptions.path}: ${error.message}');
        if (error.response?.statusCode != 401) {
          FirebaseCrashlytics.instance.recordError(
            error.error ?? error,
            error.stackTrace,
            reason: 'API ${error.requestOptions.method} ${error.requestOptions.path}',
            fatal: false,
          );
        }
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: _tokenKey);
        }
        handler.next(error);
      },
    ));
  }

  Future<String?> get baseUrl => _storage.read(key: _baseUrlKey);

  Future<void> setBaseUrl(String url) async {
    await _storage.write(key: _baseUrlKey, value: url);
    _dio.options.baseUrl = url;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final remoteUrl = prefs.getString(_remotePrefsKey);
    final savedUrl = await _storage.read(key: _baseUrlKey);
    _dio.options.baseUrl = savedUrl ?? remoteUrl ?? defaultBaseUrl;
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }
}
