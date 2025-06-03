// lib/services/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  ThemeMode _themeMode = ThemeMode.system; // Mặc định là theo hệ thống

  ThemeMode get currentThemeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode(); // Tải chủ đề đã lưu khi khởi tạo
  }

  // Tải chủ đề từ SharedPreferences
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeModeKey);
    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system; // Mặc định nếu chưa có gì được lưu hoặc giá trị không hợp lệ
    }
    notifyListeners(); // Thông báo cho các widget đang lắng nghe
  }

  // Lưu chủ đề vào SharedPreferences và cập nhật trạng thái
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // Không làm gì nếu chủ đề không thay đổi

    _themeMode = mode;
    notifyListeners(); // Thông báo ngay để UI cập nhật

    final prefs = await SharedPreferences.getInstance();
    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
      default:
        themeString = 'system';
        break;
    }
    await prefs.setString(_themeModeKey, themeString);
  }
}