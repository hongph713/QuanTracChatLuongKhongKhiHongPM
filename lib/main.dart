import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'services/locale_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Quan Trắc Không Khí',

            // Sử dụng locale từ LanguageProvider
            locale: languageProvider.currentLocale,

            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('vi'), // Vietnamese
            ],

            theme: ThemeData(
              primarySwatch: Colors.teal,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              useMaterial3: true,
            ),
            home: const AppInitializer(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

// Widget để khởi tạo ngôn ngữ đã lưu
class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load ngôn ngữ đã lưu
    await Provider.of<LanguageProvider>(context, listen: false).loadSavedLanguage();
  }

  @override
  Widget build(BuildContext context) {
    return MainScreen();
  }
}

// // lib/main.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_localizations/flutter_localizations.dart'; // Cho đa ngôn ngữ
// // import 'package:firebase_core/firebase_core.dart'; // Nếu dùng Firebase
// // import 'firebase_options.dart'; // File firebase_options.dart của bạn
//
// import 'screens/main_screen.dart';
// import 'screens/settings_screen/settings_screen.dart'; // Để truy cập các key
// import 'services/theme_provider.dart'; // Import ThemeProvider
// import 'services/locale_provider.dart'; // Import LocaleProvider
// // TODO: Import file generated cho localization (ví dụ: l10n/app_localizations.dart)
// // import 'l10n/app_localizations.dart';
//
//
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // ĐƯỜNG DẪN CHUẨN SAU KHI CHẠY flutter gen-l10n
//
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // await Firebase.initializeApp(
//   //   options: DefaultFirebaseOptions.currentPlatform,
//   // );
//   runApp(const MyAppWrapper());
// }
//
// class MyAppWrapper extends StatelessWidget {
//   const MyAppWrapper({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => ThemeProvider()),
//         ChangeNotifierProvider(create: (_) => LocaleProvider()),
//       ],
//       child: const MyApp(),
//     );
//   }
// }
//
// class MyApp extends StatefulWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _promptForNotificationPermissionIfNeeded(context);
//     });
//   }
//
//   Future<void> _promptForNotificationPermissionIfNeeded(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     bool alreadyShown = prefs.getBool(SettingsScreen.firstTimeNotificationPromptShownKey) ?? false;
//
//     // Lấy AppLocalizations một cách an toàn
//     AppLocalizations? localizations = AppLocalizations.of(context);
//
//     if (!alreadyShown && mounted && localizations != null) { // Thêm kiểm tra localizations != null
//       bool? enableNotifications = await showDialog<bool>(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext dialogContext) {
//           return AlertDialog(
//             title: Text(localizations.importantNotificationTitle), // Sử dụng localized string
//             content: Text(localizations.notificationPermissionPrompt), // Sử dụng localized string
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
//             actionsAlignment: MainAxisAlignment.end,
//             actions: <Widget>[
//               TextButton(
//                 child: Text(localizations.noThanksButton),
//                 onPressed: () => Navigator.of(dialogContext).pop(false),
//               ),
//               TextButton(
//                 child: Text(localizations.yesEnableButton, style: const TextStyle(fontWeight: FontWeight.bold)),
//                 onPressed: () => Navigator.of(dialogContext).pop(true),
//               ),
//             ],
//           );
//         },
//       );
//
//       if (enableNotifications != null) {
//         await prefs.setBool(SettingsScreen.notificationsEnabledKey, enableNotifications);
//         if (enableNotifications) {
//           print("User enabled notifications. TODO: Schedule initial daily notifications.");
//         } else {
//           print("User disabled notifications.");
//         }
//       }
//       await prefs.setBool(SettingsScreen.firstTimeNotificationPromptShownKey, true);
//     } else if (localizations == null && !alreadyShown && mounted) {
//       print("Warning: AppLocalizations not ready for notification prompt dialog.");
//       // Có thể hiển thị dialog với text mặc định nếu muốn
//       // Hoặc đợi cho đến khi AppLocalizations sẵn sàng
//       await prefs.setBool(SettingsScreen.firstTimeNotificationPromptShownKey, true); // Tạm thời đánh dấu đã hiển thị để tránh lặp vô hạn
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final localeProvider = Provider.of<LocaleProvider>(context);
//
//     return MaterialApp(
//       // onGenerateTitle được sử dụng để cung cấp một chuỗi tiêu đề được tạo động,
//       // thường là đã được dịch. Flutter sẽ sử dụng chuỗi này ở những nơi phù hợp
//       // như trong trình quản lý tác vụ của hệ điều hành.
//       onGenerateTitle: (BuildContext context) {
//         // Đảm bảo AppLocalizations đã được tải
//         // Nếu AppLocalizations.of(context) là null, có nghĩa là localization chưa sẵn sàng
//         // Trả về một tiêu đề mặc định trong trường hợp này
//         return AppLocalizations.of(context)?.appTitle ?? 'Quan Trắc Không Khí (Loading)';
//       },
//       // Nếu bạn chỉ muốn một tiêu đề tĩnh không cần dịch động qua onGenerateTitle, bạn có thể dùng:
//       // title: 'Quan Trắc Không Khí',
//
//       theme: themeProvider.lightThemeData,
//       darkTheme: themeProvider.darkThemeData,
//       themeMode: themeProvider.currentThemeMode,
//
//       locale: localeProvider.currentLocale,
//       localizationsDelegates: AppLocalizations.localizationsDelegates,
//       supportedLocales: AppLocalizations.supportedLocales,
//
//       home: const MainScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
