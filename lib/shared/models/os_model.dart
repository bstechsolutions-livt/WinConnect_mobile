import 'package:freezed_annotation/freezed_annotation.dart';

part 'os_model.freezed.dart';
part 'os_model.g.dart';

@freezed
class OrdemServico with _$OrdemServico {
  const factory OrdemServico({
    required int numos,
    @Default(0) int ordem,
    required int codprod,
    required String descricao,
    required String enderecoOrigem,
    @Default(0.0) double quantidade,
    @Default('PENDENTE') String status,
    @Default(false) bool podeExecutar,
  }) = _OrdemServico;

  factory OrdemServico.fromJson(Map<String, dynamic> json) =>
      _$OrdemServicoFromJson(json);
}