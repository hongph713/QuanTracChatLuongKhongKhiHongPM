// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/material.dart';
//
// class SettingsService {
//   static const String _languageKey = 'selected_language';
//   static const String _themeKey = 'selected_theme';
//   static const String _notificationKey = 'notifications_enabled';
//   static const String _firstLaunchKey = 'first_launch';
//
//   static SettingsService? _instance;
//   static SettingsService get instance => _instance ??= SettingsService._();
//   SettingsService._();
//
//   SharedPreferences? _prefs;
//
//   Future<void> init() async {
//     _prefs = await SharedPreferences.getInstance();
//   }
//
//   // Language settings
//   String get language => _prefs?.getString(_languageKey) ?? 'vi';
//   Future<void> setLanguage(String language) async {
//     await _prefs?.setString(_languageKey, language);
//   }
//
//   // Theme settings
//   String get theme => _prefs?.getString(_themeKey) ?? 'light';
//   Future<void> setTheme(String theme) async {
//     await _prefs?.setString(_themeKey, theme);
//   }
//
//   // Notification settings
//   bool get notificationsEnabled => _prefs?.getBool(_notificationKey) ?? false;
//   Future<void> setNotificationsEnabled(bool enabled) async {
//     await _prefs?.setBool(_notificationKey, enabled);
//   }
//
//   // First launch check
//   bool get isFirstLaunch => _prefs?.getBool(_firstLaunchKey) ?? true;
//   Future<void> setFirstLaunchCompleted() async {
//     await _prefs?.setBool(_firstLaunchKey, false);
//   }
//
//   ThemeMode get themeMode {
//     switch (theme) {
//       case 'dark':
//         return ThemeMode.dark;
//       case 'light':
//       default:
//         return ThemeMode.light;
//     }
//   }
// }