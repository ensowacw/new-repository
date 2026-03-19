import 'salary_settings.dart';

/// ストップウォッチの状態
enum TimerStatus { idle, running, paused }

/// 1つのプロジェクト（案件）を表すモデル
class Project {
  final String id;
  final String name;         // プロジェクト名
  final SalarySettings settings;
  final TimerStatus status;

  /// 累積経過時間（一時停止分を含む）
  final Duration accumulated;

  /// 現在の計測開始時刻（running中のみ non-null）
  final DateTime? startedAt;

  /// セッション履歴（このプロジェクトの停止記録）
  final List<ProjectSession> sessions;

  const Project({
    required this.id,
    required this.name,
    required this.settings,
    this.status = TimerStatus.idle,
    this.accumulated = Duration.zero,
    this.startedAt,
    this.sessions = const [],
  });

  /// 現在の合計経過時間（リアルタイム）
  Duration get elapsed {
    if (status == TimerStatus.running && startedAt != null) {
      return accumulated + DateTime.now().difference(startedAt!);
    }
    return accumulated;
  }

  /// 獲得金額 or 実質時給（モードによって使い分け）
  double get currentEarned {
    final secs = elapsed.inMilliseconds / 1000.0;
    return settings.hourlyRate * secs / 3600.0;
  }

  /// 案件モード：実質時給
  double get projectHourlyRate {
    final hours = elapsed.inMilliseconds / 1000.0 / 3600.0;
    if (hours <= 0) return settings.projectAmount;
    return settings.projectAmount / hours;
  }

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused  => status == TimerStatus.paused;
  bool get isIdle    => status == TimerStatus.idle;
  bool get hasStarted => status != TimerStatus.idle || accumulated > Duration.zero;

  Project copyWith({
    String? id,
    String? name,
    SalarySettings? settings,
    TimerStatus? status,
    Duration? accumulated,
    DateTime? startedAt,
    bool clearStartedAt = false,
    List<ProjectSession>? sessions,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      accumulated: accumulated ?? this.accumulated,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      sessions: sessions ?? this.sessions,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'settings': settings.toMap(),
        'status': status.index,
        'accumulatedMs': accumulated.inMilliseconds,
        'startedAt': startedAt?.toIso8601String(),
        'sessions': sessions.map((s) => s.toMap()).toList(),
      };

  factory Project.fromMap(Map<String, dynamic> map) {
    // running状態で保存されていた場合、paused扱いに（再起動時の安全処理）
    final savedStatus = TimerStatus.values[map['status'] as int? ?? 0];
    final startedAtStr = map['startedAt'] as String?;
    final startedAt = startedAtStr != null ? DateTime.parse(startedAtStr) : null;

    // バックグラウンド継続：running状態で保存されていた場合は
    // startedAt から経過時間を加算して accumulated に反映
    Duration accMs = Duration(milliseconds: map['accumulatedMs'] as int? ?? 0);
    TimerStatus status = savedStatus;
    DateTime? resolvedStartedAt = startedAt;

    if (savedStatus == TimerStatus.running && startedAt != null) {
      // アプリが閉じられた後も時間を継続カウント
      final extra = DateTime.now().difference(startedAt);
      accMs = accMs + extra;
      // running状態を維持（startedAtを現在時刻にリセット）
      resolvedStartedAt = DateTime.now();
    }

    return Project(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'プロジェクト',
      settings: SalarySettings.fromMap(
          Map<String, dynamic>.from(map['settings'] as Map)),
      status: status,
      accumulated: accMs,
      startedAt: resolvedStartedAt,
      sessions: ((map['sessions'] as List?) ?? [])
          .map((e) => ProjectSession.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// デフォルトプロジェクト生成
  static Project createDefault(int index) {
    final names = ['プロジェクト 1', 'プロジェクト 2', 'プロジェクト 3'];
    return Project(
      id: 'project_$index',
      name: names[index],
      settings: const SalarySettings(),
    );
  }
}

/// プロジェクト内の1セッション（停止するたびに記録）
class ProjectSession {
  final DateTime startTime;
  final DateTime endTime;
  final double earned;
  final Duration duration;

  const ProjectSession({
    required this.startTime,
    required this.endTime,
    required this.earned,
    required this.duration,
  });

  Map<String, dynamic> toMap() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'earned': earned,
        'durationMs': duration.inMilliseconds,
      };

  factory ProjectSession.fromMap(Map<String, dynamic> map) => ProjectSession(
        startTime: DateTime.parse(map['startTime'] as String),
        endTime: DateTime.parse(map['endTime'] as String),
        earned: (map['earned'] as num).toDouble(),
        duration: Duration(milliseconds: map['durationMs'] as int? ?? 0),
      );
}
