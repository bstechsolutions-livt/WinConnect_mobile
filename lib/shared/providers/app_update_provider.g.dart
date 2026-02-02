// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$updateDioHash() => r'66dcdcc4bef582c8709ec52c58a3044ce89c2200';

/// Provider de Dio para o serviço de update (sem auth)
///
/// Copied from [updateDio].
@ProviderFor(updateDio)
final updateDioProvider = Provider<Dio>.internal(
  updateDio,
  name: r'updateDioProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$updateDioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UpdateDioRef = ProviderRef<Dio>;
String _$appUpdateServiceHash() => r'b7be0ae562c1b96d61df345cc43cce65d1ce7e57';

/// Provider do serviço de atualização
///
/// Copied from [appUpdateService].
@ProviderFor(appUpdateService)
final appUpdateServiceProvider = AutoDisposeProvider<AppUpdateService>.internal(
  appUpdateService,
  name: r'appUpdateServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appUpdateServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppUpdateServiceRef = AutoDisposeProviderRef<AppUpdateService>;
String _$checkAppUpdateHash() => r'9d2c46a9389237fcca6dd871141fd6c00d15510a';

/// Provider que verifica se há atualizações disponíveis
///
/// Copied from [checkAppUpdate].
@ProviderFor(checkAppUpdate)
final checkAppUpdateProvider =
    AutoDisposeFutureProvider<AppUpdateInfo>.internal(
  checkAppUpdate,
  name: r'checkAppUpdateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$checkAppUpdateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CheckAppUpdateRef = AutoDisposeFutureProviderRef<AppUpdateInfo>;
String _$latestAppVersionHash() => r'0a6894c231ed8316fe276b76592a1195d2413745';

/// Provider que busca a versão mais recente
///
/// Copied from [latestAppVersion].
@ProviderFor(latestAppVersion)
final latestAppVersionProvider =
    AutoDisposeFutureProvider<AppVersionInfo?>.internal(
  latestAppVersion,
  name: r'latestAppVersionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$latestAppVersionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LatestAppVersionRef = AutoDisposeFutureProviderRef<AppVersionInfo?>;
String _$currentAppInfoHash() => r'4a30695b7bbae6ec9315be4ac93d4575a29998f3';

/// Provider para informações do app atual
///
/// Copied from [currentAppInfo].
@ProviderFor(currentAppInfo)
final currentAppInfoProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  currentAppInfo,
  name: r'currentAppInfoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentAppInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentAppInfoRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$appUpdateNotifierHash() => r'c8fdbc417410829c059cd37eba22222de2a81ab5';

/// Notifier para gerenciar o progresso do update
///
/// Copied from [AppUpdateNotifier].
@ProviderFor(AppUpdateNotifier)
final appUpdateNotifierProvider =
    AutoDisposeNotifierProvider<AppUpdateNotifier, UpdateProgress>.internal(
  AppUpdateNotifier.new,
  name: r'appUpdateNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appUpdateNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppUpdateNotifier = AutoDisposeNotifier<UpdateProgress>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
