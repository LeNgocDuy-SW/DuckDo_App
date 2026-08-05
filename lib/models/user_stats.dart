import 'package:isar/isar.dart';

part 'user_stats.g.dart';

@collection
class UserStats {
  Id id = 1;

  int xp = 0;
  int coins = 0;
  int level = 1;
  int currentStreak = 0;
  DateTime? lastCompletedDate;
  String equippedHat = 'none';
  List<String> unlockedHats = ['none'];
  bool soundEnabled = true;

  // Tính XP cần thiết để lên level tiếp theo
  int get xpForNextLevel => level * 100;
}
