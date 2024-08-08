import 'package:flutter/material.dart';
import 'package:pet_feeder_esp_ui/core/theme/theme_preference.dart';

class ThemeProvider extends ChangeNotifier {
  late bool _isDark;
  late ThemePreference _preference;
  bool get isDark => _isDark;

  ThemeProvider() {
    _isDark = false;
    _preference = ThemePreference();
    getPreferences();
  }
  set isDark(bool value) {
    _isDark = value;
    _preference.setTheme(value);
    notifyListeners();
  }

  getPreferences() async {
    _isDark = await _preference.getTheme();
    notifyListeners();
  }
}
