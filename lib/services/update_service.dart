import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// 版本信息模型
class AppVersion {
  final String version;
  final int buildNumber;
  final String apkUrl;
  final String releaseNotes;

  AppVersion({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.releaseNotes,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] as String? ?? '',
      buildNumber: (json['buildNumber'] as num?)?.toInt() ?? 0,
      apkUrl: json['apkUrl'] as String? ?? '',
      releaseNotes: json['releaseNotes'] as String? ?? '',
    );
  }
}

/// 联网自动更新服务。
///
/// 启动时从 mathmate.top/version.json 获取最新版本信息，
/// 与当前 app 版本比较，如有新版本则提示用户下载更新。
class UpdateService {
  static const String _versionUrl = 'https://mathmate.top/version.json';

  /// 当前 APP 版本号（与 pubspec.yaml 保持同步）
  static const int currentBuildNumber = 20260530;
  static const String currentVersion = '2.3.0';

  /// 检查更新。返回最新版本信息，若已是最新则返回 null。
  static Future<AppVersion?> checkUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final latest = AppVersion.fromJson(json);

      if (latest.buildNumber > currentBuildNumber) {
        return latest;
      }
      return null;
    } catch (_) {
      // 网络错误静默处理
      return null;
    }
  }

  /// 打开 APK 下载链接或引导用户更新。
  static Future<void> openUpdate(AppVersion version) async {
    final url = Uri.parse(version.apkUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
