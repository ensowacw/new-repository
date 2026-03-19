import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class _OnboardPage {
  final String eyebrow;
  final String headline; // \n で意味のある場所に改行
  final String body;
  const _OnboardPage({
    required this.eyebrow,
    required this.headline,
    required this.body,
  });
}

const _pages = [
  _OnboardPage(
    eyebrow: '時間とお金の話',
    headline: '今この瞬間、\nあなたの時間はいくらですか？',
    body: '漠然と過ごしている時間にも、\nはっきりとした価値がある。',
  ),
  _OnboardPage(
    eyebrow: '仕事の価値について',
    headline: 'その仕事、\n本当に割に合っていますか？',
    body: '単価だけ見ていると気づかない。\nかけた時間で割ると、真実が見えてくる。',
  ),
  _OnboardPage(
    eyebrow: '時間の使い方について',
    headline: '「忙しい」のに\nお金が増えない理由がある。',
    body: '動いている時間と、稼いでいる時間は\n必ずしも同じではない。',
  ),
  _OnboardPage(
    eyebrow: 'このアプリについて',
    headline: '時間に値札をつけると、\n見え方が変わる。',
    body: '自分の1時間の価値を知るだけで、\n何に時間を使うべきかが明確になる。',
  ),
];

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinished;
  const OnboardingScreen({super.key, this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    // onFinishedコールバックで親（_RootScreen）の_onboardDoneを更新する
    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _current == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── スキップ ──────────────────────────────────
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isLast)
                      GestureDetector(
                        onTap: _finish,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'スキップ',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.subtle,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── PageView（高さ固定でブロックがずれない）──
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageContent(page: _pages[i]),
              ),
            ),

            // ── ドット + ボタン ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _current;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 20 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: active ? AppTheme.onSurface : AppTheme.divider,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: GestureDetector(
                      onTap: _next,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.onSurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              isLast ? '始める' : '次へ',
                              key: ValueKey(isLast),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  const _PageContent({required this.page});

  // フォントサイズは全ページ完全固定
  static const double _headlineSize = 24;
  static const double _bodySize = 15;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // 中央に配置
        children: [
          // eyebrow
          Text(
            page.eyebrow.toUpperCase(),
            style: AppTheme.sectionLabel,
          ),
          const SizedBox(height: 20),

          // メインコピー
          Text(
            page.headline,
            style: const TextStyle(
              fontSize: _headlineSize,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
              height: 1.35,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 28),

          // 仕切り線
          Container(width: 32, height: 1, color: AppTheme.divider),
          const SizedBox(height: 24),

          // サブコピー
          Text(
            page.body,
            style: const TextStyle(
              fontSize: _bodySize,
              fontWeight: FontWeight.w400,
              color: AppTheme.secondary,
              height: 1.8,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
