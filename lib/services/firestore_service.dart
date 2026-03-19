import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/project.dart';
import 'auth_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ユーザーのプロジェクトコレクション参照
  static CollectionReference<Map<String, dynamic>> _projectsRef(String uid) =>
      _db.collection('users').doc(uid).collection('projects');

  /// プロジェクトリストをFirestoreに保存
  static Future<void> saveProjects(List<Project> projects) async {
    final uid = AuthService.uid;
    if (uid == null) return;

    try {
      final batch = _db.batch();
      final ref = _projectsRef(uid);

      for (int i = 0; i < projects.length; i++) {
        final p = projects[i];
        batch.set(ref.doc('project_$i'), {
          'id': p.id,
          'name': p.name,
          'settings': p.settings.toMap(),
          'status': p.status.index,
          'accumulatedMs': p.accumulated.inMilliseconds,
          'startedAt': p.startedAt?.toIso8601String(),
          'sessions': p.sessions.map((s) => s.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Firestore save error: $e');
    }
  }

  /// Firestoreからプロジェクトリストを読み込み
  static Future<List<Project>?> loadProjects() async {
    final uid = AuthService.uid;
    if (uid == null) return null;

    try {
      final snapshot = await _projectsRef(uid).get();
      if (snapshot.docs.isEmpty) return null;

      // id順でソート
      final docs = snapshot.docs.toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      return docs.map((doc) {
        final data = doc.data();
        return Project.fromMap(Map<String, dynamic>.from(data));
      }).toList();
    } catch (e) {
      debugPrint('Firestore load error: $e');
      return null;
    }
  }
}
