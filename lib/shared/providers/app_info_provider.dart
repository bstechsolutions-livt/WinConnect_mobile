import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_info_provider.g.dart';

/// Provider que fornece informações do app (versão, nome, etc.)
/// A versão é lida automaticamente do pubspec.yaml em tempo de build
@riverpod
Future<PackageInfo> packageInfo(PackageInfoRef ref) async {
  return await PackageInfo.fromPlatform();
}

/// Provider que fornece apenas a versão do app formatada
@riverpod
Future<String> appVersion(AppVersionRef ref) async {
  final packageInfo = await ref.watch(packageInfoProvider.future);
  return packageInfo.version;
}
