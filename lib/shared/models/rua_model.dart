import 'package:freezed_annotation/freezed_annotation.dart';

part 'rua_model.freezed.dart';
part 'rua_model.g.dart';

@freezed
class Rua with _$Rua {
  const factory Rua({
    required String codigo,
    required String nome,
    required int quantidade,
    @Default(false) bool selecionada,
  }) = _Rua;

  factory Rua.fromJson(Map<String, dynamic> json) => _$RuaFromJson(json);
}