import 'package:freezed_annotation/freezed_annotation.dart';

part 'os_model.freezed.dart';
part 'os_model.g.dart';

@freezed
class OrdemServico with _$OrdemServico {
  const factory OrdemServico({
    required int numos,
    required int codprod,
    required String produto,
    required String descricao,
    required String enderecoOrigem,
    required String enderecoDestino,
    required double quantidade,
    required String status,
    String? divergencia,
    DateTime? dtinicio,
    DateTime? dtfim,
  }) = _OrdemServico;

  factory OrdemServico.fromJson(Map<String, dynamic> json) =>
      _$OrdemServicoFromJson(json);
}