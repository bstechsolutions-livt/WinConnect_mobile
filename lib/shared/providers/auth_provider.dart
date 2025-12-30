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
      
      // Parse da resposta da API
      final user = User.fromJson(response['user']);
      final token = AuthToken.fromJson(response['token']);
      
      // Salva no storage local
      await _saveToStorage(user, token);
      
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> logout() async {
    try {
      final box = Hive.box('user_data');
      final tokenData = box.get(_tokenKey);
      
      if (tokenData != null) {
        final token = AuthToken.fromJson(Map<String, dynamic>.from(tokenData));
        final apiService = ref.read(apiServiceProvider);
        await apiService.logout(token.token);
      }
    } catch (e) {
      // Ignora erro de logout na API
    } finally {
      await _clearStorage();
      state = const AsyncValue.data(null);
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