// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fase2_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ruasFase2NotifierHash() => r'b7078861895e14b6d92865d7c642429872aed615';

/// Provider para listar ruas da Fase 2
///
/// Copied from [RuasFase2Notifier].
@ProviderFor(RuasFase2Notifier)
final ruasFase2NotifierProvider = AutoDisposeAsyncNotifierProvider<
    RuasFase2Notifier, List<RuaFase2>>.internal(
  RuasFase2Notifier.new,
  name: r'ruasFase2NotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ruasFase2NotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RuasFase2Notifier = AutoDisposeAsyncNotifier<List<RuaFase2>>;
String _$unitizadoresFase2NotifierHash() =>
    r'21b4a6712f73824428cc8637cdbb1c7b185247e3';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$UnitizadoresFase2Notifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Unitizador>> {
  late final String rua;

  FutureOr<List<Unitizador>> build(
    String rua,
  );
}

/// Provider para listar unitizadores de uma rua
///
/// Copied from [UnitizadoresFase2Notifier].
@ProviderFor(UnitizadoresFase2Notifier)
const unitizadoresFase2NotifierProvider = UnitizadoresFase2NotifierFamily();

/// Provider para listar unitizadores de uma rua
///
/// Copied from [UnitizadoresFase2Notifier].
class UnitizadoresFase2NotifierFamily
    extends Family<AsyncValue<List<Unitizador>>> {
  /// Provider para listar unitizadores de uma rua
  ///
  /// Copied from [UnitizadoresFase2Notifier].
  const UnitizadoresFase2NotifierFamily();

  /// Provider para listar unitizadores de uma rua
  ///
  /// Copied from [UnitizadoresFase2Notifier].
  UnitizadoresFase2NotifierProvider call(
    String rua,
  ) {
    return UnitizadoresFase2NotifierProvider(
      rua,
    );
  }

  @override
  UnitizadoresFase2NotifierProvider getProviderOverride(
    covariant UnitizadoresFase2NotifierProvider provider,
  ) {
    return call(
      provider.rua,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'unitizadoresFase2NotifierProvider';
}

/// Provider para listar unitizadores de uma rua
///
/// Copied from [UnitizadoresFase2Notifier].
class UnitizadoresFase2NotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<UnitizadoresFase2Notifier,
        List<Unitizador>> {
  /// Provider para listar unitizadores de uma rua
  ///
  /// Copied from [UnitizadoresFase2Notifier].
  UnitizadoresFase2NotifierProvider(
    String rua,
  ) : this._internal(
          () => UnitizadoresFase2Notifier()..rua = rua,
          from: unitizadoresFase2NotifierProvider,
          name: r'unitizadoresFase2NotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unitizadoresFase2NotifierHash,
          dependencies: UnitizadoresFase2NotifierFamily._dependencies,
          allTransitiveDependencies:
              UnitizadoresFase2NotifierFamily._allTransitiveDependencies,
          rua: rua,
        );

  UnitizadoresFase2NotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.rua,
  }) : super.internal();

  final String rua;

  @override
  FutureOr<List<Unitizador>> runNotifierBuild(
    covariant UnitizadoresFase2Notifier notifier,
  ) {
    return notifier.build(
      rua,
    );
  }

  @override
  Override overrideWith(UnitizadoresFase2Notifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: UnitizadoresFase2NotifierProvider._internal(
        () => create()..rua = rua,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        rua: rua,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<UnitizadoresFase2Notifier,
      List<Unitizador>> createElement() {
    return _UnitizadoresFase2NotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnitizadoresFase2NotifierProvider && other.rua == rua;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rua.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UnitizadoresFase2NotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<Unitizador>> {
  /// The parameter `rua` of this provider.
  String get rua;
}

class _UnitizadoresFase2NotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<UnitizadoresFase2Notifier,
        List<Unitizador>> with UnitizadoresFase2NotifierRef {
  _UnitizadoresFase2NotifierProviderElement(super.provider);

  @override
  String get rua => (origin as UnitizadoresFase2NotifierProvider).rua;
}

String _$unitizadorSelecionadoNotifierHash() =>
    r'88bc5b2e15cc4f043704699c0dc8eec9514eda34';

/// Provider para gerenciar o unitizador selecionado e seus itens
///
/// Copied from [UnitizadorSelecionadoNotifier].
@ProviderFor(UnitizadorSelecionadoNotifier)
final unitizadorSelecionadoNotifierProvider = NotifierProvider<
    UnitizadorSelecionadoNotifier,
    ({
      Unitizador? unitizador,
      List<ItemUnitizador> itens,
      int totalConferidos
    })>.internal(
  UnitizadorSelecionadoNotifier.new,
  name: r'unitizadorSelecionadoNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unitizadorSelecionadoNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UnitizadorSelecionadoNotifier = Notifier<
    ({
      Unitizador? unitizador,
      List<ItemUnitizador> itens,
      int totalConferidos
    })>;
String _$carrinhoNotifierHash() => r'8b95a91d5d89b60882191c45a3a6fb6c551e094e';

/// Provider para o carrinho do operador
///
/// Copied from [CarrinhoNotifier].
@ProviderFor(CarrinhoNotifier)
final carrinhoNotifierProvider =
    AsyncNotifierProvider<CarrinhoNotifier, List<ItemCarrinho>>.internal(
  CarrinhoNotifier.new,
  name: r'carrinhoNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$carrinhoNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CarrinhoNotifier = AsyncNotifier<List<ItemCarrinho>>;
String _$rotaEntregaNotifierHash() =>
    r'56e386abd0e3ae7d540aa17468a8d255781b0af2';

/// Provider para a rota calculada
///
/// Copied from [RotaEntregaNotifier].
@ProviderFor(RotaEntregaNotifier)
final rotaEntregaNotifierProvider = NotifierProvider<RotaEntregaNotifier,
    ({List<ItemRota> rota, int totalItens})>.internal(
  RotaEntregaNotifier.new,
  name: r'rotaEntregaNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$rotaEntregaNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RotaEntregaNotifier
    = Notifier<({List<ItemRota> rota, int totalItens})>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
