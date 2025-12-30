import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive/hive.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  
  @override
  Future<User?> build() async {
    return await _loadUserFromStorage();
  }

  Future<User?> _loadUserFromStorage() async {
    try {
      final box = Hive.box('user_data');
      final userData = box.get(_userKey);
      final tokenData = box.get(_tokenKey);
      
      if (userData != null && tokenData != null) {
        final user = User.fromJson(Map<String, dynamic>.from(userData));
        final token = AuthToken.fromJson(Map<String, dynamic>.from(tokenData));
        
        // Verifica se o token ainda é válido
        if (token.expiresAt.isAfter(DateTime.now())) {
          // Token será adicionado automaticamente pelo interceptador
          return user;
        } else {
          // Token expirado, remove dados
          await _clearStorage();
          return null;
        }
      }
      
      return null;
    } catch (e) {
      await _clearStorage();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.login(email, password);
      
      // Parse da resposta da API com validação mais robusta
      dynamic userData = response['user'];
      if (userData == null) {
        throw Exception('Dados do usuário não encontrados na resposta');
      }
      
      // Garantir que userData é um Map
      Map<String, dynamic> userMap;
      if (userData is Map<String, dynamic>) {
        userMap = userData;
      } else if (userData is Map) {
        userMap = userData.cast<String, dynamic>();
      } else {
        throw Exception('Formato de dados do usuário inválido: ${userData.runtimeType}');
      }
      
      final user = User.fromJson(userMap);
      
      // Verificar se token existe na resposta
      final tokenData = response['token'];
      late AuthToken token;
      
      if (tokenData is String) {
        // Token é string simples
        token = AuthToken.fromString(tokenData);
      } else if (tokenData is Map<String, dynamic>) {
        // Token é objeto completo
        token = AuthToken.fromJson(tokenData);
      } else if (tokenData is Map) {
        // Token é Map mas não tipado
        token = AuthToken.fromJson(tokenData.cast<String, dynamic>());
      } else if (response['access_token'] is String) {
        // Algumas APIs usam access_token
        token = AuthToken.fromString(response['access_token']);
      } else {
        throw Exception('Token não encontrado na resposta');
      }
      
      // Salva no storage local
      await _saveToStorage(user, token);
      
      // Token será adicionado automaticamente pelo interceptador
      
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e.toString(), stackTrace);
    }
  }

  Future<void> logout() async {
    try {
      // Limpa storage local
      await _clearStorage();
      
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e.toString(), stackTrace);
    }
  }

  Future<void> _saveToStorage(User user, AuthToken token) async {
    final box = Hive.box('user_data');
    await box.put(_userKey, user.toJson());
    await box.put(_tokenKey, token.toJson());
  }

  Future<void> _clearStorage() async {
    final box = Hive.box('user_data');
    await box.clear();
  }

  String? getToken() {
    try {
      final box = Hive.box('user_data');
      final tokenData = box.get(_tokenKey);
      
      if (tokenData != null) {
        final token = AuthToken.fromJson(Map<String, dynamic>.from(tokenData));
        
        // Verifica se o token ainda é válido
        if (token.expiresAt.isAfter(DateTime.now())) {
          return token.token;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  bool get isTokenValid {
    try {
      final box = Hive.box('user_data');
      final tokenData = box.get(_tokenKey);
      
      if (tokenData != null) {
        final token = AuthToken.fromJson(Map<String, dynamic>.from(tokenData));
        return token.expiresAt.isAfter(DateTime.now());
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
}