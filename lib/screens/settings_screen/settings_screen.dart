// import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:provider/provider.dart';
// import 'package:datn_20242/services/locale_provider.dart'; // Đường dẫn đến file locale_provider.dart
//
// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({Key? key}) : super(key: key);
//
//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }
//
// class _SettingsScreenState extends State<SettingsScreen> {
//   String selectedTheme = 'light';
//   bool notificationsEnabled = true;
//
//   final List<Map<String, String>> languages = [
//     {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
//     {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
//   ];
//
//   final List<Map<String, dynamic>> themes = [
//     {'code': 'light', 'name': 'light', 'icon': Icons.wb_sunny},
//     {'code': 'dark', 'name': 'dark', 'icon': Icons.nightlight_round},
//     {'code': 'system', 'name': 'system', 'icon': Icons.settings},
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context);
//
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 1,
//         title: Text(
//           l10n?.settingsTitle ?? 'Cài đặt',
//           style: const TextStyle(
//             color: Colors.black,
//             fontSize: 20,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         leading: Container(
//           margin: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.grey[100],
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Giao diện Section
//             _buildSectionTitle(l10n?.interfaceSectionTitle ?? 'Giao diện'),
//             const SizedBox(height: 12),
//             _buildLanguageItem(),
//             const SizedBox(height: 12),
//             _buildThemeItem(),
//
//             const SizedBox(height: 32),
//
//             // Thông báo Section
//             _buildSectionTitle(l10n?.notificationsSectionTitle ?? 'Thông báo'),
//             const SizedBox(height: 12),
//             _buildNotificationItem(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.w600,
//         color: Colors.black87,
//       ),
//     );
//   }
//
//   Widget _buildLanguageItem() {
//     final l10n = AppLocalizations.of(context);
//
//     return Consumer<LanguageProvider>(
//       builder: (context, languageProvider, child) {
//         final currentLanguage = languages.firstWhere(
//               (lang) => lang['code'] == languageProvider.currentLocale.languageCode,
//         );
//
//         // Lấy tên ngôn ngữ theo localization
//         String getLanguageName(String languageCode) {
//           if (languageCode == 'vi') {
//             return l10n?.vietnameseLanguage ?? 'Tiếng Việt';
//           } else {
//             return l10n?.englishLanguage ?? 'English';
//           }
//         }
//
//         return _buildSettingItem(
//           icon: Icons.language,
//           iconColor: Colors.blue,
//           title: l10n?.languageSettingTitle ?? 'Ngôn ngữ',
//           subtitle: getLanguageName(languageProvider.currentLocale.languageCode),
//           trailing: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 currentLanguage['flag']!,
//                 style: const TextStyle(fontSize: 20),
//               ),
//               const SizedBox(width: 8),
//               const Icon(Icons.chevron_right, color: Colors.grey),
//             ],
//           ),
//           onTap: () => _showLanguageModal(),
//         );
//       },
//     );
//   }
//
//   Widget _buildThemeItem() {
//     final l10n = AppLocalizations.of(context);
//     final currentTheme = themes.firstWhere(
//           (theme) => theme['code'] == selectedTheme,
//     );
//
//     // Lấy tên theme theo ngôn ngữ hiện tại
//     String getThemeName(String themeCode) {
//       switch (themeCode) {
//         case 'light':
//           return l10n?.lightTheme ?? 'Sáng';
//         case 'dark':
//           return l10n?.darkTheme ?? 'Tối';
//         case 'system':
//           return l10n?.systemTheme ?? 'Theo hệ thống';
//         default:
//           return l10n?.lightTheme ?? 'Sáng';
//       }
//     }
//
//     return _buildSettingItem(
//       icon: Icons.palette,
//       iconColor: Colors.purple,
//       title: l10n?.themeSettingTitle ?? 'Chủ đề',
//       subtitle: getThemeName(selectedTheme),
//       trailing: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 24,
//             height: 24,
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               currentTheme['icon'],
//               size: 16,
//               color: _getThemeIconColor(selectedTheme),
//             ),
//           ),
//           const SizedBox(width: 8),
//           const Icon(Icons.chevron_right, color: Colors.grey),
//         ],
//       ),
//       onTap: () => _showThemeModal(),
//     );
//   }
//
//   Color _getThemeIconColor(String themeCode) {
//     switch (themeCode) {
//       case 'light':
//         return Colors.orange;
//       case 'dark':
//         return Colors.blue[700]!;
//       case 'system':
//         return Colors.grey[600]!;
//       default:
//         return Colors.orange;
//     }
//   }
//
//   Widget _buildNotificationItem() {
//     final l10n = AppLocalizations.of(context);
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: Colors.green[100],
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Icon(
//               Icons.notifications,
//               color: Colors.green,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   l10n?.dailyNotificationsTitle ?? 'Thông báo hàng ngày (7:00)',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 Text(
//                   notificationsEnabled
//                       ? (l10n?.notificationsOn ?? 'Đang bật')
//                       : (l10n?.notificationsOff ?? 'Đang tắt'),
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           _buildToggleSwitch(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSettingItem({
//     required IconData icon,
//     required Color iconColor,
//     required String title,
//     required String subtitle,
//     required Widget trailing,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               spreadRadius: 1,
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: iconColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 icon,
//                 color: iconColor,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   Text(
//                     subtitle,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             trailing,
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildToggleSwitch() {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           notificationsEnabled = !notificationsEnabled;
//         });
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: 48,
//         height: 24,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           color: notificationsEnabled ? Colors.blue : Colors.grey[300],
//         ),
//         child: AnimatedAlign(
//           duration: const Duration(milliseconds: 200),
//           alignment: notificationsEnabled
//               ? Alignment.centerRight
//               : Alignment.centerLeft,
//           child: Container(
//             width: 20,
//             height: 20,
//             margin: const EdgeInsets.all(2),
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showLanguageModal() {
//     final l10n = AppLocalizations.of(context);
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   l10n?.chooseLanguageModalTitle ?? 'Chọn ngôn ngữ',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     width: 32,
//                     height: 32,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: const Icon(Icons.close, size: 20),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             ...languages.map((language) => _buildLanguageOption(language)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLanguageOption(Map<String, String> language) {
//     final l10n = AppLocalizations.of(context);
//
//     return Consumer<LanguageProvider>(
//       builder: (context, languageProvider, child) {
//         final isSelected = languageProvider.isCurrentLanguage(language['code']!);
//
//         // Lấy tên ngôn ngữ theo localization
//         String getLanguageName(String languageCode) {
//           if (languageCode == 'vi') {
//             return l10n?.vietnameseLanguage ?? 'Tiếng Việt';
//           } else {
//             return l10n?.englishLanguage ?? 'English';
//           }
//         }
//
//         return GestureDetector(
//           onTap: () async {
//             // Thay đổi ngôn ngữ
//             await languageProvider.changeLanguage(language['code']!);
//
//             if (mounted) {
//               Navigator.pop(context);
//
//               // Hiển thị thông báo
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(
//                       language['code'] == 'vi'
//                           ? 'Đã chuyển sang Tiếng Việt'
//                           : 'Changed to English'
//                   ),
//                   duration: const Duration(seconds: 2),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             }
//           },
//           child: Container(
//             margin: const EdgeInsets.only(bottom: 8),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: isSelected ? Colors.blue[50] : Colors.transparent,
//               borderRadius: BorderRadius.circular(8),
//               border: isSelected
//                   ? Border.all(color: Colors.blue[200]!)
//                   : null,
//             ),
//             child: Row(
//               children: [
//                 Text(
//                   language['flag']!,
//                   style: const TextStyle(fontSize: 24),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     getLanguageName(language['code']!),
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//                 if (isSelected)
//                   const Icon(Icons.check, color: Colors.blue, size: 20),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   void _showThemeModal() {
//     final l10n = AppLocalizations.of(context);
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   l10n?.chooseThemeModalTitle ?? 'Chọn chủ đề',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     width: 32,
//                     height: 32,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: const Icon(Icons.close, size: 20),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             ...themes.map((theme) => _buildThemeOption(theme)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildThemeOption(Map<String, dynamic> theme) {
//     final l10n = AppLocalizations.of(context);
//     final isSelected = selectedTheme == theme['code'];
//
//     // Lấy tên theme theo ngôn ngữ
//     String getThemeName(String themeCode) {
//       switch (themeCode) {
//         case 'light':
//           return l10n?.lightTheme ?? 'Sáng';
//         case 'dark':
//           return l10n?.darkTheme ?? 'Tối';
//         case 'system':
//           return l10n?.systemTheme ?? 'Theo hệ thống';
//         default:
//           return l10n?.lightTheme ?? 'Sáng';
//       }
//     }
//
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           selectedTheme = theme['code']!;
//         });
//         Navigator.pop(context);
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 8),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.blue[50] : Colors.transparent,
//           borderRadius: BorderRadius.circular(8),
//           border: isSelected
//               ? Border.all(color: Colors.blue[200]!)
//               : null,
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                 color: _getThemeBackgroundColor(theme['code']),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 theme['icon'],
//                 size: 16,
//                 color: _getThemeIconColor(theme['code']),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 getThemeName(theme['code']),
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             if (isSelected)
//               const Icon(Icons.check, color: Colors.blue, size: 20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Color _getThemeBackgroundColor(String themeCode) {
//     switch (themeCode) {
//       case 'light':
//         return Colors.yellow[100]!;
//       case 'dark':
//         return Colors.grey[800]!;
//       case 'system':
//         return Colors.blue[100]!;
//       default:
//         return Colors.yellow[100]!;
//     }
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:provider/provider.dart';
// import 'package:datn_20242/services/locale_provider.dart'; // Đường dẫn đến file locale_provider.dart
// import 'package:datn_20242/services/theme_provider.dart'; // << 1. IMPORT THEMEPROVIDER
//
// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({Key? key}) : super(key: key);
//
//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }
//
// class _SettingsScreenState extends State<SettingsScreen> {
//   // String selectedTheme = 'light'; // << 2. SẼ KHÔNG DÙNG BIẾN CỤC BỘ NÀY NỮA
//   bool notificationsEnabled = true;
//
//   final List<Map<String, String>> languages = [
//     {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
//     {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
//   ];
//
//   // Danh sách themes giữ nguyên, nhưng chúng ta sẽ ánh xạ 'code' sang ThemeMode
//   final List<Map<String, dynamic>> themes = [
//     {'code': 'light', 'name': 'light', 'icon': Icons.wb_sunny, 'mode': ThemeMode.light}, // << Thêm 'mode'
//     {'code': 'dark', 'name': 'dark', 'icon': Icons.nightlight_round, 'mode': ThemeMode.dark}, // << Thêm 'mode'
//     {'code': 'system', 'name': 'system', 'icon': Icons.settings_brightness, 'mode': ThemeMode.system}, // << Thêm 'mode' (Icons.settings đã dùng, đổi icon nếu muốn)
//   ];
//
//   // Helper function để lấy thông tin theme hiện tại từ ThemeProvider
//   Map<String, dynamic> _getCurrentThemeInfo(ThemeProvider themeProvider) {
//     return themes.firstWhere(
//           (theme) => theme['mode'] == themeProvider.currentThemeMode,
//       orElse: () => themes.firstWhere((t) => t['code'] == 'system'), // Mặc định nếu có lỗi
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context);
//     // final themeProvider = Provider.of<ThemeProvider>(context); // Có thể lấy ở đây hoặc trong từng widget con
//
//     return Scaffold(
//       // backgroundColor: Colors.grey[50], // Màu này sẽ được Theme xử lý
//       appBar: AppBar(
//         // backgroundColor: Colors.white, // Màu này sẽ được Theme xử lý
//           elevation: 1,
//           title: Text(
//             l10n?.settingsTitle ?? 'Cài đặt',
//             style: const TextStyle( // Xem xét việc định nghĩa style này trong ThemeData
//               // color: Colors.black,
//               fontSize: 20,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           leading: IconButton( // Thay Container bằng IconButton cho đúng ngữ nghĩa
//             icon: Icon(Icons.arrow_back_ios_new),
//             // style: IconButton.styleFrom(
//             //   backgroundColor: Theme.of(context).colorScheme.surfaceVariant, // Sử dụng màu từ theme
//             // ),
//             onPressed: () => Navigator.of(context).pop(),
//           )
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSectionTitle(l10n?.interfaceSectionTitle ?? 'Giao diện'),
//             const SizedBox(height: 12),
//             _buildLanguageItem(),
//             const SizedBox(height: 12),
//             _buildThemeItem(), // << Sẽ được cập nhật để dùng ThemeProvider
//
//             const SizedBox(height: 32),
//
//             _buildSectionTitle(l10n?.notificationsSectionTitle ?? 'Thông báo'),
//             const SizedBox(height: 12),
//             _buildNotificationItem(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: TextStyle( // Nên lấy style từ Theme.of(context).textTheme
//         fontSize: 18,
//         fontWeight: FontWeight.w600,
//         color: Theme.of(context).colorScheme.onSurfaceVariant, // Sử dụng màu từ theme
//       ),
//     );
//   }
//
//   Widget _buildLanguageItem() {
//     final l10n = AppLocalizations.of(context);
//
//     return Consumer<LanguageProvider>(
//       builder: (context, languageProvider, child) {
//         final currentLanguage = languages.firstWhere(
//               (lang) => lang['code'] == languageProvider.currentLocale.languageCode,
//         );
//
//         String getLanguageName(String languageCode) {
//           if (languageCode == 'vi') {
//             return l10n?.vietnameseLanguage ?? 'Tiếng Việt';
//           } else {
//             return l10n?.englishLanguage ?? 'English';
//           }
//         }
//
//         return _buildSettingItem(
//           icon: Icons.language,
//           iconColor: Colors.blue,
//           title: l10n?.languageSettingTitle ?? 'Ngôn ngữ',
//           subtitle: getLanguageName(languageProvider.currentLocale.languageCode),
//           trailing: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 currentLanguage['flag']!,
//                 style: const TextStyle(fontSize: 20),
//               ),
//               const SizedBox(width: 8),
//               Icon(Icons.chevron_right, color: Colors.grey[600]),
//             ],
//           ),
//           onTap: () => _showLanguageModal(),
//         );
//       },
//     );
//   }
//
//   Widget _buildThemeItem() {
//     final l10n = AppLocalizations.of(context);
//     // << 3. SỬ DỤNG THEMEPROVIDER ĐỂ LẤY TRẠNG THÁI
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final currentThemeInfo = _getCurrentThemeInfo(themeProvider);
//
//     String getThemeName(ThemeMode themeMode) {
//       switch (themeMode) {
//         case ThemeMode.light:
//           return l10n?.lightTheme ?? 'Sáng';
//         case ThemeMode.dark:
//           return l10n?.darkTheme ?? 'Tối';
//         case ThemeMode.system:
//         default:
//           return l10n?.systemTheme ?? 'Theo hệ thống';
//       }
//     }
//
//     return _buildSettingItem(
//       icon: Icons.palette_outlined, // Đổi icon nếu muốn
//       iconColor: Colors.purple,
//       title: l10n?.themeSettingTitle ?? 'Chủ đề',
//       subtitle: getThemeName(themeProvider.currentThemeMode), // << Lấy tên từ provider
//       trailing: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 24,
//             height: 24,
//             decoration: BoxDecoration(
//               // color: Theme.of(context).colorScheme.secondaryContainer, // Sử dụng màu từ theme
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Theme.of(context).dividerColor)
//             ),
//             child: Icon(
//               currentThemeInfo['icon'],
//               size: 16,
//               color: _getThemeIconColor(currentThemeInfo['code']), // Giữ lại logic màu icon cục bộ nếu muốn
//             ),
//           ),
//           const SizedBox(width: 8),
//           Icon(Icons.chevron_right, color: Colors.grey[600]),
//         ],
//       ),
//       onTap: () => _showThemeModal(), // << Modal sẽ được cập nhật
//     );
//   }
//
//   // Giữ lại hàm này nếu bạn muốn màu icon đặc biệt không theo ThemeProvider
//   Color _getThemeIconColor(String themeCode) {
//     // Hoặc bạn có thể lấy màu này từ Theme.of(context) nếu themeCode là system
//     // if (themeCode == 'system') {
//     //   final brightness = MediaQuery.platformBrightnessOf(context);
//     //   return brightness == Brightness.dark ? Colors.blue[700]! : Colors.orange;
//     // }
//     switch (themeCode) {
//       case 'light':
//         return Colors.orange;
//       case 'dark':
//         return Colors.indigoAccent; // Đổi màu cho dark
//       case 'system':
//         return Colors.grey[700]!; // Màu cho system
//       default:
//         return Colors.orange;
//     }
//   }
//
//   Widget _buildNotificationItem() {
//     final l10n = AppLocalizations.of(context);
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor, // Sử dụng màu từ theme
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Theme.of(context).shadowColor.withOpacity(0.05), // Sử dụng màu từ theme
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: Colors.green.withOpacity(0.1), // Giữ nguyên hoặc dùng Theme
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Icon(
//               Icons.notifications_active_outlined, // Đổi icon
//               color: Colors.green,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   l10n?.dailyNotificationsTitle ?? 'Thông báo hàng ngày (7:00)',
//                   style: Theme.of(context).textTheme.titleMedium, // Sử dụng textTheme
//                 ),
//                 Text(
//                   notificationsEnabled
//                       ? (l10n?.notificationsOn ?? 'Đang bật')
//                       : (l10n?.notificationsOff ?? 'Đang tắt'),
//                   style: Theme.of(context).textTheme.bodySmall, // Sử dụng textTheme
//                 ),
//               ],
//             ),
//           ),
//           _buildToggleSwitch(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSettingItem({
//     required IconData icon,
//     required Color iconColor,
//     required String title,
//     required String subtitle,
//     required Widget trailing,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Theme.of(context).cardColor, // Sử dụng màu từ theme
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Theme.of(context).shadowColor.withOpacity(0.05), // Sử dụng màu từ theme
//               spreadRadius: 1,
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: iconColor.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 icon,
//                 color: iconColor,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: Theme.of(context).textTheme.titleMedium, // Sử dụng textTheme
//                   ),
//                   Text(
//                     subtitle,
//                     style: Theme.of(context).textTheme.bodySmall, // Sử dụng textTheme
//                   ),
//                 ],
//               ),
//             ),
//             trailing,
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildToggleSwitch() {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           notificationsEnabled = !notificationsEnabled;
//         });
//         // TODO: Lưu trạng thái notificationsEnabled vào SharedPreferences hoặc service nếu cần
//       },
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: 48,
//         height: 24,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           color: notificationsEnabled ? Theme.of(context).primaryColor : Colors.grey[400], // Sử dụng màu từ theme
//         ),
//         child: AnimatedAlign(
//           duration: const Duration(milliseconds: 200),
//           alignment: notificationsEnabled
//               ? Alignment.centerRight
//               : Alignment.centerLeft,
//           child: Container(
//             width: 20,
//             height: 20,
//             margin: const EdgeInsets.all(2),
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               shape: BoxShape.circle,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showLanguageModal() {
//     final l10n = AppLocalizations.of(context);
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         decoration: BoxDecoration( // Sử dụng màu từ theme
//           color: Theme.of(context).bottomSheetTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   l10n?.chooseLanguageModalTitle ?? 'Chọn ngôn ngữ',
//                   style: Theme.of(context).textTheme.titleLarge, // Sử dụng textTheme
//                 ),
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: Container(
//                     width: 32,
//                     height: 32,
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).colorScheme.surfaceVariant, // Sử dụng màu từ theme
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Icon(Icons.close, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             ...languages.map((language) => _buildLanguageOption(language)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLanguageOption(Map<String, String> language) {
//     final l10n = AppLocalizations.of(context);
//
//     return Consumer<LanguageProvider>(
//       builder: (context, languageProvider, child) {
//         final isSelected = languageProvider.isCurrentLanguage(language['code']!);
//
//         String getLanguageName(String languageCode) {
//           if (languageCode == 'vi') {
//             return l10n?.vietnameseLanguage ?? 'Tiếng Việt';
//           } else {
//             return l10n?.englishLanguage ?? 'English';
//           }
//         }
//
//         return GestureDetector(
//           onTap: () async {
//             await languageProvider.changeLanguage(language['code']!);
//             if (mounted) {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(
//                       language['code'] == 'vi'
//                           ? 'Đã chuyển sang Tiếng Việt'
//                           : 'Changed to English'
//                   ),
//                   duration: const Duration(seconds: 2),
//                   backgroundColor: Colors.green, // Có thể dùng màu từ Theme
//                 ),
//               );
//             }
//           },
//           child: Container(
//             margin: const EdgeInsets.only(bottom: 8),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
//               borderRadius: BorderRadius.circular(8),
//               border: isSelected
//                   ? Border.all(color: Theme.of(context).colorScheme.primary)
//                   : Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
//             ),
//             child: Row(
//               children: [
//                 Text(
//                   language['flag']!,
//                   style: const TextStyle(fontSize: 24),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     getLanguageName(language['code']!),
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                       color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface,
//                     ),
//                   ),
//                 ),
//                 if (isSelected)
//                   Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   void _showThemeModal() {
//     final l10n = AppLocalizations.of(context);
//     // Không cần ThemeProvider ở đây vì _buildThemeOption sẽ lấy
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (modalContext) => Container( // Sử dụng modalContext riêng để tránh nhầm lẫn
//         decoration: BoxDecoration(
//           color: Theme.of(modalContext).bottomSheetTheme.backgroundColor ?? Theme.of(modalContext).colorScheme.surface,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   l10n?.chooseThemeModalTitle ?? 'Chọn chủ đề',
//                   style: Theme.of(modalContext).textTheme.titleLarge,
//                 ),
//                 GestureDetector(
//                   onTap: () => Navigator.pop(modalContext),
//                   child: Container(
//                     width: 32,
//                     height: 32,
//                     decoration: BoxDecoration(
//                       color: Theme.of(modalContext).colorScheme.surfaceVariant,
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     child: Icon(Icons.close, size: 20, color: Theme.of(modalContext).colorScheme.onSurfaceVariant),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             // << 4. TRUYỀN THEMEPROVIDER XUỐNG CHO CÁC OPTIONS
//             ...themes.map((theme) => _buildThemeOption(theme, Provider.of<ThemeProvider>(context, listen: false))),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildThemeOption(Map<String, dynamic> themeInfo, ThemeProvider themeProvider) {
//     final l10n = AppLocalizations.of(context); // context của _SettingsScreenState
//     // final themeProvider = Provider.of<ThemeProvider>(context); // KHÔNG dùng context này ở đây nếu truyền vào
//     final currentThemeMode = themeProvider.currentThemeMode;
//     final isSelected = currentThemeMode == themeInfo['mode'];
//
//     String getThemeName(String themeCode) {
//       switch (themeCode) {
//         case 'light':
//           return l10n?.lightTheme ?? 'Sáng';
//         case 'dark':
//           return l10n?.darkTheme ?? 'Tối';
//         case 'system':
//         default:
//           return l10n?.systemTheme ?? 'Theo hệ thống';
//       }
//     }
//
//     return GestureDetector(
//       onTap: () {
//         // << 5. SỬ DỤNG THEMEPROVIDER ĐỂ SET CHỦ ĐỀ
//         themeProvider.setThemeMode(themeInfo['mode'] as ThemeMode);
//         Navigator.pop(context); // Pop context của modal
//         // Không cần setState vì UI sẽ tự cập nhật khi ThemeProvider notifyListeners
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 8),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
//           borderRadius: BorderRadius.circular(8),
//           border: isSelected
//               ? Border.all(color: Theme.of(context).colorScheme.primary)
//               : Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 32,
//               height: 32,
//               decoration: BoxDecoration(
//                   color: _getThemeBackgroundColor(themeInfo['code']), // Giữ lại logic màu nền cục bộ nếu muốn
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Theme.of(context).dividerColor)
//               ),
//               child: Icon(
//                 themeInfo['icon'],
//                 size: 16,
//                 color: _getThemeIconColor(themeInfo['code']), // Giữ lại logic màu icon cục bộ nếu muốn
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 getThemeName(themeInfo['code']),
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface,
//                 ),
//               ),
//             ),
//             if (isSelected)
//               Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Giữ lại hàm này nếu bạn muốn màu nền đặc biệt không theo ThemeProvider
//   Color _getThemeBackgroundColor(String themeCode) {
//     // Tương tự như _getThemeIconColor, bạn có thể làm cho nó phụ thuộc vào theme hiện tại
//     // if (themeCode == 'system') {
//     //   final brightness = MediaQuery.platformBrightnessOf(context);
//     //   return brightness == Brightness.dark ? Colors.grey[800]! : Colors.yellow[100]!;
//     // }
//     switch (themeCode) {
//       case 'light':
//         return Colors.orange[50]!;
//       case 'dark':
//         return Colors.indigo[900]!.withOpacity(0.3);
//       case 'system':
//       default:
//         return Colors.blueGrey[50]!;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // << 1. IMPORT SHARED_PREFERENCES

// Import các provider hiện tại của bạn
import 'package:datn_20242/services/locale_provider.dart';
import 'package:datn_20242/services/theme_provider.dart';

// Import BackgroundTaskService từ main.dart (nơi bạn đã tạo instance toàn cục)
// Đường dẫn này có thể cần điều chỉnh tùy thuộc vào vị trí file main.dart của bạn
// Nếu settings_screen.dart nằm trong lib/screens/settings_screen/
// và main.dart nằm trong lib/ thì đường dẫn có thể là:
import '../../main.dart';
import '../../services/background_service.dart'; // << 2. IMPORT ĐỂ TRUY CẬP backgroundTaskService

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // bool notificationsEnabled = true; // Sẽ thay thế bằng _dailyAqiNotificationEnabled từ SharedPreferences
  bool _periodicNotificationEnabled = false;
  final String _notificationPrefKey = 'inexact_periodic_notification_enabled';

  final List<Map<String, String>> languages = [
    {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
  ];

  final List<Map<String, dynamic>> themes = [
    {'code': 'light', 'name': 'light', 'icon': Icons.wb_sunny, 'mode': ThemeMode.light},
    {'code': 'dark', 'name': 'dark', 'icon': Icons.nightlight_round, 'mode': ThemeMode.dark},
    {'code': 'system', 'name': 'system', 'icon': Icons.settings_brightness, 'mode': ThemeMode.system},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting(); // << 3. LOAD TRẠNG THÁI THÔNG BÁO KHI KHỞI TẠO
  }

  // << 4. HÀM LOAD TRẠNG THÁI THÔNG BÁO TỪ SHARED_PREFERENCES
  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _periodicNotificationEnabled = prefs.getBool(_notificationPrefKey) ?? false; // Mặc định là false nếu chưa có
    });
    print("[SettingsScreen] Trạng thái thông báo đã tải: $_periodicNotificationEnabled");
  }

  // << 5. HÀM CẬP NHẬT VÀ LƯU TRẠNG THÁI THÔNG BÁO
  Future<void> _updatePeriodicNotificationSetting(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationPrefKey, enabled);
    if (mounted) {
      setState(() {
        _periodicNotificationEnabled = enabled;
      });
    }

    if (enabled) {
      // Gọi hàm cho thông báo không chính xác
      backgroundTaskService.registerInexactPeriodicTask();
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Đã BẬT thông báo AQI định kỳ.'),
        //     backgroundColor: Colors.green,
        //   ),
        // );
      }
    } else {
      // Hủy tác vụ bằng tên unique của nó
      backgroundTaskService.cancelTask(inexactPeriodicTask);
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Đã TẮT thông báo AQI định kỳ.'),
        //     backgroundColor: Colors.orange,
        //   ),
        // );
      }
    }
  }


  Map<String, dynamic> _getCurrentThemeInfo(ThemeProvider themeProvider) {
    return themes.firstWhere(
          (theme) => theme['mode'] == themeProvider.currentThemeMode,
      orElse: () => themes.firstWhere((t) => t['code'] == 'system'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea( // Thêm SafeArea để bọc SingleChildScrollView
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(l10n?.interfaceSectionTitle ?? 'Giao diện'),
              const SizedBox(height: 12),
              _buildLanguageItem(),
              const SizedBox(height: 12),
              _buildThemeItem(),

              const SizedBox(height: 32),

              _buildSectionTitle(l10n?.notificationsSectionTitle ?? 'Thông báo'),
              const SizedBox(height: 12),
              _buildNotificationItem(), // << Sẽ sử dụng _dailyAqiNotificationEnabled
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildLanguageItem() {
    final l10n = AppLocalizations.of(context);

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final currentLanguage = languages.firstWhere(
              (lang) => lang['code'] == languageProvider.currentLocale.languageCode,
        );

        String getLanguageName(String languageCode) {
          if (languageCode == 'vi') {
            return l10n?.vietnameseLanguage ?? 'Tiếng Việt';
          } else {
            return l10n?.englishLanguage ?? 'English';
          }
        }

        return _buildSettingItem(
          icon: Icons.language,
          iconColor: Colors.blue,
          title: l10n?.languageSettingTitle ?? 'Ngôn ngữ',
          subtitle: getLanguageName(languageProvider.currentLocale.languageCode),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentLanguage['flag']!,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
          onTap: () => _showLanguageModal(),
        );
      },
    );
  }

  Widget _buildThemeItem() {
    final l10n = AppLocalizations.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentThemeInfo = _getCurrentThemeInfo(themeProvider);

    String getThemeName(ThemeMode themeMode) {
      switch (themeMode) {
        case ThemeMode.light:
          return l10n?.lightTheme ?? 'Sáng';
        case ThemeMode.dark:
          return l10n?.darkTheme ?? 'Tối';
        case ThemeMode.system:
        default:
          return l10n?.systemTheme ?? 'Theo hệ thống';
      }
    }

    return _buildSettingItem(
      icon: Icons.palette_outlined,
      iconColor: Colors.purple,
      title: l10n?.themeSettingTitle ?? 'Chủ đề',
      subtitle: getThemeName(themeProvider.currentThemeMode),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor)
            ),
            child: Icon(
              currentThemeInfo['icon'],
              size: 16,
              color: _getThemeIconColor(currentThemeInfo['code'] as String),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: Colors.grey[600]),
        ],
      ),
      onTap: () => _showThemeModal(),
    );
  }

  Color _getThemeIconColor(String themeCode) {
    switch (themeCode) {
      case 'light':
        return Colors.orange;
      case 'dark':
        return Colors.indigoAccent;
      case 'system':
        return Colors.grey[700]!;
      default:
        return Colors.orange;
    }
  }

  // << 6. CẬP NHẬT _buildNotificationItem ĐỂ SỬ DỤNG _dailyAqiNotificationEnabled
  Widget _buildNotificationItem() {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        // <<< THÊM VÀO: Hiệu ứng đổ bóng cho thẻ nổi >>>
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // <<< THÊM VÀO: Icon ở bên trái, giống các widget khác >>>
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.dailyNotificationsTitle ?? 'Thông báo hàng ngày',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _periodicNotificationEnabled
                      ? (l10n?.notificationsOn ?? 'Đang bật')
                      : (l10n?.notificationsOff ?? 'Đang tắt'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _buildToggleSwitch(), // Nút gạt bật/tắt
        ],
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return GestureDetector(
      onTap: () {
        // Khi bấm vào, gọi đến hàm xử lý logic ở Phần 3
        _updatePeriodicNotificationSetting(!_periodicNotificationEnabled);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _periodicNotificationEnabled ? Theme.of(context).colorScheme.primary : Colors.grey[400],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: _periodicNotificationEnabled
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  // Các hàm _showLanguageModal, _buildLanguageOption, _showThemeModal, _buildThemeOption, _getThemeBackgroundColor
  // giữ nguyên như trong file của bạn, không thay đổi logic cốt lõi.
  // Đảm bảo chúng hoạt động đúng với context và provider.
  void _showLanguageModal() {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomSheetTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.chooseLanguageModalTitle ?? 'Chọn ngôn ngữ',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.close, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...languages.map((language) => _buildLanguageOption(language)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(Map<String, String> language) {
    final l10n = AppLocalizations.of(context);

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final isSelected = languageProvider.isCurrentLanguage(language['code']!);

        String getLanguageName(String languageCode) {
          if (languageCode == 'vi') {
            return l10n?.vietnameseLanguage ?? 'Tiếng Việt';
          } else {
            return l10n?.englishLanguage ?? 'English';
          }
        }

        return GestureDetector(
          onTap: () async {
            await languageProvider.changeLanguage(language['code']!);
            if (mounted) {
              Navigator.pop(context);
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text(
              //         language['code'] == 'vi'
              //             ? 'Đã chuyển sang Tiếng Việt'
              //             : 'Changed to English'
              //     ),
              //     duration: const Duration(seconds: 2),
              //     backgroundColor: Colors.green,
              //   ),
              // );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: Theme.of(context).colorScheme.primary)
                  : Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Text(
                  language['flag']!,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    getLanguageName(language['code']!),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeModal() {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(modalContext).bottomSheetTheme.backgroundColor ?? Theme.of(modalContext).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.chooseThemeModalTitle ?? 'Chọn chủ đề',
                  style: Theme.of(modalContext).textTheme.titleLarge,
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(modalContext),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(modalContext).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.close, size: 20, color: Theme.of(modalContext).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...themes.map((theme) => _buildThemeOption(theme, Provider.of<ThemeProvider>(context, listen: false))),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(Map<String, dynamic> themeInfo, ThemeProvider themeProvider) {
    final l10n = AppLocalizations.of(context);
    final currentThemeMode = themeProvider.currentThemeMode;
    final isSelected = currentThemeMode == themeInfo['mode'];

    String getThemeName(String themeCode) {
      switch (themeCode) {
        case 'light':
          return l10n?.lightTheme ?? 'Sáng';
        case 'dark':
          return l10n?.darkTheme ?? 'Tối';
        case 'system':
        default:
          return l10n?.systemTheme ?? 'Theo hệ thống';
      }
    }

    return GestureDetector(
      onTap: () {
        themeProvider.setThemeMode(themeInfo['mode'] as ThemeMode);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary)
              : Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: _getThemeBackgroundColor(themeInfo['code'] as String),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor)
              ),
              child: Icon(
                themeInfo['icon'],
                size: 16,
                color: _getThemeIconColor(themeInfo['code'] as String),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                getThemeName(themeInfo['code'] as String),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Color _getThemeBackgroundColor(String themeCode) {
    switch (themeCode) {
      case 'light':
        return Colors.orange[50]!;
      case 'dark':
        return Colors.indigo[900]!.withOpacity(0.3);
      case 'system':
      default:
        return Colors.blueGrey[50]!;
    }
  }
}

