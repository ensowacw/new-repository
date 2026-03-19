import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/project.dart';
import '../models/salary_settings.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'project_settings_screen.dart';

class StopwatchScreen extends StatelessWidget {
  const StopwatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.bg,
          body: SafeArea(
            child: Column(
              children: [
                // ── ヘッダー（タップでプロジェクト切り替えシート）──
                _TopBar(provider: provider),

                // ── メインコンテンツ ──────────────────────
                Expanded(
                  child: _ProjectBody(
                    project: provider.activeProject,
                    index: provider.activeIndex,
                    provider: provider,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── トップバー ─────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final AppProvider provider;
  const _TopBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final project = provider.activeProject;
    final runningCount = provider.runningCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── キャッチコピー ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
          child: Text(
            '時間に、値段をつけろ。',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.divider,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 14),
      child: Row(
        children: [
          // ── 左：プロジェクト名タップでシート ──────────
          GestureDetector(
            onTap: () => _showProjectSheet(context, provider),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (project.isRunning) ...[
                    _PulsingDot(),
                    const SizedBox(width: 7),
                  ] else if (project.isPaused) ...[
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.subtle, width: 1.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: AppTheme.subtle,
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ── 複数計測中バッジ ─────────────────────────
          if (runningCount > 1) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5, height: 5,
                    decoration: const BoxDecoration(
                      color: AppTheme.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$runningCount件計測中',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.accentGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── 設定ボタン ────────────────────────────────
          GestureDetector(
            onTap: () => _openProjectSettings(context, provider),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 19,
                color: AppTheme.secondary,
              ),
            ),
          ),
        ],
      ),
    ),
      ],
    );
  }

  void _showProjectSheet(BuildContext context, AppProvider provider) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const _ProjectSwitchSheet(),
      ),
    );
  }

  void _openProjectSettings(BuildContext context, AppProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectSettingsScreen(
          project: provider.activeProject,
          index: provider.activeIndex,
        ),
      ),
    );
  }
}

// ── プロジェクト切り替えボトムシート ──────────────────────
class _ProjectSwitchSheet extends StatelessWidget {
  const _ProjectSwitchSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ドラッグハンドル
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'プロジェクトを切り替える',
                  style: AppTheme.sectionLabel,
                ),
              ),
              const SizedBox(height: 14),
              ...List.generate(provider.projects.length, (i) {
                final p = provider.projects[i];
                final isActive = i == provider.activeIndex;
                return _SheetRow(
                  project: p,
                  isActive: isActive,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.setActiveIndex(i);
                    Navigator.pop(context);
                  },
                  onSettings: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectSettingsScreen(
                          project: p,
                          index: i,
                        ),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── シート内の1行 ────────────────────────────────────────
class _SheetRow extends StatelessWidget {
  final Project project;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onSettings;
  const _SheetRow({
    required this.project,
    required this.isActive,
    required this.onTap,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.onSurface : AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 状態ドット
            _SheetDot(project: project, isActive: isActive),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    project.hasStarted
                        ? '${formatDuration(project.elapsed)}  ${project.settings.mode == SalaryMode.project ? "${formatYen(project.projectHourlyRate)}/h" : formatYen(project.currentEarned, showDecimal: true)}'
                        : (project.settings.isValid
                            ? (project.settings.mode == SalaryMode.project
                                ? '案件  ${formatYen(project.settings.projectAmount)}'
                                : '時給  ${formatYen(project.settings.hourlyRate)}/h')
                            : '未設定'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.subtle,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            // 設定ボタン
            GestureDetector(
              onTap: onSettings,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppTheme.subtle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetDot extends StatelessWidget {
  final Project project;
  final bool isActive;
  const _SheetDot({required this.project, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (project.isRunning) {
      return Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(
          color: AppTheme.accentGreen,
          shape: BoxShape.circle,
        ),
      );
    } else if (project.isPaused) {
      return Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? Colors.white.withValues(alpha: 0.5) : AppTheme.subtle,
            width: 1.5,
          ),
          shape: BoxShape.circle,
        ),
      );
    } else {
      return Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.25) : AppTheme.divider,
          shape: BoxShape.circle,
        ),
      );
    }
  }
}



// ── プロジェクト本体コンテンツ ──────────────────────────
class _ProjectBody extends StatelessWidget {
  final Project project;
  final int index;
  final AppProvider provider;

  const _ProjectBody({
    required this.project,
    required this.index,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final hasSettings = project.settings.isValid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),

          if (!hasSettings)
            _NoSettingsHint(index: index)
          else ...[
            // ── 時間表示 ───────────────────────────────
            _TimeRow(project: project),

            const SizedBox(height: 16),
            Container(height: 0.5, color: AppTheme.divider),
            const SizedBox(height: 20),

            // ── 金額表示 ───────────────────────────────
            if (project.settings.mode == SalaryMode.project)
              _ProjectModeDisplay(project: project)
            else
              _EarningsModeDisplay(project: project),
          ],

          const Spacer(flex: 3),

          // ── コントロールボタン ─────────────────────
          if (hasSettings)
            _Controls(project: project, index: index, provider: provider),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ── 設定未完了ヒント ─────────────────────────────────
class _NoSettingsHint extends StatelessWidget {
  final int index;
  const _NoSettingsHint({required this.index});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SETUP',
          style: AppTheme.sectionLabel,
        ),
        const SizedBox(height: 16),
        const Text(
          '給与・単価を\n設定してください。',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            height: 1.3,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectSettingsScreen(
                  project: context.read<AppProvider>().projects[index],
                  index: index,
                ),
              ),
            );
          },
          child: const Row(
            children: [
              Text(
                '設定する',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward, size: 15, color: AppTheme.onSurface),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 時間行 ────────────────────────────────────────────
class _TimeRow extends StatelessWidget {
  final Project project;
  const _TimeRow({required this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ELAPSED',
          style: AppTheme.sectionLabel,
        ),
        const SizedBox(height: 6),
        Text(
          formatDuration(project.elapsed),
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w200,
            letterSpacing: 1.5,
            color: project.isRunning ? AppTheme.onSurface : AppTheme.subtle,
            height: 1.0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        // 一時停止中バッジ
        if (project.isPaused) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '一時停止中',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.subtle,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── 時給・月給モードの収益表示 ────────────────────────
class _EarningsModeDisplay extends StatelessWidget {
  final Project project;
  const _EarningsModeDisplay({required this.project});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EARNED', style: AppTheme.sectionLabel),
        const SizedBox(height: 8),
        _BigAmount(
          amount: project.currentEarned,
          isActive: project.isRunning,
        ),
        const SizedBox(height: 16),
        _InfoChip(
          label: '時給換算',
          value: '${formatYen(project.settings.hourlyRate)} / h',
        ),
      ],
    );
  }
}

// ── 案件単価モードの表示 ─────────────────────────────
class _ProjectModeDisplay extends StatelessWidget {
  final Project project;
  const _ProjectModeDisplay({required this.project});

  // 警告レベルを判定（目標時給ベース）
  _WarnLevel _warnLevel(double rate, double target) {
    if (rate <= 0 || target <= 0) return _WarnLevel.none;
    final ratio = rate / target;
    if (ratio < 0.5) return _WarnLevel.critical;  // 目標の50%未満：赤
    if (ratio < 0.8) return _WarnLevel.warning;   // 目標の80%未満：アンバー
    if (ratio < 1.0) return _WarnLevel.caution;   // 目標未達：薄め
    return _WarnLevel.good;                       // 目標以上：問題なし
  }

  @override
  Widget build(BuildContext context) {
    final hasElapsed = project.elapsed.inSeconds > 0;
    final currentRate = hasElapsed ? project.projectHourlyRate : 0.0;
    final displayAmount = hasElapsed
        ? project.projectHourlyRate
        : project.settings.projectAmount;
    final target = project.settings.targetHourlyRate;
    final hasTarget = target > 0;
    final level = (hasElapsed && hasTarget)
        ? _warnLevel(currentRate, target)
        : _WarnLevel.none;
    final isActive = project.isRunning || project.isPaused;

    // 損益分岐点の計算（目標時給が設定されている場合のみ）
    final double? breakEvenHours = hasTarget && project.settings.projectAmount > 0
        ? project.settings.projectAmount / target
        : null;
    final elapsedHours = project.elapsed.inSeconds / 3600.0;
    final double? remainHours = breakEvenHours != null
        ? breakEvenHours - elapsedHours
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ラベル
        Row(
          children: [
            const Text('実質時給', style: AppTheme.sectionLabel),
            if (level == _WarnLevel.critical) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'BELOW TARGET',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.danger,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // メイン金額
        _BigAmount(
          amount: displayAmount,
          isActive: project.isRunning,
          overrideColor: level == _WarnLevel.critical ? AppTheme.danger : null,
        ),

        const SizedBox(height: 10),

        // 「時間とともに下がります」サブテキスト
        if (isActive && hasElapsed) ...[
          Row(
            children: [
              const Icon(
                Icons.south_rounded,
                size: 12,
                color: AppTheme.subtle,
              ),
              const SizedBox(width: 4),
              const Text(
                '時間とともに下がります',
                style: TextStyle(fontSize: 12, color: AppTheme.subtle),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // 案件金額チップ
        _InfoChip(
          label: '案件金額',
          value: formatYen(project.settings.projectAmount),
        ),

        // 損益分岐点カウンター（目標時給が設定されている場合のみ表示）
        if (hasTarget && isActive && breakEvenHours != null && remainHours != null) ...[
          const SizedBox(height: 6),
          if (remainHours > 0)
            _InfoChip(
              label: '目標時給${formatYen(target).replaceAll(".00", "")}割れまで',
              value: '残り ${_formatRemainHours(remainHours)}',
            )
          else
            _InfoChip(
              label: '目標時給割れ',
              value: '${_formatOverHours(-remainHours)}超過',
              danger: true,
            ),
        ] else if (hasTarget && !isActive) ...[
          const SizedBox(height: 6),
          _InfoChip(
            label: '目標時給',
            value: '${formatYen(target).replaceAll(".00", "")} / h',
          ),
        ],
      ],
    );
  }

  String _formatRemainHours(double h) {
    if (h >= 1) {
      final hh = h.floor();
      final mm = ((h - hh) * 60).round();
      return mm > 0 ? '$hh時間$mm分' : '$hh時間';
    } else {
      return '${(h * 60).round()}分';
    }
  }

  String _formatOverHours(double h) {
    if (h >= 1) {
      return '${h.floor()}時間${((h % 1) * 60).round()}分';
    }
    return '${(h * 60).round()}分';
  }
}

enum _WarnLevel { none, good, caution, warning, critical }

// ── 大きな金額表示 ───────────────────────────────────
class _BigAmount extends StatelessWidget {
  final double amount;
  final bool isActive;
  final Color? overrideColor;
  const _BigAmount({
    required this.amount,
    required this.isActive,
    this.overrideColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (overrideColor != null) {
      color = overrideColor!;
    } else if (!isActive && amount == 0) {
      color = AppTheme.divider;
    } else {
      color = AppTheme.onSurface;
    }

    final intPart = amount.floor();
    final decPart = ((amount - intPart) * 100).floor();
    final intStr = _fmt(intPart);
    final decStr = decPart.toString().padLeft(2, '0');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '¥\u200A$intStr',
          style: TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w200,
            letterSpacing: -1.5,
            color: color,
            height: 1.0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            '.$decStr',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: color.withValues(alpha: 0.45),
              height: 1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ── 情報チップ ───────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;
  const _InfoChip({required this.label, required this.value, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.subtle,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: danger ? AppTheme.danger : AppTheme.secondary,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ── コントロールボタン（3ボタン構成）─────────────────
class _Controls extends StatelessWidget {
  final Project project;
  final int index;
  final AppProvider provider;
  const _Controls({
    required this.project,
    required this.index,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── メインボタン（スタート / 一時停止）─────────
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              if (project.isRunning) {
                provider.pause(index);
              } else {
                provider.start(index);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                color: project.isRunning
                    ? AppTheme.bgSecondary
                    : AppTheme.onSurface,
                borderRadius: BorderRadius.circular(14),
                border: project.isRunning
                    ? Border.all(color: AppTheme.divider, width: 0.5)
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      project.isRunning
                          ? Icons.pause_rounded
                          : (project.isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.play_arrow_rounded),
                      size: 20,
                      color: project.isRunning
                          ? AppTheme.onSurface
                          : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      project.isRunning
                          ? '一時停止'
                          : (project.isPaused ? '再開する' : '計測を開始'),
                      style: TextStyle(
                        color: project.isRunning
                            ? AppTheme.onSurface
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── サブボタン（停止保存 / リセット）────────────
        if (project.isPaused || (project.isRunning)) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              // リセット（一時停止中のみ表示）
              if (project.isPaused) ...[
                Expanded(
                  child: _SubButton(
                    label: 'リセット',
                    icon: Icons.restart_alt_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _confirmReset(context);
                    },
                    destructive: true,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              // 記録して停止
              Expanded(
                child: _SubButton(
                  label: project.isPaused ? '記録して終了' : '記録して停止',
                  icon: Icons.stop_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (project.isRunning) provider.pause(index);
                    provider.reset(index);
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'リセットしますか？',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        content: const Text(
          '現在の計測をリセットします。\n記録には保存されません。',
          style: TextStyle(fontSize: 14, color: AppTheme.subtle),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル',
                style: TextStyle(color: AppTheme.subtle)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.clearProject(index);
            },
            child: const Text('リセット',
                style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}

class _SubButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
  const _SubButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.danger : AppTheme.secondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── アニメーションドット ─────────────────────────────
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppTheme.accentGreen,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}


