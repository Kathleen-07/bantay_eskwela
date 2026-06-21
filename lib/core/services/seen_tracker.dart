import 'package:shared_preferences/shared_preferences.dart';

/// Tracks when the parent last opened each tab, stored locally on the device.
/// Used to compute unread counts (badges) for News, Events, and Consent.
///
/// "Unread" = items created after the stored "last seen" time for that tab.
/// On first ever launch, all tabs are stamped with the current time so the
/// parent only sees badges for items posted AFTER they start using the app.
class SeenTracker {
  static const _keyNews = 'last_seen_news';
  static const _keyEvents = 'last_seen_events';
  static const _keyConsent = 'last_seen_consent';
  static const _keyInitialized = 'seen_initialized';

  /// Call once on parent app start. (Kept for compatibility — no longer
  /// stamps tabs as seen, so all currently-unopened items count as unread
  /// until the parent opens each tab.)
  static Future<void> ensureInitialized() async {
    // Intentionally does nothing now. Baseline "last seen" is epoch (1970),
    // so every existing announcement/event/consent shows as unread until
    // the parent opens that tab.
  }

  static String _keyFor(SeenTab tab) {
    switch (tab) {
      case SeenTab.news:
        return _keyNews;
      case SeenTab.events:
        return _keyEvents;
      case SeenTab.consent:
        return _keyConsent;
    }
  }

  /// The last time the parent opened this tab.
  static Future<DateTime> lastSeen(SeenTab tab) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyFor(tab)) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Mark this tab as seen now (clears its badge).
  static Future<void> markSeen(SeenTab tab) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFor(tab), DateTime.now().millisecondsSinceEpoch);
  }
}

enum SeenTab { news, events, consent }
