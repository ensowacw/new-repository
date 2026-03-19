import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthService.signInWithGoogle();
      // Web: signInWithRedirectはページ遷移するためここには戻らない
      // ログイン完了後はFirebaseのauthStateChangesで自動的にHomeScreenへ遷移
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'ログインに失敗しました。もう一度お試しください。';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // オンボーディングと同じ白背景
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // ── eyebrow（オンボーディングと同スタイル）──
              Text(
                'ACCOUNT',
                style: AppTheme.sectionLabel,
              ),
              const SizedBox(height: 20),

              // ── メインコピー（オンボーディングと同フォント）──
              const Text(
                'はじめましょう。',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  height: 1.35,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 28),

              // 仕切り線（オンボーディングと同じ）
              Container(width: 32, height: 1, color: AppTheme.divider),
              const SizedBox(height: 24),

              // ── サブコピー ─────────────────────────────
              const Text(
                'Googleアカウントでログインすると、\nどのデバイスからでもデータにアクセスできます。',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.secondary,
                  height: 1.8,
                  letterSpacing: 0.1,
                ),
              ),

              const Spacer(),

              // ── エラー表示 ─────────────────────────────
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.danger,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16),
              ],

              // ── Googleログインボタン（オンボーディングの「始める」と同スタイル）──
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _isLoading ? null : _signInWithGoogle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? AppTheme.bgSecondary
                          : AppTheme.onSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.subtle,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleIcon(),
                              SizedBox(width: 10),
                              Text(
                                'Googleで始める',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── 規約テキスト ────────────────────────────
              const Text(
                'ログインすることで利用規約とプライバシーポリシーに同意したものとみなします。',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.subtle,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Google "G" アイコン
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}
