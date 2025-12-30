// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SuccessImpl<T> _$$SuccessImplFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    _$SuccessImpl<T>(
      data: fromJsonT(json['data']),
      message: json['message'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$SuccessImplToJson<T>(
  _$SuccessImpl<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'data': toJsonT(instance.data),
      'message': instance.message,
      'runtimeType': instance.$type,
    };

_$ErrorImpl<T> _$$ErrorImplFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    _$ErrorImpl<T>(
      message: json['message'] as String,
      code: (json['code'] as num?)?.toInt(),
      details: json['details'],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ErrorImplToJson<T>(
  _$ErrorImpl<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'message': instance.message,
      'code': instance.code,
      'details': instance.details,
      'runtimeType': instance.$type,
    };
