import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/client_config.dart';
import '../models/app_update_info.dart';
import '../services/app_update_service.dart';

part 'app_update_provider.g.dart';

/// Provider de Dio para o serviço de update (sem auth)
@Riverpod(keepAlive: true)
Dio updateDio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ClientConfig.current.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ),
  );
  return dio;
}

/// Provider do serviço de atualização
@riverpod
AppUpdateService appUpdateService(Ref ref) {
  final dio = ref.watch(updateDioProvider);
  return AppUpdateService(dio);
}

/// Provider que verifica se há atualizações disponíveis
@riverpod
Future<AppUpdateInfo> checkAppUpdate(Ref ref) async {
  final service = ref.watch(appUpdateServiceProvider);
  return service.checkForUpdate();
}

/// Provider que busca a versão mais recente
@riverpod
Future<AppVersionInfo?> latestAppVersion(Ref ref) async {
  final service = ref.watch(appUpdateServiceProvider);
  return service.getLatestVersion();
}

/// Notifier para gerenciar o progresso do update
@riverpod
class AppUpdateNotifier extends _$AppUpdateNotifier {
  StreamSubscription? _downloadSubscription;

  @override
  UpdateProgress build() {
    ref.onDispose(() {
      _downloadSubscription?.cancel();
    });
    return const UpdateProgress();
  }

  /// Inicia o download e instalação
  Future<void> startUpdate(String downloadUrl, {String? sha256Checksum}) async {
    final service = ref.read(appUpdateServiceProvider);
    
    state = const UpdateProgress(
      status: UpdateStatus.downloading,
      progress: 0,
      message: 'Preparando download...',
    );

    _downloadSubscription?.cancel();
    _downloadSubscription = service
        .downloadAndInstall(downloadUrl, sha256Checksum: sha256Checksum)
        .listen(
      (progress) {
        state = progress;
      },
      onError: (error) {
        state = UpdateProgress(
          status: UpdateStatus.error,
          error: error.toString(),
        );
      },
    );
  }

  /// Cancela o download
  void cancelUpdate() {
    _downloadSubscription?.cancel();
    state = const UpdateProgress(
      status: UpdateStatus.cancelled,
      message: 'Download cancelado',
    );
  }

  /// Reseta o estado
  void reset() {
    _downloadSubscription?.cancel();
    state = const UpdateProgress();
  }
}

/// Provider para informações do app atual
@riverpod
Future<Map<String, dynamic>> currentAppInfo(Ref ref) async {
  final service = ref.watch(appUpdateServiceProvider);
  return service.getCurrentAppInfo();
}
