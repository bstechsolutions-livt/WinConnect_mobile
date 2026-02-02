import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

part 'app_info_provider.g.dart';

/// Instância do Shorebird Updater
final _shorebirdUpdater = ShorebirdUpdater();

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

/// Provider que fornece o número do patch do Shorebird
/// Retorna null se não houver patch instalado (versão base)
@riverpod
Future<int?> shorebirdPatchNumber(ShorebirdPatchNumberRef ref) async {
  try {
    final currentPatch = await _shorebirdUpdater.readCurrentPatch();
    return currentPatch?.number;
  } catch (e) {
    // Se não estiver rodando com Shorebird (ex: debug), retorna null
    return null;
  }
}

/// Provider que fornece a versão completa com patch: "2.1.0 + 0"
@riverpod
Future<String> appVersionWithPatch(AppVersionWithPatchRef ref) async {
  final version = await ref.watch(appVersionProvider.future);
  final patchNumber = await ref.watch(shorebirdPatchNumberProvider.future);
  
  // Se não tem patch ou é 0, mostra "+ 0", senão mostra o número do patch
  final patch = patchNumber ?? 0;
  return '$version + $patch';
}
