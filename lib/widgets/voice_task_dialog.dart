import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/task.dart';
import '../providers.dart';
import '../services/notification_services.dart';
import '../services/sound_service.dart';
import '../services/voice_task_parser.dart';
import 'duck_logo.dart';

class VoiceTaskDialog extends ConsumerStatefulWidget {
  const VoiceTaskDialog({super.key});

  @override
  ConsumerState<VoiceTaskDialog> createState() => _VoiceTaskDialogState();
}

class _VoiceTaskDialogState extends ConsumerState<VoiceTaskDialog>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late AnimationController _pulseController;

  bool _isListening = false;
  String _spokenText = '';
  ParsedTaskInfo? _parsedTask;
  String _statusMessage = 'Chạm nút Micro bên dưới và bắt đầu nói...';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _initSpeech();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (mounted) {
            if (status == 'done' || status == 'notListening') {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _statusMessage =
                  'Chưa nghe rõ (${error.errorMsg}). Nhấn nút Micro để thử lại!';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          if (available) {
            _statusMessage = 'Sẵn sàng! Nhấn nút Micro và bắt đầu nói... 🎙️';
            _startListening();
          } else {
            _statusMessage =
                'Vui lòng cấp quyền Micro trong Cài đặt ứng dụng để sử dụng.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Nhấn nút Micro bên dưới để bắt đầu nói...';
        });
      }
    }
  }

  void _startListening() async {
    await SoundService().playClickHaptics();

    try {
      if (!_speech.isAvailable) {
        bool available = await _speech.initialize();
        if (!available) {
          if (mounted) {
            setState(() {
              _statusMessage =
                  'Không thể truy cập Micro. Hãy cấp quyền Micro trong Cài đặt điện thoại.';
            });
          }
          return;
        }
      }

      setState(() {
        _isListening = true;
        _statusMessage = 'Đang lắng nghe... Hãy nói tên công việc của bạn! 🎙️';
      });

      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: 'vi_VN',
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
        onResult: (result) {
          if (mounted) {
            setState(() {
              _spokenText = result.recognizedWords;
              if (_spokenText.isNotEmpty) {
                _parsedTask = VoiceTaskParser.parseVietnameseSpeech(_spokenText);
              }
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMessage = 'Nhấn lại vào Micro để thử lại nhé!';
        });
      }
    }
  }

  void _stopListening() async {
    await SoundService().playClickHaptics();
    await _speech.stop();
    setState(() {
      _isListening = false;
      _statusMessage = 'Đã nhận diện xong!';
    });
  }

  Future<void> _saveTask() async {
    if (_parsedTask == null && _spokenText.isEmpty) return;

    final info = _parsedTask ?? VoiceTaskParser.parseVietnameseSpeech(_spokenText);
    await SoundService().playTaskCompleteHaptics();

    final newTask = Task()
      ..title = info.title
      ..description = 'Tạo tự động bằng giọng nói AI 🎙️'
      ..dueDate = info.dueDate
      ..priority = info.priority
      ..category = info.category
      ..repeatRule = 'none'
      ..isCompleted = false
      ..createdAt = DateTime.now();

    await ref.read(databaseProvider).saveTask(newTask);

    if (info.dueDate.isAfter(DateTime.now())) {
      await NotificationService().scheduleNotification(
        id: newTask.id,
        title: '⏰ Nhắc việc AI: ${newTask.title}',
        body: 'Đã đến thời gian thực hiện công việc!',
        scheduledTime: info.dueDate,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Đã tạo công việc "${info.title}" bằng giọng nói AI!'),
          backgroundColor: const Color(0xFFFF8F00),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DuckLogo(size: 80, animate: true, showQuackBadge: false),
            const SizedBox(height: 12),
            const Text(
              'Tạo Việc Bằng Giọng Nói AI 🎙️',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8F00),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // PULSING MICROPHONE BUTTON
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final double scale = _isListening ? 1.0 + (_pulseController.value * 0.15) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8F00).withValues(
                              alpha: _isListening ? 0.6 : 0.2,
                            ),
                            blurRadius: _isListening ? 20 : 8,
                            spreadRadius: _isListening ? 6 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // LIVE TRANSCRIBED TEXT DISPLAY
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Text(
                _spokenText.isNotEmpty
                    ? '"$_spokenText"'
                    : 'Ví dụ: "Nhắc tôi đi họp lúc 3 giờ chiều"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : const Color(0xFF5D4037),
                ),
              ),
            ),

            // AI EXTRACTED PREVIEW CARD
            if (_parsedTask != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8F00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF8F00)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFFF8F00)),
                        SizedBox(width: 6),
                        Text(
                          'AI Đã Trích Xuất Công Việc:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8F00),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📝 Tiêu đề: ${_parsedTask!.title}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '⏰ Hẹn giờ: ${_parsedTask!.dueDate.hour.toString().padLeft(2, '0')}:${_parsedTask!.dueDate.minute.toString().padLeft(2, '0')} (Hôm nay)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '🏷️ Danh mục: ${_parsedTask!.category}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_spokenText.isEmpty && _parsedTask == null)
                        ? null
                        : _saveTask,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8F00),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Lưu Việc 🐥'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
