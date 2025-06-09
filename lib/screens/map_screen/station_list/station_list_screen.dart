import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../models/station.dart';
import '../widgets/station_info_card.dart';

class StationListScreen extends StatefulWidget {
  final Function(String stationId)? onStationSelected;

  const StationListScreen({Key? key, this.onStationSelected}) : super(key: key);

  @override
  _StationListScreenState createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref().child('cacThietBiQuanTrac');
  StreamSubscription<DatabaseEvent>? _stationsSubscription;

  List<Station> _allStations = [];
  List<Station> _filteredStations = [];

  bool _isLoading = true;
  String _statusMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print("[StationListScreen] initState called");
    _searchController.addListener(_filterStations);
    // Delay để đảm bảo context đã sẵn sàng cho localization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToFirebaseData();
    });
  }

  void _listenToFirebaseData() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      print("[StationListScreen] AppLocalizations not available yet, retrying...");
      Future.delayed(const Duration(milliseconds: 100), _listenToFirebaseData);
      return;
    }

    print("[StationListScreen] Starting to listen to Firebase data");
    if (mounted) {
      setState(() {
        _isLoading = true;
        _statusMessage = l10n.loadingData ?? 'Đang tải dữ liệu...';
      });
    }

    _stationsSubscription = _databaseRef.onValue.listen(
          (DatabaseEvent event) async {
        if (!mounted) return;

        final currentL10n = AppLocalizations.of(context);
        if (currentL10n == null) return;

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
              _statusMessage = currentL10n.invalidDataFormat ?? 'Dữ liệu Firebase không đúng định dạng.';
              _filterStations();
            });
            print("[StationListScreen] Firebase data is not a Map.");
            return;
          }

          final Map<dynamic, dynamic> stationDataMap = data as Map<dynamic, dynamic>;
          final List<Future<Station?>> futureStations = [];

          stationDataMap.forEach((key, value) {
            if (value is Map) {
              // Sử dụng phiên bản localized của fromFirebase
              futureStations.add(
                  Station.fromFirebaseLocalized(
                      value as Map<dynamic, dynamic>,
                      key.toString(),
                      currentL10n
                  ).then((station) => station)
                      .catchError((e, s) {
                    print("[StationListScreen] Error parsing station with key $key: $e");
                    print(s);
                    return null;
                  })
              );
            } else {
              print("[StationListScreen] Data for key $key is not a Map: $value");
            }
          });

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
            _statusMessage = '${currentL10n.dataProcessingError ?? "Lỗi xử lý dữ liệu"}: ${e.toString()}';
            _filterStations();
          });
        }
      },
      onError: (error) {
        print("[StationListScreen] Firebase stream error: $error");
        if (mounted) {
          final currentL10n = AppLocalizations.of(context);
          setState(() {
            _isLoading = false;
            _allStations = [];
            _statusMessage = '${currentL10n?.firebaseConnectionError ?? "Lỗi kết nối Firebase"}: ${error.toString()}';
            _filterStations();
          });
        }
      },
    );
  }

  void _filterStations() {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

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
        if (_statusMessage.toLowerCase().contains(l10n.error?.toLowerCase() ?? 'lỗi') ||
            _statusMessage.contains(l10n.invalidDataFormat ?? 'Dữ liệu Firebase không đúng định dạng.') ||
            _statusMessage.contains(l10n.noDeviceData ?? 'Không có dữ liệu thiết bị nào.')) {
          newStatusMessage = _statusMessage;
        } else {
          newStatusMessage = l10n.noStationData ?? 'Không có dữ liệu trạm nào.';
        }
      } else if (tempFilteredStations.isEmpty) {
        if (query.isNotEmpty) {
          newStatusMessage = '${l10n.noStationFound ?? "Không tìm thấy trạm nào cho"} "$query".';
        }
      }
    } else {
      newStatusMessage = l10n.loadingData ?? 'Đang tải dữ liệu...';
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
    final l10n = AppLocalizations.of(context);

    print("[StationListScreen] build called. Loading: $_isLoading, Status: '$_statusMessage', AllStations: ${_allStations.length}, FilteredStations: ${_filteredStations.length}");

    return Scaffold(
      // Bọc nội dung body bằng SafeArea
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildStationList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: l10n?.searchByStationName ?? 'Tìm kiếm theo tên trạm...',
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
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredStations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _statusMessage.isNotEmpty
                ? _statusMessage
                : (l10n?.noStationsToDisplay ?? 'Không có trạm nào để hiển thị.'),
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