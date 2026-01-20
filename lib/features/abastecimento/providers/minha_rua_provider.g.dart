// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'minha_rua_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$minhaRuaNotifierHash() => r'd07837b231b61a4f86ebb6322768d9028cf765b8';

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

abstract class _$MinhaRuaNotifier
    extends BuildlessAutoDisposeAsyncNotifier<MinhaRuaInfo> {
  late final int fase;

  FutureOr<MinhaRuaInfo> build(
    int fase,
  );
}

/// Provider para gerenciar informações da rua atual do operador
/// Usa o endpoint GET /api/wms/fase1/minha-rua
///
/// Copied from [MinhaRuaNotifier].
@ProviderFor(MinhaRuaNotifier)
const minhaRuaNotifierProvider = MinhaRuaNotifierFamily();

/// Provider para gerenciar informações da rua atual do operador
/// Usa o endpoint GET /api/wms/fase1/minha-rua
///
/// Copied from [MinhaRuaNotifier].
class MinhaRuaNotifierFamily extends Family<AsyncValue<MinhaRuaInfo>> {
  /// Provider para gerenciar informações da rua atual do operador
  /// Usa o endpoint GET /api/wms/fase1/minha-rua
  ///
  /// Copied from [MinhaRuaNotifier].
  const MinhaRuaNotifierFamily();

  /// Provider para gerenciar informações da rua atual do operador
  /// Usa o endpoint GET /api/wms/fase1/minha-rua
  ///
  /// Copied from [MinhaRuaNotifier].
  MinhaRuaNotifierProvider call(
    int fase,
  ) {
    return MinhaRuaNotifierProvider(
      fase,
    );
  }

  @override
  MinhaRuaNotifierProvider getProviderOverride(
    covariant MinhaRuaNotifierProvider provider,
  ) {
    return call(
      provider.fase,
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
  String? get name => r'minhaRuaNotifierProvider';
}

/// Provider para gerenciar informações da rua atual do operador
/// Usa o endpoint GET /api/wms/fase1/minha-rua
///
/// Copied from [MinhaRuaNotifier].
class MinhaRuaNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    MinhaRuaNotifier, MinhaRuaInfo> {
  /// Provider para gerenciar informações da rua atual do operador
  /// Usa o endpoint GET /api/wms/fase1/minha-rua
  ///
  /// Copied from [MinhaRuaNotifier].
  MinhaRuaNotifierProvider(
    int fase,
  ) : this._internal(
          () => MinhaRuaNotifier()..fase = fase,
          from: minhaRuaNotifierProvider,
          name: r'minhaRuaNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$minhaRuaNotifierHash,
          dependencies: MinhaRuaNotifierFamily._dependencies,
          allTransitiveDependencies:
              MinhaRuaNotifierFamily._allTransitiveDependencies,
          fase: fase,
        );

  MinhaRuaNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.fase,
  }) : super.internal();

  final int fase;

  @override
  FutureOr<MinhaRuaInfo> runNotifierBuild(
    covariant MinhaRuaNotifier notifier,
  ) {
    return notifier.build(
      fase,
    );
  }

  @override
  Override overrideWith(MinhaRuaNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MinhaRuaNotifierProvider._internal(
        () => create()..fase = fase,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        fase: fase,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<MinhaRuaNotifier, MinhaRuaInfo>
      createElement() {
    return _MinhaRuaNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MinhaRuaNotifierProvider && other.fase == fase;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, fase.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MinhaRuaNotifierRef on AutoDisposeAsyncNotifierProviderRef<MinhaRuaInfo> {
  /// The parameter `fase` of this provider.
  int get fase;
}

class _MinhaRuaNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<MinhaRuaNotifier,
        MinhaRuaInfo> with MinhaRuaNotifierRef {
  _MinhaRuaNotifierProviderElement(super.provider);

  @override
  int get fase => (origin as MinhaRuaNotifierProvider).fase;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
