import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  // Key để lưu trữ lựa chọn ngôn ngữ
  static const String _languagePrefKey = 'language_code_preference';

  Locale _currentLocale = const Locale('vi'); // Mặc định là Tiếng Việt

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    loadSavedLanguage();
  }

  bool isCurrentLanguage(String languageCode) {
    return _currentLocale.languageCode == languageCode;
  }

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languagePrefKey) ?? 'vi';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);

    // <<< THÊM VÀO: LƯU LỰA CHỌN NGÔN NGỮ >>>
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePrefKey, languageCode);

    notifyListeners();
    print("[LanguageProvider] Đã đổi ngôn ngữ sang '$languageCode' và lưu lại.");
  }
}
