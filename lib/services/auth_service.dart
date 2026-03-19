import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 現在のユーザー
  static User? get currentUser => _auth.currentUser;

  /// 認証状態ストリーム
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Googleサインイン
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: リダイレクト方式（GitHub PagesはPopupがブロックされるためRedirectを使用）
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        await _auth.signInWithRedirect(googleProvider);
        return null; // リダイレクト後に自動でauthStateChangesが更新される
      } else {
        // モバイル: ネイティブGoogle認証
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // ユーザーがキャンセル

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// サインアウト
  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      if (!kIsWeb) _googleSignIn.signOut(),
    ]);
  }

  /// ユーザー表示名
  static String get displayName =>
      currentUser?.displayName ?? currentUser?.email ?? 'ユーザー';

  /// ユーザーメール
  static String? get email => currentUser?.email;

  /// ユーザーUID
  static String? get uid => currentUser?.uid;
}
