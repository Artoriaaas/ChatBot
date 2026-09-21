import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

enum AppLanguage { vi, en }

class SettingsRepository {
  static const _themeKey = 'paper_ink_theme';
  static const _languageKey = 'paper_ink_language';
  static const _readerFontKey = 'paper_ink_reader_font';
  static const _chatFontKey = 'paper_ink_chat_font';
  static const _reduceMotionKey = 'paper_ink_reduce_motion';
  
  late SharedPreferences _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  AppThemeMode get themeMode {
    final idx = _prefs.getInt(_themeKey) ?? 2; // default: system
    return AppThemeMode.values[idx.clamp(0, 2)];
  }
  Future<void> setThemeMode(AppThemeMode mode) => _prefs.setInt(_themeKey, mode.index);
  
  AppLanguage get language {
    final idx = _prefs.getInt(_languageKey) ?? 0; // default: 0 = vi
    return AppLanguage.values[idx.clamp(0, 1)];
  }
  Future<void> setLanguage(AppLanguage lang) => _prefs.setInt(_languageKey, lang.index);

  double get readerFontSize => _prefs.getDouble(_readerFontKey) ?? 15.0;
  Future<void> setReaderFontSize(double v) => _prefs.setDouble(_readerFontKey, v);
  
  double get chatFontSize => _prefs.getDouble(_chatFontKey) ?? 15.0;
  Future<void> setChatFontSize(double v) => _prefs.setDouble(_chatFontKey, v);
  
  bool get reduceMotion => _prefs.getBool(_reduceMotionKey) ?? false;
  Future<void> setReduceMotion(bool v) => _prefs.setBool(_reduceMotionKey, v);
}
