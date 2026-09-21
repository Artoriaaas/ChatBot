import 'package:flutter/material.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/services/settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _repo;
  
  SettingsViewModel(this._repo);
  
  AppThemeMode get themeMode => _repo.themeMode;
  AppLanguage get language => _repo.language;
  AppStrings get strings => AppStrings(language);

  double get readerFontSize => _repo.readerFontSize;
  double get chatFontSize => _repo.chatFontSize;
  bool get reduceMotion => _repo.reduceMotion;
  
  ThemeMode get flutterThemeMode => switch (themeMode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };
  
  Future<void> setThemeMode(AppThemeMode mode) async {
    await _repo.setThemeMode(mode);
    notifyListeners();
  }
  
  Future<void> setLanguage(AppLanguage lang) async {
    await _repo.setLanguage(lang);
    notifyListeners();
  }

  Future<void> setReaderFontSize(double v) async {
    await _repo.setReaderFontSize(v);
    notifyListeners();
  }
  
  Future<void> setChatFontSize(double v) async {
    await _repo.setChatFontSize(v);
    notifyListeners();
  }
  
  Future<void> setReduceMotion(bool v) async {
    await _repo.setReduceMotion(v);
    notifyListeners();
  }
}
