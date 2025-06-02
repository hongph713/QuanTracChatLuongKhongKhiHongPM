// import 'package:datn_20242/screens/map_screen/station_list/station_list_screen.dart';
// import 'package:datn_20242/screens/settings_screen/settings_screen.dart';
// import 'package:flutter/material.dart';
//
// import 'map_screen/widgets/map_screen.dart';
//
// // import 'station_list_screen.dart'; // Sẽ làm sau
// // import 'settings_screen.dart';     // Sẽ làm sau
//
// class MainScreen extends StatefulWidget {
//   @override
//   _MainScreenState createState() => _MainScreenState();
// }
//
// class _MainScreenState extends State<MainScreen> {
//   int _selectedIndex = 0;
//
//   // Danh sách các widget cho từng tab
//   // Đảm bảo MapScreen() được import và định nghĩa đúng
//   static List<Widget> _widgetOptions = <Widget>[
//     MapScreen(), // Màn hình bản đồ (Hình 1)
//     StationListScreen(),
//     SettingsScreen()      // Placeholder
//   ];
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack( // Sử dụng IndexedStack để giữ trạng thái các tab
//         index: _selectedIndex,
//         children: _widgetOptions,
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.map_outlined),
//             activeIcon: Icon(Icons.map), // Icon khi được chọn
//             label: 'Bản đồ',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.list_alt_outlined),
//             activeIcon: Icon(Icons.list_alt),
//             label: 'Danh sách trạm đo',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings_outlined),
//             activeIcon: Icon(Icons.settings),
//             label: 'Cài đặt',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Theme.of(context).primaryColor,
//         unselectedItemColor: Colors.grey[600],
//         onTap: _onItemTapped,
//         type: BottomNavigationBarType.fixed, // Để hiển thị label ngay cả khi có nhiều item
//       ),
//     );
//   }
// }
//

// lib/screens/main_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'map_screen/station_list/station_list_screen.dart'; // Đường dẫn của bạn
import 'map_screen/widgets/map_screen.dart';
import 'settings_screen/settings_screen.dart'; // THÊM IMPORT NÀY
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Để sử dụng đa ng

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  @override
  _MainScreenState createState() => _MainScreenState();
}
class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Mặc định chọn tab Bản đồ

  // Danh sách các widget cho từng tab
  static List<Widget> _widgetOptions = <Widget>[
    MapScreen(), // Màn hình bản đồ (Hình 1)
    StationListScreen(), // Placeholder
    SettingsScreen(),        // Placeholder
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            // label: 'Bản đồ',
            label: l10n.mapTabLabel, // Sử dụng đa ngôn ngữ
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: l10n.stationListTabLabel, // Sử dụng đa ngôn ngữ
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: l10n.settingsTabLabel, // Sử dụng đa ngôn ngữ,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor, // Hoặc màu bạn muốn
        onTap: _onItemTapped,
      ),
    );
  }
}

// class _MainScreenState extends State<MainScreen> {
//   int _selectedIndex = 0;
//   final PageController _pageController = PageController();
//
//   // ... (Hàm _onStationSelectedFromList nếu có) ...
//
//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//     _pageController.jumpToPage(index);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final List<Widget> widgetOptions = <Widget>[
//       const MapScreen(),
//       StationListScreen(onStationSelected: (stationId) { /* ... */ }),
//       const SettingsScreen(), // SỬ DỤNG SettingsScreen ở đây
//     ];
//
//     return Scaffold(
//       body: PageView(
//         controller: _pageController,
//         onPageChanged: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//         children: widgetOptions,
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         // ... (items của bạn) ...
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.map_outlined),
//             activeIcon: Icon(Icons.map),
//             label: 'Bản đồ',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.list_alt_outlined),
//             activeIcon: Icon(Icons.list_alt),
//             label: 'Danh sách trạm đo',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings_outlined),
//             activeIcon: Icon(Icons.settings),
//             label: 'Cài đặt', // Label cho tab Cài đặt
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Theme.of(context).primaryColor,
//         unselectedItemColor: Colors.grey[600],
//         onTap: _onItemTapped,
//         type: BottomNavigationBarType.fixed,
//       ),
//     );
//   }
// }
//
