import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  static const String _rcKey = 'api_base_url';
  static const String _prefsKey = 'remote_api_base_url';

  final SharedPreferences _prefs;

  RemoteConfigService(this._prefs);

  Future<String?> getCachedUrl() async => _prefs.getString(_prefsKey);

  Future<String?> fetchAndCache() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 60),
        minimumFetchInterval: Duration.zero,
      ));
      await rc.setDefaults({_rcKey: ''});
      await rc.fetchAndActivate();
      final url = rc.getString(_rcKey);
      if (url.isNotEmpty) {
        final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
        await _prefs.setString(_prefsKey, cleanUrl);
        return cleanUrl;
      }
    } catch (_) {}
    return null;
  }
}
