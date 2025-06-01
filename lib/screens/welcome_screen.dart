// import 'package:flutter/material.dart';
// import '../services/settings_service.dart';
// import '../services/notification_service.dart';
// import 'main_screen.dart';
//
// class WelcomeScreen extends StatefulWidget {
//   const WelcomeScreen({Key? key}) : super(key: key);
//
//   @override
//   State<WelcomeScreen> createState() => _WelcomeScreenState();
// }
//
// class _WelcomeScreenState extends State<WelcomeScreen> {
//   bool _isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.blue[50],
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             children: [
//               const Spacer(),
//
//               // App Icon/Logo
//               Container(
//                 width: 120,
//                 height: 120,
//                 decoration: BoxDecoration(
//                   color: Colors.blue[600],
//                   borderRadius: BorderRadius.circular(30),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.blue.withOpacity(0.3),
//                       spreadRadius: 0,
//                       blurRadius: 20,
//                       offset: const Offset(0, 10),
//                     ),
//                   ],
//                 ),
//                 child: const Icon(
//                   Icons.air,
//                   size: 60,
//                   color: Colors.white,
//                 ),
//               ),
//
//               const SizedBox(height: 32),
//
//               // Welcome Title
//               Text(
//                 'Chào mừng đến với\nỨng dụng Quan trắc\nChất lượng Không khí',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue[800],
//                   height: 1.2,
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//
//               // Description
//               Text(
//                 'Theo dõi chất lượng không khí xung quanh bạn và nhận thông báo hàng ngày về tình hình môi trường.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey[600],
//                   height: 1.4,
//                 ),
//               ),
//
//               const Spacer(),
//
//               // Notification Question
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       spreadRadius: 0,
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Icon(
//                       Icons.notifications_active,
//                       size: 48,
//                       color: Colors.blue[600],
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Bạn có muốn nhận thông báo hàng ngày về chất lượng không khí?',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[800],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Chúng tôi sẽ gửi thông báo vào 7:00 sáng mỗi ngày',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 24),
//
//               // Buttons
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildButton(
//                       'Không, cảm ơn',
//                       Colors.grey[300]!,
//                       Colors.grey[700]!,
//                           () => _handleNotificationChoice(false),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: _buildButton(
//                       'Có, tôi muốn',
//                       Colors.blue[600]!,
//                       Colors.white,
//                           () => _handleNotificationChoice(true),
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildButton(String text, Color bgColor, Color textColor, VoidCallback onPressed) {
//     return ElevatedButton(
//       onPressed: _isLoading ? null : onPressed,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: bgColor,
//         foregroundColor: textColor,
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         elevation: 0,
//       ),
//       child: _isLoading
//           ? const SizedBox(
//         width: 20,
//         height: 20,
//         child: CircularProgressIndicator(strokeWidth: 2),
//       )
//           : Text(
//         text,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }
//
//   Future<void> _handleNotificationChoice(bool enableNotifications) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       // Lưu setting thông báo
//       await SettingsService.instance.setNotificationsEnabled(enableNotifications);
//
//       if (enableNotifications) {
//         // Yêu cầu quyền thông báo
//         bool permissionGranted = await NotificationService().requestPermissions();
//         if (permissionGranted) {
//           // Lên lịch thông báo hàng ngày
//           await NotificationService().scheduleDailyNotification();
//         } else {
//           // Nếu không được cấp quyền, tắt setting
//           await SettingsService.instance.setNotificationsEnabled(false);
//         }
//       }
//
//       // Đánh dấu đã hoàn thành lần đầu mở app
//       await SettingsService.instance.setFirstLaunchCompleted();
//
//       // Chuyển đến màn hình chính
//       if (mounted) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (context) => MainScreen()),
//         );
//       }
//     } catch (e) {
//       print('Error handling notification choice: $e');
//       // Vẫn chuyển đến màn hình chính nếu có lỗi
//       if (mounted) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (context) => MainScreen()),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
// }