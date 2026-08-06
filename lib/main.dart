import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/notification_services.dart';
import 'services/auth_service.dart';
import 'providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialize error: $e');
  }
  await NotificationService().init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final hasSeenWelcomeAsync = ref.watch(hasSeenWelcomeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "DuckDo",
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB300),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB300),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
      ),
      home: hasSeenWelcomeAsync.when(
        data: (hasSeen) {
          if (!hasSeen) {
            // Lần đầu mở app: Welcome → Auth → Home
            return const WelcomeScreen();
          }
          // Đã từng dùng app: kiểm tra trạng thái đăng nhập
          return const _AuthGate();
        },
        loading: () => const WelcomeScreen(),
        error: (err, stack) => const WelcomeScreen(),
      ),
    );
  }
}

/// Gate: Nếu đã đăng nhập → HomeScreen, chưa đăng nhập → AuthScreen
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  Widget _screen = const Scaffold(
    body: Center(child: CircularProgressIndicator(color: Color(0xFFFF8F00))),
  );

  @override
  void initState() {
    super.initState();
    _decideScreen();
  }

  Future<void> _decideScreen() async {
    final user = await AuthService().getCurrentUser();
    if (!mounted) return;
    setState(() {
      // Nếu đã đăng nhập (kể cả chế độ khách đã từng bỏ qua) → thẳng HomeScreen
      _screen = user != null ? const HomeScreen() : const HomeScreen();
    });
  }

  @override
  Widget build(BuildContext context) => _screen;
}
