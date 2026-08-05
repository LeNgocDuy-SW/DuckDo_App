import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // Kích hoạt rung haptics khi hoàn thành công việc
  Future<void> playTaskCompleteHaptics() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  // Kích hoạt rung khi thăng cấp (Level Up)
  Future<void> playLevelUpHaptics() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  // Rung tương tác thông thường
  Future<void> playClickHaptics() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
