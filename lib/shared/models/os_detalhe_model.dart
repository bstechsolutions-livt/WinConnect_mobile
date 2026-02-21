import 'package:freezed_annotation/freezed_annotation.dart';

part 'os_detalhe_model.freezed.dart';
part 'os_detalhe_model.g.dart';

@freezed
class OsDetalhe with _$OsDetalhe {
  const factory OsDetalhe({
    required int numos,
    required int codprod,
    required String codauxiliar,
    String? codauxiliar2, // Código de barras da CAIXA
    required String descricao,
    required String unidade,
    required int multiplo,
    required double qtSolicitada,
    required double qtEstoqueAtual,
    required EnderecoOs enderecoOrigem,
    required EnderecoOs enderecoDestino,
    required String status,
    @Default(false) bool produtoBipado,
    @Default(false) bool unitizadorVinculado,
    String? codunitizador,
    String? divergencia,
    String? tipoBipado, // 'caixa' ou 'unidade' - tipo do último código bipado
  }) = _OsDetalhe;

  factory OsDetalhe.fromJson(Map<String, dynamic> json) =>
      _$OsDetalheFromJson(json);
}

@freezed
class EnderecoOs with _$EnderecoOs {
  const factory EnderecoOs({
    required String rua,
    required int predio,
    required int nivel,
    required int apto,
    @Default('') String enderecoFormatado,
    int? codendereco,
  }) = _EnderecoOs;

  factory EnderecoOs.fromJson(Map<String, dynamic> json) =>
      _$EnderecoOsFromJson(json);
}

@freezed
class EstoqueProduto with _$EstoqueProduto {
  const factory EstoqueProduto({
    required String rua,
    @Default('') String endereco,
    @Default(0) int predio,
    @Default(0) int nivel,
    @Default(0) int apto,
    required double quantidade,
  }) = _EstoqueProduto;

  factory EstoqueProduto.fromJson(Map<String, dynamic> json) =>
      _$EstoqueProdutoFromJson(json);
}