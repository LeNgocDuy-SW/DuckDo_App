import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
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

      setState(() {
        _user = user;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Chào mừng ${_user!.displayName} đến với DuckDo!'),
            backgroundColor: const Color(0xFFFF8F00),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleAuth() async {
    await SoundService().playClickHaptics();
    setState(() => _isLoading = true);
    final user = await AuthService().signInWithGoogle();

    await CloudSyncService.restoreFromCloud(
      dbService: ref.read(databaseProvider),
      user: user,
    );

    setState(() {
      _user = user;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Đăng nhập Google thành công! Chào ${user.displayName}'),
          backgroundColor: const Color(0xFFFF8F00),
        ),
      );
    }
  }

  Future<void> _handleFacebookAuth() async {
    await SoundService().playClickHaptics();
    setState(() => _isLoading = true);
    final user = await AuthService().signInWithFacebook();

    await CloudSyncService.restoreFromCloud(
      dbService: ref.read(databaseProvider),
      user: user,
    );

    setState(() {
      _user = user;
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Đăng nhập Facebook thành công! Chào ${user.displayName}'),
          backgroundColor: const Color(0xFF1877F2),
        ),
      );
    }
  }

  Future<void> _handleBackup() async {
    if (_user == null) return;
    await SoundService().playClickHaptics();
    setState(() => _isLoading = true);

    final success = await CloudSyncService.backupToCloud(
      dbService: ref.read(databaseProvider),
      user: _user!,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '☁️ Đã sao lưu dữ liệu công việc & XP lên Đám mây!'
                : '⚠️ Sao lưu không thành công.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await SoundService().playClickHaptics();
    await AuthService().signOut();
    setState(() {
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tài Khoản & Đám Mây ☁️',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF8F00),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const DuckLogo(size: 110, animate: true, showQuackBadge: true),
            const SizedBox(height: 16),

            // IF USER IS ALREADY LOGGED IN
            if (_user != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
                        : const [Color(0xFFFFF8E7), Color(0xFFFFF3C4)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFFF8F00),
                      child: Text(
                        _user!.displayName.isNotEmpty
                            ? _user!.displayName[0].toUpperCase()
                            : '🐥',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _user!.displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      _user!.email,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.cloud_done_rounded,
                              size: 16, color: Colors.white),
                          label: Text('Đồng bộ: ${_user!.provider.toUpperCase()}'),
                          backgroundColor: const Color(0xFFFF8F00),
                          labelStyle: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleBackup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8F00),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload_rounded),
                      label: const Text(
                        'Sao lưu Đám mây ngay ☁️',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _handleSignOut,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Đăng xuất tài khoản'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // LOGIN / SIGNUP FORM
              Text(
                _isSignUp
                    ? 'Đăng ký Tài khoản DuckDo 🐣'
                    : 'Đăng nhập DuckDo 🔑',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Đăng nhập để đồng bộ danh sách công việc và Cấp độ Vịt lên Đám mây!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Họ và tên / Biệt danh Vịt',
                          prefixIcon: const Icon(Icons.person_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
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
                      decoration: InputDecoration(
                        labelText: 'Địa chỉ Email',
                        prefixIcon: const Icon(Icons.email_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
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
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (val) => val == null || val.length < 6
                          ? 'Mật khẩu phải từ 6 ký tự'
                          : null,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8F00),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isSignUp ? 'Đăng Ký Ngay 🐥' : 'Đăng Nhập 🔑',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                        });
                      },
                      child: Text(
                        _isSignUp
                            ? 'Đã có tài khoản? Đăng nhập ngay'
                            : 'Chưa có tài khoản? Đăng ký tại đây',
                        style: const TextStyle(color: Color(0xFFFF8F00)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('Hoặc đăng nhập với',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // SOCIAL LOGIN BUTTONS (Google & Facebook)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleAuth,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Text('🌐', style: TextStyle(fontSize: 18)),
                      label: const Text('Google',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleFacebookAuth,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: const Color(0xFF1877F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Text('📘', style: TextStyle(fontSize: 18)),
                      label: const Text('Facebook',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
