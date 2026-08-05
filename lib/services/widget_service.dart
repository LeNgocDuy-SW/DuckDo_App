import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/task.dart';
import '../models/user_stats.dart';

class WidgetService {
  static const String appGroupId = 'group.duckdo_app';
  static const String androidWidgetProvider = 'DuckWidgetProvider';

  static Future<void> updateHomeScreenWidget({
    required List<Task> tasks,
    required UserStats stats,
  }) async {
    try {
      final now = DateTime.now();
      final todayTasks = tasks.where((t) {
        if (t.isCompleted || t.dueDate == null) return false;
        return t.dueDate!.year == now.year &&
            t.dueDate!.month == now.month &&
            t.dueDate!.day == now.day;
      }).toList();

      final String task1 = todayTasks.isNotEmpty ? '• ${todayTasks[0].title}' : '🎉 Không có việc dồn!';
      final String task2 = todayTasks.length > 1 ? '• ${todayTasks[1].title}' : '';
      final String task3 = todayTasks.length > 2 ? '• ${todayTasks[2].title}' : '';

      await HomeWidget.saveWidgetData<String>('duck_level', 'Lv.${stats.level}');
      await HomeWidget.saveWidgetData<String>('duck_streak', '🔥 ${stats.currentStreak}d');
      await HomeWidget.saveWidgetData<String>('task_1', task1);
      await HomeWidget.saveWidgetData<String>('task_2', task2);
      await HomeWidget.saveWidgetData<String>('task_3', task3);
      await HomeWidget.saveWidgetData<int>('task_count', todayTasks.length);

      await HomeWidget.updateWidget(
        androidName: androidWidgetProvider,
        name: androidWidgetProvider,
      );
    } catch (e) {
      debugPrint('Lỗi cập nhật HomeWidget: $e');
    }
  }
}
