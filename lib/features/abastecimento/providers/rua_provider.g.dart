// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rua_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ruaNotifierHash() => r'c8220db52dca84ff2b9b7f3454338373d5bd4458';

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

abstract class _$RuaNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Rua>> {
  late final int fase;

  FutureOr<List<Rua>> build(
    int fase,
  );
}

/// See also [RuaNotifier].
@ProviderFor(RuaNotifier)
const ruaNotifierProvider = RuaNotifierFamily();

/// See also [RuaNotifier].
class RuaNotifierFamily extends Family<AsyncValue<List<Rua>>> {
  /// See also [RuaNotifier].
  const RuaNotifierFamily();

  /// See also [RuaNotifier].
  RuaNotifierProvider call(
    int fase,
  ) {
    return RuaNotifierProvider(
      fase,
    );
  }

  @override
  RuaNotifierProvider getProviderOverride(
    covariant RuaNotifierProvider provider,
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
  String? get name => r'ruaNotifierProvider';
}

/// See also [RuaNotifier].
class RuaNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<RuaNotifier, List<Rua>> {
  /// See also [RuaNotifier].
  RuaNotifierProvider(
    int fase,
  ) : this._internal(
          () => RuaNotifier()..fase = fase,
          from: ruaNotifierProvider,
          name: r'ruaNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$ruaNotifierHash,
          dependencies: RuaNotifierFamily._dependencies,
          allTransitiveDependencies:
              RuaNotifierFamily._allTransitiveDependencies,
          fase: fase,
        );

  RuaNotifierProvider._internal(
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
  FutureOr<List<Rua>> runNotifierBuild(
    covariant RuaNotifier notifier,
  ) {
    return notifier.build(
      fase,
    );
  }

  @override
  Override overrideWith(RuaNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: RuaNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<RuaNotifier, List<Rua>>
      createElement() {
    return _RuaNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RuaNotifierProvider && other.fase == fase;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, fase.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RuaNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Rua>> {
  /// The parameter `fase` of this provider.
  int get fase;
}

class _RuaNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<RuaNotifier, List<Rua>>
    with RuaNotifierRef {
  _RuaNotifierProviderElement(super.provider);

  @override
  int get fase => (origin as RuaNotifierProvider).fase;
}

String _$ruaAtualHash() => r'c924762bc206dd662a7134944b94b35eae7e104a';

/// See also [RuaAtual].
@ProviderFor(RuaAtual)
final ruaAtualProvider =
    AutoDisposeNotifierProvider<RuaAtual, String?>.internal(
  RuaAtual.new,
  name: r'ruaAtualProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$ruaAtualHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RuaAtual = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
