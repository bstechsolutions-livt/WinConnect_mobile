// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerifiedAt: json['emailVerifiedAt'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'emailVerifiedAt': instance.emailVerifiedAt,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$AuthTokenImpl _$$AuthTokenImplFromJson(Map<String, dynamic> json) =>
    _$AuthTokenImpl(
      token: json['token'] as String,
      type: json['type'] as String? ?? 'Bearer',
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$$AuthTokenImplToJson(_$AuthTokenImpl instance) =>
    <String, dynamic>{
      'token': instance.token,
      'type': instance.type,
      'expiresAt': instance.expiresAt.toIso8601String(),
    };

_$LoginResponseImpl _$$LoginResponseImplFromJson(Map<String, dynamic> json) =>
    _$LoginResponseImpl(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: AuthToken.fromJson(json['token'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$LoginResponseImplToJson(_$LoginResponseImpl instance) =>
    <String, dynamic>{
      'user': instance.user,
      'token': instance.token,
    };
