// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppUpdateInfoImpl _$$AppUpdateInfoImplFromJson(Map<String, dynamic> json) =>
    _$AppUpdateInfoImpl(
      hasUpdate: json['hasUpdate'] as bool? ?? false,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      latestVersion: json['latestVersion'] as String?,
      latestBuild: (json['latestBuild'] as num?)?.toInt(),
      currentBuild: (json['currentBuild'] as num?)?.toInt(),
      downloadUrl: json['downloadUrl'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      sha256Checksum: json['sha256Checksum'] as String?,
      changelog: json['changelog'] as String?,
      changelogHtml: json['changelogHtml'] as String?,
      releasedAt: json['releasedAt'] as String?,
    );

Map<String, dynamic> _$$AppUpdateInfoImplToJson(_$AppUpdateInfoImpl instance) =>
    <String, dynamic>{
      'hasUpdate': instance.hasUpdate,
      'forceUpdate': instance.forceUpdate,
      'latestVersion': instance.latestVersion,
      'latestBuild': instance.latestBuild,
      'currentBuild': instance.currentBuild,
      'downloadUrl': instance.downloadUrl,
      'fileSize': instance.fileSize,
      'sha256Checksum': instance.sha256Checksum,
      'changelog': instance.changelog,
      'changelogHtml': instance.changelogHtml,
      'releasedAt': instance.releasedAt,
    };

_$AppVersionInfoImpl _$$AppVersionInfoImplFromJson(Map<String, dynamic> json) =>
    _$AppVersionInfoImpl(
      version: json['version'] as String,
      buildNumber: (json['buildNumber'] as num).toInt(),
      platform: json['platform'] as String,
      downloadUrl: json['downloadUrl'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      fileSizeFormatted: json['fileSizeFormatted'] as String?,
      sha256Checksum: json['sha256Checksum'] as String?,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      minVersion: json['minVersion'] as String?,
      changelog: json['changelog'] as String?,
      changelogHtml: json['changelogHtml'] as String?,
      releasedAt: json['releasedAt'] as String?,
    );

Map<String, dynamic> _$$AppVersionInfoImplToJson(
        _$AppVersionInfoImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'buildNumber': instance.buildNumber,
      'platform': instance.platform,
      'downloadUrl': instance.downloadUrl,
      'fileSize': instance.fileSize,
      'fileSizeFormatted': instance.fileSizeFormatted,
      'sha256Checksum': instance.sha256Checksum,
      'forceUpdate': instance.forceUpdate,
      'minVersion': instance.minVersion,
      'changelog': instance.changelog,
      'changelogHtml': instance.changelogHtml,
      'releasedAt': instance.releasedAt,
    };
