import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';
import '../models/salary_settings.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class AppProvider extends ChangeNotifier {
  // ── プロジェクト管理 ──────────────────────────────────
  List<Project> _projects = [];
  int _activeIndex = 0;

  // ── ロード完了フラグ ──────────────────────────────────
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // ── タイマー ──────────────────────────────────────────
  Timer? _ticker;

  // ── Getters ───────────────────────────────────────────
  List<Project> get projects => List.unmodifiable(_projects);
  int get activeIndex => _activeIndex;
  Project get activeProject => _projects[_activeIndex];

  // onboardingDone は廃止：ログイン状態のみで判定する
  bool get onboardingDone => false; // 後方互換のため残すが常にfalse

  /// 動作中のプロジェクト数
  int get runningCount => _projects.where((p) => p.isRunning).length;

  AppProvider() {
    _load();
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

  void reset(int index) {
    if (index < 0 || index >= _projects.length) return;
    final p = _projects[index];

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

  // ── 永続化（プロジェクトデータのみ）────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

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

    while (_projects.length < 3) {
      _projects.add(Project.createDefault(_projects.length));
    }
    if (_projects.length > 3) {
      _projects = _projects.sublist(0, 3);
    }

    if (_projects.any((p) => p.isRunning)) {
      _ensureTicker();
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveProjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'projects_v2',
      _projects.map((p) => jsonEncode(p.toMap())).toList(),
    );
    if (AuthService.uid != null) {
      FirestoreService.saveProjects(_projects);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
