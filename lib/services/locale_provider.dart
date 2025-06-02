import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('vi'); // Mặc định là tiếng Việt

  Locale get currentLocale => _currentLocale;

// Khởi tạo và load ngôn ngữ đã lưu
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('language_code') ?? 'vi';
    _currentLocale = Locale(savedLanguageCode);
    notifyListeners();
  }

// Thay đổi ngôn ngữ
  Future<void> changeLanguage(String languageCode) async {
    if (_currentLocale.languageCode != languageCode) {
      _currentLocale = Locale(languageCode);

      // Lưu vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);

      notifyListeners();
    }
  }

// Kiểm tra xem có phải ngôn ngữ hiện tại không
  bool isCurrentLanguage(String languageCode) {
    return _currentLocale.languageCode == languageCode;
  }
}