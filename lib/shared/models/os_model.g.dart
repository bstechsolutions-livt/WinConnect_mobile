// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'os_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrdemServicoImpl _$$OrdemServicoImplFromJson(Map<String, dynamic> json) =>
    _$OrdemServicoImpl(
      numos: const FlexibleIntConverter().fromJson(json['numos']),
      ordem: json['ordem'] == null
          ? 0
          : const FlexibleIntConverter().fromJson(json['ordem']),
      codprod: const FlexibleIntConverter().fromJson(json['codprod']),
      descricao: json['descricao'] as String,
      enderecoOrigem: json['enderecoOrigem'] as String,
      quantidade: json['quantidade'] == null
          ? 0.0
          : const FlexibleDoubleConverter().fromJson(json['quantidade']),
      status: json['status'] as String? ?? 'PENDENTE',
      podeExecutar: json['podeExecutar'] as bool? ?? false,
    );

Map<String, dynamic> _$$OrdemServicoImplToJson(_$OrdemServicoImpl instance) =>
    <String, dynamic>{
      'numos': const FlexibleIntConverter().toJson(instance.numos),
      'ordem': const FlexibleIntConverter().toJson(instance.ordem),
      'codprod': const FlexibleIntConverter().toJson(instance.codprod),
      'descricao': instance.descricao,
      'enderecoOrigem': instance.enderecoOrigem,
      'quantidade': const FlexibleDoubleConverter().toJson(instance.quantidade),
      'status': instance.status,
      'podeExecutar': instance.podeExecutar,
    };
