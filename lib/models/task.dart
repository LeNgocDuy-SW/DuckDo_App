import 'package:isar/isar.dart';
// Dòng này rất quan trọng để Isar biết cần sinh ra file task.g.dart
part 'task.g.dart';

@collection
class Task {
  // Id tự động tăng của Isar
  Id id = Isar.autoIncrement;
  // Tên công việc (không được phép null)
  late String title;
  // Mô tả chi tiết (có thể null nếu không nhập)
  String? description;
  // Thời gian đến hạn
  DateTime? dueDate;
  // Trạng thái hoàn thành (mặc định là chưa hoàn thành)
  bool isCompleted = false;
  // Thời gian tạo task (để dễ dàng sắp xếp)
  late DateTime createdAt;
  // Mức độ ưu tiên: 0: Thấp, 1: Bình thường, 2: Gấp
  int priority = 1;
  // Danh mục phân loại: 'Công việc', 'Cá nhân', 'Học tập', 'Sức khỏe', 'Chung'
  String category = 'Chung';
  // Quy tắc lặp lại: 'none' (Không lặp), 'daily' (Hàng ngày), 'weekly' (Hàng tuần), 'monthly' (Hàng tháng)
  String repeatRule = 'none';
}

// (Nếu sau này bạn có cập nhật lại Model, thêm sửa xóa các trường, 
// hãy chạy lại lệnh trên với cờ update: dart run build_runner build --delete-conflicting-outputs)