import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ── Web ─────────────────────────────────────────────────
  // ※ FirebaseコンソールのWebアプリ設定から取得した値
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCiPo5b4alxc8G5mu3VzPN8n4h9X1AyBGk',
    authDomain: 'timeval-e9a0e.firebaseapp.com',
    projectId: 'timeval-e9a0e',
    storageBucket: 'timeval-e9a0e.firebasestorage.app',
    messagingSenderId: '188140482685',
    appId: '1:188140482685:web:4d1bc0d87d1fa1c0b34114',
  );

  // ── Android ──────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCiPo5b4alxc8G5mu3VzPN8n4h9X1AyBGk',
    authDomain: 'timeval-e9a0e.firebaseapp.com',
    projectId: 'timeval-e9a0e',
    storageBucket: 'timeval-e9a0e.firebasestorage.app',
    messagingSenderId: '188140482685',
    appId: '1:188140482685:android:c5a12d952b94d93cb34114',
  );

  // ── iOS ──────────────────────────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCiPo5b4alxc8G5mu3VzPN8n4h9X1AyBGk',
    authDomain: 'timeval-e9a0e.firebaseapp.com',
    projectId: 'timeval-e9a0e',
    storageBucket: 'timeval-e9a0e.firebasestorage.app',
    messagingSenderId: '188140482685',
    appId: '1:188140482685:ios:placeholder', // iOSアプリ登録後に更新
  );
}
