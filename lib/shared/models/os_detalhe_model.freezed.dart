// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'os_detalhe_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OsDetalhe _$OsDetalheFromJson(Map<String, dynamic> json) {
  return _OsDetalhe.fromJson(json);
}

/// @nodoc
mixin _$OsDetalhe {
  int get numos => throw _privateConstructorUsedError;
  int get codprod => throw _privateConstructorUsedError;
  String get codauxiliar => throw _privateConstructorUsedError;
  String? get codauxiliar2 =>
      throw _privateConstructorUsedError; // Código de barras da CAIXA
  String get descricao => throw _privateConstructorUsedError;
  String get unidade => throw _privateConstructorUsedError;
  int get multiplo => throw _privateConstructorUsedError;
  double get qtSolicitada => throw _privateConstructorUsedError;
  double get qtEstoqueAtual => throw _privateConstructorUsedError;
  EnderecoOs get enderecoOrigem => throw _privateConstructorUsedError;
  EnderecoOs get enderecoDestino => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  bool get produtoBipado => throw _privateConstructorUsedError;
  bool get unitizadorVinculado => throw _privateConstructorUsedError;
  String? get codunitizador => throw _privateConstructorUsedError;
  String? get divergencia => throw _privateConstructorUsedError;
  String? get tipoBipado => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OsDetalheCopyWith<OsDetalhe> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OsDetalheCopyWith<$Res> {
  factory $OsDetalheCopyWith(OsDetalhe value, $Res Function(OsDetalhe) then) =
      _$OsDetalheCopyWithImpl<$Res, OsDetalhe>;
  @useResult
  $Res call(
      {int numos,
      int codprod,
      String codauxiliar,
      String? codauxiliar2,
      String descricao,
      String unidade,
      int multiplo,
      double qtSolicitada,
      double qtEstoqueAtual,
      EnderecoOs enderecoOrigem,
      EnderecoOs enderecoDestino,
      String status,
      bool produtoBipado,
      bool unitizadorVinculado,
      String? codunitizador,
      String? divergencia,
      String? tipoBipado});

  $EnderecoOsCopyWith<$Res> get enderecoOrigem;
  $EnderecoOsCopyWith<$Res> get enderecoDestino;
}

/// @nodoc
class _$OsDetalheCopyWithImpl<$Res, $Val extends OsDetalhe>
    implements $OsDetalheCopyWith<$Res> {
  _$OsDetalheCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? numos = null,
    Object? codprod = null,
    Object? codauxiliar = null,
    Object? codauxiliar2 = freezed,
    Object? descricao = null,
    Object? unidade = null,
    Object? multiplo = null,
    Object? qtSolicitada = null,
    Object? qtEstoqueAtual = null,
    Object? enderecoOrigem = null,
    Object? enderecoDestino = null,
    Object? status = null,
    Object? produtoBipado = null,
    Object? unitizadorVinculado = null,
    Object? codunitizador = freezed,
    Object? divergencia = freezed,
    Object? tipoBipado = freezed,
  }) {
    return _then(_value.copyWith(
      numos: null == numos
          ? _value.numos
          : numos // ignore: cast_nullable_to_non_nullable
              as int,
      codprod: null == codprod
          ? _value.codprod
          : codprod // ignore: cast_nullable_to_non_nullable
              as int,
      codauxiliar: null == codauxiliar
          ? _value.codauxiliar
          : codauxiliar // ignore: cast_nullable_to_non_nullable
              as String,
      codauxiliar2: freezed == codauxiliar2
          ? _value.codauxiliar2
          : codauxiliar2 // ignore: cast_nullable_to_non_nullable
              as String?,
      descricao: null == descricao
          ? _value.descricao
          : descricao // ignore: cast_nullable_to_non_nullable
              as String,
      unidade: null == unidade
          ? _value.unidade
          : unidade // ignore: cast_nullable_to_non_nullable
              as String,
      multiplo: null == multiplo
          ? _value.multiplo
          : multiplo // ignore: cast_nullable_to_non_nullable
              as int,
      qtSolicitada: null == qtSolicitada
          ? _value.qtSolicitada
          : qtSolicitada // ignore: cast_nullable_to_non_nullable
              as double,
      qtEstoqueAtual: null == qtEstoqueAtual
          ? _value.qtEstoqueAtual
          : qtEstoqueAtual // ignore: cast_nullable_to_non_nullable
              as double,
      enderecoOrigem: null == enderecoOrigem
          ? _value.enderecoOrigem
          : enderecoOrigem // ignore: cast_nullable_to_non_nullable
              as EnderecoOs,
      enderecoDestino: null == enderecoDestino
          ? _value.enderecoDestino
          : enderecoDestino // ignore: cast_nullable_to_non_nullable
              as EnderecoOs,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      produtoBipado: null == produtoBipado
          ? _value.produtoBipado
          : produtoBipado // ignore: cast_nullable_to_non_nullable
              as bool,
      unitizadorVinculado: null == unitizadorVinculado
          ? _value.unitizadorVinculado
          : unitizadorVinculado // ignore: cast_nullable_to_non_nullable
              as bool,
      codunitizador: freezed == codunitizador
          ? _value.codunitizador
          : codunitizador // ignore: cast_nullable_to_non_nullable
              as String?,
      divergencia: freezed == divergencia
          ? _value.divergencia
          : divergencia // ignore: cast_nullable_to_non_nullable
              as String?,
      tipoBipado: freezed == tipoBipado
          ? _value.tipoBipado
          : tipoBipado // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $EnderecoOsCopyWith<$Res> get enderecoOrigem {
    return $EnderecoOsCopyWith<$Res>(_value.enderecoOrigem, (value) {
      return _then(_value.copyWith(enderecoOrigem: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $EnderecoOsCopyWith<$Res> get enderecoDestino {
    return $EnderecoOsCopyWith<$Res>(_value.enderecoDestino, (value) {
      return _then(_value.copyWith(enderecoDestino: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OsDetalheImplCopyWith<$Res>
    implements $OsDetalheCopyWith<$Res> {
  factory _$$OsDetalheImplCopyWith(
          _$OsDetalheImpl value, $Res Function(_$OsDetalheImpl) then) =
      __$$OsDetalheImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int numos,
      int codprod,
      String codauxiliar,
      String? codauxiliar2,
      String descricao,
      String unidade,
      int multiplo,
      double qtSolicitada,
      double qtEstoqueAtual,
      EnderecoOs enderecoOrigem,
      EnderecoOs enderecoDestino,
      String status,
      bool produtoBipado,
      bool unitizadorVinculado,
      String? codunitizador,
      String? divergencia,
      String? tipoBipado});

  @override
  $EnderecoOsCopyWith<$Res> get enderecoOrigem;
  @override
  $EnderecoOsCopyWith<$Res> get enderecoDestino;
}

/// @nodoc
class __$$OsDetalheImplCopyWithImpl<$Res>
    extends _$OsDetalheCopyWithImpl<$Res, _$OsDetalheImpl>
    implements _$$OsDetalheImplCopyWith<$Res> {
  __$$OsDetalheImplCopyWithImpl(
      _$OsDetalheImpl _value, $Res Function(_$OsDetalheImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? numos = null,
    Object? codprod = null,
    Object? codauxiliar = null,
    Object? codauxiliar2 = freezed,
    Object? descricao = null,
    Object? unidade = null,
    Object? multiplo = null,
    Object? qtSolicitada = null,
    Object? qtEstoqueAtual = null,
    Object? enderecoOrigem = null,
    Object? enderecoDestino = null,
    Object? status = null,
    Object? produtoBipado = null,
    Object? unitizadorVinculado = null,
    Object? codunitizador = freezed,
    Object? divergencia = freezed,
    Object? tipoBipado = freezed,
  }) {
    return _then(_$OsDetalheImpl(
      numos: null == numos
          ? _value.numos
          : numos // ignore: cast_nullable_to_non_nullable
              as int,
      codprod: null == codprod
          ? _value.codprod
          : codprod // ignore: cast_nullable_to_non_nullable
              as int,
      codauxiliar: null == codauxiliar
          ? _value.codauxiliar
          : codauxiliar // ignore: cast_nullable_to_non_nullable
              as String,
      codauxiliar2: freezed == codauxiliar2
          ? _value.codauxiliar2
          : codauxiliar2 // ignore: cast_nullable_to_non_nullable
              as String?,
      descricao: null == descricao
          ? _value.descricao
          : descricao // ignore: cast_nullable_to_non_nullable
              as String,
      unidade: null == unidade
          ? _value.unidade
          : unidade // ignore: cast_nullable_to_non_nullable
              as String,
      multiplo: null == multiplo
          ? _value.multiplo
          : multiplo // ignore: cast_nullable_to_non_nullable
              as int,
      qtSolicitada: null == qtSolicitada
          ? _value.qtSolicitada
          : qtSolicitada // ignore: cast_nullable_to_non_nullable
              as double,
      qtEstoqueAtual: null == qtEstoqueAtual
          ? _value.qtEstoqueAtual
          : qtEstoqueAtual // ignore: cast_nullable_to_non_nullable
              as double,
      enderecoOrigem: null == enderecoOrigem
          ? _value.enderecoOrigem
          : enderecoOrigem // ignore: cast_nullable_to_non_nullable
              as EnderecoOs,
      enderecoDestino: null == enderecoDestino
          ? _value.enderecoDestino
          : enderecoDestino // ignore: cast_nullable_to_non_nullable
              as EnderecoOs,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      produtoBipado: null == produtoBipado
          ? _value.produtoBipado
          : produtoBipado // ignore: cast_nullable_to_non_nullable
              as bool,
      unitizadorVinculado: null == unitizadorVinculado
          ? _value.unitizadorVinculado
          : unitizadorVinculado // ignore: cast_nullable_to_non_nullable
              as bool,
      codunitizador: freezed == codunitizador
          ? _value.codunitizador
          : codunitizador // ignore: cast_nullable_to_non_nullable
              as String?,
      divergencia: freezed == divergencia
          ? _value.divergencia
          : divergencia // ignore: cast_nullable_to_non_nullable
              as String?,
      tipoBipado: freezed == tipoBipado
          ? _value.tipoBipado
          : tipoBipado // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OsDetalheImpl implements _OsDetalhe {
  const _$OsDetalheImpl(
      {required this.numos,
      required this.codprod,
      required this.codauxiliar,
      this.codauxiliar2,
      required this.descricao,
      required this.unidade,
      required this.multiplo,
      required this.qtSolicitada,
      required this.qtEstoqueAtual,
      required this.enderecoOrigem,
      required this.enderecoDestino,
      required this.status,
      this.produtoBipado = false,
      this.unitizadorVinculado = false,
      this.codunitizador,
      this.divergencia,
      this.tipoBipado});

  factory _$OsDetalheImpl.fromJson(Map<String, dynamic> json) =>
      _$$OsDetalheImplFromJson(json);

  @override
  final int numos;
  @override
  final int codprod;
  @override
  final String codauxiliar;
  @override
  final String? codauxiliar2;
// Código de barras da CAIXA
  @override
  final String descricao;
  @override
  final String unidade;
  @override
  final int multiplo;
  @override
  final double qtSolicitada;
  @override
  final double qtEstoqueAtual;
  @override
  final EnderecoOs enderecoOrigem;
  @override
  final EnderecoOs enderecoDestino;
  @override
  final String status;
  @override
  @JsonKey()
  final bool produtoBipado;
  @override
  @JsonKey()
  final bool unitizadorVinculado;
  @override
  final String? codunitizador;
  @override
  final String? divergencia;
  @override
  final String? tipoBipado;

  @override
  String toString() {
    return 'OsDetalhe(numos: $numos, codprod: $codprod, codauxiliar: $codauxiliar, codauxiliar2: $codauxiliar2, descricao: $descricao, unidade: $unidade, multiplo: $multiplo, qtSolicitada: $qtSolicitada, qtEstoqueAtual: $qtEstoqueAtual, enderecoOrigem: $enderecoOrigem, enderecoDestino: $enderecoDestino, status: $status, produtoBipado: $produtoBipado, unitizadorVinculado: $unitizadorVinculado, codunitizador: $codunitizador, divergencia: $divergencia, tipoBipado: $tipoBipado)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OsDetalheImpl &&
            (identical(other.numos, numos) || other.numos == numos) &&
            (identical(other.codprod, codprod) || other.codprod == codprod) &&
            (identical(other.codauxiliar, codauxiliar) ||
                other.codauxiliar == codauxiliar) &&
            (identical(other.codauxiliar2, codauxiliar2) ||
                other.codauxiliar2 == codauxiliar2) &&
            (identical(other.descricao, descricao) ||
                other.descricao == descricao) &&
            (identical(other.unidade, unidade) || other.unidade == unidade) &&
            (identical(other.multiplo, multiplo) ||
                other.multiplo == multiplo) &&
            (identical(other.qtSolicitada, qtSolicitada) ||
                other.qtSolicitada == qtSolicitada) &&
            (identical(other.qtEstoqueAtual, qtEstoqueAtual) ||
                other.qtEstoqueAtual == qtEstoqueAtual) &&
            (identical(other.enderecoOrigem, enderecoOrigem) ||
                other.enderecoOrigem == enderecoOrigem) &&
            (identical(other.enderecoDestino, enderecoDestino) ||
                other.enderecoDestino == enderecoDestino) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.produtoBipado, produtoBipado) ||
                other.produtoBipado == produtoBipado) &&
            (identical(other.unitizadorVinculado, unitizadorVinculado) ||
                other.unitizadorVinculado == unitizadorVinculado) &&
            (identical(other.codunitizador, codunitizador) ||
                other.codunitizador == codunitizador) &&
            (identical(other.divergencia, divergencia) ||
                other.divergencia == divergencia) &&
            (identical(other.tipoBipado, tipoBipado) ||
                other.tipoBipado == tipoBipado));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      numos,
      codprod,
      codauxiliar,
      codauxiliar2,
      descricao,
      unidade,
      multiplo,
      qtSolicitada,
      qtEstoqueAtual,
      enderecoOrigem,
      enderecoDestino,
      status,
      produtoBipado,
      unitizadorVinculado,
      codunitizador,
      divergencia,
      tipoBipado);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OsDetalheImplCopyWith<_$OsDetalheImpl> get copyWith =>
      __$$OsDetalheImplCopyWithImpl<_$OsDetalheImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OsDetalheImplToJson(
      this,
    );
  }
}

abstract class _OsDetalhe implements OsDetalhe {
  const factory _OsDetalhe(
      {required final int numos,
      required final int codprod,
      required final String codauxiliar,
      final String? codauxiliar2,
      required final String descricao,
      required final String unidade,
      required final int multiplo,
      required final double qtSolicitada,
      required final double qtEstoqueAtual,
      required final EnderecoOs enderecoOrigem,
      required final EnderecoOs enderecoDestino,
      required final String status,
      final bool produtoBipado,
      final bool unitizadorVinculado,
      final String? codunitizador,
      final String? divergencia,
      final String? tipoBipado}) = _$OsDetalheImpl;

  factory _OsDetalhe.fromJson(Map<String, dynamic> json) =
      _$OsDetalheImpl.fromJson;

  @override
  int get numos;
  @override
  int get codprod;
  @override
  String get codauxiliar;
  @override
  String? get codauxiliar2;
  @override // Código de barras da CAIXA
  String get descricao;
  @override
  String get unidade;
  @override
  int get multiplo;
  @override
  double get qtSolicitada;
  @override
  double get qtEstoqueAtual;
  @override
  EnderecoOs get enderecoOrigem;
  @override
  EnderecoOs get enderecoDestino;
  @override
  String get status;
  @override
  bool get produtoBipado;
  @override
  bool get unitizadorVinculado;
  @override
  String? get codunitizador;
  @override
  String? get divergencia;
  @override
  String? get tipoBipado;
  @override
  @JsonKey(ignore: true)
  _$$OsDetalheImplCopyWith<_$OsDetalheImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EnderecoOs _$EnderecoOsFromJson(Map<String, dynamic> json) {
  return _EnderecoOs.fromJson(json);
}

/// @nodoc
mixin _$EnderecoOs {
  String get rua => throw _privateConstructorUsedError;
  int get predio => throw _privateConstructorUsedError;
  int get nivel => throw _privateConstructorUsedError;
  int get apto => throw _privateConstructorUsedError;
  String get enderecoFormatado => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EnderecoOsCopyWith<EnderecoOs> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnderecoOsCopyWith<$Res> {
  factory $EnderecoOsCopyWith(
          EnderecoOs value, $Res Function(EnderecoOs) then) =
      _$EnderecoOsCopyWithImpl<$Res, EnderecoOs>;
  @useResult
  $Res call(
      {String rua, int predio, int nivel, int apto, String enderecoFormatado});
}

/// @nodoc
class _$EnderecoOsCopyWithImpl<$Res, $Val extends EnderecoOs>
    implements $EnderecoOsCopyWith<$Res> {
  _$EnderecoOsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rua = null,
    Object? predio = null,
    Object? nivel = null,
    Object? apto = null,
    Object? enderecoFormatado = null,
  }) {
    return _then(_value.copyWith(
      rua: null == rua
          ? _value.rua
          : rua // ignore: cast_nullable_to_non_nullable
              as String,
      predio: null == predio
          ? _value.predio
          : predio // ignore: cast_nullable_to_non_nullable
              as int,
      nivel: null == nivel
          ? _value.nivel
          : nivel // ignore: cast_nullable_to_non_nullable
              as int,
      apto: null == apto
          ? _value.apto
          : apto // ignore: cast_nullable_to_non_nullable
              as int,
      enderecoFormatado: null == enderecoFormatado
          ? _value.enderecoFormatado
          : enderecoFormatado // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EnderecoOsImplCopyWith<$Res>
    implements $EnderecoOsCopyWith<$Res> {
  factory _$$EnderecoOsImplCopyWith(
          _$EnderecoOsImpl value, $Res Function(_$EnderecoOsImpl) then) =
      __$$EnderecoOsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String rua, int predio, int nivel, int apto, String enderecoFormatado});
}

/// @nodoc
class __$$EnderecoOsImplCopyWithImpl<$Res>
    extends _$EnderecoOsCopyWithImpl<$Res, _$EnderecoOsImpl>
    implements _$$EnderecoOsImplCopyWith<$Res> {
  __$$EnderecoOsImplCopyWithImpl(
      _$EnderecoOsImpl _value, $Res Function(_$EnderecoOsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rua = null,
    Object? predio = null,
    Object? nivel = null,
    Object? apto = null,
    Object? enderecoFormatado = null,
  }) {
    return _then(_$EnderecoOsImpl(
      rua: null == rua
          ? _value.rua
          : rua // ignore: cast_nullable_to_non_nullable
              as String,
      predio: null == predio
          ? _value.predio
          : predio // ignore: cast_nullable_to_non_nullable
              as int,
      nivel: null == nivel
          ? _value.nivel
          : nivel // ignore: cast_nullable_to_non_nullable
              as int,
      apto: null == apto
          ? _value.apto
          : apto // ignore: cast_nullable_to_non_nullable
              as int,
      enderecoFormatado: null == enderecoFormatado
          ? _value.enderecoFormatado
          : enderecoFormatado // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EnderecoOsImpl implements _EnderecoOs {
  const _$EnderecoOsImpl(
      {required this.rua,
      required this.predio,
      required this.nivel,
      required this.apto,
      this.enderecoFormatado = ''});

  factory _$EnderecoOsImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnderecoOsImplFromJson(json);

  @override
  final String rua;
  @override
  final int predio;
  @override
  final int nivel;
  @override
  final int apto;
  @override
  @JsonKey()
  final String enderecoFormatado;

  @override
  String toString() {
    return 'EnderecoOs(rua: $rua, predio: $predio, nivel: $nivel, apto: $apto, enderecoFormatado: $enderecoFormatado)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnderecoOsImpl &&
            (identical(other.rua, rua) || other.rua == rua) &&
            (identical(other.predio, predio) || other.predio == predio) &&
            (identical(other.nivel, nivel) || other.nivel == nivel) &&
            (identical(other.apto, apto) || other.apto == apto) &&
            (identical(other.enderecoFormatado, enderecoFormatado) ||
                other.enderecoFormatado == enderecoFormatado));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, rua, predio, nivel, apto, enderecoFormatado);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EnderecoOsImplCopyWith<_$EnderecoOsImpl> get copyWith =>
      __$$EnderecoOsImplCopyWithImpl<_$EnderecoOsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EnderecoOsImplToJson(
      this,
    );
  }
}

abstract class _EnderecoOs implements EnderecoOs {
  const factory _EnderecoOs(
      {required final String rua,
      required final int predio,
      required final int nivel,
      required final int apto,
      final String enderecoFormatado}) = _$EnderecoOsImpl;

  factory _EnderecoOs.fromJson(Map<String, dynamic> json) =
      _$EnderecoOsImpl.fromJson;

  @override
  String get rua;
  @override
  int get predio;
  @override
  int get nivel;
  @override
  int get apto;
  @override
  String get enderecoFormatado;
  @override
  @JsonKey(ignore: true)
  _$$EnderecoOsImplCopyWith<_$EnderecoOsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EstoqueProduto _$EstoqueProdutoFromJson(Map<String, dynamic> json) {
  return _EstoqueProduto.fromJson(json);
}

/// @nodoc
mixin _$EstoqueProduto {
  String get rua => throw _privateConstructorUsedError;
  String get endereco => throw _privateConstructorUsedError;
  int get predio => throw _privateConstructorUsedError;
  int get nivel => throw _privateConstructorUsedError;
  int get apto => throw _privateConstructorUsedError;
  double get quantidade => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EstoqueProdutoCopyWith<EstoqueProduto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EstoqueProdutoCopyWith<$Res> {
  factory $EstoqueProdutoCopyWith(
          EstoqueProduto value, $Res Function(EstoqueProduto) then) =
      _$EstoqueProdutoCopyWithImpl<$Res, EstoqueProduto>;
  @useResult
  $Res call(
      {String rua,
      String endereco,
      int predio,
      int nivel,
      int apto,
      double quantidade});
}

/// @nodoc
class _$EstoqueProdutoCopyWithImpl<$Res, $Val extends EstoqueProduto>
    implements $EstoqueProdutoCopyWith<$Res> {
  _$EstoqueProdutoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rua = null,
    Object? endereco = null,
    Object? predio = null,
    Object? nivel = null,
    Object? apto = null,
    Object? quantidade = null,
  }) {
    return _then(_value.copyWith(
      rua: null == rua
          ? _value.rua
          : rua // ignore: cast_nullable_to_non_nullable
              as String,
      endereco: null == endereco
          ? _value.endereco
          : endereco // ignore: cast_nullable_to_non_nullable
              as String,
      predio: null == predio
          ? _value.predio
          : predio // ignore: cast_nullable_to_non_nullable
              as int,
      nivel: null == nivel
          ? _value.nivel
          : nivel // ignore: cast_nullable_to_non_nullable
              as int,
      apto: null == apto
          ? _value.apto
          : apto // ignore: cast_nullable_to_non_nullable
              as int,
      quantidade: null == quantidade
          ? _value.quantidade
          : quantidade // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EstoqueProdutoImplCopyWith<$Res>
    implements $EstoqueProdutoCopyWith<$Res> {
  factory _$$EstoqueProdutoImplCopyWith(_$EstoqueProdutoImpl value,
          $Res Function(_$EstoqueProdutoImpl) then) =
      __$$EstoqueProdutoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String rua,
      String endereco,
      int predio,
      int nivel,
      int apto,
      double quantidade});
}

/// @nodoc
class __$$EstoqueProdutoImplCopyWithImpl<$Res>
    extends _$EstoqueProdutoCopyWithImpl<$Res, _$EstoqueProdutoImpl>
    implements _$$EstoqueProdutoImplCopyWith<$Res> {
  __$$EstoqueProdutoImplCopyWithImpl(
      _$EstoqueProdutoImpl _value, $Res Function(_$EstoqueProdutoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rua = null,
    Object? endereco = null,
    Object? predio = null,
    Object? nivel = null,
    Object? apto = null,
    Object? quantidade = null,
  }) {
    return _then(_$EstoqueProdutoImpl(
      rua: null == rua
          ? _value.rua
          : rua // ignore: cast_nullable_to_non_nullable
              as String,
      endereco: null == endereco
          ? _value.endereco
          : endereco // ignore: cast_nullable_to_non_nullable
              as String,
      predio: null == predio
          ? _value.predio
          : predio // ignore: cast_nullable_to_non_nullable
              as int,
      nivel: null == nivel
          ? _value.nivel
          : nivel // ignore: cast_nullable_to_non_nullable
              as int,
      apto: null == apto
          ? _value.apto
          : apto // ignore: cast_nullable_to_non_nullable
              as int,
      quantidade: null == quantidade
          ? _value.quantidade
          : quantidade // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EstoqueProdutoImpl implements _EstoqueProduto {
  const _$EstoqueProdutoImpl(
      {required this.rua,
      this.endereco = '',
      this.predio = 0,
      this.nivel = 0,
      this.apto = 0,
      required this.quantidade});

  factory _$EstoqueProdutoImpl.fromJson(Map<String, dynamic> json) =>
      _$$EstoqueProdutoImplFromJson(json);

  @override
  final String rua;
  @override
  @JsonKey()
  final String endereco;
  @override
  @JsonKey()
  final int predio;
  @override
  @JsonKey()
  final int nivel;
  @override
  @JsonKey()
  final int apto;
  @override
  final double quantidade;

  @override
  String toString() {
    return 'EstoqueProduto(rua: $rua, endereco: $endereco, predio: $predio, nivel: $nivel, apto: $apto, quantidade: $quantidade)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EstoqueProdutoImpl &&
            (identical(other.rua, rua) || other.rua == rua) &&
            (identical(other.endereco, endereco) ||
                other.endereco == endereco) &&
            (identical(other.predio, predio) || other.predio == predio) &&
            (identical(other.nivel, nivel) || other.nivel == nivel) &&
            (identical(other.apto, apto) || other.apto == apto) &&
            (identical(other.quantidade, quantidade) ||
                other.quantidade == quantidade));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, rua, endereco, predio, nivel, apto, quantidade);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EstoqueProdutoImplCopyWith<_$EstoqueProdutoImpl> get copyWith =>
      __$$EstoqueProdutoImplCopyWithImpl<_$EstoqueProdutoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EstoqueProdutoImplToJson(
      this,
    );
  }
}

abstract class _EstoqueProduto implements EstoqueProduto {
  const factory _EstoqueProduto(
      {required final String rua,
      final String endereco,
      final int predio,
      final int nivel,
      final int apto,
      required final double quantidade}) = _$EstoqueProdutoImpl;

  factory _EstoqueProduto.fromJson(Map<String, dynamic> json) =
      _$EstoqueProdutoImpl.fromJson;

  @override
  String get rua;
  @override
  String get endereco;
  @override
  int get predio;
  @override
  int get nivel;
  @override
  int get apto;
  @override
  double get quantidade;
  @override
  @JsonKey(ignore: true)
  _$$EstoqueProdutoImplCopyWith<_$EstoqueProdutoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
