// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'os_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$osNotifierHash() => r'ea6cdf47642aa3a3c400964d1aa7229ec7629f26';

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

abstract class _$OsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<OrdemServico>> {
  late final int fase;
  late final String rua;

  FutureOr<List<OrdemServico>> build(
    int fase,
    String rua,
  );
}

/// See also [OsNotifier].
@ProviderFor(OsNotifier)
const osNotifierProvider = OsNotifierFamily();

/// See also [OsNotifier].
class OsNotifierFamily extends Family<AsyncValue<List<OrdemServico>>> {
  /// See also [OsNotifier].
  const OsNotifierFamily();

  /// See also [OsNotifier].
  OsNotifierProvider call(
    int fase,
    String rua,
  ) {
    return OsNotifierProvider(
      fase,
      rua,
    );
  }

  @override
  OsNotifierProvider getProviderOverride(
    covariant OsNotifierProvider provider,
  ) {
    return call(
      provider.fase,
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
  String? get name => r'osNotifierProvider';
}

/// See also [OsNotifier].
class OsNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    OsNotifier, List<OrdemServico>> {
  /// See also [OsNotifier].
  OsNotifierProvider(
    int fase,
    String rua,
  ) : this._internal(
          () => OsNotifier()
            ..fase = fase
            ..rua = rua,
          from: osNotifierProvider,
          name: r'osNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$osNotifierHash,
          dependencies: OsNotifierFamily._dependencies,
          allTransitiveDependencies:
              OsNotifierFamily._allTransitiveDependencies,
          fase: fase,
          rua: rua,
        );

  OsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.fase,
    required this.rua,
  }) : super.internal();

  final int fase;
  final String rua;

  @override
  FutureOr<List<OrdemServico>> runNotifierBuild(
    covariant OsNotifier notifier,
  ) {
    return notifier.build(
      fase,
      rua,
    );
  }

  @override
  Override overrideWith(OsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: OsNotifierProvider._internal(
        () => create()
          ..fase = fase
          ..rua = rua,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        fase: fase,
        rua: rua,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<OsNotifier, List<OrdemServico>>
      createElement() {
    return _OsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OsNotifierProvider &&
        other.fase == fase &&
        other.rua == rua;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, fase.hashCode);
    hash = _SystemHash.combine(hash, rua.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin OsNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<OrdemServico>> {
  /// The parameter `fase` of this provider.
  int get fase;

  /// The parameter `rua` of this provider.
  String get rua;
}

class _OsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<OsNotifier,
        List<OrdemServico>> with OsNotifierRef {
  _OsNotifierProviderElement(super.provider);

  @override
  int get fase => (origin as OsNotifierProvider).fase;
  @override
  String get rua => (origin as OsNotifierProvider).rua;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
