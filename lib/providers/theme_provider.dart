import 'package:flutter/material.dart';
import '../services/database_service.dart';

/// Provider for managing app theme mode (Light, Dark, System) and persisting user choice.
class ThemeProvider extends ChangeNotifier {
  final DatabaseService _dbService;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider(this._dbService) {
    _loadThemePreference();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemePreference() async {
    try {
      final String? saved = await _dbService.getPreference('themeMode');
      if (saved != null) {
        switch (saved) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            _themeMode = ThemeMode.system;
            break;
        }
        notifyListeners();
      }
    } catch (_) {
      // Fallback silently to system mode
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final String value = mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
              ? 'dark'
              : 'system';
      await _dbService.setPreference('themeMode', value);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}
