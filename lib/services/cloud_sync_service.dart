import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_services.dart';
import 'auth_service.dart';

class CloudSyncService {
  static const String _cloudBackupKey = 'duckdo_cloud_backup_data';

  static Future<bool> backupToCloud({
    required DatabaseService dbService,
    required UserModel user,
  }) async {
    try {
      final tasks = await dbService.getTasks();
      final stats = await dbService.getUserStats();

      final backupPayload = {
        'uid': user.uid,
        'userEmail': user.email,
        'backupDate': DateTime.now().toIso8601String(),
        'stats': {
          'xp': stats.xp,
          'coins': stats.coins,
          'level': stats.level,
          'currentStreak': stats.currentStreak,
          'equippedHat': stats.equippedHat,
          'unlockedHats': stats.unlockedHats,
        },
        'tasks': tasks
            .map((t) => {
                  'id': t.id,
                  'title': t.title,
                  'description': t.description,
                  'dueDate': t.dueDate?.toIso8601String(),
                  'priority': t.priority,
                  'category': t.category,
                  'repeatRule': t.repeatRule,
                  'isCompleted': t.isCompleted,
                })
            .toList(),
      };

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_cloudBackupKey}_${user.uid}', json.encode(backupPayload));
      debugPrint('Đã sao lưu Đám mây thành công cho tài khoản: ${user.email}');
      return true;
    } catch (e) {
      debugPrint('Lỗi sao lưu Đám mây: $e');
      return false;
    }
  }

  static Future<bool> restoreFromCloud({
    required DatabaseService dbService,
    required UserModel user,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupStr = prefs.getString('${_cloudBackupKey}_${user.uid}');
      if (backupStr == null || backupStr.isEmpty) return false;

      final data = json.decode(backupStr) as Map<String, dynamic>;
      final statsMap = data['stats'] as Map<String, dynamic>?;

      if (statsMap != null) {
        final stats = await dbService.getUserStats();
        stats.xp = statsMap['xp'] as int? ?? stats.xp;
        stats.coins = statsMap['coins'] as int? ?? stats.coins;
        stats.level = statsMap['level'] as int? ?? stats.level;
        stats.currentStreak = statsMap['currentStreak'] as int? ?? stats.currentStreak;
        stats.equippedHat = statsMap['equippedHat'] as String? ?? stats.equippedHat;
        if (statsMap['unlockedHats'] != null) {
          stats.unlockedHats = List<String>.from(statsMap['unlockedHats'] as List);
        }
        await dbService.saveUserStats(stats);
      }
      return true;
    } catch (e) {
      debugPrint('Lỗi khôi phục Đám mây: $e');
      return false;
    }
  }
}
