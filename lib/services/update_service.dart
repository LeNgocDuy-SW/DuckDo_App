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

  bool _isServerVersionNewer(String current, String server) {
    try {
      final currentParts =
          current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final serverParts =
          server.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final s = i < serverParts.length ? serverParts[i] : 0;
        if (s > c) return true;
        if (s < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final currentVer = await getCurrentVersion();
      final currentCode = await getCurrentVersionCode();

      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final url = '$_manifestUrl?t=$cacheBuster';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final updateInfo = UpdateInfo.fromJson(data);

        final isServerVerNewer =
            _isServerVersionNewer(currentVer, updateInfo.version);
        final isServerCodeNewer = updateInfo.versionCode > currentCode;

        // Báo cập nhật nếu Server có version cao hơn HOẶC versionCode cao hơn
        if ((isServerVerNewer || isServerCodeNewer) &&
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
      final client = http.Client();
      var request = http.Request('GET', Uri.parse(downloadUrl));
      request.followRedirects = false; // Tự xử lý redirect từ GitHub sang AWS S3

      var response = await client.send(request);

      // Nếu GitHub chuyển hướng (301, 302, 307, 308) tới AWS S3 direct download
      if (response.statusCode == 301 ||
          response.statusCode == 302 ||
          response.statusCode == 307 ||
          response.statusCode == 308) {
        final redirectLocation = response.headers['location'];
        if (redirectLocation != null) {
          final redirectedRequest =
              http.Request('GET', Uri.parse(redirectLocation));
          response = await client.send(redirectedRequest);
        }
      }

      if (response.statusCode != 200) {
        debugPrint('Tải APK thất bại với mã lỗi HTTP: ${response.statusCode}');
        return false;
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/duckdo-update.apk';
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

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

      // Tự động mở trình cài đặt package APK trên Android với MIME type chính xác
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Lỗi downloadAndInstallApk: $e');
      return false;
    }
  }
}
