import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../services/sound_service.dart';
import '../widgets/duck_logo.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  int _selectedDurationSeconds = 25 * 60; // Default 25 minutes
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  String _modeLabel = '🎯 Tập trung';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _selectMode(String label, int minutes) {
    if (_isRunning) _pauseTimer();
    setState(() {
      _modeLabel = label;
      _selectedDurationSeconds = minutes * 60;
      _remainingSeconds = minutes * 60;
    });
  }

  void _startTimer() async {
    await SoundService().playClickHaptics();
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
        });
        await _onTimerFinished();
      }
    });
  }

  void _pauseTimer() async {
    await SoundService().playClickHaptics();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() async {
    await SoundService().playClickHaptics();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedDurationSeconds;
    });
  }

  Future<void> _onTimerFinished() async {
    await SoundService().playLevelUpHaptics();

    // Reward +25 XP and +10 Coins if in focus mode
    if (_modeLabel == '🎯 Tập trung') {
      final stats = await ref.read(databaseProvider).getUserStats();
      final oldLevel = stats.level;
      stats.xp += 25;
      stats.coins += 10;

      int calculatedLevel = (stats.xp / 100).floor() + 1;
      bool leveledUp = calculatedLevel > oldLevel;
      if (leveledUp) {
        stats.level = calculatedLevel;
      }
      await ref.read(databaseProvider).saveUserStats(stats);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Column(
              children: const [
                DuckLogo(size: 100, animate: true, showQuackBadge: true),
                SizedBox(height: 12),
                Text(
                  '🎉 TẬP TRUNG XUẤT SẮC! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8F00),
                  ),
                ),
              ],
            ),
            content: Text(
              'Bạn đã hoàn thành 25 phút tập trung!\n\nThưởng cho bạn: +25 XP | +10 🪙\nChú Vịt DuckDo rất tự hào về bạn! 🐥✨',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              Center(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8F00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Nhận phần thưởng 🏆'),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final userStatsAsync = ref.watch(userStatsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double progress = _selectedDurationSeconds > 0
        ? (1.0 - (_remainingSeconds / _selectedDurationSeconds))
        : 0.0;

    final String equippedHat = userStatsAsync.maybeWhen(
      data: (s) => s.equippedHat,
      orElse: () => 'none',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đồng hồ Pomodoro Vịt ⏱️',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF8F00),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Mode Select Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeChip('🎯 Tập trung', 25, isDark),
                const SizedBox(width: 8),
                _buildModeChip('☕ Nghỉ ngắn', 5, isDark),
                const SizedBox(width: 8),
                _buildModeChip('🌴 Nghỉ dài', 15, isDark),
              ],
            ),

            const SizedBox(height: 36),

            // Circular Progress Timer with Duck Mascot inside
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFFFECB3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF8F00),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DuckLogo(
                      size: 90,
                      animate: _isRunning,
                      showQuackBadge: false,
                      equippedHat: equippedHat,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      _modeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8F00),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Controls (Start/Pause, Reset)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: _resetTimer,
                  iconSize: 28,
                  icon: const Icon(Icons.refresh_rounded),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8F00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  icon: Icon(
                    _isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 28,
                  ),
                  label: Text(
                    _isRunning ? 'Tạm dừng' : 'Bắt đầu ngay',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, int minutes, bool isDark) {
    final bool isSelected = _modeLabel == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFFF8F00),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => _selectMode(label, minutes),
    );
  }
}
