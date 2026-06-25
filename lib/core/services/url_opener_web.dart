// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Opens [url] in a new browser tab. Uses window.open directly so the
/// call stays within the user-gesture context and is NOT blocked by the
/// popup blocker (which silently kills url_launcher's new-tab attempts
/// on web when they happen after an await).
Future<bool> openUrlWeb(String url) async {
  final win = html.window.open(url, '_blank');
  // window.open returns a WindowBase; if blocked it can be null-ish.
  return win != null;
}
