import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/client_config.dart';

part 'api_service_provider.g.dart';

@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) {
  return ApiService();
}

class ApiService {
  late final Dio _dio;

  /// URL base da API - vem da configuração do cliente
  static String get baseUrl => ClientConfig.current.apiBaseUrl;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true', // Pula aviso do ngrok free
        },
      ),
    );

    // Interceptador para adicionar token automaticamente
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _getStoredToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  String? _getStoredToken() {
    try {
      final box = Hive.box('user_data');
      final tokenData = box.get('auth_token');

      if (tokenData != null) {
        // Se é um Map (IdentityMap<String, dynamic>)
        if (tokenData is Map) {
          final tokenMap = Map<String, dynamic>.from(tokenData);
          final tokenString = tokenMap['token'] as String?;
          final expiresAtString = tokenMap['expires_at'] as String?;

          if (tokenString != null) {
            if (expiresAtString != null) {
              final expiresAt = DateTime.parse(expiresAtString);
              if (expiresAt.isAfter(DateTime.now())) {
                return tokenString;
              }
            } else {
              // Se não tem data de expiração, assume que é válido
              return tokenString;
            }
          }
        }
        // Se é uma String direta
        else if (tokenData is String) {
          return tokenData;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      print('===== API GET: $endpoint =====');
      final response = await _dio.get(endpoint);
      print('Response type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');
      print('==============================');
      return response.data;
    } on DioException catch (e) {
      print('===== API ERROR: $endpoint =====');
      print('Error: $e');
      print('================================');
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tempo limite de conexão. Verifique sua internet.';
      case DioExceptionType.badResponse:
        final message =
            e.response?.data?['message'] ?? 'Erro ao processar solicitação';
        return message;
      case DioExceptionType.cancel:
        return 'Operação cancelada';
      case DioExceptionType.unknown:
      default:
        return 'Erro de conexão. Verifique sua internet.';
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    return post('/login', {
      'email': email,
      'password': password,
      'device_name': 'WinConnect Mobile',
    });
  }

  Future<void> logout() async {
    await post('/logout', {});
  }
}
