// screens/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/AQIUtils.dart';
import '../../../models/station.dart';
import '../../station_detail_screen/station_detail_screen.dart';
import 'station_info_card.dart';



class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    print("[MapScreen] initState called");
    _setupLocationPermission();
    _listenToFirebaseData();
  }

  @override
  void dispose() {
    _stationsSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _setupLocationPermission() async {
    print("[MapScreen] Setting up location permissions");
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _streamStatusMessage = 'Dịch vụ vị trí bị tắt';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _streamStatusMessage = 'Quyền vị trí bị từ chối';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _streamStatusMessage = 'Quyền vị trí bị từ chối vĩnh viễn';
      });
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
    print("[MapScreen] Starting to listen to Firebase data");
    setState(() {
      isLoading = true;
      _streamStatusMessage = 'Đang kết nối đến cơ sở dữ liệu...';
    });

    _stationsSubscription = _databaseRef.child('cacThietBiQuanTrac').onValue.listen(
          (DatabaseEvent event) async {
        print("[MapScreen] Received Firebase data event");

        if (event.snapshot.value == null) {
          setState(() {
            isLoading = false;
            _streamStatusMessage = 'Không có dữ liệu thiết bị';
            _markers.clear();
            _stations.clear();
          });
          return;
        }

        try {
          print("[MapScreen] Raw data from Firebase:");
          print(event.snapshot.value);

          Map<dynamic, dynamic> values = event.snapshot.value as Map<dynamic, dynamic>;
          print("[MapScreen] Number of devices: ${values.length}");

          Map<String, Station> newStations = {};
          Set<Marker> newMarkers = {};

          // Xử lý từng thiết bị và tạo marker
          for (var entry in values.entries) {
            String key = entry.key;
            var value = entry.value;

            try {
              print("[MapScreen] Processing device with key: $key");
              print("Device data: $value");

              if (value['lat'] == null || value['long'] == null) {
                print("[MapScreen] Missing location data for device $key");
                continue;
              }

              // Tạo đối tượng Station từ dữ liệu Firebase
              Station station = await Station.fromFirebase(value, key);
              print("[MapScreen] Device location: ${station.latitude}, ${station.longitude}");

              // Thêm vào map stations
              newStations[key] = station;

              // Tính toán AQI và lấy màu tương ứng
              int aqi = station.aqi;

              // Tạo marker với màu dựa trên AQI
              BitmapDescriptor markerIcon = await AQIUtils.getMarkerIconByAQI(aqi);

              // Tạo marker cho thiết bị
              Marker marker = Marker(
                markerId: MarkerId(key),
                position: LatLng(station.latitude, station.longitude),
                icon: markerIcon,
                infoWindow: InfoWindow(
                  title: station.viTri,
                  //snippet: 'AQI: $aqi - ${station.aqiDescription}',
                ),
                onTap: () {
                  print("[MapScreen] Marker tapped: ${station.viTri}");
                  setState(() {
                    _selectedStation = station;
                  });
                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StationDetailScreen(station: station),
                      ),
                    );
                  };
                },
              );

              // Thêm marker vào set markers
              newMarkers.add(marker);
            } catch (e) {
              print("[MapScreen] Error processing device $key: $e");
            }
          }

          // Cập nhật state
          setState(() {
            _stations = newStations;
            _markers = newMarkers;
            isLoading = false;
            _streamStatusMessage = 'Đã đánh dấu ${newStations.length} thiết bị trên bản đồ';

            // Sau 3 giây, xóa thông báo
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _streamStatusMessage = '';
                });
              }
            });
          });

          print("[MapScreen] Updated ${newStations.length} stations and markers");

          // Nếu có ít nhất một thiết bị, di chuyển camera đến vị trí trung tâm của các thiết bị
          if (newStations.isNotEmpty && _mapController != null) {
            _fitAllMarkers();
          }

          // In thông tin chi tiết về các thiết bị để dễ theo dõi
          print("\n[MapScreen] === SUMMARY OF DEVICES ===");
          newStations.forEach((key, station) {
            print("[MapScreen] Device: ${station.viTri} (ID: ${station.id})");
            print("  - Location: ${station.latitude}, ${station.longitude}");
            print("  - Temperature: ${station.nhietDo}°C");
            print("  - Humidity: ${station.doAm}%");
            print("  - Dust concentration: ${station.nongDoBuiMin}");
            print("  - AQI: ${station.aqi} (${station.aqiDescription})");
            print("  ------------------------------");
          });

        } catch (e) {
          print("[MapScreen] Error processing Firebase data: $e");
          setState(() {
            isLoading = false;
            _streamStatusMessage = 'Lỗi xử lý dữ liệu: ${e.toString()}';
          });
        }
      },
      onError: (error) {
        print("[MapScreen] Firebase stream error: $error");
        setState(() {
          isLoading = false;
          _streamStatusMessage = 'Lỗi kết nối: ${error.toString()}';
        });
      },
    );
  }

  void _fitAllMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    print("[MapScreen] Fitting all markers on screen");

    // Tạo LatLngBounds từ tất cả các marker
    final bounds = _createBoundsFromMarkers();

    // Di chuyển camera đến vị trí hiển thị tất cả marker
    _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50) // padding 50
    );
  }

  LatLngBounds _createBoundsFromMarkers() {
    double? minLat, maxLat, minLng, maxLng;

    for (Marker marker in _markers) {
      if (minLat == null || marker.position.latitude < minLat) {
        minLat = marker.position.latitude;
      }
      if (maxLat == null || marker.position.latitude > maxLat) {
        maxLat = marker.position.latitude;
      }
      if (minLng == null || marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (maxLng == null || marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    // Thêm padding cho bounds
    minLat = minLat! - 0.01;
    maxLat = maxLat! + 0.01;
    minLng = minLng! - 0.01;
    maxLng = maxLng! + 0.01;

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    print("[MapScreen] Map created");
    _mapController = controller;
  }

  // Hàm di chuyển đến một thiết bị cụ thể
  void _goToDevice(String deviceId) {
    if (_stations.containsKey(deviceId) && _mapController != null) {
      final station = _stations[deviceId]!;
      print("[MapScreen] Going to device: ${station.viTri}");

      // Di chuyển camera đến vị trí thiết bị
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(station.latitude, station.longitude),
          16.0, // Mức zoom
        ),
      );

      // Hiển thị thông tin thiết bị
      setState(() {
        _selectedStation = station;
      });
    } else {
      print("[MapScreen] Device with ID $deviceId not found");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("[MapScreen] build called. Loading: $isLoading, Status: $_streamStatusMessage, Markers: ${_markers.length}");
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
              print("[MapScreen] Map tapped at $position, hiding info card.");
              setState(() {
                _selectedStation = null;
              });
            },
          ),

          // Hiển thị loading indicator hoặc thông báo trạng thái
          if (isLoading)
            const Center(child: CircularProgressIndicator(semanticsLabel: 'Đang tải dữ liệu bản đồ...')),

          if (!isLoading && _streamStatusMessage.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      color: _streamStatusMessage.toLowerCase().contains("lỗi") || _streamStatusMessage.toLowerCase().contains("không")
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
              child: StationInfoCard(
                station: _selectedStation!,
              ),
            ),


          Positioned(
            bottom: 120, // Điều chỉnh vị trí theo ý muốn
            right: 16,
            child: FloatingActionButton(
              heroTag: "btn_my_location",
              mini: true,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
              onPressed: _goToMyLocation,
            ),
          ),


          // Thêm các nút điều khiển
          // Positioned(
          //   bottom: _selectedStation != null ? 140 : 20,
          //   right: 10,
          //   child: Column(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       // Nút để hiển thị tất cả marker
          //       FloatingActionButton(
          //         heroTag: "btn_all",
          //         mini: true,
          //         backgroundColor: Colors.white,
          //         child: const Icon(Icons.map, color: Colors.blue),
          //         onPressed: _fitAllMarkers,
          //       ),
          //       const SizedBox(height: 8),
          //
          //       // Thêm các nút cho từng thiết bị nếu cần
          //       // ..._stations.entries.map((entry) {
          //       //   int index = _stations.keys.toList().indexOf(entry.key) + 1;
          //       //   return Padding(
          //       //     padding: const EdgeInsets.only(bottom: 8),
          //       //     child: FloatingActionButton(
          //       //       heroTag: "btn_device_$index",
          //       //       mini: true,
          //       //       backgroundColor: entry.value.aqiColor.withOpacity(0.7),
          //       //       child: Text(
          //       //         "$index",
          //       //         style: TextStyle(
          //       //             color: entry.value.aqiColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          //       //             fontWeight: FontWeight.bold
          //       //         ),
          //       //       ),
          //       //       onPressed: () => _goToDevice(entry.key),
          //       //     ),
          //       //   );
          //       // }).toList(),
          //     ],
          //   ),
          // ),

          // Thêm chú thích về màu AQI
          // Positioned(
          //   top: MediaQuery.of(context).padding.top + 10,
          //   left: 10,
          //   child: Container(
          //     padding: const EdgeInsets.all(8),
          //     decoration: BoxDecoration(
          //       color: Colors.white.withOpacity(0.8),
          //       borderRadius: BorderRadius.circular(8),
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.black.withOpacity(0.1),
          //           spreadRadius: 1,
          //           blurRadius: 2,
          //           offset: const Offset(0, 1),
          //         )
          //       ],
          //     ),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         const Text('Chỉ số AQI:', style: TextStyle(fontWeight: FontWeight.bold)),
          //         const SizedBox(height: 4),
          //         _buildAQILegendItem(Colors.green, 'Tốt (0-50)'),
          //         _buildAQILegendItem(Colors.yellow, 'Trung bình (51-100)'),
          //         _buildAQILegendItem(Colors.orange, 'Không tốt cho nhóm nhạy cảm (101-150)'),
          //         _buildAQILegendItem(Colors.red, 'Không tốt cho sức khỏe (151-200)'),
          //         _buildAQILegendItem(Colors.purple, 'Rất không tốt (201-300)'),
          //         _buildAQILegendItem(Colors.brown, 'Nguy hiểm (>300)'),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    try {
      // Kiểm tra quyền truy cập vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng mở cài đặt để cấp quyền.'),
          ),
        );
        return;
      }

      // Lấy vị trí hiện tại
      Position position = await Geolocator.getCurrentPosition();
      print("Vị trí hiện tại: ${position.latitude}, ${position.longitude}");

      print(_mapController==null);
      // Di chuyển camera đến vị trí hiện tại
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16.0, // Mức zoom khi định vị
          ),
        );

      }
    } catch (e) {
      print("Lỗi khi định vị: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể định vị: ${e.toString()}')),
      );
    }}

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


