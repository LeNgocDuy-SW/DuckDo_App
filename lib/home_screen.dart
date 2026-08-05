import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'add_task_bottom_sheet.dart';
import 'services/update_service.dart';
import 'services/notification_services.dart';
import 'services/sound_service.dart';
import 'widgets/duck_logo.dart';
import 'widgets/duck_wardrobe_sheet.dart';
import 'screens/pomodoro_screen.dart';
import 'screens/auth_screen.dart';
import 'widgets/voice_task_dialog.dart';
import 'services/widget_service.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isCalendarExpanded = false;

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

  void _openWardrobeSheet() {
    SoundService().playClickHaptics();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DuckWardrobeSheet(),
    );
  }

  void _showLevelUpDialog(int newLevel) {
    SoundService().playLevelUpHaptics();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          title: Column(
            children: [
              const DuckLogo(size: 100, animate: true, showQuackBadge: false),
              const SizedBox(height: 12),
              const Text(
                '🎉 CHÚC MỪNG THĂNG CẤP! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF8F00),
                ),
              ),
            ],
          ),
          content: Text(
            'Chú Vịt DuckDo của bạn vừa thăng lên LEVEL $newLevel! 🐥✨\n\nHãy tiếp tục hoàn thành các công việc để nhận thêm nhiều xu và mở khóa phụ kiện xịn xò nhé!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            Center(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openWardrobeSheet();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8F00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text(
                  'Xem Tủ Đồ Ngay 🛍️',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateDialog(BuildContext context, {UpdateInfo? updateInfo}) async {
    final currentVer = await UpdateService().getCurrentVersion();
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        double progress = 0.0;
        bool isDownloading = false;
        bool isChecking = updateInfo == null;
        UpdateInfo? latestInfo = updateInfo;

        return StatefulBuilder(
          builder: (context, setState) {
            if (isChecking) {
              UpdateService().checkForUpdate().then((info) {
                if (dialogContext.mounted) {
                  setState(() {
                    latestInfo = info;
                    isChecking = false;
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Text('🦆 DuckDo ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('v$currentVer', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isChecking) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          CircularProgressIndicator(strokeWidth: 2.5),
                          SizedBox(width: 16),
                          Expanded(child: Text('Đang kết nối kiểm tra phiên bản mới...')),
                        ],
                      ),
                    ),
                  ] else if (latestInfo != null) ...[
                    Text(
                      '🎉 Đã có phiên bản mới: v${latestInfo!.version}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✨ Có gì mới trong bản cập nhật này:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            latestInfo!.releaseNotes,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text('🦆 Bạn đang sử dụng phiên bản mới nhất!'),
                    const SizedBox(height: 10),
                    const Text(
                      'Hệ thống tự động kiểm tra bản cập nhật mỗi khi có nâng cấp mới trên GitHub.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  if (isDownloading) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: progress, minHeight: 8),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Đang tải bản nâng cấp: ${(progress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!isDownloading)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Đóng'),
                  ),
                if (!isChecking && latestInfo != null && !isDownloading)
                  FilledButton.icon(
                    onPressed: () async {
                      setState(() {
                        isDownloading = true;
                      });
                      final success = await UpdateService().downloadAndInstallApk(
                        downloadUrl: latestInfo!.downloadUrl,
                        onProgress: (p) {
                          if (dialogContext.mounted) {
                            setState(() {
                              progress = p;
                            });
                          }
                        },
                      );
                      if (dialogContext.mounted) {
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Tải bản nâng cấp không thành công. Hãy thử lại.'),
                            ),
                          );
                        }
                        Navigator.pop(dialogContext);
                      }
                    },
                    icon: const Icon(Icons.download_rounded),
                    label: Text('Tải & Nâng cấp v${latestInfo!.version}'),
                  )
                else if (!isChecking && latestInfo == null)
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(dialogContext),
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

  String _formatDateTitle(DateTime date) {
    final now = DateTime.now();
    final isToday = isSameDay(date, now);
    final isTomorrow = isSameDay(date, now.add(const Duration(days: 1)));
    final isYesterday = isSameDay(date, now.subtract(const Duration(days: 1)));

    String prefix = '';
    if (isToday) prefix = 'Hôm nay, ';
    if (isTomorrow) prefix = 'Ngày mai, ';
    if (isYesterday) prefix = 'Hôm qua, ';

    final daysOfWeek = [
      'Chủ Nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy'
    ];
    final dayName = daysOfWeek[date.weekday % 7];

    return '$prefix$dayName (${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year})';
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final tasksAsyncValue = ref.watch(tasksStreamProvider);
    final userStatsAsync = ref.watch(userStatsStreamProvider);

    ref.listen(tasksStreamProvider, (previous, next) {
      next.whenData((tasks) async {
        final stats = await ref.read(databaseProvider).getUserStats();
        await WidgetService.updateHomeScreenWidget(tasks: tasks, stats: stats);
      });
    });
    final themeMode = ref.watch(themeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final colorScheme = Theme.of(context).colorScheme;

    final String equippedHat = userStatsAsync.maybeWhen(
      data: (s) => s.equippedHat,
      orElse: () => 'none',
    );

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: DuckLogo(
                size: 26,
                animate: true,
                showQuackBadge: false,
                equippedHat: equippedHat,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'DuckDo',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF8F00),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // LEVEL & STREAK BADGE BUTTON
          userStatsAsync.when(
            data: (stats) => GestureDetector(
              onTap: _openWardrobeSheet,
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF3C4), Color(0xFFFFE082)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8F00).withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lv.${stats.level}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('🔥', style: TextStyle(fontSize: 11)),
                    Text(
                      '${stats.currentStreak}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
          // POMODORO TIMER BUTTON
          IconButton(
            tooltip: 'Đồng hồ Tập trung Pomodoro',
            icon: const Icon(Icons.timer_outlined, color: Color(0xFFFF8F00)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PomodoroScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Kiểm tra bản cập nhật mới',
            icon: const Icon(Icons.system_update_rounded),
            onPressed: () => _showUpdateDialog(context),
          ),
          IconButton(
            tooltip: 'Tài khoản & Đám mây',
            icon: const Icon(Icons.person_outline_rounded, color: Color(0xFFFF8F00)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
          IconButton(
            tooltip: isDark
                ? 'Chuyển sang chế độ Sáng'
                : 'Chuyển sang chế độ Tối',
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFFF8F00),
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. THANH CHỌN NGÀY THÁNG THU GỌN (Compact Expandable Date Selector)
          GestureDetector(
            onTap: () {
              setState(() {
                _isCalendarExpanded = !_isCalendarExpanded;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                      : const [Color(0xFFFFF8E7), Color(0xFFFFF3C4)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFFFD54F),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8F00).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFFFF8F00),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDateTitle(selectedDate),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isCalendarExpanded
                              ? 'Chạm để thu gọn lịch 🔼'
                              : 'Chạm để mở lịch chọn ngày 🔽',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isCalendarExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFFFF8F00),
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // LỊCH TO MỞ RỘNG (TableCalendar Expandable)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFFFE082),
                ),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: selectedDate,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) {
                  return isSameDay(selectedDate, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  ref.read(selectedDateProvider.notifier).state = selectedDay;
                  setState(() {
                    _isCalendarExpanded = false;
                  });
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFFFF8F00),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  weekendTextStyle: TextStyle(color: Colors.red.shade300),
                ),
              ),
            ),
            crossFadeState: _isCalendarExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          const SizedBox(height: 4),

          // 2. Thanh lọc danh mục công việc
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                      selectedColor: const Color(0xFFFFB300),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
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

          // 3. Danh sách công việc
          Expanded(
            child: tasksAsyncValue.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF8F00)),
              ),
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

                // DUCK MASCOT EMPTY STATE WEARING EQUIPPED HAT
                if (dailyTasks.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          DuckLogo(
                            size: 110,
                            animate: true,
                            showQuackBadge: true,
                            equippedHat: equippedHat,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedCategory == 'Tất cả'
                                ? 'Không có công việc nào trong ngày này!'
                                : 'Không có công việc nào trong danh mục "$selectedCategory"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Thư giãn như chú vịt quack quack 🐣 hoặc chạm nút bên dưới để thêm mới!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final completedCount =
                    dailyTasks.where((t) => t.isCompleted).length;
                final totalCount = dailyTasks.length;
                final progress = completedCount / totalCount;

                return Column(
                  children: [
                    // Thanh tiến độ hoàn thành công việc theo Duck Theme
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                              : const [Color(0xFFFFFBEB), Color(0xFFFFF3C4)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFFFE082),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Text(
                                    '🐥 Tiến độ Duck Do',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$completedCount/$totalCount (${(progress * 100).toInt()}%)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF8F00),
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
                              backgroundColor: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFFFECB3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress == 1.0
                                    ? Colors.green
                                    : const Color(0xFFFF8F00),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: dailyTasks.length,
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 80,
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
                                  side: BorderSide(
                                    color: task.isCompleted
                                        ? Colors.transparent
                                        : (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFFFE082)),
                                  ),
                                ),
                                color: task.isCompleted
                                    ? (isDark
                                        ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                                        : Colors.grey.shade100)
                                    : (isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white),
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
                                                ? colorScheme.onSurface
                                                    .withValues(alpha: 0.4)
                                                : colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _buildPriorityBadge(task.priority),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              color: const Color(0xFFFFB300)
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              task.category,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFFD97706),
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
                                    activeColor: const Color(0xFFFF8F00),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (value) async {
                                      final reward = await ref
                                          .read(databaseProvider)
                                          .toggleTaskCompletion(task.id);

                                      if (reward != null &&
                                          reward.isCompletedNow) {
                                        await SoundService()
                                            .playTaskCompleteHaptics();

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Text(
                                                      '🎉 Quack xong! '),
                                                  Text(
                                                    '+${reward.earnedXp} XP  +${reward.earnedCoins} 🪙',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFFFFD54F),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor:
                                                  const Color(0xFF1E293B),
                                              duration: const Duration(
                                                  seconds: 2),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        }

                                        if (reward.leveledUp &&
                                            context.mounted) {
                                          _showLevelUpDialog(reward.newLevel);
                                        }
                                      }
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
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // VOICE TO TASK AI BUTTON
          FloatingActionButton(
            heroTag: 'voice_ai_fab',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const VoiceTaskDialog(),
              );
            },
            backgroundColor: const Color(0xFFFFD54F),
            foregroundColor: const Color(0xFF5D4037),
            elevation: 4,
            child: const Icon(Icons.mic_rounded, size: 28),
          ),
          const SizedBox(width: 12),
          // ADD TASK BUTTON
          FloatingActionButton.extended(
            heroTag: 'add_task_fab',
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
            backgroundColor: const Color(0xFFFF8F00),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Thêm công việc',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
