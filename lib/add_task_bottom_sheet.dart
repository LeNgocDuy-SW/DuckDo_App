import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'providers.dart';
import 'models/task.dart';
import 'services/notification_services.dart';

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
    {'label': 'Thấp', 'value': 0, 'color': Colors.green},
    {'label': 'Thường', 'value': 1, 'color': Colors.blue},
    {'label': 'Gấp!', 'value': 2, 'color': Colors.red},
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
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDate != null
          ? TimeOfDay.fromDateTime(_selectedDate!)
          : TimeOfDay.now(),
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
    return 'Hạn chót: $hour:$minute - $day/$month/$year';
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên công việc')),
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

      // 1. Chờ lưu task vào DB để nhận/giữ ID chính xác từ Isar
      await ref.read(databaseProvider).saveTask(newTask);

      // 2. Kiểm tra và lên lịch thông báo
      if (_selectedDate != null && newTask.id != Isar.autoIncrement) {
        final now = DateTime.now();

        if (_selectedDate!.isAfter(now)) {
          await NotificationService().scheduleNotification(
            id: newTask.id,
            title: '⏰ Nhắc việc: ${newTask.title}',
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
            title: '⏰ Nhắc việc: ${newTask.title}',
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
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.taskToEdit != null;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: bottomInset + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag indicator handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isEditing ? 'Chỉnh sửa công việc' : 'Thêm công việc mới',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tên công việc',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.task_alt),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Mô tả chi tiết',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 12),

            // Chọn mức độ ưu tiên
            Text(
              'Mức độ ưu tiên',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: _priorities.map((p) {
                final isSelected = _selectedPriority == p['value'];
                final Color pColor = p['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      p['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : pColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: pColor,
                    backgroundColor: pColor.withValues(alpha: 0.1),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPriority = p['value'] as int;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Chọn danh mục
            Text(
              'Danh mục',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
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
            const SizedBox(height: 12),

            // Chọn chu kỳ lặp lại
            Text(
              'Chu kỳ lặp lại',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _repeatRules.map((rule) {
                  final isSelected = _selectedRepeatRule == rule['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(rule['label']!),
                      selected: isSelected,
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
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Chưa chọn thời gian'
                        : _formatDateTime(_selectedDate!),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _selectedDate == null
                          ? colorScheme.onSurface.withValues(alpha: 0.6)
                          : colorScheme.primary,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _presentDateTimePicker,
                  icon: const Icon(Icons.access_time_filled),
                  label: const Text('Hẹn giờ'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saveTask,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isEditing ? 'Cập nhật công việc' : 'Lưu công việc',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
