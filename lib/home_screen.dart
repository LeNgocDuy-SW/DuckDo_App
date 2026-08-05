import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'add_task_bottom_sheet.dart';
import 'services/update_service.dart';
import 'package:table_calendar/table_calendar.dart';

import 'services/notification_services.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoCheckUpdate();
    });
  }

  void _autoCheckUpdate() async {
    final updateInfo = await UpdateService().checkForUpdate();
    if (updateInfo != null && mounted) {
      await NotificationService().showInstantNotification(
        id: 99999,
        title: '🎉 Cập nhật mới: DuckDo v${updateInfo.version}',
        body: 'Đã có bản nâng cấp mới! Chạm để nâng cấp ngay.',
      );
      if (!mounted) return;
      _showUpdateDialog(context, updateInfo: updateInfo);
    }
  }

  void _showUpdateDialog(BuildContext context, {UpdateInfo? updateInfo}) async {
    final currentVer = await UpdateService().getCurrentVersion();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        double progress = 0.0;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: const [
                  Text('🦆 DuckDo ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('v1.0.0', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phiên bản hiện tại: v$currentVer'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✨ Hệ thống Cập nhật Tự động (In-App Auto Update)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• Khi phát hiện có bản nâng cấp mới, ứng dụng sẽ tự động tải & nâng cấp trực tiếp ngầm trong App mà không cần chép file tay.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (progress > 0) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 6),
                    Text('Đang tải bản nâng cấp: ${(progress * 100).toInt()}%'),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🦆 Bạn đang dùng phiên bản mới nhất!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Đã mới nhất'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getRepeatLabel(String rule) {
    switch (rule) {
      case 'daily':
        return '🔄 Hàng ngày';
      case 'weekly':
        return '📅 Hàng tuần';
      case 'monthly':
        return '🗓️ Hàng tháng';
      default:
        return '';
    }
  }

  Widget _buildPriorityBadge(int priority) {
    String label;
    Color color;
    switch (priority) {
      case 2:
        label = '🔴 Gấp';
        color = Colors.red;
        break;
      case 0:
        label = '🟢 Thấp';
        color = Colors.green;
        break;
      case 1:
      default:
        label = '🔵 Thường';
        color = Colors.blue;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final tasksAsyncValue = ref.watch(tasksStreamProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final colorScheme = Theme.of(context).colorScheme;

    final categories = [
      'Tất cả',
      '💼 Công việc',
      '👤 Cá nhân',
      '📚 Học tập',
      '❤️ Sức khỏe',
      '📌 Chung',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DuckDo 🦆',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Kiểm tra bản cập nhật mới',
            icon: const Icon(Icons.system_update_rounded),
            onPressed: () => _showUpdateDialog(context),
          ),
          IconButton(
            tooltip: isDark
                ? 'Chuyển sang chế độ Sáng'
                : 'Chuyển sang chế độ Tối',
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: isDark ? Colors.amber : colorScheme.primary,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: selectedDate,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) {
              return isSameDay(selectedDate, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              ref.read(selectedDateProvider.notifier).state = selectedDay;
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: TextStyle(color: Colors.red.shade300),
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Thanh chọn lọc danh mục
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      visualDensity: VisualDensity.compact,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(selectedCategoryProvider.notifier).state = cat;
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),

          Expanded(
            child: tasksAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_sync_outlined, size: 48, color: Colors.orange),
                      const SizedBox(height: 8),
                      const Text('Đang tự động dọn dẹp CSDL...'),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(tasksStreamProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              },
              data: (allTasks) {
                var dailyTasks = allTasks.where((task) {
                  if (task.dueDate == null) return false;
                  return isSameDay(task.dueDate, selectedDate);
                }).toList();

                if (selectedCategory != 'Tất cả') {
                  dailyTasks = dailyTasks
                      .where((t) => t.category == selectedCategory)
                      .toList();
                }

                if (dailyTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          selectedCategory == 'Tất cả'
                              ? 'Không có công việc nào trong ngày này'
                              : 'Không có công việc thuộc danh mục "$selectedCategory"',
                          style: TextStyle(
                            fontSize: 15,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final completedCount = dailyTasks
                    .where((t) => t.isCompleted)
                    .length;
                final totalCount = dailyTasks.length;
                final progress = completedCount / totalCount;

                return Column(
                  children: [
                    // Thanh tiến độ hoàn thành công việc trong ngày
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tiến độ hoàn thành',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '$completedCount/$totalCount (${(progress * 100).toInt()}%)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: colorScheme.outlineVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress == 1.0
                                    ? Colors.green
                                    : colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: dailyTasks.length,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemBuilder: (context, index) {
                          final task = dailyTasks[index];
                          final String timeStr = task.dueDate != null
                              ? '${task.dueDate!.hour.toString().padLeft(2, '0')}:${task.dueDate!.minute.toString().padLeft(2, '0')}'
                              : '';
                          final String desc = task.description ?? '';
                          final String subtitleText = [
                            if (timeStr.isNotEmpty) '⏰ Hạn chót: $timeStr',
                            if (desc.isNotEmpty) desc,
                          ].join('\n');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Dismissible(
                              key: ValueKey(task.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              onDismissed: (direction) {
                                ref.read(databaseProvider).deleteTask(task.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã xóa "${task.title}"'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: task.isCompleted ? 0 : 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: task.isCompleted
                                    ? colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.3)
                                    : colorScheme.surface,
                                child: ListTile(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24)),
                                      ),
                                      builder: (context) =>
                                          AddTaskBottomSheet(taskToEdit: task),
                                    );
                                  },
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: TextStyle(
                                            fontWeight: task.isCompleted
                                                ? FontWeight.normal
                                                : FontWeight.w600,
                                            decoration: task.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: task.isCompleted
                                                ? colorScheme.onSurface.withValues(
                                                    alpha: 0.5,
                                                  )
                                                : colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _buildPriorityBadge(task.priority),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (subtitleText.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            subtitleText,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .secondaryContainer
                                                  .withValues(alpha: 0.5),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              task.category,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: colorScheme
                                                    .onSecondaryContainer,
                                              ),
                                            ),
                                          ),
                                          if (_getRepeatLabel(task.repeatRule)
                                              .isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .tertiaryContainer
                                                    .withValues(alpha: 0.5),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                _getRepeatLabel(
                                                    task.repeatRule),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme
                                                      .onTertiaryContainer,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  leading: Checkbox(
                                    value: task.isCompleted,
                                    activeColor: colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (value) {
                                      ref
                                          .read(databaseProvider)
                                          .toggleTaskCompletion(task.id);
                                    },
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red.shade400,
                                    ),
                                    onPressed: () {
                                      ref
                                          .read(databaseProvider)
                                          .deleteTask(task.id);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => const AddTaskBottomSheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm công việc'),
      ),
    );
  }
}
