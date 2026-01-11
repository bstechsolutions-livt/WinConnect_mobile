// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'os_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrdemServicoImpl _$$OrdemServicoImplFromJson(Map<String, dynamic> json) =>
    _$OrdemServicoImpl(
      numos: (json['numos'] as num).toInt(),
      ordem: (json['ordem'] as num?)?.toInt() ?? 0,
      codprod: (json['codprod'] as num).toInt(),
      descricao: json['descricao'] as String,
      enderecoOrigem: json['enderecoOrigem'] as String,
      quantidade: (json['quantidade'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'PENDENTE',
      podeExecutar: json['podeExecutar'] as bool? ?? false,
    );

Map<String, dynamic> _$$OrdemServicoImplToJson(_$OrdemServicoImpl instance) =>
    <String, dynamic>{
      'numos': instance.numos,
      'ordem': instance.ordem,
      'codprod': instance.codprod,
      'descricao': instance.descricao,
      'enderecoOrigem': instance.enderecoOrigem,
      'quantidade': instance.quantidade,
      'status': instance.status,
      'podeExecutar': instance.podeExecutar,
    };
