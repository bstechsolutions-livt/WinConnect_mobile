// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'os_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrdemServicoImpl _$$OrdemServicoImplFromJson(Map<String, dynamic> json) =>
    _$OrdemServicoImpl(
      numos: (json['numos'] as num).toInt(),
      codprod: (json['codprod'] as num).toInt(),
      produto: json['produto'] as String,
      descricao: json['descricao'] as String,
      enderecoOrigem: json['enderecoOrigem'] as String,
      enderecoDestino: json['enderecoDestino'] as String,
      quantidade: (json['quantidade'] as num).toDouble(),
      status: json['status'] as String,
      divergencia: json['divergencia'] as String?,
      dtinicio: json['dtinicio'] == null
          ? null
          : DateTime.parse(json['dtinicio'] as String),
      dtfim: json['dtfim'] == null
          ? null
          : DateTime.parse(json['dtfim'] as String),
    );

Map<String, dynamic> _$$OrdemServicoImplToJson(_$OrdemServicoImpl instance) =>
    <String, dynamic>{
      'numos': instance.numos,
      'codprod': instance.codprod,
      'produto': instance.produto,
      'descricao': instance.descricao,
      'enderecoOrigem': instance.enderecoOrigem,
      'enderecoDestino': instance.enderecoDestino,
      'quantidade': instance.quantidade,
      'status': instance.status,
      'divergencia': instance.divergencia,
      'dtinicio': instance.dtinicio?.toIso8601String(),
      'dtfim': instance.dtfim?.toIso8601String(),
    };
