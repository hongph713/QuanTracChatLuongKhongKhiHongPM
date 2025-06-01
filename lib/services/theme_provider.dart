// // lib/services/theme_provider.dart
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// // Nên định nghĩa key này ở một nơi chung hoặc đảm bảo nó khớp với SettingsScreen
// const String appThemeKey = 'app_selected_theme_v2';
//
// class ThemeProvider with ChangeNotifier {
//   ThemeMode _themeMode = ThemeMode.light; // Mặc định
//
//   // Cache các đối tượng ThemeData
//   // TODO: Tùy chỉnh các ThemeData này theo thiết kế của bạn
//   final ThemeData _lightTheme = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.light,
//     primarySwatch: Colors.blue,
//     scaffoldBackgroundColor: Colors.grey[100],
//     appBarTheme: AppBarTheme(
//       backgroundColor: Colors.blue[600],
//       foregroundColor: Colors.white, // Màu chữ và icon trên AppBar
//       elevation: 1,
//     ),
//     cardColor: Colors.white,
//     // Thêm các tùy chỉnh khác cho theme sáng
//     // colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
//   );
//
//   final ThemeData _darkTheme = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.dark,
//     primarySwatch: Colors.teal,
//     scaffoldBackgroundColor: Colors.grey[900],
//     appBarTheme: AppBarTheme(
//       backgroundColor: Colors.grey[850],
//       foregroundColor: Colors.white,
//       elevation: 1,
//     ),
//     cardColor: Colors.grey[800],
//     // Thêm các tùy chỉnh khác cho theme tối
//     // colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
//   );
//
//   ThemeMode get currentThemeMode => _themeMode;
//   ThemeData get lightThemeData => _lightTheme;
//   ThemeData get darkThemeData => _darkTheme;
//
//   ThemeProvider() {
//     _loadThemePreference();
//   }
//
//   Future<void> _loadThemePreference() async {
//     final prefs = await SharedPreferences.getInstance();
//     String themePreference = prefs.getString(appThemeKey) ?? 'light'; // Mặc định là 'light'
//     _setThemeModeFromString(themePreference, notify: false); // Không notify ở lần load đầu
//     print("ThemeProvider: Loaded theme preference: $themePreference -> $_themeMode");
//     // Notify sau khi load xong để MaterialApp cập nhật nếu cần
//     // nhưng chỉ khi giá trị ban đầu (mặc định _themeMode = ThemeMode.light) khác với giá trị đã load
//     if ((themePreference == 'dark' && _themeMode != ThemeMode.dark) ||
//         (themePreference == 'system' && _themeMode != ThemeMode.system) ||
//         (themePreference == 'light' && _themeMode != ThemeMode.light) ) {
//       // Thực ra _setThemeModeFromString đã cập nhật _themeMode rồi
//       // Chỉ cần notify nếu giá trị _themeMode đã thay đổi so với giá trị mặc định ban đầu
//       // Cách đơn giản hơn là luôn notify sau khi load, nhưng kiểm tra thay đổi là tốt nhất
//     }
//     // Để đảm bảo UI cập nhật sau khi load, chúng ta có thể gọi notifyListeners() ở đây một cách an toàn
//     // vì đây là lần khởi tạo.
//     Future.microtask(() => notifyListeners());
//   }
//
//   void _setThemeModeFromString(String themeString, {bool notify = false}) {
//     ThemeMode newMode;
//     switch (themeString) {
//       case 'dark':
//         newMode = ThemeMode.dark;
//         break;
//       case 'system':
//         newMode = ThemeMode.system;
//         break;
//       default:
//         newMode = ThemeMode.light;
//     }
//
//     if (_themeMode != newMode) {
//       _themeMode = newMode;
//       if (notify) {
//         notifyListeners();
//       }
//     }
//   }
//
//   Future<void> setThemeMode(String themeCode) async {
//     // themeCode là 'light', 'dark', hoặc 'system'
//     ThemeMode newMode;
//     switch (themeCode) {
//       case 'dark':
//         newMode = ThemeMode.dark;
//         break;
//       case 'system':
//         newMode = ThemeMode.system;
//         break;
//       default:
//         newMode = ThemeMode.light;
//     }
//
//     if (_themeMode != newMode) {
//       _themeMode = newMode;
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(appThemeKey, themeCode);
//       notifyListeners();
//       print("ThemeProvider: Theme mode changed to $_themeMode (saved as '$themeCode')");
//     } else {
//       print("ThemeProvider: Theme mode not changed, already $_themeMode (requested '$themeCode')");
//     }
//   }
// }
