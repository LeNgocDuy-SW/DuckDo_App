import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final int versionCode;
  final String downloadUrl;
  final String releaseNotes;

  UpdateInfo({
    required this.version,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String? ?? '1.0.0',
      versionCode: json['versionCode'] as int? ?? 1,
      downloadUrl: json['downloadUrl'] as String? ?? '',
      releaseNotes:
          json['releaseNotes'] as String? ??
          'Cập nhật thêm tính năng mới và tối ưu hóa ứng dụng.',
    );
  }
}

class UpdateService {
  // Đường dẫn Server / GitHub chứa thông tin phiên bản mới nhất của DuckDo
  static const String _manifestUrl =
      'https://raw.githubusercontent.com/LeNgocDuy-SW/DuckDo_App/main/version.json';

  Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (e) {
      return '1.0.0';
    }
  }

  Future<int> getCurrentVersionCode() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return int.tryParse(info.buildNumber) ?? 1;
    } catch (e) {
      return 1;
    }
  }

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final currentCode = await getCurrentVersionCode();

      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final url = '$_manifestUrl?t=$cacheBuster';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final updateInfo = UpdateInfo.fromJson(data);

        // Nếu versionCode trên Server lớn hơn versionCode trên máy điện thoại
        if (updateInfo.versionCode > currentCode &&
            updateInfo.downloadUrl.isNotEmpty) {
          return updateInfo;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Chưa thể kết nối máy chủ phiên bản: $e');
      return null;
    }
  }

  Future<bool> downloadAndInstallApk({
    required String downloadUrl,
    required Function(double progress) onProgress,
  }) async {
    try {
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await http.Client().send(request);

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/duckdo-update.apk';
      final file = File(filePath);
      final sink = file.openWrite();

      await for (var chunk in response.stream) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await sink.flush();
      await sink.close();

      // Tự động mở trình cài đặt package APK trên Android
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Lỗi downloadAndInstallApk: $e');
      return false;
    }
  }
}
