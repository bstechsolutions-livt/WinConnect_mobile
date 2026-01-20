import 'package:freezed_annotation/freezed_annotation.dart';

part 'os_model.freezed.dart';
part 'os_model.g.dart';

/// Conversor para lidar com valores que podem vir como String ou int da API
class FlexibleIntConverter implements JsonConverter<int, dynamic> {
  const FlexibleIntConverter();

  @override
  int fromJson(dynamic json) {
    if (json is int) return json;
    if (json is String) return int.tryParse(json) ?? 0;
    if (json is num) return json.toInt();
    return 0;
  }

  @override
  dynamic toJson(int object) => object;
}

/// Conversor para double que pode vir como String
class FlexibleDoubleConverter implements JsonConverter<double, dynamic> {
  const FlexibleDoubleConverter();

  @override
  double fromJson(dynamic json) {
    if (json is double) return json;
    if (json is int) return json.toDouble();
    if (json is String) return double.tryParse(json) ?? 0.0;
    if (json is num) return json.toDouble();
    return 0.0;
  }

  @override
  dynamic toJson(double object) => object;
}

@freezed
class OrdemServico with _$OrdemServico {
  const factory OrdemServico({
    @FlexibleIntConverter() required int numos,
    @FlexibleIntConverter() @Default(0) int ordem,
    @FlexibleIntConverter() required int codprod,
    required String descricao,
    required String enderecoOrigem,
    @FlexibleDoubleConverter() @Default(0.0) double quantidade,
    @Default('PENDENTE') String status,
    @Default(false) bool podeExecutar,
  }) = _OrdemServico;

  factory OrdemServico.fromJson(Map<String, dynamic> json) =>
      _$OrdemServicoFromJson(json);
}