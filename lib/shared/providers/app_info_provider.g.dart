// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$packageInfoHash() => r'70b4a9f2a022e5b2378e51d1d49d1f88448f9784';

/// Provider que fornece informações do app (versão, nome, etc.)
/// A versão é lida automaticamente do pubspec.yaml em tempo de build
///
/// Copied from [packageInfo].
@ProviderFor(packageInfo)
final packageInfoProvider = AutoDisposeFutureProvider<PackageInfo>.internal(
  packageInfo,
  name: r'packageInfoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$packageInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PackageInfoRef = AutoDisposeFutureProviderRef<PackageInfo>;
String _$appVersionHash() => r'd1ed0219c7f1a07fb2c08a00f80d4695fd0caa9f';

/// Provider que fornece apenas a versão do app formatada
///
/// Copied from [appVersion].
@ProviderFor(appVersion)
final appVersionProvider = AutoDisposeFutureProvider<String>.internal(
  appVersion,
  name: r'appVersionProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appVersionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppVersionRef = AutoDisposeFutureProviderRef<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
