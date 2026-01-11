import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    int? matricula,
    String? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class AuthToken with _$AuthToken {
  const factory AuthToken({
    required String token,
    @Default('Bearer') String type,
    required DateTime expiresAt,
  }) = _AuthToken;

  factory AuthToken.fromJson(Map<String, dynamic> json) => _$AuthTokenFromJson(json);
  
  // Método para criar token simples a partir de string
  factory AuthToken.fromString(String tokenString) {
    return AuthToken(
      token: tokenString,
      type: 'Bearer',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
  }
}

@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required User user,
    required AuthToken token,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
}