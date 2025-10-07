import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryStorage {
  SearchHistoryStorage(this._preferences);

  static const String _key = 'RECENT_SEARCH_HISTORY';

  final SharedPreferences _preferences;

  Future<List<String>> loadHistory() async {
    try {
      return _preferences.getStringList(_key) ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> saveHistory(List<String> history) async {
    await _preferences.setStringList(_key, history);
  }

  Future<void> clearHistory() async {
    await _preferences.remove(_key);
  }
}
