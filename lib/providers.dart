import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_services.dart';
import 'models/task.dart';

final databaseProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final tasksStreamProvider = StreamProvider<List<Task>>((ref) async* {
  final dbService = ref.watch(databaseProvider);
  yield* dbService.watchTasks();
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final selectedCategoryProvider = StateProvider<String>((ref) {
  return 'Tất cả';
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const _key = 'isDarkMode';

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_key);
      if (isDark != null && mounted) {
        state = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final isDark = state == ThemeMode.dark;
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, !isDark);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
