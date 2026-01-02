import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  late SharedPreferences _prefs;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Initialize and load saved theme
  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    // Read from memory (default to false/light if nothing saved)
    bool isDark = _prefs.getBool('is_dark') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _isLoaded = true;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      if (_isLoaded) _prefs.setBool('is_dark', true); // Save "True"
    } else {
      _themeMode = ThemeMode.light;
      if (_isLoaded) _prefs.setBool('is_dark', false); // Save "False"
    }
    notifyListeners();
  }
}