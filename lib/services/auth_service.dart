import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザー
  static User? get currentUser => _auth.currentUser;

  /// 認証状態ストリーム
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Googleサインイン
  /// Web: signInWithPopup（ポップアップ）
  /// Mobile: signInWithPopup
  static Future<UserCredential?> signInWithGoogle() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    if (kIsWeb) {
      // Web: ポップアップでサインイン（リダイレクトはページリロードを起こすため使わない）
      final result = await _auth.signInWithPopup(googleProvider);
      return result;
    } else {
      // モバイル: ポップアップ
      final result = await _auth.signInWithPopup(googleProvider);
      return result;
    }
  }

  /// サインアウト
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// ユーザー表示名
  static String get displayName =>
      currentUser?.displayName ?? currentUser?.email ?? 'ユーザー';

  /// ユーザーメール
  static String? get email => currentUser?.email;

  /// ユーザーUID
  static String? get uid => currentUser?.uid;
}
