// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rua_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Rua _$RuaFromJson(Map<String, dynamic> json) {
  return _Rua.fromJson(json);
}

/// @nodoc
mixin _$Rua {
  String get codigo => throw _privateConstructorUsedError;
  String get nome => throw _privateConstructorUsedError;
  int get quantidade => throw _privateConstructorUsedError;
  bool get selecionada => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RuaCopyWith<Rua> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RuaCopyWith<$Res> {
  factory $RuaCopyWith(Rua value, $Res Function(Rua) then) =
      _$RuaCopyWithImpl<$Res, Rua>;
  @useResult
  $Res call({String codigo, String nome, int quantidade, bool selecionada});
}

/// @nodoc
class _$RuaCopyWithImpl<$Res, $Val extends Rua> implements $RuaCopyWith<$Res> {
  _$RuaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? codigo = null,
    Object? nome = null,
    Object? quantidade = null,
    Object? selecionada = null,
  }) {
    return _then(_value.copyWith(
      codigo: null == codigo
          ? _value.codigo
          : codigo // ignore: cast_nullable_to_non_nullable
              as String,
      nome: null == nome
          ? _value.nome
          : nome // ignore: cast_nullable_to_non_nullable
              as String,
      quantidade: null == quantidade
          ? _value.quantidade
          : quantidade // ignore: cast_nullable_to_non_nullable
              as int,
      selecionada: null == selecionada
          ? _value.selecionada
          : selecionada // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RuaImplCopyWith<$Res> implements $RuaCopyWith<$Res> {
  factory _$$RuaImplCopyWith(_$RuaImpl value, $Res Function(_$RuaImpl) then) =
      __$$RuaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String codigo, String nome, int quantidade, bool selecionada});
}

/// @nodoc
class __$$RuaImplCopyWithImpl<$Res> extends _$RuaCopyWithImpl<$Res, _$RuaImpl>
    implements _$$RuaImplCopyWith<$Res> {
  __$$RuaImplCopyWithImpl(_$RuaImpl _value, $Res Function(_$RuaImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? codigo = null,
    Object? nome = null,
    Object? quantidade = null,
    Object? selecionada = null,
  }) {
    return _then(_$RuaImpl(
      codigo: null == codigo
          ? _value.codigo
          : codigo // ignore: cast_nullable_to_non_nullable
              as String,
      nome: null == nome
          ? _value.nome
          : nome // ignore: cast_nullable_to_non_nullable
              as String,
      quantidade: null == quantidade
          ? _value.quantidade
          : quantidade // ignore: cast_nullable_to_non_nullable
              as int,
      selecionada: null == selecionada
          ? _value.selecionada
          : selecionada // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RuaImpl implements _Rua {
  const _$RuaImpl(
      {required this.codigo,
      required this.nome,
      required this.quantidade,
      this.selecionada = false});

  factory _$RuaImpl.fromJson(Map<String, dynamic> json) =>
      _$$RuaImplFromJson(json);

  @override
  final String codigo;
  @override
  final String nome;
  @override
  final int quantidade;
  @override
  @JsonKey()
  final bool selecionada;

  @override
  String toString() {
    return 'Rua(codigo: $codigo, nome: $nome, quantidade: $quantidade, selecionada: $selecionada)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RuaImpl &&
            (identical(other.codigo, codigo) || other.codigo == codigo) &&
            (identical(other.nome, nome) || other.nome == nome) &&
            (identical(other.quantidade, quantidade) ||
                other.quantidade == quantidade) &&
            (identical(other.selecionada, selecionada) ||
                other.selecionada == selecionada));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, codigo, nome, quantidade, selecionada);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RuaImplCopyWith<_$RuaImpl> get copyWith =>
      __$$RuaImplCopyWithImpl<_$RuaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RuaImplToJson(
      this,
    );
  }
}

abstract class _Rua implements Rua {
  const factory _Rua(
      {required final String codigo,
      required final String nome,
      required final int quantidade,
      final bool selecionada}) = _$RuaImpl;

  factory _Rua.fromJson(Map<String, dynamic> json) = _$RuaImpl.fromJson;

  @override
  String get codigo;
  @override
  String get nome;
  @override
  int get quantidade;
  @override
  bool get selecionada;
  @override
  @JsonKey(ignore: true)
  _$$RuaImplCopyWith<_$RuaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
