// Web implementation
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool hasResetParam() {
  final uri = Uri.parse(html.window.location.href);
  return uri.queryParameters.containsKey('reset');
}
