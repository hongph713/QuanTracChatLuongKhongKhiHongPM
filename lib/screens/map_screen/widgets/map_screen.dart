// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//
// import '../../../models/AQIUtils.dart';
// import '../../../models/station.dart';
// import '../../station_detail_screen/station_detail_screen.dart';
// import 'station_info_card.dart';
//
// class MapScreen extends StatefulWidget {
//   const MapScreen({Key? key}) : super(key: key);
//
//   @override
//   _MapScreenState createState() => _MapScreenState();
// }
//
// class _MapScreenState extends State<MapScreen> {
//   final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
//   bool isLoading = true;
//   String _streamStatusMessage = '';
//
//   final LatLng _initialPosition = const LatLng(21.0285, 105.8542); // Hà Nội
//   final double _initialZoom = 12.0;
//   Set<Marker> _markers = {};
//   GoogleMapController? _mapController;
//
//   Map<String, Station> _stations = {};
//   Station? _selectedStation;
//
//   StreamSubscription<DatabaseEvent>? _stationsSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     print("[MapScreen] initState called");
//     // Delay để đảm bảo context đã sẵn sàng cho localization
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _setupLocationPermission();
//       _listenToFirebaseData();
//     });
//   }
//
//   @override
//   void dispose() {
//     _stationsSubscription?.cancel();
//     _mapController?.dispose();
//     super.dispose();
//   }
//
//   Future<void> _setupLocationPermission() async {
//     final l10n = AppLocalizations.of(context);
//     if (l10n == null) return;
//
//     print("[MapScreen] Setting up location permissions");
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       if (mounted) {
//         setState(() {
//           _streamStatusMessage = l10n.locationServiceDisabled ?? 'Dịch vụ vị trí bị tắt';
//         });
//       }
//       return;
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         if (mounted) {
//           setState(() {
//             _streamStatusMessage = l10n.locationPermissionDenied ?? 'Quyền vị trí bị từ chối';
//           });
//         }
//         return;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       if (mounted) {
//         setState(() {
//           _streamStatusMessage = l10n.locationPermissionDeniedForever ?? 'Quyền vị trí bị từ chối vĩnh viễn';
//         });
//       }
//       return;
//     }
//
//     try {
//       Position position = await Geolocator.getCurrentPosition();
//       if (_mapController != null) {
//         _mapController!.animateCamera(
//             CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude))
//         );
//       }
//     } catch (e) {
//       print("[MapScreen] Error getting current location: $e");
//     }
//   }
//
//   void _listenToFirebaseData() {
//     final l10n = AppLocalizations.of(context);
//     if (l10n == null) {
//       print("[MapScreen] AppLocalizations not available yet, retrying...");
//       Future.delayed(const Duration(milliseconds: 100), _listenToFirebaseData);
//       return;
//     }
//
//     print("[MapScreen] Starting to listen to Firebase data");
//     if (mounted) {
//       setState(() {
//         isLoading = true;
//         _streamStatusMessage = l10n.connectingToDatabase ?? 'Đang kết nối đến cơ sở dữ liệu...';
//       });
//     }
//
//     _stationsSubscription = _databaseRef.child('cacThietBiQuanTrac').onValue.listen(
//           (DatabaseEvent event) async {
//         if (!mounted) return;
//
//         final currentL10n = AppLocalizations.of(context);
//         if (currentL10n == null) return;
//
//         print("[MapScreen] Received Firebase data event");
//
//         if (event.snapshot.value == null) {
//           setState(() {
//             isLoading = false;
//             _streamStatusMessage = currentL10n.noDeviceData ?? 'Không có dữ liệu thiết bị';
//             _markers.clear();
//             _stations.clear();
//           });
//           return;
//         }
//
//         try {
//           print("[MapScreen] Raw data from Firebase:");
//           print(event.snapshot.value);
//
//           Map<dynamic, dynamic> values = event.snapshot.value as Map<dynamic, dynamic>;
//           print("[MapScreen] Number of devices: ${values.length}");
//
//           Map<String, Station> newStations = {};
//           Set<Marker> newMarkers = {};
//
//           // Xử lý từng thiết bị và tạo marker
//           for (var entry in values.entries) {
//             String key = entry.key;
//             var value = entry.value;
//
//             try {
//               print("[MapScreen] Processing device with key: $key");
//               print("Device data: $value");
//
//               if (value['lat'] == null || value['long'] == null) {
//                 print("[MapScreen] Missing location data for device $key");
//                 continue;
//               }
//
//               // Tạo đối tượng Station từ dữ liệu Firebase với localization
//               Station station = await Station.fromFirebaseLocalized(value, key, currentL10n);
//               print("[MapScreen] Device location: ${station.latitude}, ${station.longitude}");
//
//               // Thêm vào map stations
//               newStations[key] = station;
//
//               // Tính toán AQI và lấy màu tương ứng
//               int aqi = station.aqi;
//
//               // Tạo marker với màu dựa trên AQI
//               BitmapDescriptor markerIcon = await AQIUtils.getMarkerIconByAQI(aqi);
//
//               // Tạo marker cho thiết bị
//               Marker marker = Marker(
//                 markerId: MarkerId(key),
//                 position: LatLng(station.latitude, station.longitude),
//                 icon: markerIcon,
//                 infoWindow: InfoWindow(
//                   title: station.viTri,
//                   snippet: 'AQI: $aqi - ${station.getAqiDescription(currentL10n)}',
//                 ),
//                 onTap: () {
//                   print("[MapScreen] Marker tapped: ${station.viTri}");
//                   setState(() {
//                     _selectedStation = station;
//                   });
//                   // // Điều hướng đến màn hình chi tiết
//                   // Navigator.push(
//                   //   context,
//                   //   MaterialPageRoute(
//                   //     builder: (context) => StationDetailScreen(station: station),
//                   //   ),
//                   // );
//                 },
//               );
//
//               // Thêm marker vào set markers
//               newMarkers.add(marker);
//             } catch (e) {
//               print("[MapScreen] Error processing device $key: $e");
//             }
//           }
//
//           // Cập nhật state
//           setState(() {
//             _stations = newStations;
//             _markers = newMarkers;
//             isLoading = false;
//             _streamStatusMessage = '${currentL10n.markedDevicesOnMap ?? "Đã đánh dấu"} ${newStations.length} ${currentL10n.devicesOnMap ?? "thiết bị trên bản đồ"}';
//
//             // Sau 3 giây, xóa thông báo
//             Future.delayed(const Duration(seconds: 3), () {
//               if (mounted) {
//                 setState(() {
//                   _streamStatusMessage = '';
//                 });
//               }
//             });
//           });
//
//           print("[MapScreen] Updated ${newStations.length} stations and markers");
//
//           // Nếu có ít nhất một thiết bị, di chuyển camera đến vị trí trung tâm của các thiết bị
//           if (newStations.isNotEmpty && _mapController != null) {
//             _fitAllMarkers();
//           }
//
//           // In thông tin chi tiết về các thiết bị để dễ theo dõi
//           print("\n[MapScreen] === SUMMARY OF DEVICES ===");
//           newStations.forEach((key, station) {
//             print("[MapScreen] Device: ${station.viTri} (ID: ${station.id})");
//             print("  - Location: ${station.latitude}, ${station.longitude}");
//             print("  - Temperature: ${station.nhietDo}°C");
//             print("  - Humidity: ${station.doAm}%");
//             print("  - Dust concentration: ${station.nongDoBuiMin}");
//             print("  - AQI: ${station.aqi} (${station.getAqiDescription(currentL10n)})");
//             print("  ------------------------------");
//           });
//
//         } catch (e) {
//           print("[MapScreen] Error processing Firebase data: $e");
//           setState(() {
//             isLoading = false;
//             _streamStatusMessage = '${currentL10n.dataProcessingError ?? "Lỗi xử lý dữ liệu"}: ${e.toString()}';
//           });
//         }
//       },
//       onError: (error) {
//         print("[MapScreen] Firebase stream error: $error");
//         if (mounted) {
//           final currentL10n = AppLocalizations.of(context);
//           setState(() {
//             isLoading = false;
//             _streamStatusMessage = '${currentL10n?.firebaseConnectionError ?? "Lỗi kết nối"}: ${error.toString()}';
//           });
//         }
//       },
//     );
//   }
//
//   void _fitAllMarkers() {
//     if (_markers.isEmpty || _mapController == null) return;
//
//     print("[MapScreen] Fitting all markers on screen");
//
//     // Tạo LatLngBounds từ tất cả các marker
//     final bounds = _createBoundsFromMarkers();
//
//     // Di chuyển camera đến vị trí hiển thị tất cả marker
//     _mapController!.animateCamera(
//         CameraUpdate.newLatLngBounds(bounds, 50) // padding 50
//     );
//   }
//
//   LatLngBounds _createBoundsFromMarkers() {
//     double? minLat, maxLat, minLng, maxLng;
//
//     for (Marker marker in _markers) {
//       if (minLat == null || marker.position.latitude < minLat) {
//         minLat = marker.position.latitude;
//       }
//       if (maxLat == null || marker.position.latitude > maxLat) {
//         maxLat = marker.position.latitude;
//       }
//       if (minLng == null || marker.position.longitude < minLng) {
//         minLng = marker.position.longitude;
//       }
//       if (maxLng == null || marker.position.longitude > maxLng) {
//         maxLng = marker.position.longitude;
//       }
//     }
//
//     // Thêm padding cho bounds
//     minLat = minLat! - 0.01;
//     maxLat = maxLat! + 0.01;
//     minLng = minLng! - 0.01;
//     maxLng = maxLng! + 0.01;
//
//     return LatLngBounds(
//       southwest: LatLng(minLat, minLng),
//       northeast: LatLng(maxLat, maxLng),
//     );
//   }
//
//   void _onMapCreated(GoogleMapController controller) {
//     print("[MapScreen] Map created");
//     _mapController = controller;
//   }
//
// // Hàm di chuyển đến một thiết bị cụ thể
//   void _goToDevice(String deviceId) {
//     if (_stations.containsKey(deviceId) && _mapController != null) {
//       final station = _stations[deviceId]!;
//       print("[MapScreen] Going to device: ${station.viTri}");
//
//       // Di chuyển camera đến vị trí thiết bị
//       _mapController!.animateCamera(
//         CameraUpdate.newLatLngZoom(
//           LatLng(station.latitude, station.longitude),
//           16.0, // Mức zoom
//         ),
//       );
//
//       // Hiển thị thông tin thiết bị
//       setState(() {
//         _selectedStation = station;
//       });
//     } else {
//       print("[MapScreen] Device with ID $deviceId not found");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context);
//
//     print("[MapScreen] build called. Loading: $isLoading, Status: $_streamStatusMessage, Markers: ${_markers.length}");
//     return Scaffold(
//       body: Stack(
//         children: [
//           GoogleMap(
//             key: const ValueKey("google_map_main"),
//             onMapCreated: _onMapCreated,
//             initialCameraPosition: CameraPosition(
//               target: _initialPosition,
//               zoom: _initialZoom,
//             ),
//             markers: _markers,
//             myLocationButtonEnabled: false,
//             myLocationEnabled: true,
//             onTap: (LatLng position) {
//               print("[MapScreen] Map tapped at $position, hiding info card.");
//               setState(() {
//                 _selectedStation = null;
//               });
//             },
//           ),
//
//           // Hiển thị loading indicator hoặc thông báo trạng thái
//           if (isLoading)
//             Center(
//                 child: CircularProgressIndicator(
//                     semanticsLabel: l10n?.loadingMapData ?? 'Đang tải dữ liệu bản đồ...'
//                 )
//             ),
//
//           if (!isLoading && _streamStatusMessage.isNotEmpty)
//             Positioned(
//               top: MediaQuery.of(context).padding.top + 10,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                   decoration: BoxDecoration(
//                       color: _streamStatusMessage.toLowerCase().contains(l10n?.error?.toLowerCase() ?? "lỗi") ||
//                           _streamStatusMessage.toLowerCase().contains(l10n?.noData?.toLowerCase() ?? "không")
//                           ? Colors.redAccent.withOpacity(0.9)
//                           : Colors.black.withOpacity(0.75),
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.2),
//                           spreadRadius: 1,
//                           blurRadius: 3,
//                           offset: const Offset(0, 2),
//                         )
//                       ]
//                   ),
//                   child: Text(
//                     _streamStatusMessage,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
//                   ),
//                 ),
//               ),
//             ),
//
//           if (_selectedStation != null)
//             Positioned(
//               bottom: 20,
//               left: 15,
//               right: 15,
//               child: StationInfoCard(
//                 station: _selectedStation!,
//               ),
//             ),
//
//           Positioned(
//             bottom: 120, // Điều chỉnh vị trí theo ý muốn
//             right: 16,
//             child: FloatingActionButton(
//               heroTag: "btn_my_location",
//               mini: true,
//               backgroundColor: Colors.white,
//               child: const Icon(Icons.my_location, color: Colors.blue),
//               onPressed: _goToMyLocation,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _goToMyLocation() async {
//     final l10n = AppLocalizations.of(context);
//     if (l10n == null) return;
//
//     try {
//       // Kiểm tra quyền truy cập vị trí
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(l10n.locationPermissionDenied ?? 'Quyền truy cập vị trí bị từ chối')),
//             );
//           }
//           return;
//         }
//       }
//
//       if (permission == LocationPermission.deniedForever) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(l10n.locationPermissionDeniedForeverMessage ??
//                   'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng mở cài đặt để cấp quyền.'),
//             ),
//           );
//         }
//         return;
//       }
//
//       // Lấy vị trí hiện tại
//       Position position = await Geolocator.getCurrentPosition();
//       print("Vị trí hiện tại: ${position.latitude}, ${position.longitude}");
//
//       // Di chuyển camera đến vị trí hiện tại
//       if (_mapController != null) {
//         _mapController!.animateCamera(
//           CameraUpdate.newLatLngZoom(
//             LatLng(position.latitude, position.longitude),
//             16.0, // Mức zoom khi định vị
//           ),
//         );
//       }
//     } catch (e) {
//       print("Lỗi khi định vị: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('${l10n.cannotLocate ?? "Không thể định vị"}: ${e.toString()}')),
//         );
//       }
//     }
//   }
//
//   Widget _buildAQILegendItem(Color color, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 4),
//           Text(text, style: const TextStyle(fontSize: 12)),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle; // << 1. Import để đọc file asset
// import 'package:firebase_database/firebase_database.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:provider/provider.dart'; // << 2. Import Provider
// import '../../../services/theme_provider.dart'; // << 3. Import ThemeProvider của bạn
//
// import '../../../models/AQIUtils.dart';
// import '../../../models/station.dart';
// import '../../station_detail_screen/station_detail_screen.dart';
// import 'station_info_card.dart';
//
// class MapScreen extends StatefulWidget {
//   const MapScreen({Key? key}) : super(key: key);
//
//   @override
//   _MapScreenState createState() => _MapScreenState();
// }
//
// class _MapScreenState extends State<MapScreen> {
//   final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
//   bool isLoading = true;
//   String _streamStatusMessage = '';
//
//   final LatLng _initialPosition = const LatLng(21.0285, 105.8542); // Hà Nội
//   final double _initialZoom = 12.0;
//   Set<Marker> _markers = {};
//   GoogleMapController? _mapController;
//
//   Map<String, Station> _stations = {};
//   Station? _selectedStation;
//
//   StreamSubscription<DatabaseEvent>? _stationsSubscription;
//
//   // << 4. Thêm các biến để quản lý style bản đồ
//   String? _darkMapStyle;
//   ThemeMode? _previousThemeMode;
//
//   @override
//   void initState() {
//     super.initState();
//     print("[MapScreen] initState called");
//     _loadMapStyles(); // << 5. Tải style bản đồ khi khởi tạo
//
//     // Delay để đảm bảo context đã sẵn sàng cho localization
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _setupLocationPermission();
//       _listenToFirebaseData();
//     });
//   }
//
//   // << 6. Thêm hàm để tải style JSON từ assets
//   Future<void> _loadMapStyles() async {
//     try {
//       _darkMapStyle = await rootBundle.loadString('assets/map_styles/dark_mode.json');
//       print("[MapScreen] Dark map style loaded successfully.");
//     } catch (e) {
//       print("[MapScreen] Error loading dark map style: $e");
//     }
//   }
//
//   // << 7. Thêm hàm để cập nhật style bản đồ dựa trên theme
//   void _updateMapStyle() {
//     if (_mapController == null) return; // Nếu controller chưa sẵn sàng thì thoát
//
//     final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
//     final currentThemeMode = themeProvider.currentThemeMode;
//
//     // Xác định xem có nên dùng chế độ tối hay không
//     bool isDarkMode;
//     if (currentThemeMode == ThemeMode.system) {
//       isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
//     } else {
//       isDarkMode = currentThemeMode == ThemeMode.dark;
//     }
//
//     // Áp dụng style
//     if (isDarkMode) {
//       print("[MapScreen] Applying dark map style.");
//       _mapController!.setMapStyle(_darkMapStyle);
//     } else {
//       print("[MapScreen] Applying light map style (default).");
//       // Truyền `null` sẽ reset bản đồ về style mặc định (chế độ sáng)
//       _mapController!.setMapStyle(null);
//     }
//   }
//
//   // << 8. Thêm didChangeDependencies để lắng nghe sự thay đổi theme
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final currentThemeMode = Provider.of<ThemeProvider>(context).currentThemeMode;
//     // Chỉ cập nhật style nếu theme thực sự thay đổi
//     if (_previousThemeMode != currentThemeMode) {
//       _previousThemeMode = currentThemeMode;
//       // Nếu map controller đã sẵn sàng, cập nhật style
//       if (_mapController != null) {
//         _updateMapStyle();
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _stationsSubscription?.cancel();
//     _mapController?.dispose();
//     super.dispose();
//   }
//
//   // ... (Các hàm _setupLocationPermission, _listenToFirebaseData, v.v. giữ nguyên)
//   Future<void> _setupLocationPermission() async {
//     final l10n = AppLocalizations.of(context);
//     if (l10n == null) return;
//
//     print("[MapScreen] Setting up location permissions");
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       if (mounted) {
//         setState(() {
//           _streamStatusMessage = l10n.locationServiceDisabled ?? 'Dịch vụ vị trí bị tắt';
//         });
//       }
//       return;
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         if (mounted) {
//           setState(() {
//             _streamStatusMessage = l10n.locationPermissionDenied ?? 'Quyền vị trí bị từ chối';
//           });
//         }
//         return;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       if (mounted) {
//         setState(() {
//           _streamStatusMessage = l10n.locationPermissionDeniedForever ?? 'Quyền vị trí bị từ chối vĩnh viễn';
//         });
//       }
//       return;
//     }
//
//     try {
//       Position position = await Geolocator.getCurrentPosition();
//       if (_mapController != null) {
//         _mapController!.animateCamera(
//             CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude))
//         );
//       }
//     } catch (e) {
//       print("[MapScreen] Error getting current location: $e");
//     }
//   }
//
//   void _listenToFirebaseData() {
//     final l10n = AppLocalizations.of(context);
//     if (l10n == null) {
//       print("[MapScreen] AppLocalizations not available yet, retrying...");
//       Future.delayed(const Duration(milliseconds: 100), _listenToFirebaseData);
//       return;
//     }
//
//     print("[MapScreen] Starting to listen to Firebase data");
//     if (mounted) {
//       setState(() {
//         isLoading = true;
//         _streamStatusMessage = l10n.connectingToDatabase ?? 'Đang kết nối đến cơ sở dữ liệu...';
//       });
//     }
//
//     _stationsSubscription = _databaseRef.child('cacThietBiQuanTrac').onValue.listen(
//           (DatabaseEvent event) async {
//         if (!mounted) return;
//
//         final currentL10n = AppLocalizations.of(context);
//         if (currentL10n == null) return;
//
//         print("[MapScreen] Received Firebase data event");
//
//         if (event.snapshot.value == null) {
//           setState(() {
//             isLoading = false;
//             _streamStatusMessage = currentL10n.noDeviceData ?? 'Không có dữ liệu thiết bị';
//             _markers.clear();
//             _stations.clear();
//           });
//           return;
//         }
//
//         try {
//           print("[MapScreen] Raw data from Firebase:");
//           print(event.snapshot.value);
//
//           Map<dynamic, dynamic> values = event.snapshot.value as Map<dynamic, dynamic>;
//           print("[MapScreen] Number of devices: ${values.length}");
//
//           Map<String, Station> newStations = {};
//           Set<Marker> newMarkers = {};
//
//           // Xử lý từng thiết bị và tạo marker
//           for (var entry in values.entries) {
//             String key = entry.key;
//             var value = entry.value;
//
//             try {
//               print("[MapScreen] Processing device with key: $key");
//               print("Device data: $value");
//
//               if (value['lat'] == null || value['long'] == null) {
//                 print("[MapScreen] Missing location data for device $key");
//                 continue;
//               }
//
//               // Tạo đối tượng Station từ dữ liệu Firebase với localization
//               Station station = await Station.fromFirebaseLocalized(value, key, currentL10n);
//               print("[MapScreen] Device location: ${station.latitude}, ${station.longitude}");
//
//               // Thêm vào map stations
//               newStations[key] = station;
//
//               // Tính toán AQI và lấy màu tương ứng
//               int aqi = station.aqi;
//
//               // Tạo marker với màu dựa trên AQI
//               BitmapDescriptor markerIcon = await AQIUtils.getMarkerIconByAQI(aqi);
//
//               // Tạo marker cho thiết bị
//               Marker marker = Marker(
//                 markerId: MarkerId(key),
//                 position: LatLng(station.latitude, station.longitude),
//                 icon: markerIcon,
//                 infoWindow: InfoWindow(
//                   title: station.viTri,
//                   snippet: 'AQI: $aqi - ${station.getAqiDescription(currentL10n)}',
//                 ),
//                 onTap: () {
//                   print("[MapScreen] Marker tapped: ${station.viTri}");
//                   setState(() {
//                     _selectedStation = station;
//                   });
//                   // // Điều hướng đến màn hình chi tiết
//                   // Navigator.push(
//                   //   context,
//                   //   MaterialPageRoute(
//                   //     builder: (context) => StationDetailScreen(station: station),
//                   //   ),
//                   // );
//                 },
//               );
//
//               // Thêm marker vào set markers
//               newMarkers.add(marker);
//             } catch (e) {
//               print("[MapScreen] Error processing device $key: $e");
//             }
//           }
//
//           // Cập nhật state
//           setState(() {
//             _stations = newStations;
//             _markers = newMarkers;
//             isLoading = false;
//             _streamStatusMessage = '${currentL10n.markedDevicesOnMap ?? "Đã đánh dấu"} ${newStations.length} ${currentL10n.devicesOnMap ?? "thiết bị trên bản đồ"}';
//
//             // Sau 3 giây, xóa thông báo
//             Future.delayed(const Duration(seconds: 3), () {
//               if (mounted) {
//                 setState(() {
//                   _streamStatusMessage = '';
//                 });
//               }
//             });
//           });
//
//           print("[MapScreen] Updated ${newStations.length} stations and markers");
//
//           // Nếu có ít nhất một thiết bị, di chuyển camera đến vị trí trung tâm của các thiết bị
//           if (newStations.isNotEmpty && _mapController != null) {
//             _fitAllMarkers();
//           }
//
//           // In thông tin chi tiết về các thiết bị để dễ theo dõi
//           print("\n[MapScreen] === SUMMARY OF DEVICES ===");
//           newStations.forEach((key, station) {
//             print("[MapScreen] Device: ${station.viTri} (ID: ${station.id})");
//             print("  - Location: ${station.latitude}, ${station.longitude}");
//             print("  - Temperature: ${station.nhietDo}°C");
//             print("  - Humidity: ${station.doAm}%");
//             print("  - Dust concentration: ${station.nongDoBuiMin}");
//             print("  - AQI: ${station.aqi} (${station.getAqiDescription(currentL10n)})");
//             print("  ------------------------------");
//           });
//
//         } catch (e) {
//           print("[MapScreen] Error processing Firebase data: $e");
//           setState(() {
//             isLoading = false;
//             _streamStatusMessage = '${currentL10n.dataProcessingError ?? "Lỗi xử lý dữ liệu"}: ${e.toString()}';
//           });
//         }
//       },
//       onError: (error) {
//         print("[MapScreen] Firebase stream error: $error");
//         if (mounted) {
//           final currentL10n = AppLocalizations.of(context);
//           setState(() {
//             isLoading = false;
//             _streamStatusMessage = '${currentL10n?.firebaseConnectionError ?? "Lỗi kết nối"}: ${error.toString()}';
//           });
//         }
//       },
//     );
//   }
//
//   void _fitAllMarkers() {
//     if (_markers.isEmpty || _mapController == null) return;
//
//     print("[MapScreen] Fitting all markers on screen");
//
//     // Tạo LatLngBounds từ tất cả các marker
//     final bounds = _createBoundsFromMarkers();
//
//     // Di chuyển camera đến vị trí hiển thị tất cả marker
//     _mapController!.animateCamera(
//         CameraUpdate.newLatLngBounds(bounds, 50) // padding 50
//     );
//   }
//
//   LatLngBounds _createBoundsFromMarkers() {
//     double? minLat, maxLat, minLng, maxLng;
//
//     for (Marker marker in _markers) {
//       if (minLat == null || marker.position.latitude < minLat) {
//         minLat = marker.position.latitude;
//       }
//       if (maxLat == null || marker.position.latitude > maxLat) {
//         maxLat = marker.position.latitude;
//       }
//       if (minLng == null || marker.position.longitude < minLng) {
//         minLng = marker.position.longitude;
//       }
//       if (maxLng == null || marker.position.longitude > maxLng) {
//         maxLng = marker.position.longitude;
//       }
//     }
//
//     // Thêm padding cho bounds
//     minLat = minLat! - 0.01;
//     maxLat = maxLat! + 0.01;
//     minLng = minLng! - 0.01;
//     maxLng = maxLng! + 0.01;
//
//     return LatLngBounds(
//       southwest: LatLng(minLat, minLng),
//       northeast: LatLng(maxLat, maxLng),
//     );
//   }
//
//
//   void _onMapCreated(GoogleMapController controller) {
//     print("[MapScreen] Map created");
//     _mapController = controller;
//     _updateMapStyle(); // << 9. Áp dụng style ngay khi bản đồ được tạo xong
//   }
//
// // Hàm di chuyển đến một thiết bị cụ thể
//   void _goToDevice(String deviceId) {
//     if (_stations.containsKey(deviceId) && _mapController != null) {
//       final station = _stations[deviceId]!;
//       print("[MapScreen] Going to device: ${station.viTri}");
//
//       // Di chuyển camera đến vị trí thiết bị
//       _mapController!.animateCamera(
//         CameraUpdate.newLatLngZoom(
//           LatLng(station.latitude, station.longitude),
//           16.0, // Mức zoom
//         ),
//       );
//
//       // Hiển thị thông tin thiết bị
//       setState(() {
//         _selectedStation = station;
//       });
//     } else {
//       print("[MapScreen] Device with ID $deviceId not found");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context);
//
//     print("[MapScreen] build called. Loading: $isLoading, Status: $_streamStatusMessage, Markers: ${_markers.length}");
//     return Scaffold(
//       body: Stack(
//         children: [
//           GoogleMap(
//             key: const ValueKey("google_map_main"),
//             onMapCreated: _onMapCreated, // << Hàm này đã được cập nhật
//             initialCameraPosition: CameraPosition(
//               target: _initialPosition,
//               zoom: _initialZoom,
//             ),
//             markers: _markers,
//             myLocationButtonEnabled: false,
//             myLocationEnabled: true,
//             onTap: (LatLng position) {
//               print("[MapScreen] Map tapped at $position, hiding info card.");
//               setState(() {
//                 _selectedStation = null;
//               });
//             },
//           ),
//
//           // Hiển thị loading indicator hoặc thông báo trạng thái
//           if (isLoading)
//             Center(
//                 child: CircularProgressIndicator(
//                     semanticsLabel: l10n?.loadingMapData ?? 'Đang tải dữ liệu bản đồ...'
//                 )
//             ),
//
//           if (!isLoading && _streamStatusMessage.isNotEmpty)
//             Positioned(
//               top: MediaQuery.of(context).padding.top + 10,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                   decoration: BoxDecoration(
//                       color: _streamStatusMessage.toLowerCase().contains(l10n?.error?.toLowerCase() ?? "lỗi") ||
//                           _streamStatusMessage.toLowerCase().contains(l10n?.noData?.toLowerCase() ?? "không")
//                           ? Colors.redAccent.withOpacity(0.9)
//                           : Colors.black.withOpacity(0.75),
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.2),
//                           spreadRadius: 1,
//                           blurRadius: 3,
//                           offset: const Offset(0, 2),
//                         )
//                       ]
//                   ),
//                   child: Text(
//                     _streamStatusMessage,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
//                   ),
//                 ),
//               ),
//             ),
//
//           if (_selectedStation != null)
//             Positioned(
//               bottom: 20,
//               left: 15,
//               right: 15,
//               child: StationInfoCard(
//                 station: _selectedStation!,
//               ),
//             ),
//
//           Positioned(
//             bottom: 120, // Điều chỉnh vị trí theo ý muốn
//             right: 16,
//             child: FloatingActionButton(
//               heroTag: "btn_my_location",
//               mini: true,
//               backgroundColor: Colors.white,
//               child: const Icon(Icons.my_location, color: Colors.blue),
//               onPressed: _goToMyLocation,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _goToMyLocation() async {
//     final l10n = AppLocalizations.of(context);
//     if (l10n == null) return;
//
//     try {
//       // Kiểm tra quyền truy cập vị trí
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(l10n.locationPermissionDenied ?? 'Quyền truy cập vị trí bị từ chối')),
//             );
//           }
//           return;
//         }
//       }
//
//       if (permission == LocationPermission.deniedForever) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(l10n.locationPermissionDeniedForeverMessage ??
//                   'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng mở cài đặt để cấp quyền.'),
//             ),
//           );
//         }
//         return;
//       }
//
//       // Lấy vị trí hiện tại
//       Position position = await Geolocator.getCurrentPosition();
//       print("Vị trí hiện tại: ${position.latitude}, ${position.longitude}");
//
//       // Di chuyển camera đến vị trí hiện tại
//       if (_mapController != null) {
//         _mapController!.animateCamera(
//           CameraUpdate.newLatLngZoom(
//             LatLng(position.latitude, position.longitude),
//             16.0, // Mức zoom khi định vị
//           ),
//         );
//       }
//     } catch (e) {
//       print("Lỗi khi định vị: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('${l10n.cannotLocate ?? "Không thể định vị"}: ${e.toString()}')),
//         );
//       }
//     }
//   }
//
//   Widget _buildAQILegendItem(Color color, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 4),
//           Text(text, style: const TextStyle(fontSize: 12)),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../services/theme_provider.dart';

import '../../../models/AQIUtils.dart';
import '../../../models/station.dart';
import '../../station_detail_screen/station_detail_screen.dart';
import 'station_info_card.dart';

class MapScreen extends StatefulWidget {
  final String? highlightedStationId;

  const MapScreen({Key? key, this.highlightedStationId}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  bool isLoading = true;
  String _streamStatusMessage = '';

  final LatLng _initialPosition = const LatLng(21.0285, 105.8542); // Hà Nội
  final double _initialZoom = 12.0;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  Map<String, Station> _stations = {};
  Station? _selectedStation;

  StreamSubscription<DatabaseEvent>? _stationsSubscription;

  String? _darkMapStyle;
  ThemeMode? _previousThemeMode;
  bool _notificationTapHandled = false;

  @override
  void initState() {
    super.initState();
    print("[MapScreen] initState called");
    _loadMapStyles();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupLocationPermission();
      _listenToFirebaseData();
    });
  }

  Future<void> _loadMapStyles() async {
    try {
      _darkMapStyle = await rootBundle.loadString('assets/map_styles/dark_mode.json');
      print("[MapScreen] Dark map style loaded successfully.");
    } catch (e) {
      print("[MapScreen] Error loading dark map style: $e");
    }
  }

  void _updateMapStyle() {
    if (_mapController == null) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final currentThemeMode = themeProvider.currentThemeMode;

    bool isDarkMode;
    if (currentThemeMode == ThemeMode.system) {
      isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
    } else {
      isDarkMode = currentThemeMode == ThemeMode.dark;
    }

    if (isDarkMode) {
      _mapController!.setMapStyle(_darkMapStyle);
    } else {
      _mapController!.setMapStyle(null);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentThemeMode = Provider.of<ThemeProvider>(context).currentThemeMode;
    if (_previousThemeMode != currentThemeMode) {
      _previousThemeMode = currentThemeMode;
      if (_mapController != null) {
        _updateMapStyle();
      }
    }
  }

  @override
  void dispose() {
    _stationsSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _setupLocationPermission() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    print("[MapScreen] Setting up location permissions");
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _streamStatusMessage = l10n.locationServiceDisabled;
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _streamStatusMessage = l10n.locationPermissionDenied;
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _streamStatusMessage = l10n.locationPermissionDeniedForever;
        });
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      if (_mapController != null) {
        _mapController!.animateCamera(
            CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude))
        );
      }
    } catch (e) {
      print("[MapScreen] Error getting current location: $e");
    }
  }

  void _listenToFirebaseData() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      Future.delayed(const Duration(milliseconds: 100), _listenToFirebaseData);
      return;
    }

    if (mounted) {
      setState(() {
        isLoading = true;
        _streamStatusMessage = l10n.connectingToDatabase ?? 'Đang kết nối...';
      });
    }

    _stationsSubscription = _databaseRef.child('cacThietBiQuanTrac').onValue.listen(
          (DatabaseEvent event) async {
        if (!mounted) return;

        final currentL10n = AppLocalizations.of(context);
        if (currentL10n == null) return;

        if (event.snapshot.value == null) {
          setState(() {
            isLoading = false;
            _streamStatusMessage = currentL10n.noDeviceData ?? 'Không có dữ liệu thiết bị';
            _markers.clear();
            _stations.clear();
          });
          return;
        }

        try {
          Map<dynamic, dynamic> values = event.snapshot.value as Map<dynamic, dynamic>;
          Map<String, Station> newStations = {};
          Set<Marker> newMarkers = {};

          for (var entry in values.entries) {
            String key = entry.key;
            var value = entry.value;

            try {
              if (value['lat'] == null || value['long'] == null) continue;

              Station station = await Station.fromFirebaseLocalized(value, key, currentL10n);
              newStations[key] = station;

              int aqi = station.aqi;
              BitmapDescriptor markerIcon = await AQIUtils.getMarkerIconByAQI(aqi);

              Marker marker = Marker(
                markerId: MarkerId(key),
                position: LatLng(station.latitude, station.longitude),
                icon: markerIcon,
                infoWindow: InfoWindow(
                  title: station.viTri,
                  snippet: 'AQI: $aqi - ${station.getAqiDescription(currentL10n)}',
                ),
                onTap: () {
                  setState(() {
                    _selectedStation = station;
                  });
                },
              );
              newMarkers.add(marker);
            } catch (e) {
              print("[MapScreen] Error processing device $key: $e");
            }
          }

          setState(() {
            _stations = newStations;
            _markers = newMarkers;
            isLoading = false;
            _streamStatusMessage = '${currentL10n.markedDevicesOnMap ?? "Đã đánh dấu"} ${newStations.length} ${currentL10n.devicesOnMap ?? "thiết bị trên bản đồ"}';

            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) setState(() => _streamStatusMessage = '');
            });
          });

          // Xử lý việc điều hướng từ thông báo
          if (widget.highlightedStationId != null && !_notificationTapHandled) {
            setState(() => _notificationTapHandled = true);
            _goToDevice(widget.highlightedStationId!);
          } else if (newStations.isNotEmpty && _mapController != null) {
            _fitAllMarkers();
          }

        } catch (e) {
          setState(() {
            isLoading = false;
            _streamStatusMessage = '${currentL10n.dataProcessingError ?? "Lỗi xử lý dữ liệu"}: ${e.toString()}';
          });
        }
      },
      onError: (error) {
        if (mounted) {
          final currentL10n = AppLocalizations.of(context);
          setState(() {
            isLoading = false;
            _streamStatusMessage = '${currentL10n?.firebaseConnectionError ?? "Lỗi kết nối"}: ${error.toString()}';
          });
        }
      },
    );
  }

  void _fitAllMarkers() {
    if (_markers.isEmpty || _mapController == null) return;
    final bounds = _createBoundsFromMarkers();
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  LatLngBounds _createBoundsFromMarkers() {
    double? minLat, maxLat, minLng, maxLng;
    for (Marker marker in _markers) {
      if (minLat == null || marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (maxLat == null || marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (minLng == null || marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (maxLng == null || marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat! - 0.01, minLng! - 0.01),
      northeast: LatLng(maxLat! + 0.01, maxLng! + 0.01),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMapStyle();
  }

  void _goToDevice(String deviceId) {
    if (_stations.containsKey(deviceId) && _mapController != null) {
      final station = _stations[deviceId]!;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(station.latitude, station.longitude), 16.0),
      );
      setState(() => _selectedStation = station);
    } else {
      print("[MapScreen] Device with ID $deviceId not found");
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            key: const ValueKey("google_map_main"),
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: _initialZoom,
            ),
            markers: _markers,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            onTap: (LatLng position) {
              setState(() {
                _selectedStation = null;
              });
            },
            zoomControlsEnabled: false,
          ),
          if (isLoading)
            Center(child: CircularProgressIndicator(semanticsLabel: l10n?.loadingMapData)),
          if (!isLoading && _streamStatusMessage.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      color: _streamStatusMessage.toLowerCase().contains(l10n?.error?.toLowerCase() ?? "lỗi") ||
                          _streamStatusMessage.toLowerCase().contains(l10n?.noData?.toLowerCase() ?? "không")
                          ? Colors.redAccent.withOpacity(0.9)
                          : Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        )
                      ]
                  ),
                  child: Text(
                    _streamStatusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          if (_selectedStation != null)
            Positioned(
              bottom: 20,
              left: 15,
              right: 15,

              child: StationInfoCard(station: _selectedStation!),


            ),
          Positioned(
            bottom: (_selectedStation != null) ? 180 : 20,
            right: 16,
            child: FloatingActionButton(
              heroTag: "btn_my_location",
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.locationPermissionDenied)),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.locationPermissionDeniedForeverMessage),
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 16.0),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.cannotLocate ?? "Không thể định vị"}: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildAQILegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
