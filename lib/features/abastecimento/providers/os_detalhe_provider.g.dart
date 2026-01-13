// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'os_detalhe_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$consultaEstoqueHash() => r'358010f8e6492861dd5a89b320df2a7f06b77949';

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

/// See also [consultaEstoque].
@ProviderFor(consultaEstoque)
const consultaEstoqueProvider = ConsultaEstoqueFamily();

/// See also [consultaEstoque].
class ConsultaEstoqueFamily extends Family<AsyncValue<List<EstoqueProduto>>> {
  /// See also [consultaEstoque].
  const ConsultaEstoqueFamily();

  /// See also [consultaEstoque].
  ConsultaEstoqueProvider call(
    int codprod,
  ) {
    return ConsultaEstoqueProvider(
      codprod,
    );
  }

  @override
  ConsultaEstoqueProvider getProviderOverride(
    covariant ConsultaEstoqueProvider provider,
  ) {
    return call(
      provider.codprod,
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
  String? get name => r'consultaEstoqueProvider';
}

/// See also [consultaEstoque].
class ConsultaEstoqueProvider
    extends AutoDisposeFutureProvider<List<EstoqueProduto>> {
  /// See also [consultaEstoque].
  ConsultaEstoqueProvider(
    int codprod,
  ) : this._internal(
          (ref) => consultaEstoque(
            ref as ConsultaEstoqueRef,
            codprod,
          ),
          from: consultaEstoqueProvider,
          name: r'consultaEstoqueProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$consultaEstoqueHash,
          dependencies: ConsultaEstoqueFamily._dependencies,
          allTransitiveDependencies:
              ConsultaEstoqueFamily._allTransitiveDependencies,
          codprod: codprod,
        );

  ConsultaEstoqueProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.codprod,
  }) : super.internal();

  final int codprod;

  @override
  Override overrideWith(
    FutureOr<List<EstoqueProduto>> Function(ConsultaEstoqueRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConsultaEstoqueProvider._internal(
        (ref) => create(ref as ConsultaEstoqueRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        codprod: codprod,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<EstoqueProduto>> createElement() {
    return _ConsultaEstoqueProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConsultaEstoqueProvider && other.codprod == codprod;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, codprod.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ConsultaEstoqueRef on AutoDisposeFutureProviderRef<List<EstoqueProduto>> {
  /// The parameter `codprod` of this provider.
  int get codprod;
}

class _ConsultaEstoqueProviderElement
    extends AutoDisposeFutureProviderElement<List<EstoqueProduto>>
    with ConsultaEstoqueRef {
  _ConsultaEstoqueProviderElement(super.provider);

  @override
  int get codprod => (origin as ConsultaEstoqueProvider).codprod;
}

String _$osDetalheNotifierHash() => r'b21873d5a978230a7d1e72e99cf653f5841a7c7f';

abstract class _$OsDetalheNotifier
    extends BuildlessAutoDisposeAsyncNotifier<OsDetalhe> {
  late final int fase;
  late final int numos;

  FutureOr<OsDetalhe> build(
    int fase,
    int numos,
  );
}

/// See also [OsDetalheNotifier].
@ProviderFor(OsDetalheNotifier)
const osDetalheNotifierProvider = OsDetalheNotifierFamily();

/// See also [OsDetalheNotifier].
class OsDetalheNotifierFamily extends Family<AsyncValue<OsDetalhe>> {
  /// See also [OsDetalheNotifier].
  const OsDetalheNotifierFamily();

  /// See also [OsDetalheNotifier].
  OsDetalheNotifierProvider call(
    int fase,
    int numos,
  ) {
    return OsDetalheNotifierProvider(
      fase,
      numos,
    );
  }

  @override
  OsDetalheNotifierProvider getProviderOverride(
    covariant OsDetalheNotifierProvider provider,
  ) {
    return call(
      provider.fase,
      provider.numos,
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
  String? get name => r'osDetalheNotifierProvider';
}

/// See also [OsDetalheNotifier].
class OsDetalheNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<OsDetalheNotifier, OsDetalhe> {
  /// See also [OsDetalheNotifier].
  OsDetalheNotifierProvider(
    int fase,
    int numos,
  ) : this._internal(
          () => OsDetalheNotifier()
            ..fase = fase
            ..numos = numos,
          from: osDetalheNotifierProvider,
          name: r'osDetalheNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$osDetalheNotifierHash,
          dependencies: OsDetalheNotifierFamily._dependencies,
          allTransitiveDependencies:
              OsDetalheNotifierFamily._allTransitiveDependencies,
          fase: fase,
          numos: numos,
        );

  OsDetalheNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.fase,
    required this.numos,
  }) : super.internal();

  final int fase;
  final int numos;

  @override
  FutureOr<OsDetalhe> runNotifierBuild(
    covariant OsDetalheNotifier notifier,
  ) {
    return notifier.build(
      fase,
      numos,
    );
  }

  @override
  Override overrideWith(OsDetalheNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: OsDetalheNotifierProvider._internal(
        () => create()
          ..fase = fase
          ..numos = numos,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        fase: fase,
        numos: numos,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<OsDetalheNotifier, OsDetalhe>
      createElement() {
    return _OsDetalheNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OsDetalheNotifierProvider &&
        other.fase == fase &&
        other.numos == numos;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, fase.hashCode);
    hash = _SystemHash.combine(hash, numos.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin OsDetalheNotifierRef on AutoDisposeAsyncNotifierProviderRef<OsDetalhe> {
  /// The parameter `fase` of this provider.
  int get fase;

  /// The parameter `numos` of this provider.
  int get numos;
}

class _OsDetalheNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<OsDetalheNotifier,
        OsDetalhe> with OsDetalheNotifierRef {
  _OsDetalheNotifierProviderElement(super.provider);

  @override
  int get fase => (origin as OsDetalheNotifierProvider).fase;
  @override
  int get numos => (origin as OsDetalheNotifierProvider).numos;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
