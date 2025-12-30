// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rua_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RuaImpl _$$RuaImplFromJson(Map<String, dynamic> json) => _$RuaImpl(
      codigo: json['codigo'] as String,
      nome: json['nome'] as String,
      quantidade: (json['quantidade'] as num).toInt(),
      selecionada: json['selecionada'] as bool? ?? false,
    );

Map<String, dynamic> _$$RuaImplToJson(_$RuaImpl instance) => <String, dynamic>{
      'codigo': instance.codigo,
      'nome': instance.nome,
      'quantidade': instance.quantidade,
      'selecionada': instance.selecionada,
    };
