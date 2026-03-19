import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/stopwatch_screen.dart';
import 'screens/history_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timeval',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _RootScreen(),
    );
  }
}

// ── ルート画面：スプラッシュ→オンボード→ログイン→メイン ──
class _RootScreen extends StatefulWidget {
  const _RootScreen();

  @override
  State<_RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<_RootScreen> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    // ① スプラッシュ未完了
    if (!_splashDone) {
      return SplashScreen(
        onComplete: () => setState(() => _splashDone = true),
      );
    }

    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        // ② データロード中はローディング表示（onboardingDoneの誤判定を防ぐ）
        if (!provider.isLoaded) {
          return const Scaffold(
            backgroundColor: AppTheme.bg,
            body: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.subtle,
              ),
            ),
          );
        }

        // ③ オンボーディング未完了 → 必ず表示（ログイン状態に関わらず）
        if (!provider.onboardingDone) {
          return OnboardingScreen(
            onFinished: () {
              // onFinished は completeOnboarding() 済み（OnboardingScreen内で呼ぶ）
            },
          );
        }

        // ④ オンボーディング完了後 → Firebase Auth状態を監視
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppTheme.bg,
                body: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.subtle,
                  ),
                ),
              );
            }

            final user = snapshot.data;

            // 未ログイン → ログイン画面
            if (user == null) {
              return const LoginScreen();
            }

            // ⑤ ログイン済み → メイン画面
            return const HomeScreen();
          },
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _screens = [
    StopwatchScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.timer_outlined, activeIcon: Icons.timer, label: 'タイマー'),
      _NavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: '履歴'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (i == 0)
                        Consumer<AppProvider>(
                          builder: (_, p, __) => p.runningCount > 0
                              ? _RunningBadge(count: p.runningCount)
                              : Icon(
                                  active ? item.activeIcon : item.icon,
                                  size: 22,
                                  color: active
                                      ? AppTheme.onSurface
                                      : AppTheme.subtle,
                                ),
                        )
                      else
                        Icon(
                          active ? item.activeIcon : item.icon,
                          size: 22,
                          color: active ? AppTheme.onSurface : AppTheme.subtle,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          color:
                              active ? AppTheme.onSurface : AppTheme.subtle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _RunningBadge extends StatelessWidget {
  final int count;
  const _RunningBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.timer, size: 22, color: AppTheme.onSurface),
        Positioned(
          top: -2,
          right: -6,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: AppTheme.accentGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
