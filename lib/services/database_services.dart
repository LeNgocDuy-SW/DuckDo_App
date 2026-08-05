import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task.dart';
import '../models/user_stats.dart';
import 'notification_services.dart';

class TaskRewardResult {
  final bool isCompletedNow;
  final bool leveledUp;
  final int oldLevel;
  final int newLevel;
  final int earnedXp;
  final int earnedCoins;

  TaskRewardResult({
    required this.isCompletedNow,
    required this.leveledUp,
    required this.oldLevel,
    required this.newLevel,
    required this.earnedXp,
    required this.earnedCoins,
  });
}

class DatabaseService {
  late Future<Isar> db = initDb();

  Future<Isar> initDb() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Isar 3.x chưa hỗ trợ Web.',
      );
    }

    final existingInstance = Isar.getInstance();
    if (existingInstance != null && existingInstance.isOpen) {
      try {
        await existingInstance.tasks.where().findAll();
        await existingInstance.userStats.where().findAll();
        return existingInstance;
      } catch (e) {
        await existingInstance.close(deleteFromDisk: true);
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    try {
      final isar = await Isar.open(
        [TaskSchema, UserStatsSchema],
        directory: dir.path,
        inspector: false,
      );
      await isar.tasks.where().findAll();
      await isar.userStats.where().findAll();
      return isar;
    } catch (e) {
      debugPrint('Lỗi mở/đọc Isar: $e. Đang tự động làm sạch CSDL cũ...');
      final inst = Isar.getInstance();
      if (inst != null && inst.isOpen) {
        await inst.close(deleteFromDisk: true);
      } else {
        final isarFile = File('${dir.path}/default.isar');
        final isarLockFile = File('${dir.path}/default.isar.lock');
        if (await isarFile.exists()) {
          await isarFile.delete();
        }
        if (await isarLockFile.exists()) {
          await isarLockFile.delete();
        }
      }
      return await Isar.open(
        [TaskSchema, UserStatsSchema],
        directory: dir.path,
        inspector: false,
      );
    }
  }

  // --- USER STATS METHODS ---

  Future<UserStats> getUserStats() async {
    try {
      final isar = await db;
      var stats = await isar.userStats.get(1);
      if (stats == null) {
        stats = UserStats();
        await isar.writeTxn(() async {
          await isar.userStats.put(stats!);
        });
      }
      return stats;
    } catch (e) {
      return UserStats();
    }
  }

  Stream<UserStats> watchUserStats() async* {
    try {
      final isar = await db;
      yield* isar.userStats
          .watchObject(1, fireImmediately: true)
          .asyncMap((stats) async {
        if (stats == null) {
          return await getUserStats();
        }
        return stats;
      });
    } catch (e) {
      yield UserStats();
    }
  }

  Future<void> saveUserStats(UserStats stats) async {
    try {
      final isar = await db;
      await isar.writeTxn(() async {
        await isar.userStats.put(stats);
      });
    } catch (e) {
      debugPrint('Lỗi saveUserStats: $e');
    }
  }

  // --- TASK METHODS ---

  Future<void> saveTask(Task task) async {
    try {
      final isar = await db;
      await isar.writeTxn(() async {
        await isar.tasks.put(task);
      });
    } catch (e, stack) {
      debugPrint('Lỗi saveTask: $e\n$stack');
    }
  }

  Future<List<Task>> getTasks() async {
    try {
      final isar = await db;
      return await isar.tasks.where().findAll();
    } catch (e) {
      return [];
    }
  }

  Stream<List<Task>> watchTasks() async* {
    try {
      final isar = await db;
      yield* isar.tasks.where().watch(fireImmediately: true).handleError((e) {
        debugPrint('Lỗi watchTasks stream: $e');
      });
    } catch (e) {
      yield [];
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      final isar = await db;
      await isar.writeTxn(() async {
        await isar.tasks.delete(id);
      });
      await NotificationService().cancelNotification(id);
    } catch (e) {
      debugPrint('Lỗi deleteTask: $e');
    }
  }

  // Xử lý toggle hoàn thành + Thưởng XP, Xu & Chuỗi ngày Streak
  Future<TaskRewardResult?> toggleTaskCompletion(int id) async {
    try {
      final isar = await db;
      final task = await isar.tasks.get(id);
      if (task == null) return null;

      final bool newlyCompleted = !task.isCompleted;
      task.isCompleted = newlyCompleted;

      await isar.writeTxn(() async {
        await isar.tasks.put(task);
      });

      if (!newlyCompleted) {
        return TaskRewardResult(
          isCompletedNow: false,
          leveledUp: false,
          oldLevel: 1,
          newLevel: 1,
          earnedXp: 0,
          earnedCoins: 0,
        );
      }

      // Hủy thông báo của task vừa làm xong
      await NotificationService().cancelNotification(id);

      // Thưởng XP & Coins dựa theo độ ưu tiên
      int xpReward = 15;
      int coinReward = 5;
      if (task.priority == 2) {
        xpReward = 30; // Gấp
        coinReward = 10;
      } else if (task.priority == 0) {
        xpReward = 10; // Thấp
        coinReward = 3;
      }

      // Cập nhật UserStats
      var stats = await isar.userStats.get(1) ?? UserStats();
      final int oldLevel = stats.level;
      stats.xp += xpReward;
      stats.coins += coinReward;

      // Tính Level mới
      int calculatedLevel = (stats.xp / 100).floor() + 1;
      bool leveledUp = calculatedLevel > oldLevel;
      if (leveledUp) {
        stats.level = calculatedLevel;
      }

      // Xử lý Streak
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (stats.lastCompletedDate == null) {
        stats.currentStreak = 1;
        stats.lastCompletedDate = today;
      } else {
        final lastDate = DateTime(
          stats.lastCompletedDate!.year,
          stats.lastCompletedDate!.month,
          stats.lastCompletedDate!.day,
        );
        final difference = today.difference(lastDate).inDays;
        if (difference == 1) {
          stats.currentStreak += 1;
          stats.lastCompletedDate = today;
        } else if (difference > 1) {
          stats.currentStreak = 1;
          stats.lastCompletedDate = today;
        }
      }

      await isar.writeTxn(() async {
        await isar.userStats.put(stats);
      });

      // Nếu công việc có cài đặt lặp lại -> Tự động sinh task mới
      if (task.repeatRule != 'none') {
        final DateTime currentDue = task.dueDate ?? DateTime.now();
        DateTime nextDueDate;

        switch (task.repeatRule) {
          case 'daily':
            nextDueDate = currentDue.add(const Duration(days: 1));
            break;
          case 'weekly':
            nextDueDate = currentDue.add(const Duration(days: 7));
            break;
          case 'monthly':
            nextDueDate = DateTime(
              currentDue.year + (currentDue.month == 12 ? 1 : 0),
              currentDue.month == 12 ? 1 : currentDue.month + 1,
              currentDue.day,
              currentDue.hour,
              currentDue.minute,
            );
            break;
          default:
            nextDueDate = currentDue.add(const Duration(days: 1));
            break;
        }

        final nextTask = Task()
          ..title = task.title
          ..description = task.description
          ..dueDate = nextDueDate
          ..priority = task.priority
          ..category = task.category
          ..repeatRule = task.repeatRule
          ..isCompleted = false
          ..createdAt = DateTime.now();

        await saveTask(nextTask);

        if (nextDueDate.isAfter(DateTime.now()) &&
            nextTask.id != Isar.autoIncrement) {
          await NotificationService().scheduleNotification(
            id: nextTask.id,
            title: '⏰ Nhắc việc: ${nextTask.title}',
            body: nextTask.description?.isNotEmpty == true
                ? nextTask.description!
                : 'Đã đến thời gian thực hiện công việc này!',
            scheduledTime: nextDueDate,
          );
        }
      }

      return TaskRewardResult(
        isCompletedNow: true,
        leveledUp: leveledUp,
        oldLevel: oldLevel,
        newLevel: stats.level,
        earnedXp: xpReward,
        earnedCoins: coinReward,
      );
    } catch (e) {
      debugPrint('Lỗi toggleTaskCompletion: $e');
      return null;
    }
  }
}
