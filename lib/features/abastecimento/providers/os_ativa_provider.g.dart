// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'os_ativa_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$osAtivaHash() => r'87aa21bb757f8709e80f2d046a464c0d4d9620a3';

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

/// See also [osAtiva].
@ProviderFor(osAtiva)
const osAtivaProvider = OsAtivaFamily();

/// See also [osAtiva].
class OsAtivaFamily extends Family<AsyncValue<OsAtiva?>> {
  /// See also [osAtiva].
  const OsAtivaFamily();

  /// See also [osAtiva].
  OsAtivaProvider call(
    int matricula,
  ) {
    return OsAtivaProvider(
      matricula,
    );
  }

  @override
  OsAtivaProvider getProviderOverride(
    covariant OsAtivaProvider provider,
  ) {
    return call(
      provider.matricula,
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
  String? get name => r'osAtivaProvider';
}

/// See also [osAtiva].
class OsAtivaProvider extends AutoDisposeFutureProvider<OsAtiva?> {
  /// See also [osAtiva].
  OsAtivaProvider(
    int matricula,
  ) : this._internal(
          (ref) => osAtiva(
            ref as OsAtivaRef,
            matricula,
          ),
          from: osAtivaProvider,
          name: r'osAtivaProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$osAtivaHash,
          dependencies: OsAtivaFamily._dependencies,
          allTransitiveDependencies: OsAtivaFamily._allTransitiveDependencies,
          matricula: matricula,
        );

  OsAtivaProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.matricula,
  }) : super.internal();

  final int matricula;

  @override
  Override overrideWith(
    FutureOr<OsAtiva?> Function(OsAtivaRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OsAtivaProvider._internal(
        (ref) => create(ref as OsAtivaRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        matricula: matricula,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<OsAtiva?> createElement() {
    return _OsAtivaProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OsAtivaProvider && other.matricula == matricula;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, matricula.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin OsAtivaRef on AutoDisposeFutureProviderRef<OsAtiva?> {
  /// The parameter `matricula` of this provider.
  int get matricula;
}

class _OsAtivaProviderElement extends AutoDisposeFutureProviderElement<OsAtiva?>
    with OsAtivaRef {
  _OsAtivaProviderElement(super.provider);

  @override
  int get matricula => (origin as OsAtivaProvider).matricula;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
