// // lib/services/locale_provider.dart
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// // Nên định nghĩa key này ở một nơi chung hoặc đảm bảo nó khớp với SettingsScreen
// const String appLangKey = 'app_selected_language_v2';
//
// class LocaleProvider with ChangeNotifier {
//   Locale _locale = const Locale('vi'); // Mặc định Tiếng Việt
//
//   Locale get currentLocale => _locale;
//
//   static const List<Locale> supportedLocalesList = [
//     Locale('vi', ''), // Tiếng Việt
//     Locale('en', ''), // Tiếng Anh
//   ];
//
//   LocaleProvider() {
//     _loadLocalePreference();
//   }
//
//   Future<void> _loadLocalePreference() async {
//     final prefs = await SharedPreferences.getInstance();
//     String languageCode = prefs.getString(appLangKey) ?? 'vi';
//
//     Locale newLocale = const Locale('vi'); // Mặc định fallback
//     if (supportedLocalesList.any((locale) => locale.languageCode == languageCode)) {
//       newLocale = Locale(languageCode);
//     }
//
//     if (_locale != newLocale) {
//       _locale = newLocale;
//       // Notify sau khi load xong để MaterialApp cập nhật nếu cần
//       // nhưng chỉ khi giá trị ban đầu khác với giá trị đã load
//     }
//     print("LocaleProvider: Loaded locale preference: $languageCode -> $_locale");
//     // Để đảm bảo UI cập nhật sau khi load, chúng ta có thể gọi notifyListeners() ở đây một cách an toàn
//     Future.microtask(() => notifyListeners());
//   }
//
//   Future<void> setLocale(String languageCode) async {
//     Locale newLocaleCandidate = _locale;
//
//     if (supportedLocalesList.any((locale) => locale.languageCode == languageCode)) {
//       newLocaleCandidate = Locale(languageCode);
//     } else {
//       print("LocaleProvider: Attempted to set unsupported locale: $languageCode. Keeping current: $_locale");
//       return;
//     }
//
//     if (_locale != newLocaleCandidate) {
//       _locale = newLocaleCandidate;
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(appLangKey, languageCode);
//       notifyListeners();
//       print("LocaleProvider: Locale changed to $_locale");
//     } else {
//       print("LocaleProvider: Locale not changed, already $_locale (requested '$languageCode')");
//     }
//   }
// }
