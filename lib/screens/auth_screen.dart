import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home_screen.dart';
import '../providers.dart';
import '../services/auth_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/sound_service.dart';
import '../widgets/duck_logo.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    _checkAlreadyLoggedIn();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkAlreadyLoggedIn() async {
    final user = await AuthService().getCurrentUser();
    if (user != null && mounted) {
      _navigateToHome();
    }
  }

  Future<void> _navigateToHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ $msg'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    await SoundService().playClickHaptics();
    setState(() => _isLoading = true);

    try {
      UserModel user;
      if (_isSignUp) {
        user = await AuthService().signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
        );
      } else {
        user = await AuthService().signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }

      await CloudSyncService.restoreFromCloud(
        dbService: ref.read(databaseProvider),
        user: user,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Chào mừng ${user.displayName} đến với DuckDo!'),
            backgroundColor: const Color(0xFFFF8F00),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final String msg;
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              msg = 'Tài khoản không tồn tại. Vui lòng đăng ký!';
              break;
            case 'wrong-password':
            case 'invalid-credential':
              msg = 'Email hoặc mật khẩu không chính xác.';
              break;
            case 'email-already-in-use':
              msg = 'Email này đã được sử dụng cho tài khoản khác.';
              break;
            case 'weak-password':
              msg = 'Mật khẩu quá yếu (cần tối thiểu 6 ký tự).';
              break;
            case 'invalid-email':
              msg = 'Định dạng Email không hợp lệ.';
              break;
            default:
              msg = e.message ?? 'Đăng nhập thất bại (${e.code})';
          }
        } else {
          msg = e.toString().replaceAll('Exception: ', '');
        }
        _showError(msg);
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    await SoundService().playClickHaptics();
    setState(() => _isLoading = true);

    try {
      final user = await AuthService().signInWithGoogle();

      await CloudSyncService.restoreFromCloud(
        dbService: ref.read(databaseProvider),
        user: user,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Google: Chào mừng ${user.displayName}!'),
            backgroundColor: const Color(0xFFFF8F00),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 700));
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final String msg;
        if (e is FirebaseAuthException) {
          msg = e.message ?? 'Lỗi xác thực Firebase (${e.code})';
        } else {
          final errStr = e.toString();
          if (errStr.contains('hủy') ||
              errStr.contains('canceled') ||
              errStr.contains('cancelled')) {
            msg = 'Đã hủy chọn tài khoản Google.';
          } else {
            msg = 'Lỗi đăng nhập Google: ${errStr.replaceAll('Exception: ', '')}';
          }
        }
        _showError(msg);
      }
    }
  }

  Future<void> _handleFacebookAuth() async {
    await SoundService().playClickHaptics();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📘 Facebook sẽ sớm được hỗ trợ. Vui lòng dùng Google hoặc Email!'),
          backgroundColor: Color(0xFF1877F2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)]
                : const [Color(0xFFFFFBEB), Color(0xFFFFF3C4), Color(0xFFF8FAFC)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16),
                child: Column(
                  children: [
                    // Skip button
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : _navigateToHome,
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        label: const Text(
                          'Bỏ qua',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.amber.shade200
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Duck Mascot
                    const DuckLogo(size: 110, animate: true, showQuackBadge: true),
                    const SizedBox(height: 16),

                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFB300), Color(0xFFFF8F00), Color(0xFFD97706)],
                      ).createShader(bounds),
                      child: Text(
                        _isSignUp ? 'Tạo Tài Khoản DuckDo 🐣' : 'Chào mừng trở lại! 🔑',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Đăng nhập để đồng bộ công việc & Cấp độ Vịt lên Đám mây',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B).withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : Colors.amber.shade100,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_isSignUp) ...[
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Họ và tên / Biệt danh Vịt',
                                  prefixIcon: const Icon(Icons.person_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Vui lòng nhập tên của bạn'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Địa chỉ Email',
                                prefixIcon: const Icon(Icons.email_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              validator: (val) => val == null || !val.contains('@')
                                  ? 'Vui lòng nhập Email hợp lệ'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleEmailAuth(),
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                prefixIcon: const Icon(Icons.lock_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              validator: (val) => val == null || val.length < 6
                                  ? 'Mật khẩu phải từ 6 ký tự'
                                  : null,
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleEmailAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8F00),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : Text(
                                        _isSignUp ? 'Đăng Ký Ngay 🐥' : 'Đăng Nhập 🔑',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            TextButton(
                              onPressed: () => setState(() => _isSignUp = !_isSignUp),
                              child: Text(
                                _isSignUp
                                    ? 'Đã có tài khoản? Đăng nhập ngay'
                                    : 'Chưa có tài khoản? Đăng ký tại đây',
                                style: const TextStyle(
                                  color: Color(0xFFFF8F00),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Hoặc tiếp tục với',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Social Login Buttons
                    Column(
                      children: [
                        // Google Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleGoogleAuth,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              foregroundColor: isDark ? Colors.white : const Color(0xFF1F2937),
                              side: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: isDark ? 0 : 1,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CustomPaint(painter: _GoogleGLogoPainter()),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Đăng nhập bằng Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Facebook Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleFacebookAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1877F2),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'f',
                                      style: TextStyle(
                                        color: Color(0xFF1877F2),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Đăng nhập bằng Facebook',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Blue arc & horizontal bar
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final Path bluePath = Path()
      ..moveTo(w * 0.95, h * 0.5)
      ..cubicTo(w * 0.95, h * 0.44, w * 0.94, h * 0.38, w * 0.93, h * 0.32)
      ..lineTo(w * 0.5, h * 0.32)
      ..lineTo(w * 0.5, h * 0.52)
      ..lineTo(w * 0.76, h * 0.52)
      ..cubicTo(w * 0.75, h * 0.61, w * 0.69, h * 0.71, w * 0.5, h * 0.71)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Red arc
    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final Path redPath = Path()
      ..moveTo(w * 0.5, h * 0.28)
      ..cubicTo(w * 0.62, h * 0.28, w * 0.72, h * 0.33, w * 0.79, h * 0.39)
      ..lineTo(w * 0.9, h * 0.28)
      ..cubicTo(w * 0.8, h * 0.19, w * 0.66, h * 0.13, w * 0.5, h * 0.13)
      ..cubicTo(w * 0.32, h * 0.13, w * 0.17, h * 0.23, w * 0.1, h * 0.38)
      ..lineTo(w * 0.26, h * 0.5)
      ..cubicTo(w * 0.3, h * 0.37, w * 0.39, h * 0.28, w * 0.5, h * 0.28)
      ..close();
    canvas.drawPath(redPath, redPaint);

    // Yellow arc
    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final Path yellowPath = Path()
      ..moveTo(w * 0.1, h * 0.38)
      ..cubicTo(w * 0.05, h * 0.46, w * 0.05, h * 0.54, w * 0.1, h * 0.62)
      ..lineTo(w * 0.26, h * 0.5)
      ..cubicTo(w * 0.25, h * 0.47, w * 0.25, h * 0.43, w * 0.26, h * 0.38)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Green arc
    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final Path greenPath = Path()
      ..moveTo(w * 0.5, h * 0.71)
      ..cubicTo(w * 0.39, h * 0.71, w * 0.3, h * 0.63, w * 0.26, h * 0.5)
      ..lineTo(w * 0.1, h * 0.62)
      ..cubicTo(w * 0.17, h * 0.77, w * 0.32, h * 0.87, w * 0.5, h * 0.87)
      ..cubicTo(w * 0.66, h * 0.87, w * 0.79, h * 0.81, w * 0.88, h * 0.73)
      ..lineTo(w * 0.73, h * 0.61)
      ..cubicTo(w * 0.67, h * 0.67, w * 0.59, h * 0.71, w * 0.5, h * 0.71)
      ..close();
    canvas.drawPath(greenPath, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
