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
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '時間に、値段をつけろ。',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.divider,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            const Text('履歴'),
          ],
        ),
      ),
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, _) {
            final allSessions = <_SessionWithMeta>[];
            for (final p in provider.projects) {
              for (final s in p.sessions) {
                allSessions.add(_SessionWithMeta(session: s, projectName: p.name));
              }
            }
            allSessions.sort((a, b) =>
                b.session.startTime.compareTo(a.session.startTime));

            if (allSessions.isEmpty) {
              return const _EmptyState();
            }

            final totalEarned =
                allSessions.fold(0.0, (s, e) => s + e.session.earned);
            final totalDuration = allSessions.fold(
                Duration.zero, (s, e) => s + e.session.duration);

            // 今週・先週のセッションを計算
            final now = DateTime.now();
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final thisWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
            final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

            final thisWeekSessions = allSessions.where((s) =>
                s.session.startTime.isAfter(thisWeekStart)).toList();
            final lastWeekSessions = allSessions.where((s) =>
                s.session.startTime.isAfter(lastWeekStart) &&
                s.session.startTime.isBefore(thisWeekStart)).toList();

            final thisWeekEarned = thisWeekSessions.fold(0.0, (s, e) => s + e.session.earned);
            final lastWeekEarned = lastWeekSessions.fold(0.0, (s, e) => s + e.session.earned);
            final thisWeekDuration = thisWeekSessions.fold(Duration.zero, (s, e) => s + e.session.duration);

            // 日付グループに分けて表示
            final grouped = _groupByDate(allSessions);

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── 全体サマリー ──────────────────────────
                _SummaryBar(
                  totalEarned: totalEarned,
                  totalDuration: totalDuration,
                  count: allSessions.length,
                ),
                Container(height: 0.5, color: AppTheme.divider),

                // ── 週次サマリー ──────────────────────────
                _WeeklySummary(
                  thisWeekEarned: thisWeekEarned,
                  lastWeekEarned: lastWeekEarned,
                  thisWeekDuration: thisWeekDuration,
                  thisWeekCount: thisWeekSessions.length,
                ),

                // ── 日付別セッションリスト ─────────────────
                ...grouped.entries.map((entry) => _DaySection(
                      dateLabel: entry.key,
                      sessions: entry.value,
                    )),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  // 日付ごとにグループ化
  Map<String, List<_SessionWithMeta>> _groupByDate(List<_SessionWithMeta> sessions) {
    final map = <String, List<_SessionWithMeta>>{};
    final fmt = DateFormat('M月d日(E)', 'ja');
    final now = DateTime.now();
    for (final s in sessions) {
      final d = s.session.startTime;
      String label;
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(d.year, d.month, d.day))
          .inDays;
      if (diff == 0) {
        label = '今日  ${fmt.format(d)}';
      } else if (diff == 1) {
        label = '昨日  ${fmt.format(d)}';
      } else {
        label = fmt.format(d);
      }
      map.putIfAbsent(label, () => []).add(s);
    }
    return map;
  }
}

// ── データクラス ──────────────────────────────────────
class _SessionWithMeta {
  final ProjectSession session;
  final String projectName;
  const _SessionWithMeta({required this.session, required this.projectName});
}

// ── 全体サマリーバー ──────────────────────────────────
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

// ── 週次サマリー ─────────────────────────────────────
class _WeeklySummary extends StatelessWidget {
  final double thisWeekEarned;
  final double lastWeekEarned;
  final Duration thisWeekDuration;
  final int thisWeekCount;

  const _WeeklySummary({
    required this.thisWeekEarned,
    required this.lastWeekEarned,
    required this.thisWeekDuration,
    required this.thisWeekCount,
  });

  @override
  Widget build(BuildContext context) {
    final diff = thisWeekEarned - lastWeekEarned;
    final isUp = diff >= 0;
    final hasPrev = lastWeekEarned > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今週', style: AppTheme.sectionLabel),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatYen(thisWeekEarned),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.onSurface,
                  fontFeatures: [FontFeature.tabularFigures()],
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              if (hasPrev)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 13,
                        color: isUp ? AppTheme.accentGreen : AppTheme.danger,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${isUp ? "+" : ""}${formatYen(diff)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isUp ? AppTheme.accentGreen : AppTheme.danger,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '先週比',
                        style: TextStyle(fontSize: 11, color: AppTheme.subtle),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: AppTheme.divider),
          const SizedBox(height: 10),
          Row(
            children: [
              _WeekChip(label: '時間', value: formatDurationShort(thisWeekDuration)),
              const SizedBox(width: 20),
              _WeekChip(label: 'セッション', value: '$thisWeekCount 回'),
              if (hasPrev) ...[
                const SizedBox(width: 20),
                _WeekChip(
                  label: '先週',
                  value: formatYen(lastWeekEarned),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekChip extends StatelessWidget {
  final String label;
  final String value;
  const _WeekChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppTheme.subtle, letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.secondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
}

// ── 日付セクション ────────────────────────────────────
class _DaySection extends StatelessWidget {
  final String dateLabel;
  final List<_SessionWithMeta> sessions;
  const _DaySection({required this.dateLabel, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final dayEarned = sessions.fold(0.0, (s, e) => s + e.session.earned);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateLabel, style: AppTheme.sectionLabel),
              Text(
                formatYen(dayEarned),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.secondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: List.generate(sessions.length, (i) {
              final isFirst = i == 0;
              final isLast = i == sessions.length - 1;
              return _SessionRow(
                meta: sessions[i],
                isFirst: isFirst,
                isLast: isLast,
              );
            }),
          ),
        ),
      ],
    );
  }
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
            // 左：プロジェクト名・時刻
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                    ],
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
                    '${timeFmt.format(s.startTime)} 〜 ${timeFmt.format(s.endTime)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.subtle),
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
                const SizedBox(height: 2),
                // 時給換算
                if (s.duration.inSeconds > 0)
                  Text(
                    '${formatYen(s.earned / (s.duration.inSeconds / 3600))}/h',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.subtle,
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
