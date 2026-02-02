// Modelo para informações de atualização do app
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_update_info.freezed.dart';
part 'app_update_info.g.dart';

@freezed
class AppUpdateInfo with _$AppUpdateInfo {
  const factory AppUpdateInfo({
    @Default(false) bool hasUpdate,
    @Default(false) bool forceUpdate,
    String? latestVersion,
    int? latestBuild,
    int? currentBuild,
    String? downloadUrl,
    int? fileSize,
    String? sha256Checksum,
    String? changelog,
    String? changelogHtml,
    String? releasedAt,
  }) = _AppUpdateInfo;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) =>
      _$AppUpdateInfoFromJson(json);
}

@freezed
class AppVersionInfo with _$AppVersionInfo {
  const factory AppVersionInfo({
    required String version,
    required int buildNumber,
    required String platform,
    String? downloadUrl,
    int? fileSize,
    String? fileSizeFormatted,
    String? sha256Checksum,
    @Default(false) bool forceUpdate,
    String? minVersion,
    String? changelog,
    String? changelogHtml,
    String? releasedAt,
  }) = _AppVersionInfo;

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) =>
      _$AppVersionInfoFromJson(json);
}

/// Status do download/instalação
enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  installing,
  installed,
  error,
  cancelled,
}

/// Progresso do update
class UpdateProgress {
  final UpdateStatus status;
  final double progress; // 0.0 a 1.0
  final String? message;
  final String? error;

  const UpdateProgress({
    this.status = UpdateStatus.idle,
    this.progress = 0.0,
    this.message,
    this.error,
  });

  UpdateProgress copyWith({
    UpdateStatus? status,
    double? progress,
    String? message,
    String? error,
  }) {
    return UpdateProgress(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }

  bool get isDownloading => status == UpdateStatus.downloading;
  bool get isInstalling => status == UpdateStatus.installing;
  bool get hasError => status == UpdateStatus.error;
  bool get isComplete => status == UpdateStatus.installed;
  
  int get progressPercent => (progress * 100).toInt();
}
