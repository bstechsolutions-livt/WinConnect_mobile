import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/client_config.dart';
import '../models/app_update_info.dart';

/// Service responsável por gerenciar atualizações do app
/// 
/// Suporta dois modos:
/// 1. OTA Update: Download e instalação de novo APK (atualiza tudo)
/// 2. Code Push (Shorebird): Patches de código Dart apenas
class AppUpdateService {
  final Dio _dio;
  
  AppUpdateService(this._dio);

  /// Verifica se há atualização disponível
  Future<AppUpdateInfo> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      
      final response = await _dio.get(
        '/app/check-update',
        queryParameters: {
          'version': packageInfo.version,
          'build': currentBuild,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'client': ClientConfig.current.id,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        return AppUpdateInfo(
          hasUpdate: data['has_update'] ?? false,
          forceUpdate: data['force_update'] ?? false,
          latestVersion: data['latest_version'],
          latestBuild: data['latest_build'],
          currentBuild: data['current_build'],
          downloadUrl: data['download_url'],
          fileSize: data['file_size'],
          sha256Checksum: data['sha256_checksum'],
          changelog: data['changelog'],
          changelogHtml: data['changelog_html'],
          releasedAt: data['released_at'],
        );
      }

      return const AppUpdateInfo();
    } catch (e) {
      debugPrint('Erro ao verificar atualização: $e');
      return const AppUpdateInfo();
    }
  }

  /// Busca informações da versão mais recente
  Future<AppVersionInfo?> getLatestVersion() async {
    try {
      final response = await _dio.get(
        '/app/latest',
        queryParameters: {
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'client': ClientConfig.current.id,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return AppVersionInfo.fromJson(response.data['data']);
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao buscar versão mais recente: $e');
      return null;
    }
  }

  /// Inicia o download e instalação do APK (Android apenas)
  /// 
  /// Retorna um Stream de eventos de progresso
  Stream<UpdateProgress> downloadAndInstall(String downloadUrl, {String? sha256Checksum}) async* {
    if (!Platform.isAndroid) {
      yield const UpdateProgress(
        status: UpdateStatus.error,
        error: 'Atualização OTA disponível apenas para Android',
      );
      return;
    }

    yield const UpdateProgress(
      status: UpdateStatus.downloading,
      progress: 0,
      message: 'Iniciando download...',
    );

    try {
      // Usa o pacote ota_update para baixar e instalar
      await for (final event in OtaUpdate().execute(
        downloadUrl,
        destinationFilename: 'winconnect_update.apk',
        sha256checksum: sha256Checksum,
      )) {
        switch (event.status) {
          case OtaStatus.DOWNLOADING:
            final progress = double.tryParse(event.value ?? '0') ?? 0;
            yield UpdateProgress(
              status: UpdateStatus.downloading,
              progress: progress / 100,
              message: 'Baixando... ${progress.toInt()}%',
            );
            break;
            
          case OtaStatus.INSTALLING:
            yield const UpdateProgress(
              status: UpdateStatus.installing,
              progress: 1.0,
              message: 'Instalando atualização...',
            );
            break;
            
          case OtaStatus.ALREADY_RUNNING_ERROR:
            yield const UpdateProgress(
              status: UpdateStatus.error,
              error: 'Uma atualização já está em andamento',
            );
            break;
            
          case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
            yield const UpdateProgress(
              status: UpdateStatus.error,
              error: 'Permissão para instalar apps não concedida',
            );
            break;
            
          case OtaStatus.DOWNLOAD_ERROR:
            yield UpdateProgress(
              status: UpdateStatus.error,
              error: 'Erro no download: ${event.value}',
            );
            break;
            
          case OtaStatus.CHECKSUM_ERROR:
            yield const UpdateProgress(
              status: UpdateStatus.error,
              error: 'Arquivo corrompido. Tente novamente.',
            );
            break;
            
          case OtaStatus.INTERNAL_ERROR:
            yield UpdateProgress(
              status: UpdateStatus.error,
              error: 'Erro interno: ${event.value}',
            );
            break;
            
          default:
            break;
        }
      }
    } catch (e) {
      yield UpdateProgress(
        status: UpdateStatus.error,
        error: 'Erro ao atualizar: $e',
      );
    }
  }

  /// Retorna informações do app atual
  Future<Map<String, dynamic>> getCurrentAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'client': ClientConfig.current.id,
    };
  }

  /// Formata tamanho de arquivo
  String formatFileSize(int? bytes) {
    if (bytes == null) return 'N/A';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    
    while (size > 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}
