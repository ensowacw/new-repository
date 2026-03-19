import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../models/salary_settings.dart';

// Webのみ: URLクエリパラメータを取得するためのコンディショナルインポート
import 'url_helper_stub.dart'
    if (dart.library.html) 'url_helper_web.dart';

class AppProvider extends ChangeNotifier {
  // ── プロジェクト管理 ──────────────────────────────────
  List<Project> _projects = [];
  int _activeIndex = 0; // 現在表示中のプロジェクトindex

  // ── オンボーディング ──────────────────────────────────
  bool _onboardingDone = false;

  // ── タイマー ──────────────────────────────────────────
  Timer? _ticker;

  // ── Getters ───────────────────────────────────────────
  List<Project> get projects => List.unmodifiable(_projects);
  int get activeIndex => _activeIndex;
  Project get activeProject => _projects[_activeIndex];
  bool get onboardingDone => _onboardingDone;

  /// 動作中のプロジェクト数
  int get runningCount => _projects.where((p) => p.isRunning).length;

  AppProvider() {
    _load();
  }

  // ── オンボーディング ──────────────────────────────────
  void completeOnboarding() {
    _onboardingDone = true;
    _saveOnboarding();
    notifyListeners();
  }

  // ── プロジェクト切り替え ──────────────────────────────
  void setActiveIndex(int index) {
    if (index < 0 || index >= _projects.length) return;
    _activeIndex = index;
    notifyListeners();
  }

  // ── プロジェクト名・設定の更新 ──────────────────────
  void updateProjectName(int index, String name) {
    if (index < 0 || index >= _projects.length) return;
    _projects[index] = _projects[index].copyWith(name: name);
    _saveProjects();
    notifyListeners();
  }

  void updateProjectSettings(int index, SalarySettings settings) {
    if (index < 0 || index >= _projects.length) return;
    _projects[index] = _projects[index].copyWith(settings: settings);
    _saveProjects();
    notifyListeners();
  }

  // ── タイマー操作 ──────────────────────────────────────

  /// スタート（idle/paused → running）
  void start(int index) {
    if (index < 0 || index >= _projects.length) return;
    final p = _projects[index];
    if (p.isRunning) return;

    _projects[index] = p.copyWith(
      status: TimerStatus.running,
      startedAt: DateTime.now(),
    );
    _ensureTicker();
    _saveProjects();
    notifyListeners();
  }

  /// 一時停止（running → paused）
  void pause(int index) {
    if (index < 0 || index >= _projects.length) return;
    final p = _projects[index];
    if (!p.isRunning) return;

    final now = DateTime.now();
    final extra = p.startedAt != null
        ? now.difference(p.startedAt!)
        : Duration.zero;

    _projects[index] = p.copyWith(
      status: TimerStatus.paused,
      accumulated: p.accumulated + extra,
      clearStartedAt: true,
    );
    _maybeStopTicker();
    _saveProjects();
    notifyListeners();
  }

  /// リセット（全停止してゼロに戻す）＋セッション保存
  void reset(int index) {
    if (index < 0 || index >= _projects.length) return;
    final p = _projects[index];

    // セッション保存
    List<ProjectSession> newSessions = List.from(p.sessions);
    if (p.elapsed.inSeconds > 0) {
      newSessions.insert(
        0,
        ProjectSession(
          startTime: p.startedAt ??
              DateTime.now().subtract(p.accumulated),
          endTime: DateTime.now(),
          earned: p.settings.mode == SalaryMode.project
              ? p.settings.projectAmount
              : p.currentEarned,
          duration: p.elapsed,
        ),
      );
      // 最新10件のみ保持
      if (newSessions.length > 10) {
        newSessions = newSessions.sublist(0, 10);
      }
    }

    _projects[index] = p.copyWith(
      status: TimerStatus.idle,
      accumulated: Duration.zero,
      clearStartedAt: true,
      sessions: newSessions,
    );
    _maybeStopTicker();
    _saveProjects();
    notifyListeners();
  }

  // ── プロジェクトのリセット（履歴も含めてクリア）──────
  void clearProject(int index) {
    if (index < 0 || index >= _projects.length) return;
    final p = _projects[index];
    if (p.isRunning) pause(index);
    _projects[index] = Project.createDefault(index).copyWith(
      name: p.name,
      settings: p.settings,
    );
    _saveProjects();
    notifyListeners();
  }

  // ── 内部タイマー管理 ──────────────────────────────────
  void _ensureTicker() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      notifyListeners();
    });
  }

  void _maybeStopTicker() {
    if (runningCount == 0) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  // ── 永続化 ────────────────────────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Web: URLに ?reset=1 があればオンボーディングをリセット
    if (kIsWeb && hasResetParam()) {
      await prefs.setBool('onboarding_done', false);
    }

    _onboardingDone = prefs.getBool('onboarding_done') ?? false;

    final raw = prefs.getStringList('projects_v2');
    if (raw != null && raw.isNotEmpty) {
      _projects = raw.map((e) {
        try {
          return Project.fromMap(
              Map<String, dynamic>.from(jsonDecode(e) as Map));
        } catch (_) {
          return null;
        }
      }).whereType<Project>().toList();
    }

    // 3プロジェクト未満なら補完
    while (_projects.length < 3) {
      _projects.add(Project.createDefault(_projects.length));
    }
    if (_projects.length > 3) {
      _projects = _projects.sublist(0, 3);
    }

    // running中のプロジェクトがあればタイマー再開
    if (_projects.any((p) => p.isRunning)) {
      _ensureTicker();
    }

    notifyListeners();
  }

  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'projects_v2',
      _projects.map((p) => jsonEncode(p.toMap())).toList(),
    );
  }

  Future<void> _saveOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
