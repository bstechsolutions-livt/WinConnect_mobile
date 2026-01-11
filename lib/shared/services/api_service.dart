import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/client_config.dart';

// Provider usando sintaxe clássica do Riverpod
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  
  // Base URL - vem da configuração do cliente
  dio.options.baseUrl = ClientConfig.current.apiBaseUrl;
  
  // Headers padrão
  dio.options.headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true', // Pula aviso do ngrok free
  };
  
  // Timeout
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  
  // Logger para debug
  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    ),
  );
  
  return dio;
});

// API Service usando sintaxe clássica
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});

class ApiService {
  final Dio dio;
  
  ApiService(this.dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await dio.post('/login', data: {
        'email': email,
        'password': password,
      });
      
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Email ou senha inválidos');
      } else if (e.response?.statusCode == 422) {
        throw Exception('Dados inválidos');
      } else {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await dio.post('/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });
      
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw Exception('Email já cadastrado ou dados inválidos');
      } else {
        throw Exception('Erro de conexão. Verifique sua internet.');
      }
    }
  }

  Future<void> logout(String token) async {
    try {
      await dio.post(
        '/logout',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      // Ignora erro de logout - remove local mesmo assim
    }
  }
}