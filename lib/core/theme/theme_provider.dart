import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'IsDarkMode';

  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeProvider() {
    getPreferences();
  }

  set isDark(bool value) {
    _isDark = value;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(_themeKey, value));
  }

  getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }
}
