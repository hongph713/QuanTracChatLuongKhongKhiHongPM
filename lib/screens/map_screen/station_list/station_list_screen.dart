import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:collection/collection.dart'; // THÊM IMPORT NÀY
import '../../../models/station.dart'; // Model Station của bạn
import '../widgets/station_info_card.dart'; // Widget StationInfoCard bạn đã xây dựng

class StationListScreen extends StatefulWidget {
  final Function(String stationId)? onStationSelected; // Callback khi một trạm được chọn

  const StationListScreen({Key? key, this.onStationSelected}) : super(key: key);

  @override
  _StationListScreenState createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child('cacThietBiQuanTrac');
  StreamSubscription<DatabaseEvent>? _stationsSubscription;

  List<Station> _allStations = []; // Danh sách tất cả các trạm từ Firebase
  List<Station> _filteredStations = []; // Danh sách trạm đã được lọc bởi tìm kiếm

  bool _isLoading = true;
  String _statusMessage = ''; // Để hiển thị thông báo (lỗi, không có dữ liệu, v.v.)
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print("[StationListScreen] initState called");
    _listenToFirebaseData();
    _searchController.addListener(_filterStations); // Gọi _filterStations mỗi khi text thay đổi
  }

  void _listenToFirebaseData() {
    print("[StationListScreen] Starting to listen to Firebase data");
    if (mounted) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Đang tải dữ liệu...';
      });
    }

    _stationsSubscription = _databaseRef.onValue.listen(
      // Đánh dấu callback này là async để có thể dùng await bên trong
          (DatabaseEvent event) async {
        if (!mounted) return;
        print("[StationListScreen] Received Firebase data event");
        _isLoading = false;

        if (event.snapshot.value == null) {
          setState(() {
            _allStations = [];
            _filterStations();
          });
          print("[StationListScreen] Firebase snapshot is null.");
          return;
        }

        try {
          final data = event.snapshot.value;
          if (data is! Map) {
            setState(() {
              _allStations = [];
              _statusMessage = 'Dữ liệu Firebase không đúng định dạng.';
              _filterStations();
            });
            print("[StationListScreen] Firebase data is not a Map.");
            return;
          }

          final Map<dynamic, dynamic> stationDataMap = data as Map<dynamic, dynamic>;
          // Sử dụng List<Future<Station?>> để xử lý trường hợp fromFirebase có thể trả về null hoặc lỗi
          final List<Future<Station?>> futureStations = [];

          stationDataMap.forEach((key, value) {
            if (value is Map) {
              // Giả sử Station.fromFirebase là async và có thể trả về Future<Station>
              // hoặc Future<Station?> nếu có thể có lỗi parse cho từng item
              futureStations.add(
                  Station.fromFirebase(value as Map<dynamic,dynamic>, key.toString())
                      .then((station) => station) // Đảm bảo kiểu trả về là Future<Station?>
                      .catchError((e, s) {
                    print("[StationListScreen] Error parsing station with key $key: $e");
                    print(s);
                    return null; // Trả về null nếu có lỗi parse cho một trạm cụ thể
                  })
              );
            } else {
              print("[StationListScreen] Data for key $key is not a Map: $value");
            }
          });

          // Đợi tất cả các Future hoàn thành và lọc bỏ các giá trị null (do lỗi parse)
          final List<Station?> parsedStationsNullable = await Future.wait(futureStations);
          final List<Station> fetchedStations = parsedStationsNullable.whereType<Station>().toList();


          setState(() {
            _allStations = fetchedStations;
            _filterStations();
          });
          print("[StationListScreen] Updated ${_allStations.length} stations.");

        } catch (e, s) {
          print("[StationListScreen] Error processing Firebase data: $e");
          print(s);
          setState(() {
            _allStations = [];
            _statusMessage = 'Lỗi xử lý dữ liệu: ${e.toString()}';
            _filterStations();
          });
        }
      },
      onError: (error) {
        print("[StationListScreen] Firebase stream error: $error");
        if (mounted) {
          setState(() {
            _isLoading = false;
            _allStations = [];
            _statusMessage = 'Lỗi kết nối Firebase: ${error.toString()}';
            _filterStations();
          });
        }
      },
    );
  }

  void _filterStations() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase();
    List<Station> tempFilteredStations;

    if (query.isEmpty) {
      tempFilteredStations = List.from(_allStations);
    } else {
      tempFilteredStations = _allStations
          .where((station) =>
          station.viTri.toLowerCase().contains(query))
          .toList();
    }

    String newStatusMessage = '';
    if (!_isLoading) {
      if (_allStations.isEmpty) {
        if (_statusMessage.toLowerCase().contains('lỗi') ||
            _statusMessage == 'Dữ liệu Firebase không đúng định dạng.' ||
            _statusMessage == 'Không có dữ liệu thiết bị nào.') {
          newStatusMessage = _statusMessage;
        } else {
          newStatusMessage = 'Không có dữ liệu trạm nào.';
        }
      } else if (tempFilteredStations.isEmpty) {
        if (query.isNotEmpty) {
          newStatusMessage = 'Không tìm thấy trạm nào cho "$query".';
        }
      }
    } else {
      newStatusMessage = 'Đang tải dữ liệu...';
    }

    if (_filteredStations.length != tempFilteredStations.length ||
        !const ListEquality().equals(_filteredStations.map((s) => s.id).toList(), tempFilteredStations.map((s) => s.id).toList()) ||
        _statusMessage != newStatusMessage) {
      setState(() {
        _filteredStations = tempFilteredStations;
        _statusMessage = newStatusMessage;
      });
    }
  }

  @override
  void dispose() {
    _stationsSubscription?.cancel();
    _searchController.removeListener(_filterStations);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("[StationListScreen] build called. Loading: $_isLoading, Status: '$_statusMessage', AllStations: ${_allStations.length}, FilteredStations: ${_filteredStations.length}");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách trạm đo'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildStationList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên trạm...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildStationList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredStations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _statusMessage.isNotEmpty ? _statusMessage : 'Không có trạm nào để hiển thị.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      itemCount: _filteredStations.length,
      itemBuilder: (context, index) {
        final station = _filteredStations[index];
        return StationInfoCard(
          station: station,
        );
      },
    );
  }
}
