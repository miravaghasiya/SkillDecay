import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class PreferencesService with ChangeNotifier {
  static const String _onboardingKey = 'onboardingCompleted';
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  bool get isOnboardingCompleted => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_onboardingKey, value);
    notifyListeners();
  }
}
