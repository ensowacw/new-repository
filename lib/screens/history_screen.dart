import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/project.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('履歴'),
      ),
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, _) {
            // 全プロジェクトのセッションを収集
            final allSessions = <_SessionWithMeta>[];
            for (final p in provider.projects) {
              for (final s in p.sessions) {
                allSessions.add(_SessionWithMeta(session: s, projectName: p.name));
              }
            }
            // 新しい順にソート
            allSessions.sort((a, b) =>
                b.session.startTime.compareTo(a.session.startTime));

            if (allSessions.isEmpty) {
              return const _EmptyState();
            }

            final totalEarned =
                allSessions.fold(0.0, (s, e) => s + e.session.earned);
            final totalDuration = allSessions.fold(
                Duration.zero, (s, e) => s + e.session.duration);

            return Column(
              children: [
                _SummaryBar(
                  totalEarned: totalEarned,
                  totalDuration: totalDuration,
                  count: allSessions.length,
                ),
                Container(height: 0.5, color: AppTheme.divider),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: allSessions.length,
                    itemBuilder: (context, i) {
                      final meta = allSessions[i];
                      final isFirst = i == 0;
                      final isLast = i == allSessions.length - 1;
                      return _SessionRow(
                        meta: meta,
                        isFirst: isFirst,
                        isLast: isLast,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── データクラス ──────────────────────────────────────
class _SessionWithMeta {
  final ProjectSession session;
  final String projectName;
  const _SessionWithMeta({required this.session, required this.projectName});
}

// ── サマリーバー ─────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final double totalEarned;
  final Duration totalDuration;
  final int count;

  const _SummaryBar({
    required this.totalEarned,
    required this.totalDuration,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          _Stat(label: '合計金額', value: formatYen(totalEarned)),
          const SizedBox(width: 28),
          _Stat(label: '合計時間', value: formatDurationShort(totalDuration)),
          const Spacer(),
          _Stat(label: '回数', value: '$count 回', right: true),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool right;
  const _Stat({required this.label, required this.value, this.right = false});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.sectionLabel),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
}

// ── セッション行 ─────────────────────────────────────
class _SessionRow extends StatelessWidget {
  final _SessionWithMeta meta;
  final bool isFirst;
  final bool isLast;

  const _SessionRow({
    required this.meta,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final s = meta.session;
    final dateFmt = DateFormat('M/d(E)', 'ja');
    final timeFmt = DateFormat('HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
        border: Border.all(color: AppTheme.divider, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // 左：プロジェクト名・日時
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // プロジェクト名バッジ
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      meta.projectName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.subtle,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatDurationShort(s.duration),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dateFmt.format(s.startTime)}  ${timeFmt.format(s.startTime)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.subtle,
                    ),
                  ),
                ],
              ),
            ),

            // 右：金額
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatYen(s.earned, showDecimal: true),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.onSurface,
                    fontFeatures: [FontFeature.tabularFigures()],
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

// ── 空状態 ───────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HISTORY', style: AppTheme.sectionLabel),
            const SizedBox(height: 20),
            const Text(
              'まだ記録が\nありません。',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
                height: 1.35,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'タイマーを計測して\n「記録して終了」すると\nここに表示されます。',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.subtle,
                height: 1.7,
              ),
            ),
          ],
        ),
      );
}
