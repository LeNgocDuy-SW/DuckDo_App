import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task.dart';
import 'notification_services.dart';

class DatabaseService {
  late Future<Isar> db = initDb();

  Future<Isar> initDb() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Isar 3.x chưa hỗ trợ Web. Vui lòng chuyển target device sang Windows (flutter run -d windows), Android hoặc iOS.',
      );
    }

    final existingInstance = Isar.getInstance();
    if (existingInstance != null && existingInstance.isOpen) {
      try {
        await existingInstance.tasks.where().findAll();
        return existingInstance;
      } catch (e) {
        await existingInstance.close(deleteFromDisk: true);
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    try {
      final isar = await Isar.open(
        [TaskSchema],
        directory: dir.path,
        inspector: false,
      );
      // Kiểm tra đọc thử dữ liệu để phát hiện lệch offset nhị phân CSDL cũ
      await isar.tasks.where().findAll();
      return isar;
    } catch (e) {
      debugPrint('Lỗi mở/đọc Isar (RangeError/Schema Mismatch): $e. Đang tự động làm sạch CSDL cũ...');
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
        [TaskSchema],
        directory: dir.path,
        inspector: false,
      );
    }
  }

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

  Future<void> toggleTaskCompletion(int id) async {
    try {
      final isar = await db;
      final task = await isar.tasks.get(id);
      if (task != null) {
        task.isCompleted = !task.isCompleted;
        await isar.writeTxn(() async {
          await isar.tasks.put(task);
        });

        if (task.isCompleted) {
          await NotificationService().cancelNotification(id);

          // Nếu công việc có cài đặt lặp lại -> Tự động sinh công việc mới cho chu kỳ tiếp theo
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
        }
      }
    } catch (e) {
      debugPrint('Lỗi toggleTaskCompletion: $e');
    }
  }
}
