import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'providers.dart';
import 'models/task.dart';
import 'services/notification_services.dart';
import 'widgets/duck_logo.dart';

class AddTaskBottomSheet extends ConsumerStatefulWidget {
  final Task? taskToEdit;

  const AddTaskBottomSheet({super.key, this.taskToEdit});

  @override
  ConsumerState<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends ConsumerState<AddTaskBottomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime? _selectedDate;
  int _selectedPriority = 1; // 0: Thấp, 1: Bình thường, 2: Gấp
  String _selectedCategory = '📌 Chung';
  String _selectedRepeatRule = 'none';

  final List<Map<String, dynamic>> _priorities = [
    {'label': '🟢 Thấp', 'value': 0, 'color': const Color(0xFF10B981)},
    {'label': '🔵 Thường', 'value': 1, 'color': const Color(0xFF3B82F6)},
    {'label': '🔴 Gấp!', 'value': 2, 'color': const Color(0xFFEF4444)},
  ];

  final List<String> _categories = [
    '💼 Công việc',
    '👤 Cá nhân',
    '📚 Học tập',
    '❤️ Sức khỏe',
    '📌 Chung',
  ];

  final List<Map<String, String>> _repeatRules = [
    {'label': '🚫 Không lặp', 'value': 'none'},
    {'label': '🔄 Hàng ngày', 'value': 'daily'},
    {'label': '📅 Hàng tuần', 'value': 'weekly'},
    {'label': '🗓️ Hàng tháng', 'value': 'monthly'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      final task = widget.taskToEdit!;
      _titleController.text = task.title;
      _descController.text = task.description ?? '';
      _selectedDate = task.dueDate;
      _selectedPriority = task.priority;
      _selectedCategory = task.category;
      _selectedRepeatRule = task.repeatRule;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _presentDateTimePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.isBefore(_selectedDate ?? now) ? now : (_selectedDate ?? now),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFFFF8F00),
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDate != null
          ? TimeOfDay.fromDateTime(_selectedDate!)
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFFFF8F00),
                ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute - $day/$month/$year';
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Text('🐥 Vui lòng nhập tên công việc!'),
            ],
          ),
          backgroundColor: const Color(0xFFFF8F00),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      final newTask = Task()
        ..title = _titleController.text.trim()
        ..description = _descController.text.trim()
        ..dueDate = _selectedDate
        ..priority = _selectedPriority
        ..category = _selectedCategory
        ..repeatRule = _selectedRepeatRule
        ..createdAt = widget.taskToEdit?.createdAt ?? DateTime.now();

      if (widget.taskToEdit != null) {
        newTask.id = widget.taskToEdit!.id;
        newTask.isCompleted = widget.taskToEdit!.isCompleted;
        // Hủy thông báo cũ trước khi xếp lịch mới
        await NotificationService().cancelNotification(widget.taskToEdit!.id);
      }

      // 1. Lưu task vào DB
      await ref.read(databaseProvider).saveTask(newTask);

      // 2. Kiểm tra và lên lịch thông báo
      if (_selectedDate != null && newTask.id != Isar.autoIncrement) {
        final now = DateTime.now();

        if (_selectedDate!.isAfter(now)) {
          await NotificationService().scheduleNotification(
            id: newTask.id,
            title: '⏰ Nhắc việc DuckDo: ${newTask.title}',
            body: newTask.description?.isNotEmpty == true
                ? newTask.description!
                : 'Đã đến thời gian thực hiện công việc này!',
            scheduledTime: _selectedDate!,
          );
        } else if (_selectedDate!.year == now.year &&
            _selectedDate!.month == now.month &&
            _selectedDate!.day == now.day &&
            _selectedDate!.hour == now.hour &&
            _selectedDate!.minute == now.minute) {
          await NotificationService().showInstantNotification(
            id: newTask.id,
            title: '⏰ Nhắc việc DuckDo: ${newTask.title}',
            body: newTask.description?.isNotEmpty == true
                ? newTask.description!
                : 'Đã đến thời gian thực hiện công việc này!',
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e, stack) {
      debugPrint('Lỗi _saveTask: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu công việc: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.taskToEdit != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: bottomInset + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Indicator handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Title Header with Duck Mascot Accent
              Row(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: DuckLogo(
                      size: 24,
                      animate: true,
                      showQuackBadge: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Chỉnh sửa công việc' : 'Thêm công việc Duck Do 🐥',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Input Tên công việc
              TextField(
                controller: _titleController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  labelText: 'Tên công việc *',
                  hintText: 'Nhập công việc cần làm...',
                  floatingLabelStyle: const TextStyle(color: Color(0xFFFF8F00)),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFFFFBEB),
                  prefixIcon: const Icon(
                    Icons.task_alt_rounded,
                    color: Color(0xFFFF8F00),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF8F00),
                      width: 1.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Input Mô tả chi tiết
              TextField(
                controller: _descController,
                maxLines: 2,
                minLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
                decoration: InputDecoration(
                  labelText: 'Ghi chú mô tả (Tùy chọn)',
                  hintText: 'Thêm thông tin bổ sung...',
                  floatingLabelStyle: const TextStyle(color: Color(0xFFFF8F00)),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFFFFBEB),
                  prefixIcon: const Icon(
                    Icons.notes_rounded,
                    color: Color(0xFFFFB300),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFB300),
                      width: 1.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Mức độ ưu tiên
              Text(
                'Mức độ ưu tiên',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final isSelected = _selectedPriority == p['value'];
                  final Color pColor = p['color'] as Color;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPriority = p['value'] as int;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? pColor
                                : (isDark
                                    ? const Color(0xFF0F172A)
                                    : pColor.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? pColor
                                  : pColor.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              p['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : pColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Danh mục
              Text(
                'Danh mục',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFFB300),
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Chu kỳ lặp lại
              Text(
                'Chu kỳ lặp lại',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _repeatRules.map((rule) {
                    final isSelected = _selectedRepeatRule == rule['value'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(rule['label']!),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFFB300),
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedRepeatRule = rule['value']!;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Hạn chót & Nhắc giờ
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFFFE082),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_filled_rounded,
                      color: Color(0xFFFF8F00),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDate == null
                                ? 'Chưa đặt thời gian hạn chót'
                                : 'Hạn chót: ${_formatDateTime(_selectedDate!)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedDate == null
                                  ? (isDark
                                      ? Colors.white54
                                      : const Color(0xFF64748B))
                                  : const Color(0xFFFF8F00),
                            ),
                          ),
                          if (_selectedDate != null)
                            const Text(
                              '🔔 Tự động bật thông báo khi tới giờ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _presentDateTimePicker,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF8F00),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        _selectedDate == null ? 'Chọn giờ' : 'Đổi giờ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Nút Lưu công việc với Gradient Duck Theme
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFB300),
                      Color(0xFFFF8F00),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8F00).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isEditing ? 'Cập nhật công việc' : 'Lưu công việc Duck Do 🐥',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
