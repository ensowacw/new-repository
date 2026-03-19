import 'package:intl/intl.dart';

final _yenFmt = NumberFormat('#,###', 'ja_JP');
final _yenDecFmt = NumberFormat('#,###.##', 'ja_JP');

String formatYen(double amount, {bool showDecimal = false}) {
  if (showDecimal) {
    // 小数点以下が0なら整数表示
    if (amount == amount.floorToDouble()) {
      return '¥${_yenFmt.format(amount.floor())}';
    }
    return '¥${_yenDecFmt.format(amount)}';
  }
  return '¥${_yenFmt.format(amount.floor())}';
}

/// 大きな数字を読みやすく（万単位）
String formatYenCompact(double amount) {
  if (amount >= 10000) {
    final man = amount / 10000;
    return '¥${man.toStringAsFixed(man >= 10 ? 0 : 1)}万';
  }
  return formatYen(amount);
}

String formatDuration(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String formatDurationShort(Duration d) {
  if (d.inHours > 0) {
    return '${d.inHours}時間${d.inMinutes % 60}分';
  }
  if (d.inMinutes > 0) {
    return '${d.inMinutes}分${d.inSeconds % 60}秒';
  }
  return '${d.inSeconds}秒';
}
