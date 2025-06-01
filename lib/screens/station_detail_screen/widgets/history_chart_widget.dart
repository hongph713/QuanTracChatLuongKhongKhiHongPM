// lib/screens/station_detail_screen/widgets/history_chart_widget.dart
import 'dart:async';
import 'dart:math'; // For min/max
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// TODO: Đảm bảo các đường dẫn import này đúng
import '../../../models/AQIUtils.dart'; // Cần để tính AQI nếu không có sẵn

// Enum để quản lý loại biểu đồ và khoảng thời gian (đã có)
enum ChartDataType { aqi, pm25 }
enum ChartTimeRange { hour, day }

// Class để lưu trữ dữ liệu lịch sử cho biểu đồ
class HistoricalDataPoint {
  final DateTime timestamp; // Đã chuyển đổi từ Unix timestamp
  final double value; // Giá trị AQI hoặc PM2.5

  HistoricalDataPoint({required this.timestamp, required this.value});
}

class HistoryChartWidget extends StatefulWidget {
  final String stationId; // ID của trạm đo (ví dụ: "id_1_caugiay")

  const HistoryChartWidget({Key? key, required this.stationId}) : super(key: key);

  @override
  _HistoryChartWidgetState createState() => _HistoryChartWidgetState();
}

class _HistoryChartWidgetState extends State<HistoryChartWidget> {
  ChartDataType _selectedDataType = ChartDataType.aqi;
  ChartTimeRange _selectedTimeRange = ChartTimeRange.hour;

  List<HistoricalDataPoint> _rawHistoricalData = []; // Dữ liệu gốc từ Firebase
  List<FlSpot> _chartSpots = []; // Dữ liệu đã chuẩn bị cho fl_chart
  bool _isLoadingChart = true;
  String _chartErrorMessage = '';
  String _displayDateRange = '';
  double _averageValue = 0;

  // Các giá trị min/max cho trục của biểu đồ
  double _minX = 0, _maxX = 0, _minY = 0, _maxY = 0;

  // StreamSubscription? _historySubscription; // Không dùng listen nữa, dùng once()

  @override
  void initState() {
    super.initState();
    print("[HistoryChartWidget] initState for stationId: ${widget.stationId}");
    _fetchHistoryData();
  }

  @override
  void dispose() {
    // _historySubscription?.cancel(); // Không cần nếu dùng once()
    super.dispose();
  }

  Future<void> _fetchHistoryData() async {
    if (!mounted) return;
    print('[HistoryChartWidget] Fetching data - Type: $_selectedDataType, Range: $_selectedTimeRange for station: ${widget.stationId}');
    setState(() {
      _isLoadingChart = true;
      _chartErrorMessage = '';
      _chartSpots = [];
      _rawHistoricalData = []; // Xóa dữ liệu cũ
    });

    try {
      // Đường dẫn đến dữ liệu lịch sử của trạm.
      // Dữ liệu lịch sử là một danh sách các bản ghi trực tiếp dưới stationId.
      final historyRef = FirebaseDatabase.instance
          .ref('cacThietBiQuanTrac/${widget.stationId}'); // Không có '/historyReadings'

      DateTime now = DateTime.now();
      DateTime startTime;

      if (_selectedTimeRange == ChartTimeRange.hour) {
        startTime = now.subtract(const Duration(hours: 24));
      } else {
        startTime = now.subtract(const Duration(days: 7));
      }
      final int startTimestampMs = startTime.millisecondsSinceEpoch;

      // Query dữ liệu từ Firebase, sắp xếp theo 'time'
      // và lấy 500 bản ghi mới nhất để lọc ở client.
      final snapshot = await historyRef.orderByChild('time').limitToLast(500).once();

      if (!mounted) return;

      if (snapshot.snapshot.value == null) {
        print('[HistoryChartWidget] No historical data found at path: ${historyRef.path}');
        setState(() {
          _isLoadingChart = false;
          _chartErrorMessage = 'Không có dữ liệu lịch sử.';
          _prepareChartData();
        });
        return;
      }

      // Dữ liệu trả về từ Realtime DB khi query một node cha là một Map các pushID và value của chúng
      final Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      List<HistoricalDataPoint> fetchedPoints = [];

      print('[HistoryChartWidget] Raw data received: ${data.length} entries.');

      data.forEach((pushId, record) { // pushId là key tự sinh của Firebase, record là value
        if (record is Map) {
          try {
            // Sử dụng trường 'time' cho timestamp và 'pm25' cho giá trị bụi
            final int? timestampMs = record['time'] as int?;
            final num? pm25Value = record['pm25'] as num?; // Đọc trường 'pm25'

            if (timestampMs == null || pm25Value == null) {
              print('[HistoryChartWidget] Skipping record $pushId due to missing time or pm25. Data: $record');
              return; // Bỏ qua bản ghi này nếu thiếu dữ liệu cần thiết
            }

            // Chỉ lấy các điểm trong khoảng thời gian đã chọn
            if (timestampMs >= startTimestampMs) {
              final double pm25 = pm25Value.toDouble();
              double pointValue;
              if (_selectedDataType == ChartDataType.aqi) {
                pointValue = AQIUtils.calculateAQI(pm25).toDouble();
              } else {
                pointValue = pm25;
              }
              fetchedPoints.add(HistoricalDataPoint(
                timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
                value: pointValue,
              ));
            }
          } catch (e, s) {
            print('[HistoryChartWidget] Error parsing historical point with pushId $pushId: $e');
            print(s);
          }
        } else {
          print('[HistoryChartWidget] Record with pushId $pushId is not a Map: $record');
        }
      });

      fetchedPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      print('[HistoryChartWidget] Fetched and filtered ${fetchedPoints.length} historical points.');

      setState(() {
        _rawHistoricalData = fetchedPoints;
        _isLoadingChart = false;
        _prepareChartData();
      });

    } catch (e, s) {
      print('[HistoryChartWidget] Error fetching history data: $e');
      print(s);
      if (mounted) {
        setState(() {
          _isLoadingChart = false;
          _chartErrorMessage = 'Lỗi tải dữ liệu lịch sử.';
          _rawHistoricalData = [];
          _prepareChartData();
        });
      }
    }
  }

  void _prepareChartData() {
    if (!mounted) return;
    if (_rawHistoricalData.isEmpty) {
      setState(() {
        _chartSpots = [];
        _minX = 0; _maxX = 0; _minY = 0; _maxY = 0;
        _averageValue = 0;
        _displayDateRange = _selectedTimeRange == ChartTimeRange.hour
            ? "24 giờ qua"
            : "7 ngày qua";
        // Chỉ đặt lỗi nếu _chartErrorMessage đang rỗng và không phải đang loading
        if (_chartErrorMessage.isEmpty && !_isLoadingChart) {
          _chartErrorMessage = "Không có dữ liệu cho khoảng thời gian này.";
        }
      });
      return;
    }

    List<FlSpot> spots = [];
    double sum = 0;

    _minX = _rawHistoricalData.first.timestamp.millisecondsSinceEpoch.toDouble();
    _maxX = _rawHistoricalData.last.timestamp.millisecondsSinceEpoch.toDouble();

    // Xử lý trường hợp chỉ có một điểm dữ liệu cho minX, maxX
    if (_minX == _maxX && _rawHistoricalData.length == 1) {
      _minX -= Duration(hours: 1).inMilliseconds.toDouble(); // Lùi lại 1 giờ
      _maxX += Duration(hours: 1).inMilliseconds.toDouble(); // Tiến tới 1 giờ
    } else if (_minX == _maxX) { // Nếu vẫn bằng nhau (ví dụ nhiều điểm cùng timestamp, không nên xảy ra)
      _maxX = _minX + 1; // Đảm bảo không bằng nhau
    }


    _minY = _rawHistoricalData.map((p) => p.value).reduce(min);
    _maxY = _rawHistoricalData.map((p) => p.value).reduce(max);

    for (var point in _rawHistoricalData) {
      spots.add(FlSpot(point.timestamp.millisecondsSinceEpoch.toDouble(), point.value));
      sum += point.value;
    }

    _minY = max(0, _minY - (_maxY - _minY) * 0.1 - 5); // Thêm khoảng đệm và đảm bảo không âm
    _maxY = _maxY + (_maxY - _minY) * 0.1 + 5; // Thêm khoảng đệm
    if (_minY >= _maxY) {
      _minY = max(0, _maxY - 10); // Đảm bảo minY < maxY và không âm
      if (_minY == _maxY) _maxY = _minY +10; // Xử lý trường hợp _maxY cũng là 0
    }


    setState(() {
      _chartSpots = spots;
      _averageValue = _rawHistoricalData.isNotEmpty ? sum / _rawHistoricalData.length : 0;

      final DateFormat formatter = _selectedTimeRange == ChartTimeRange.hour
          ? DateFormat('HH:mm, dd/MM')
          : DateFormat('dd/MM/yyyy');
      _displayDateRange = '${formatter.format(_rawHistoricalData.first.timestamp)} - ${formatter.format(_rawHistoricalData.last.timestamp)}';
      _chartErrorMessage = '';
    });
  }

  String _formatTimestampForAxis(double timestampMs) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestampMs.toInt());
    if (_selectedTimeRange == ChartTimeRange.hour) {
      // Hiển thị giờ, có thể thêm ngày nếu qua ngày mới
      if (dateTime.hour == 0) { // Mốc 0 giờ, hiển thị cả ngày
        return DateFormat('HH\ndd/MM').format(dateTime);
      }
      return DateFormat('HH').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color chartLineColor = _selectedDataType == ChartDataType.aqi
        ? AQIUtils.getAQIColor(_averageValue.round())
        : Colors.blueAccent;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeRangeButton(ChartTimeRange.hour, 'Giờ'),
                const SizedBox(width: 10),
                _buildTimeRangeButton(ChartTimeRange.day, 'Ngày'),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDataTypeButton(ChartDataType.aqi, 'AQI'),
                  const SizedBox(width: 8),
                  _buildDataTypeButton(ChartDataType.pm25, 'PM2.5'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 250,
              padding: const EdgeInsets.only(right: 16, top: 10), // Thêm padding để nhãn không bị cắt
              child: _isLoadingChart
                  ? const Center(child: CircularProgressIndicator())
                  : _chartSpots.isEmpty || _chartErrorMessage.isNotEmpty
                  ? Center(
                child: Text(
                  _chartErrorMessage.isNotEmpty ? _chartErrorMessage : 'Không có dữ liệu để hiển thị.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
                  : LineChart(
                LineChartData(
                  minX: _minX,
                  maxX: _maxX,
                  minY: _minY,
                  maxY: _maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (_maxY - _minY) / 4 > 0 ? (_maxY - _minY) / 4 : 10, // Điều chỉnh interval ngang
                    verticalInterval: (_maxX - _minX) / 5 > 0 ? (_maxX - _minX) / 5 : Duration(hours: 4).inMilliseconds.toDouble(), // Điều chỉnh interval dọc
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 0.5);
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 0.5);
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35, // Tăng reservedSize
                        interval: (_maxX - _minX) / 4 > 0 ? (_maxX - _minX) / 4 : Duration(hours: 6).inMilliseconds.toDouble(), // Khoảng cách giữa các nhãn trục X
                        getTitlesWidget: (value, meta) {
                          // Chỉ hiển thị một số nhãn để tránh chồng chéo
                          if (value == _minX || value == _maxX || (value - _minX) % (((_maxX - _minX) / 4).floorToDouble()) == 0) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8.0,
                              child: Text(_formatTimestampForAxis(value), style: const TextStyle(fontSize: 9, color: Colors.black54)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          // Hiển thị các giá trị có ý nghĩa
                          if (value == _minY || value == _maxY || value % (((_maxY - _minY)/4).ceilToDouble()) == 0 && value.toInt() !=0) {
                            if (value < 0 && _minY <0) return const Text(''); // Tránh hiển thị giá trị âm nếu không cần thiết
                            return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.black54));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartSpots,
                      isCurved: true,
                      color: chartLineColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: chartLineColor.withOpacity(0.15),
                      ),
                    ),
                  ],
                  // Thêm tooltip
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final flSpot = barSpot;
                          if (flSpot.x == null || flSpot.y == null) {
                            return null;
                          }
                          DateTime dt = DateTime.fromMillisecondsSinceEpoch(flSpot.x.toInt());
                          String timeStr = DateFormat('HH:mm dd/MM').format(dt);
                          return LineTooltipItem(
                            '${_selectedDataType == ChartDataType.aqi ? "AQI" : "PM2.5"}: ${flSpot.y.toStringAsFixed(1)}\n',
                            TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            children: [
                              TextSpan(
                                text: timeStr,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.normal,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                            textAlign: TextAlign.left,
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (!_isLoadingChart && _rawHistoricalData.isNotEmpty) ...[
              Center(
                child: Text(
                  _displayDateRange,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
              Center(
                child: Text(
                  '${_selectedDataType == ChartDataType.aqi ? "AQI" : "PM2.5"} trung bình: ${_averageValue.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeButton(ChartTimeRange range, String text) {
    bool isSelected = _selectedTimeRange == range;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black54,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      onPressed: () {
        if (!isSelected) {
          setState(() {
            _selectedTimeRange = range;
          });
          _fetchHistoryData();
        }
      },
      child: Text(text),
    );
  }

  Widget _buildDataTypeButton(ChartDataType type, String text) {
    bool isSelected = _selectedDataType == type;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
        side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onPressed: () {
        if (!isSelected) {
          setState(() {
            _selectedDataType = type;
          });
          _fetchHistoryData();
        }
      },
      child: Text(text, style: TextStyle(color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700])),
    );
  }
}

// // lib/screens/station_detail_screen/widgets/history_chart_widget.dart
// import 'dart:async';
// import 'dart:math'; // For min/max
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';
//
// // TODO: Đảm bảo các đường dẫn import này đúng
// import '../../../models/AQIUtils.dart'; // Cần để tính AQI nếu không có sẵn
//
// // Enum để quản lý loại biểu đồ và khoảng thời gian (đã có)
// enum ChartDataType { aqi, pm25 }
// enum ChartTimeRange { hour, day }
//
// // Class để lưu trữ dữ liệu lịch sử cho biểu đồ
// class HistoricalDataPoint {
//   final DateTime timestamp; // Đã chuyển đổi từ Unix timestamp
//   final double value; // Giá trị AQI hoặc PM2.5
//
//   HistoricalDataPoint({required this.timestamp, required this.value});
// }
//
// class HistoryChartWidget extends StatefulWidget {
//   final String stationId; // ID của trạm đo (ví dụ: "id_1_caugiay")
//
//   const HistoryChartWidget({Key? key, required this.stationId}) : super(key: key);
//
//   @override
//   _HistoryChartWidgetState createState() => _HistoryChartWidgetState();
// }
//
// class _HistoryChartWidgetState extends State<HistoryChartWidget> {
//   ChartDataType _selectedDataType = ChartDataType.aqi;
//   ChartTimeRange _selectedTimeRange = ChartTimeRange.hour;
//
//   List<HistoricalDataPoint> _rawHistoricalData = []; // Dữ liệu gốc từ Firebase
//   List<FlSpot> _chartSpots = []; // Dữ liệu đã chuẩn bị cho fl_chart
//   bool _isLoadingChart = true;
//   String _chartErrorMessage = '';
//   String _displayDateRange = '';
//   double _averageValue = 0;
//
//   // Các giá trị min/max cho trục của biểu đồ
//   double _minX = 0, _maxX = 0, _minY = 0, _maxY = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     print("[HistoryChartWidget] initState for stationId: ${widget.stationId}");
//     _fetchHistoryData();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   Future<void> _fetchHistoryData() async {
//     if (!mounted) return;
//     print('[HistoryChartWidget] Fetching data - Type: $_selectedDataType, Range: $_selectedTimeRange for station: ${widget.stationId}');
//     setState(() {
//       _isLoadingChart = true;
//       _chartErrorMessage = '';
//       _chartSpots = [];
//       _rawHistoricalData = []; // Xóa dữ liệu cũ
//     });
//
//     try {
//       // SỬA ĐƯỜNG DẪN Ở ĐÂY: Thêm '/data_points'
//       final historyRef = FirebaseDatabase.instance
//           .ref('cacThietBiQuanTrac/${widget.stationId}/data_points');
//
//       DateTime now = DateTime.now();
//       DateTime startTimeFilter;
//
//       if (_selectedTimeRange == ChartTimeRange.hour) {
//         startTimeFilter = now.subtract(const Duration(hours: 24));
//       } else {
//         startTimeFilter = now.subtract(const Duration(days: 7));
//       }
//       final int startTimestampFilterMs = startTimeFilter.millisecondsSinceEpoch;
//
//       final snapshot = await historyRef.orderByChild('time').limitToLast(1000).once();
//
//       if (!mounted) return;
//
//       if (snapshot.snapshot.value == null) {
//         print('[HistoryChartWidget] No historical data found at path: ${historyRef.path}');
//         setState(() {
//           _isLoadingChart = false;
//           _chartErrorMessage = 'Không có dữ liệu lịch sử.';
//           _prepareChartData();
//         });
//         return;
//       }
//
//       final Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
//       List<HistoricalDataPoint> fetchedPoints = [];
//
//       print('[HistoryChartWidget] Raw data received from data_points: ${data.length} entries.');
//
//       data.forEach((pushId, record) {
//         if (record is Map) {
//           try {
//             dynamic timeValue = record['time'];
//             int? timestampMs;
//
//             if (timeValue is int) {
//               timestampMs = timeValue;
//             } else if (timeValue is Map && timeValue['.sv'] == 'timestamp') {
//               print('[HistoryChartWidget] Server timestamp placeholder found for pushId $pushId. Skipping for chart.');
//               return;
//             } else {
//               print('[HistoryChartWidget] Invalid time format for pushId $pushId. Skipping. Data: $record');
//               return;
//             }
//
//             final num? pm25Value = record['pm25'] as num?;
//
//             if (pm25Value == null) {
//               print('[HistoryChartWidget] Skipping record $pushId due to missing pm25. Data: $record');
//               return;
//             }
//
//             if (timestampMs >= startTimestampFilterMs) {
//               final double pm25 = pm25Value.toDouble();
//               double pointValue;
//               if (_selectedDataType == ChartDataType.aqi) {
//                 pointValue = AQIUtils.calculateAQI(pm25).toDouble();
//               } else {
//                 pointValue = pm25;
//               }
//               fetchedPoints.add(HistoricalDataPoint(
//                 timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
//                 value: pointValue,
//               ));
//             }
//           } catch (e, s) {
//             print('[HistoryChartWidget] Error parsing historical point with pushId $pushId: $e');
//             print(s);
//           }
//         } else {
//           print('[HistoryChartWidget] Record with pushId $pushId is not a Map: $record');
//         }
//       });
//
//       fetchedPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//
//       print('[HistoryChartWidget] Fetched and filtered ${fetchedPoints.length} historical points.');
//
//       setState(() {
//         _rawHistoricalData = fetchedPoints;
//         _isLoadingChart = false;
//         _prepareChartData();
//       });
//
//     } catch (e, s) {
//       print('[HistoryChartWidget] Error fetching history data: $e');
//       print(s);
//       if (mounted) {
//         setState(() {
//           _isLoadingChart = false;
//           _chartErrorMessage = 'Lỗi tải dữ liệu lịch sử.';
//           _rawHistoricalData = [];
//           _prepareChartData();
//         });
//       }
//     }
//   }
//
//   void _prepareChartData() {
//     if (!mounted) return;
//     if (_rawHistoricalData.isEmpty) {
//       setState(() {
//         _chartSpots = [];
//         _minX = 0; _maxX = 0; _minY = 0; _maxY = 0;
//         _averageValue = 0;
//         _displayDateRange = _selectedTimeRange == ChartTimeRange.hour
//             ? "24 giờ qua"
//             : "7 ngày qua";
//         if (_chartErrorMessage.isEmpty && !_isLoadingChart) {
//           _chartErrorMessage = "Không có dữ liệu cho khoảng thời gian này.";
//         }
//       });
//       return;
//     }
//
//     List<FlSpot> spots = [];
//     double sum = 0;
//
//     _minX = _rawHistoricalData.first.timestamp.millisecondsSinceEpoch.toDouble();
//     _maxX = _rawHistoricalData.last.timestamp.millisecondsSinceEpoch.toDouble();
//
//     if (_minX == _maxX && _rawHistoricalData.length == 1) {
//       _minX -= const Duration(hours: 1).inMilliseconds.toDouble();
//       _maxX += const Duration(hours: 1).inMilliseconds.toDouble();
//     } else if (_minX == _maxX) {
//       _maxX = _minX + 1;
//     }
//
//     _minY = _rawHistoricalData.map((p) => p.value).reduce(min);
//     _maxY = _rawHistoricalData.map((p) => p.value).reduce(max);
//
//     for (var point in _rawHistoricalData) {
//       spots.add(FlSpot(point.timestamp.millisecondsSinceEpoch.toDouble(), point.value));
//       sum += point.value;
//     }
//
//     _minY = max(0, _minY - (_maxY - _minY) * 0.1 - 5);
//     _maxY = _maxY + (_maxY - _minY) * 0.1 + 5;
//     if (_minY >= _maxY) {
//       _minY = max(0, _maxY - 10);
//       if (_minY == _maxY) _maxY = _minY +10;
//     }
//
//     setState(() {
//       _chartSpots = spots;
//       _averageValue = _rawHistoricalData.isNotEmpty ? sum / _rawHistoricalData.length : 0;
//
//       final DateFormat formatter = _selectedTimeRange == ChartTimeRange.hour
//           ? DateFormat('HH:mm, dd/MM')
//           : DateFormat('dd/MM/yyyy');
//       _displayDateRange = '${formatter.format(_rawHistoricalData.first.timestamp)} - ${formatter.format(_rawHistoricalData.last.timestamp)}';
//       _chartErrorMessage = '';
//     });
//   }
//
//   String _formatTimestampForAxis(double timestampMs) {
//     DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestampMs.toInt());
//     if (_selectedTimeRange == ChartTimeRange.hour) {
//       if (dateTime.hour == 0) {
//         return DateFormat('HH\ndd/MM').format(dateTime);
//       }
//       return DateFormat('HH').format(dateTime);
//     } else {
//       return DateFormat('dd/MM').format(dateTime);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     Color chartLineColor = _selectedDataType == ChartDataType.aqi
//         ? AQIUtils.getAQIColor(_averageValue.round())
//         : Colors.blueAccent;
//
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       elevation: 2.0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _buildTimeRangeButton(ChartTimeRange.hour, 'Giờ'),
//                 const SizedBox(width: 10),
//                 _buildTimeRangeButton(ChartTimeRange.day, 'Ngày'),
//               ],
//             ),
//             const SizedBox(height: 12),
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   _buildDataTypeButton(ChartDataType.aqi, 'AQI'),
//                   const SizedBox(width: 8),
//                   _buildDataTypeButton(ChartDataType.pm25, 'PM2.5'),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             Container(
//               height: 250,
//               padding: const EdgeInsets.only(right: 16, top: 10),
//               child: _isLoadingChart
//                   ? const Center(child: CircularProgressIndicator())
//                   : _chartSpots.isEmpty || _chartErrorMessage.isNotEmpty
//                   ? Center(
//                 child: Text(
//                   _chartErrorMessage.isNotEmpty ? _chartErrorMessage : 'Không có dữ liệu để hiển thị.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.grey[600]),
//                 ),
//               )
//                   : LineChart(
//                 LineChartData(
//                   minX: _minX,
//                   maxX: _maxX,
//                   minY: _minY,
//                   maxY: _maxY,
//                   gridData: FlGridData(
//                     show: true,
//                     drawVerticalLine: true,
//                     horizontalInterval: (_maxY - _minY) / 4 > 0 ? (_maxY - _minY) / 4 : 10,
//                     verticalInterval: (_maxX - _minX) / 5 > 0 ? (_maxX - _minX) / 5 : const Duration(hours: 4).inMilliseconds.toDouble(),
//                     getDrawingHorizontalLine: (value) {
//                       return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 0.5);
//                     },
//                     getDrawingVerticalLine: (value) {
//                       return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 0.5);
//                     },
//                   ),
//                   titlesData: FlTitlesData(
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 35,
//                         interval: (_maxX - _minX) / 4 > 0 ? (_maxX - _minX) / 4 : const Duration(hours: 6).inMilliseconds.toDouble(),
//                         getTitlesWidget: (value, meta) {
//                           if (value == _minX || value == _maxX || ((_maxX - _minX) > 0 && (value - _minX) % (((_maxX - _minX) / 4).floorToDouble()) == 0) ) {
//                             return SideTitleWidget(
//                               axisSide: meta.axisSide,
//                               space: 8.0,
//                               child: Text(_formatTimestampForAxis(value), style: const TextStyle(fontSize: 9, color: Colors.black54)),
//                             );
//                           }
//                           return const SizedBox.shrink();
//                         },
//                       ),
//                     ),
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 40,
//                         getTitlesWidget: (value, meta) {
//                           if (value == _minY || value == _maxY || (_maxY - _minY > 0 && value % (((_maxY - _minY)/4).ceilToDouble()) == 0 && value.toInt() !=0) ) {
//                             if (value < 0 && _minY <0) return const Text('');
//                             return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.black54));
//                           }
//                           return const Text('');
//                         },
//                       ),
//                     ),
//                     topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   ),
//                   borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.3), width: 0.5)),
//                   lineBarsData: [
//                     LineChartBarData(
//                       spots: _chartSpots,
//                       isCurved: true,
//                       color: chartLineColor,
//                       barWidth: 2.5,
//                       isStrokeCapRound: true,
//                       dotData: const FlDotData(show: false),
//                       belowBarData: BarAreaData(
//                         show: true,
//                         color: chartLineColor.withOpacity(0.15),
//                       ),
//                     ),
//                   ],
//                   lineTouchData: LineTouchData(
//                     touchTooltipData: LineTouchTooltipData(
//                       getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
//                         return touchedBarSpots.map((barSpot) {
//                           final flSpot = barSpot;
//                           if (flSpot.x == null || flSpot.y == null) {
//                             return null;
//                           }
//                           DateTime dt = DateTime.fromMillisecondsSinceEpoch(flSpot.x.toInt());
//                           String timeStr = DateFormat('HH:mm dd/MM').format(dt);
//                           return LineTooltipItem(
//                             '${_selectedDataType == ChartDataType.aqi ? "AQI" : "PM2.5"}: ${flSpot.y.toStringAsFixed(1)}\n',
//                             TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
//                             children: [
//                               TextSpan(
//                                 text: timeStr,
//                                 style: TextStyle(
//                                   color: Colors.white.withOpacity(0.8),
//                                   fontWeight: FontWeight.normal,
//                                   fontSize: 10,
//                                 ),
//                               ),
//                             ],
//                             textAlign: TextAlign.left,
//                           );
//                         }).toList();
//                       },
//                     ),
//                     handleBuiltInTouches: true,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             if (!_isLoadingChart && _rawHistoricalData.isNotEmpty) ...[
//               Center(
//                 child: Text(
//                   _displayDateRange,
//                   style: TextStyle(fontSize: 13, color: Colors.grey[700]),
//                 ),
//               ),
//               Center(
//                 child: Text(
//                   '${_selectedDataType == ChartDataType.aqi ? "AQI" : "PM2.5"} trung bình: ${_averageValue.toStringAsFixed(1)}',
//                   style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ]
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTimeRangeButton(ChartTimeRange range, String text) {
//     bool isSelected = _selectedTimeRange == range;
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[300],
//         foregroundColor: isSelected ? Colors.white : Colors.black54,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       ),
//       onPressed: () {
//         if (!isSelected) {
//           setState(() {
//             _selectedTimeRange = range;
//           });
//           _fetchHistoryData();
//         }
//       },
//       child: Text(text),
//     );
//   }
//
//   Widget _buildDataTypeButton(ChartDataType type, String text) {
//     bool isSelected = _selectedDataType == type;
//     return OutlinedButton(
//       style: OutlinedButton.styleFrom(
//         backgroundColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
//         side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       ),
//       onPressed: () {
//         if (!isSelected) {
//           setState(() {
//             _selectedDataType = type;
//           });
//           _fetchHistoryData();
//         }
//       },
//       child: Text(text, style: TextStyle(color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700])),
//     );
//   }
// }
