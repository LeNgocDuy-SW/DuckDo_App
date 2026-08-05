import 'package:flutter/foundation.dart';

class ParsedTaskInfo {
  final String title;
  final DateTime dueDate;
  final String category;
  final int priority;

  ParsedTaskInfo({
    required this.title,
    required this.dueDate,
    required this.category,
    required this.priority,
  });
}

class VoiceTaskParser {
  static ParsedTaskInfo parseVietnameseSpeech(String text) {
    if (text.trim().isEmpty) {
      return ParsedTaskInfo(
        title: 'Công việc mới từ giọng nói',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        category: '📌 Chung',
        priority: 1,
      );
    }

    final String rawLower = text.toLowerCase().trim();
    DateTime targetDate = DateTime.now();

    // 1. Phân tích Ngày (Hôm nay / Ngày mai)
    if (rawLower.contains('ngày mai')) {
      targetDate = targetDate.add(const Duration(days: 1));
    }

    // 2. Phân tích Giờ (Ví dụ: "3 giờ chiều", "8 giờ sáng", "9 giờ tối", "15 giờ")
    int hour = 17; // Mặc định 17h chiều nếu không đọc giờ
    int minute = 0;

    final RegExp hourRegex = RegExp(r'(\d{1,2})\s*(?:giờ|g|h)');
    final match = hourRegex.firstMatch(rawLower);

    if (match != null) {
      int parsedHour = int.tryParse(match.group(1)!) ?? 17;

      if (rawLower.contains('chiều') ||
          rawLower.contains('tối') ||
          rawLower.contains('đêm')) {
        if (parsedHour < 12) parsedHour += 12;
      } else if (rawLower.contains('sáng')) {
        if (parsedHour == 12) parsedHour = 0;
      }

      if (parsedHour >= 0 && parsedHour <= 23) {
        hour = parsedHour;
      }
    }

    // Ghép ngày & giờ
    final DateTime finalDueDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );

    // 3. Tách và làm sạch Tiêu đề công việc
    String title = text;

    // Loại bỏ tiền tố nhắc nhở
    final prefixes = [
      'nhắc tôi',
      'nhắc mình',
      'nhắc',
      'tạo công việc',
      'tạo việc',
      'thêm công việc',
      'thêm việc',
    ];
    for (var prefix in prefixes) {
      if (title.toLowerCase().startsWith(prefix)) {
        title = title.substring(prefix.length).trim();
        break;
      }
    }

    // Loại bỏ các cụm từ thời gian trong tiêu đề
    title = title.replaceAll(RegExp(r'lúc\s+\d{1,2}\s*(?:giờ|g|h)\s*(?:chiều|sáng|tối|đêm)?', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'ngày\s+mai', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'hôm\s+nay', caseSensitive: false), '');
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (title.isEmpty) {
      title = 'Công việc mới 🐥';
    } else {
      title = title[0].toUpperCase() + title.substring(1);
    }

    // 4. Đoán Danh mục
    String category = '📌 Chung';
    int priority = 1;

    if (rawLower.contains('họp') ||
        rawLower.contains('báo cáo') ||
        rawLower.contains('gặp') ||
        rawLower.contains('dự án') ||
        rawLower.contains('công việc')) {
      category = '💼 Công việc';
      priority = 2; // Gấp
    } else if (rawLower.contains('học') ||
        rawLower.contains('bài tập') ||
        rawLower.contains('thi') ||
        rawLower.contains('đọc sách')) {
      category = '📚 Học tập';
    } else if (rawLower.contains('chạy') ||
        rawLower.contains('tập') ||
        rawLower.contains('uống nước') ||
        rawLower.contains('thuốc')) {
      category = '❤️ Sức khỏe';
    } else if (rawLower.contains('đi chợ') ||
        rawLower.contains('mua') ||
        rawLower.contains('xem phim')) {
      category = '👤 Cá nhân';
    }

    debugPrint('AI Voice Parsed: Title="$title", Date=$finalDueDate, Category=$category');

    return ParsedTaskInfo(
      title: title,
      dueDate: finalDueDate,
      category: category,
      priority: priority,
    );
  }
}
