// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:provider/provider.dart';
// import 'screens/main_screen.dart';
// import 'services/locale_provider.dart';
// import 'firebase_options.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => LanguageProvider()),
//       ],
//       child: Consumer<LanguageProvider>(
//         builder: (context, languageProvider, child) {
//           return MaterialApp(
//             title: 'Quan Trắc Không Khí',
//
//             // Sử dụng locale từ LanguageProvider
//             locale: languageProvider.currentLocale,
//
//             localizationsDelegates: const [
//               AppLocalizations.delegate,
//               GlobalMaterialLocalizations.delegate,
//               GlobalWidgetsLocalizations.delegate,
//               GlobalCupertinoLocalizations.delegate,
//             ],
//             supportedLocales: const [
//               Locale('en'), // English
//               Locale('vi'), // Vietnamese
//             ],
//
//             theme: ThemeData(
//               primarySwatch: Colors.teal,
//               visualDensity: VisualDensity.adaptivePlatformDensity,
//               useMaterial3: true,
//             ),
//             home: const AppInitializer(),
//             debugShowCheckedModeBanner: false,
//           );
//         },
//       ),
//     );
//   }
// }
//
// // Widget để khởi tạo ngôn ngữ đã lưu
// class AppInitializer extends StatefulWidget {
//   const AppInitializer({Key? key}) : super(key: key);
//
//   @override
//   State<AppInitializer> createState() => _AppInitializerState();
// }
//
// class _AppInitializerState extends State<AppInitializer> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }
//
//   Future<void> _initializeApp() async {
//     // Load ngôn ngữ đã lưu
//     await Provider.of<LanguageProvider>(context, listen: false).loadSavedLanguage();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MainScreen();
//   }
// }
//

// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:provider/provider.dart';
// import 'screens/main_screen.dart'; // Màn hình chính của bạn
// import 'services/locale_provider.dart'; // Provider quản lý ngôn ngữ
// import 'services/theme_provider.dart';  // << Import ThemeProvider của bạn
// import 'firebase_options.dart';
// // import 'theme/app_theme.dart'; // << (Tùy chọn) Import file định nghĩa theme chi tiết
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => LanguageProvider()),
//         ChangeNotifierProvider(create: (_) => ThemeProvider()), // << Thêm ThemeProvider
//       ],
//       child: Consumer2<LanguageProvider, ThemeProvider>( // << Sử dụng Consumer2 để lắng nghe cả hai
//         builder: (context, languageProvider, themeProvider, child) {
//           return MaterialApp(
//             title: 'Quan Trắc Không Khí',
//
//             // Sử dụng locale từ LanguageProvider
//             locale: languageProvider.currentLocale,
//
//             localizationsDelegates: const [
//               AppLocalizations.delegate,
//               GlobalMaterialLocalizations.delegate,
//               GlobalWidgetsLocalizations.delegate,
//               GlobalCupertinoLocalizations.delegate,
//             ],
//             supportedLocales: const [
//               Locale('en'), // English
//               Locale('vi'), // Vietnamese
//             ],
//
//             // --- Tích hợp Theme ---
//             theme: ThemeData( // Chủ đề sáng cơ bản (hoặc AppTheme.lightTheme nếu bạn tạo file riêng)
//               brightness: Brightness.light,
//               primarySwatch: Colors.teal, // Giữ nguyên màu teal cho sáng hoặc tùy chỉnh
//               visualDensity: VisualDensity.adaptivePlatformDensity,
//               useMaterial3: true,
//               // Thêm các tùy chỉnh khác cho chủ đề sáng nếu muốn
//               // Ví dụ:
//               // scaffoldBackgroundColor: Colors.white,
//               // colorScheme: ColorScheme.light(
//               //   primary: Colors.teal,
//               //   secondary: Colors.amber,
//               // ),
//             ),
//             darkTheme: ThemeData( // Chủ đề tối cơ bản (hoặc AppTheme.darkTheme)
//               brightness: Brightness.dark,
//               primarySwatch: Colors.teal, // Bạn có thể chọn màu khác cho chủ đề tối
//               visualDensity: VisualDensity.adaptivePlatformDensity,
//               useMaterial3: true,
//               // Thêm các tùy chỉnh khác cho chủ đề tối
//               // Ví dụ:
//               // scaffoldBackgroundColor: Colors.grey[850],
//               // colorScheme: ColorScheme.dark(
//               //   primary: Colors.teal[700]!,
//               //   secondary: Colors.orangeAccent,
//               // ),
//             ),
//             themeMode: themeProvider.currentThemeMode, // << Lấy themeMode từ ThemeProvider
//             // --- Kết thúc tích hợp Theme ---
//
//             home: const AppInitializer(),
//             debugShowCheckedModeBanner: false,
//           );
//         },
//       ),
//     );
//   }
// }
//
// // Widget để khởi tạo các dịch vụ cần thiết (bao gồm cả ngôn ngữ)
// class AppInitializer extends StatefulWidget {
//   const AppInitializer({Key? key}) : super(key: key);
//
//   @override
//   State<AppInitializer> createState() => _AppInitializerState();
// }
//
// class _AppInitializerState extends State<AppInitializer> {
//   bool _isInitialized = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }
//
//   Future<void> _initializeApp() async {
//     // Load ngôn ngữ đã lưu
//     // Không cần listen vì đây là quá trình khởi tạo, widget này sẽ không rebuild dựa trên thay đổi này
//     await Provider.of<LanguageProvider>(context, listen: false).loadSavedLanguage();
//
//     // ThemeProvider đã tự động load theme trong constructor của nó,
//     // nên không cần gọi thêm ở đây trừ khi bạn có logic khởi tạo đặc biệt.
//
//     // Đánh dấu đã khởi tạo xong để build MainScreen
//     if (mounted) {
//       setState(() {
//         _isInitialized = true;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Chỉ hiển thị MainScreen sau khi các dịch vụ đã được khởi tạo
//     // Điều này giúp tránh lỗi khi truy cập Provider trước khi chúng sẵn sàng
//     if (_isInitialized) {
//       return MainScreen();
//     } else {
//       // Hiển thị một màn hình loading trong khi chờ
//       return Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }
//   }
// }

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/main_screen.dart'; // Màn hình chính của bạn
import 'services/locale_provider.dart'; // Provider quản lý ngôn ngữ
import 'services/theme_provider.dart';  // Provider quản lý theme

// Import các service mới cho thông báo và tác vụ nền
import 'services/notification_service.dart';
import 'services/background_service.dart';

import 'firebase_options.dart'; // Đảm bảo file này tồn tại và đúng

// (Tùy chọn) Tạo instance toàn cục cho các service để dễ truy cập từ nhiều nơi,
// bao gồm cả từ màn hình Cài đặt hoặc các nút test.
// Nếu bạn dùng GetIt hoặc một DI container khác, bạn có thể đăng ký chúng ở đó.
final NotificationService notificationService = NotificationService();
final BackgroundTaskService backgroundTaskService = BackgroundTaskService();

void main() async {
  // Đảm bảo Flutter bindings đã được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("[main.dart] Firebase initialized.");

  // Khởi tạo Notification Service (cho main isolate)
  // Việc này cần thiết để đăng ký kênh thông báo và xin quyền (nếu cần).
  await notificationService.initializeLocalNotifications();
  print("[main.dart] NotificationService initialized for main isolate.");

  // Khởi tạo Background Task Service (WorkManager)
  // Việc này sẽ đăng ký callbackDispatcher với hệ điều hành.
  await backgroundTaskService.initializeWorkManager();
  print("[main.dart] BackgroundTaskService (WorkManager) initialized.");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // (Tùy chọn) Nếu bạn dùng onDidReceiveNotificationResponse để điều hướng
  // static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, languageProvider, themeProvider, child) {
          return MaterialApp(
            title: 'Quan Trắc Không Khí',
            // navigatorKey: MyApp.navigatorKey, // (Tùy chọn) Cho điều hướng từ notification

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
              brightness: Brightness.light,
              primarySwatch: Colors.teal,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.teal,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              useMaterial3: true,
            ),
            themeMode: themeProvider.currentThemeMode,
            home: const AppInitializer(), // AppInitializer của bạn vẫn giữ nguyên
            debugShowCheckedModeBanner: false,
            // routes: { // (Tùy chọn) Nếu bạn điều hướng từ notification payload
            //   '/stationDetail': (context) {
            //      final String? payload = ModalRoute.of(context)?.settings.arguments as String?;
            //      // return StationDetailScreen(payload: payload); // Ví dụ
            //      return Scaffold(appBar: AppBar(title: Text("Chi tiết trạm")), body: Center(child: Text("Payload: $payload")));
            //   }
            // },
          );
        },
      ),
    );
  }
}

// Widget AppInitializer của bạn giữ nguyên, nó xử lý việc load ngôn ngữ
// và các khởi tạo khác sau khi app đã chạy.
class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load ngôn ngữ đã lưu
    await Provider.of<LanguageProvider>(context, listen: false).loadSavedLanguage();

    // ThemeProvider đã tự động load theme trong constructor hoặc init của nó.

    // Các dịch vụ notificationService và backgroundTaskService đã được khởi tạo trong main().
    // Không cần khởi tạo lại ở đây.

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return MainScreen(); // Hoặc màn hình chính của bạn
    } else {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}