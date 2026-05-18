import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _baseUrlKey = 'api_base_url';
  static const String _tokenKey = 'access_token';
  static const String defaultBaseUrl = true ?"https://188c-202-166-205-90.ngrok-free.app/api":"https://split-now-production.up.railway.app/api"; // Android emulator

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
        handler.next(options);
      },
      onError: (error, handler) async {
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
    final savedUrl = await _storage.read(key: _baseUrlKey);
    _dio.options.baseUrl = savedUrl ?? defaultBaseUrl;
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
