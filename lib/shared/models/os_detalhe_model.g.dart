// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'os_detalhe_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OsDetalheImpl _$$OsDetalheImplFromJson(Map<String, dynamic> json) =>
    _$OsDetalheImpl(
      numos: (json['numos'] as num).toInt(),
      codprod: (json['codprod'] as num).toInt(),
      codauxiliar: json['codauxiliar'] as String,
      descricao: json['descricao'] as String,
      unidade: json['unidade'] as String,
      multiplo: (json['multiplo'] as num).toInt(),
      qtSolicitada: (json['qtSolicitada'] as num).toDouble(),
      qtEstoqueAtual: (json['qtEstoqueAtual'] as num).toDouble(),
      enderecoOrigem:
          EnderecoOs.fromJson(json['enderecoOrigem'] as Map<String, dynamic>),
      enderecoDestino:
          EnderecoOs.fromJson(json['enderecoDestino'] as Map<String, dynamic>),
      status: json['status'] as String,
      produtoBipado: json['produtoBipado'] as bool? ?? false,
      unitizadorVinculado: json['unitizadorVinculado'] as bool? ?? false,
      codunitizador: json['codunitizador'] as String?,
      divergencia: json['divergencia'] as String?,
    );

Map<String, dynamic> _$$OsDetalheImplToJson(_$OsDetalheImpl instance) =>
    <String, dynamic>{
      'numos': instance.numos,
      'codprod': instance.codprod,
      'codauxiliar': instance.codauxiliar,
      'descricao': instance.descricao,
      'unidade': instance.unidade,
      'multiplo': instance.multiplo,
      'qtSolicitada': instance.qtSolicitada,
      'qtEstoqueAtual': instance.qtEstoqueAtual,
      'enderecoOrigem': instance.enderecoOrigem,
      'enderecoDestino': instance.enderecoDestino,
      'status': instance.status,
      'produtoBipado': instance.produtoBipado,
      'unitizadorVinculado': instance.unitizadorVinculado,
      'codunitizador': instance.codunitizador,
      'divergencia': instance.divergencia,
    };

_$EnderecoOsImpl _$$EnderecoOsImplFromJson(Map<String, dynamic> json) =>
    _$EnderecoOsImpl(
      rua: json['rua'] as String,
      predio: (json['predio'] as num).toInt(),
      nivel: (json['nivel'] as num).toInt(),
      apto: (json['apto'] as num).toInt(),
      enderecoFormatado: json['enderecoFormatado'] as String? ?? '',
    );

Map<String, dynamic> _$$EnderecoOsImplToJson(_$EnderecoOsImpl instance) =>
    <String, dynamic>{
      'rua': instance.rua,
      'predio': instance.predio,
      'nivel': instance.nivel,
      'apto': instance.apto,
      'enderecoFormatado': instance.enderecoFormatado,
    };

_$EstoqueProdutoImpl _$$EstoqueProdutoImplFromJson(Map<String, dynamic> json) =>
    _$EstoqueProdutoImpl(
      rua: json['rua'] as String,
      endereco: json['endereco'] as String? ?? '',
      predio: (json['predio'] as num?)?.toInt() ?? 0,
      nivel: (json['nivel'] as num?)?.toInt() ?? 0,
      apto: (json['apto'] as num?)?.toInt() ?? 0,
      quantidade: (json['quantidade'] as num).toDouble(),
    );

Map<String, dynamic> _$$EstoqueProdutoImplToJson(
        _$EstoqueProdutoImpl instance) =>
    <String, dynamic>{
      'rua': instance.rua,
      'endereco': instance.endereco,
      'predio': instance.predio,
      'nivel': instance.nivel,
      'apto': instance.apto,
      'quantidade': instance.quantidade,
    };
