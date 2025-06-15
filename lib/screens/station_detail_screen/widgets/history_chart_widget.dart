// import 'dart:async';
// import 'dart:math'; // For min/max
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
//
// // Đảm bảo các đường dẫn import này đúng
// import '../../../models/AQIUtils.dart';
//
// // Enum để quản lý loại biểu đồ và khoảng thời gian
// enum ChartDataType { aqi, pm25 }
// enum ChartTimeRange { hour, day }
//
// // Class để lưu trữ dữ liệu lịch sử cho biểu đồ
// class HistoricalDataPoint {
//   final DateTime timestamp;
//   final double value;
//
//   HistoricalDataPoint({required this.timestamp, required this.value});
// }
//
// class HistoryChartWidget extends StatefulWidget {
//   final String stationId;
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
//   List<HistoricalDataPoint> _rawHistoricalData = [];
//   List<FlSpot> _chartSpots = [];
//   bool _isLoadingChart = true;
//   String _chartErrorMessage = '';
//   String _displayDateRange = '';
//   double _averageValue = 0;
//   double _minX = 0, _maxX = 0, _minY = 0, _maxY = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     print("[HistoryChartWidget] initState for stationId: ${widget.stationId}");
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _fetchHistoryData();
//     });
//   }
//
//   Future<void> _fetchHistoryData() async {
//     if (!mounted) return;
//
//     final l10n = AppLocalizations.of(context);
//     if (l10n == null) {
//       Future.delayed(const Duration(milliseconds: 100), _fetchHistoryData);
//       return;
//     }
//
//     print('[HistoryChartWidget] Fetching data - Type: $_selectedDataType, Range: $_selectedTimeRange for station: ${widget.stationId}');
//     setState(() {
//       _isLoadingChart = true;
//       _chartErrorMessage = '';
//       _chartSpots = [];
//       _rawHistoricalData = [];
//     });
//
//     try {
//       // Đường dẫn đã đúng với cấu trúc phẳng mới, không cần '/data_points'
//       final historyRef = FirebaseDatabase.instance
//           .ref('cacThietBiQuanTrac/${widget.stationId}');
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
//       // Query dữ liệu, orderByChild('time') vẫn hoạt động vì Firebase sẽ bỏ qua các node không có 'time' (như lat/long)
//       final snapshot = await historyRef.orderByChild('time').limitToLast(1000).once();
//
//       if (!mounted) return;
//
//       if (snapshot.snapshot.value == null) {
//         print('[HistoryChartWidget] No historical data found at path: ${historyRef.path}');
//         setState(() {
//           _isLoadingChart = false;
//           _chartErrorMessage = l10n.noHistoricalData ?? 'Không có dữ liệu lịch sử.';
//           _prepareChartData();
//         });
//         return;
//       }
//
//       final Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
//       List<HistoricalDataPoint> fetchedPoints = [];
//
//       print('[HistoryChartWidget] Raw data received: ${data.length} entries.');
//
//       data.forEach((pushId, record) {
//         // `if (record is Map)` sẽ tự động bỏ qua các trường 'lat', 'long' vì chúng không phải là Map
//         if (record is Map) {
//           try {
//             final int? timestampMs = record['time'] as int?;
//             final num? pm25Value = record['pm25'] as num?;
//
//             if (timestampMs == null || pm25Value == null) {
//               print('[HistoryChartWidget] Skipping record $pushId due to missing time or pm25. Data: $record');
//               return;
//             }
//
//             if (timestampMs >= startTimestampFilterMs) {
//               // *** THAY ĐỔI QUAN TRỌNG: Chia giá trị pm25 cho 100 ***
//               final double pm25 = pm25Value.toDouble() / 100.0;
//
//               double pointValue;
//               if (_selectedDataType == ChartDataType.aqi) {
//                 pointValue = AQIUtils.calculateAQI(pm25).toDouble();
//               } else {
//                 pointValue = pm25;
//               }
//
//               fetchedPoints.add(HistoricalDataPoint(
//                 timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
//                 value: pointValue,
//               ));
//             }
//           } catch (e, s) {
//             print('[HistoryChartWidget] Error parsing historical point with pushId $pushId: $e');
//             print(s);
//           }
//         }
//       });
//
//       fetchedPoints.sort((a, b) => a.timestamp.compareTo(b.timestamp));
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
//         final currentL10n = AppLocalizations.of(context);
//         setState(() {
//           _isLoadingChart = false;
//           _chartErrorMessage = currentL10n?.errorLoadingHistoryData ?? 'Lỗi tải dữ liệu lịch sử.';
//           _rawHistoricalData = [];
//           _prepareChartData();
//         });
//       }
//     }
//   }
//
//   void _prepareChartData() {
//     if (!mounted) return;
//
//     final l10n = AppLocalizations.of(context);
//
//     if (_rawHistoricalData.isEmpty) {
//       setState(() {
//         _chartSpots = [];
//         _minX = 0; _maxX = 0; _minY = 0; _maxY = 0;
//         _averageValue = 0;
//         _displayDateRange = _selectedTimeRange == ChartTimeRange.hour
//             ? (l10n?.last24Hours ?? "24 giờ qua")
//             : (l10n?.last7Days ?? "7 ngày qua");
//         if (_chartErrorMessage.isEmpty && !_isLoadingChart) {
//           _chartErrorMessage = l10n?.noDataForTimeRange ?? "Không có dữ liệu cho khoảng thời gian này.";
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
//       if (_minY == _maxY) _maxY = _minY + 10;
//     }
//
//     setState(() {
//       _chartSpots = spots;
//       _averageValue = _rawHistoricalData.isNotEmpty ? sum / _rawHistoricalData.length : 0;
//       final DateFormat formatter = _selectedTimeRange == ChartTimeRange.hour ? DateFormat('HH:mm, dd/MM') : DateFormat('dd/MM/yyyy');
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
//     final l10n = AppLocalizations.of(context);
//
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
//                 _buildTimeRangeButton(ChartTimeRange.hour, l10n?.hour ?? 'Giờ'),
//                 const SizedBox(width: 10),
//                 _buildTimeRangeButton(ChartTimeRange.day, l10n?.day ?? 'Ngày'),
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
//                   _chartErrorMessage.isNotEmpty ? _chartErrorMessage : (l10n?.noDataToDisplay ?? 'Không có dữ liệu để hiển thị.'),
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
//                     getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 0.5),
//                     getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 0.5),
//                   ),
//                   titlesData: FlTitlesData(
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 35,
//                         interval: (_maxX - _minX) / 4 > 0 ? (_maxX - _minX) / 4 : const Duration(hours: 6).inMilliseconds.toDouble(),
//                         getTitlesWidget: (value, meta) {
//                           if (value == _minX || value == _maxX) return const SizedBox.shrink();
//                           return SideTitleWidget(
//                             axisSide: meta.axisSide,
//                             space: 8.0,
//                             child: Text(_formatTimestampForAxis(value), style: const TextStyle(fontSize: 9, color: Colors.black54)),
//                           );
//                         },
//                       ),
//                     ),
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 40,
//                         getTitlesWidget: (value, meta) {
//                           return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.black54));
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
//                           DateTime dt = DateTime.fromMillisecondsSinceEpoch(flSpot.x.toInt());
//                           String timeStr = DateFormat('HH:mm dd/MM').format(dt);
//                           return LineTooltipItem(
//                             '${_selectedDataType == ChartDataType.aqi ? "AQI" : "PM2.5"}: ${flSpot.y.toStringAsFixed(1)}\n',
//                             const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
//                   '${_selectedDataType == ChartDataType.aqi ? "AQI" : "PM2.5"} ${l10n?.average ?? "trung bình"}: ${_averageValue.toStringAsFixed(1)}',
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
//           setState(() => _selectedTimeRange = range);
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
//           setState(() => _selectedDataType = type);
//           _fetchHistoryData();
//         }
//       },
//       child: Text(text, style: TextStyle(color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700])),
//     );
//   }
// }

// Dán toàn bộ nội dung này vào file HistoryChartWidget.dart của bạn

// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:intl/intl.dart';
// import 'package:collection/collection.dart';
//
// import '../../../models/AQIUtils.dart';
//
// enum ChartDataType { aqi, pm25 }
// enum ChartTimeRange { hour, day }
//
// class HistoricalDataPoint {
//   final DateTime timestamp;
//   final double value;
//
//   HistoricalDataPoint({required this.timestamp, required this.value});
// }
//
// class HistoryChartWidget extends StatefulWidget {
//   final String stationId;
//
//   const HistoryChartWidget({Key? key, required this.stationId}) : super(key: key);
//
//   @override
//   _HistoryChartWidgetState createState() => _HistoryChartWidgetState();
// }
//
// class _HistoryChartWidgetState extends State<HistoryChartWidget> {
//   ChartDataType _selectedDataType = ChartDataType.aqi;
//   ChartTimeRange _selectedTimeRange = ChartTimeRange.day;
//
//   List<HistoricalDataPoint> _aggregatedData = [];
//   bool _isLoadingChart = true;
//   String _chartErrorMessage = '';
//   String _displayDateRange = '';
//   double _averageValue = 0;
//   double _maxY = 0;
//
//   int? _touchedIndex;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _fetchHistoryData();
//     });
//   }
//
//   List<HistoricalDataPoint> _aggregateData(List<HistoricalDataPoint> rawData, ChartTimeRange timeRange) {
//     if (rawData.isEmpty) return [];
//
//     if (timeRange == ChartTimeRange.hour) {
//       final groupedByHour = groupBy(rawData, (p) => DateFormat('yyyy-MM-dd-HH').format(p.timestamp));
//       return groupedByHour.entries.map((entry) {
//         final values = entry.value.map((p) => p.value).toList();
//         final average = values.reduce((a, b) => a + b) / values.length;
//         return HistoricalDataPoint(timestamp: entry.value.first.timestamp, value: average);
//       }).toList();
//     } else {
//       final groupedByDay = groupBy(rawData, (p) => DateFormat('yyyy-MM-dd').format(p.timestamp));
//       return groupedByDay.entries.map((entry) {
//         final values = entry.value.map((p) => p.value).toList();
//         final average = values.reduce((a, b) => a + b) / values.length;
//         return HistoricalDataPoint(timestamp: entry.value.first.timestamp, value: average);
//       }).toList();
//     }
//   }
//
//   Future<void> _fetchHistoryData() async {
//     if (!mounted) return;
//     final l10n = AppLocalizations.of(context);
//     if (l10n == null) {
//       Future.delayed(const Duration(milliseconds: 100), () => _fetchHistoryData());
//       return;
//     }
//
//     setState(() {
//       _isLoadingChart = true;
//       _chartErrorMessage = '';
//       _aggregatedData = [];
//     });
//
//     try {
//       final historyRef = FirebaseDatabase.instance.ref('cacThietBiQuanTrac/${widget.stationId}');
//       final now = DateTime.now();
//       final startTimeFilter = now.subtract(const Duration(days: 7));
//       final snapshot = await historyRef.orderByChild('time').startAt(startTimeFilter.millisecondsSinceEpoch).once();
//
//       if (!mounted || snapshot.snapshot.value == null) {
//         setState(() {
//           _isLoadingChart = false;
//           _chartErrorMessage = l10n.noHistoricalData ?? 'Không có dữ liệu lịch sử.';
//         });
//         return;
//       }
//
//       final Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
//       List<HistoricalDataPoint> fetchedPoints = [];
//
//       data.forEach((key, record) {
//         if (record is Map) {
//           final int? timestampMs = record['time'] as int?;
//           final num? pm25Value = record['pm25'] as num?;
//           if (timestampMs != null && pm25Value != null) {
//             final double pm25 = pm25Value.toDouble() / 100.0;
//             final double pointValue = _selectedDataType == ChartDataType.aqi ? AQIUtils.calculateAQI(pm25).toDouble() : pm25;
//             fetchedPoints.add(HistoricalDataPoint(
//               timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
//               value: pointValue,
//             ));
//           }
//         }
//       });
//
//       List<HistoricalDataPoint> finalData;
//       if (_selectedTimeRange == ChartTimeRange.hour) {
//         final last24hData = fetchedPoints.where((p) => p.timestamp.isAfter(now.subtract(const Duration(hours: 24)))).toList();
//         finalData = _aggregateData(last24hData, _selectedTimeRange);
//       } else {
//         finalData = _aggregateData(fetchedPoints, _selectedTimeRange);
//       }
//
//       finalData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//
//       setState(() {
//         _aggregatedData = finalData;
//         _isLoadingChart = false;
//         _prepareChartData();
//       });
//     } catch (e, s) {
//       if (mounted) {
//         print('[HistoryChartWidget] Error: $e\n$s');
//         setState(() => _isLoadingChart = false);
//       }
//     }
//   }
//
//   void _prepareChartData() {
//     if (!mounted) return;
//     final l10n = AppLocalizations.of(context);
//
//     if (_aggregatedData.isEmpty) {
//       setState(() {
//         _averageValue = 0;
//         _displayDateRange = _selectedTimeRange == ChartTimeRange.hour ? (l10n?.last24Hours ?? "24 giờ qua") : (l10n?.last7Days ?? "7 ngày qua");
//         if (_chartErrorMessage.isEmpty && !_isLoadingChart) {
//           _chartErrorMessage = l10n?.noDataForTimeRange ?? "Không có dữ liệu cho khoảng thời gian này.";
//         }
//       });
//       return;
//     }
//
//     double sum = _aggregatedData.map((p) => p.value).reduce((a, b) => a + b);
//     double maxValue = _aggregatedData.map((p) => p.value).reduce(max);
//
//     setState(() {
//       _averageValue = sum / _aggregatedData.length;
//       _maxY = (maxValue / 50).ceil() * 50.0;
//       if (_maxY == 0) _maxY = 50;
//
//       final formatter = _selectedTimeRange == ChartTimeRange.hour ? DateFormat('HH:mm, dd/MM') : DateFormat('dd/MM/yyyy');
//       _displayDateRange = '${formatter.format(_aggregatedData.first.timestamp)} - ${formatter.format(_aggregatedData.last.timestamp)}';
//       _chartErrorMessage = '';
//     });
//   }
//
//   Widget _bottomTitles(double value, TitleMeta meta) {
//     final int index = value.toInt();
//     if (index >= _aggregatedData.length) return const SizedBox.shrink();
//
//     String text = '';
//     final point = _aggregatedData[index];
//
//     // YÊU CẦU 3: TÙY CHỈNH LẠI TRỤC HOÀNH (X)
//     if (_selectedTimeRange == ChartTimeRange.hour) {
//       // Hiển thị các mốc 2 giờ một lần để đỡ rối
//       if (index % 2 == 0) {
//         text = DateFormat('H:00').format(point.timestamp);
//       }
//     } else {
//       text = DateFormat('dd/MM').format(point.timestamp);
//     }
//     return SideTitleWidget(
//       axisSide: meta.axisSide,
//       space: 4,
//       child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.black54)),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context);
//
//     final barGroups = <BarChartGroupData>[];
//     for (int i = 0; i < _aggregatedData.length; i++) {
//       final point = _aggregatedData[i];
//       final isTouched = i == _touchedIndex;
//       barGroups.add(
//         BarChartGroupData(
//           x: i,
//           barRods: [
//             BarChartRodData(
//               toY: point.value,
//               color: _selectedDataType == ChartDataType.aqi ? AQIUtils.getAQIColor(point.value.round()) : Colors.lightBlue,
//               // YÊU CẦU 1 & 4: Cột rộng hơn và to hơn khi chạm vào
//               width: isTouched ? 20 : 16,
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(5),
//                 topRight: Radius.circular(5),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
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
//                 _buildTimeRangeButton(ChartTimeRange.hour, l10n?.hour ?? 'Giờ'),
//                 const SizedBox(width: 10),
//                 _buildTimeRangeButton(ChartTimeRange.day, l10n?.day ?? 'Ngày'),
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
//               child: _isLoadingChart
//                   ? const Center(child: CircularProgressIndicator())
//                   : barGroups.isEmpty || _chartErrorMessage.isNotEmpty
//                   ? Center(child: Text(_chartErrorMessage.isNotEmpty ? _chartErrorMessage : (l10n?.noDataToDisplay ?? 'Không có dữ liệu để hiển thị.')))
//                   : BarChart(
//                 BarChartData(
//                   maxY: _maxY,
//                   barGroups: barGroups,
//                   // YÊU CẦU 1: Giảm khoảng cách giữa các cột
//                   groupsSpace: 4,
//                   gridData: FlGridData(
//                     show: true,
//                     drawVerticalLine: false,
//                     horizontalInterval: 50, // YÊU CẦU 2: Khoảng cách trục tung là 50
//                     getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
//                   ),
//                   borderData: FlBorderData(show: false),
//                   titlesData: FlTitlesData(
//                     bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitles, reservedSize: 30)),
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 32, // Giảm kích thước để có thêm không gian
//                         interval: 50, // YÊU CẦU 2: Khoảng cách nhãn trục tung là 50
//                       ),
//                     ),
//                     topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   ),
//                   barTouchData: BarTouchData(
//                     touchCallback: (event, response) {
//                       setState(() {
//                         if (response == null || response.spot == null || event is PointerUpEvent || event is FlPanEndEvent) {
//                           _touchedIndex = null;
//                           return;
//                         }
//                         _touchedIndex = response.spot!.touchedBarGroupIndex;
//                       });
//                     },
//                     touchTooltipData: BarTouchTooltipData(
//                       getTooltipItem: (group, groupIndex, rod, rodIndex) => null, // Tắt tooltip mặc định
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             if (!_isLoadingChart && _aggregatedData.isNotEmpty) ...[
//               AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 200),
//                 child: _touchedIndex != null ? _buildCustomTooltip(_aggregatedData[_touchedIndex!]) : const SizedBox(height: 44), // Placeholder có chiều cao cố định
//               ),
//               Center(child: Text(_displayDateRange)),
//               Center(child: Text('${_selectedDataType == ChartDataType.aqi ? "AQI" : "PM2.5"} ${l10n?.average ?? "trung bình"}: ${_averageValue.toStringAsFixed(1)}')),
//             ]
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCustomTooltip(HistoricalDataPoint dataPoint) {
//     String timeStr = _selectedTimeRange == ChartTimeRange.hour
//         ? 'Giờ: ${DateFormat('HH:00, dd/MM').format(dataPoint.timestamp)}'
//         : 'Ngày: ${DateFormat('dd/MM/yyyy').format(dataPoint.timestamp)}';
//
//     return Container(
//       key: ValueKey(dataPoint.timestamp),
//       margin: const EdgeInsets.only(bottom: 8.0),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.8),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.center,
//         children: [
//           Text(
//             '${_selectedDataType == ChartDataType.aqi ? "AQI TB" : "PM2.5 TB"}: ${dataPoint.value.toStringAsFixed(1)}',
//             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
//           ),
//           Text(timeStr, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
//         ],
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
//           setState(() => _selectedTimeRange = range);
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
//           setState(() => _selectedDataType = type);
//           _fetchHistoryData();
//         }
//       },
//       child: Text(text, style: TextStyle(color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700])),
//     );
//   }
// }

// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:intl/intl.dart';
// import 'package:collection/collection.dart';
//
// import '../../../models/AQIUtils.dart';
//
// enum ChartDataType { aqi, pm25 }
// enum ChartTimeRange { hour, day }
//
// class HistoricalDataPoint {
//   final DateTime timestamp;
//   final double pm25Value;
//
//   HistoricalDataPoint({required this.timestamp, required this.pm25Value});
// }
//
// class HistoryChartWidget extends StatefulWidget {
//   final String stationId;
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
//   List<HistoricalDataPoint> _aggregatedData = [];
//   bool _isLoadingChart = true;
//   String _chartErrorMessage = '';
//   String _displayDateRange = '';
//   double _averageValue = 0;
//   double _maxY = 0;
//
//   int? _touchedIndex;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _fetchHistoryData();
//     });
//   }
//
//   // ... (Các hàm _aggregateData, _fetchHistoryData, _prepareChartData giữ nguyên)
//   List<HistoricalDataPoint> _aggregateData(List<HistoricalDataPoint> rawData, ChartTimeRange timeRange) {
//     if (rawData.isEmpty) return [];
//
//     if (timeRange == ChartTimeRange.hour) {
//       final groupedByHour = groupBy(rawData, (p) => DateFormat('yyyy-MM-dd-HH').format(p.timestamp));
//       return groupedByHour.entries.map((entry) {
//         final values = entry.value.map((p) => p.pm25Value).toList();
//         final average = values.reduce((a, b) => a + b) / values.length;
//         return HistoricalDataPoint(timestamp: entry.value.first.timestamp, pm25Value: average);
//       }).toList();
//     } else { // Day
//       final groupedByDay = groupBy(rawData, (p) => DateFormat('yyyy-MM-dd').format(p.timestamp));
//       return groupedByDay.entries.map((entry) {
//         final values = entry.value.map((p) => p.pm25Value).toList();
//         final average = values.reduce((a, b) => a + b) / values.length;
//         return HistoricalDataPoint(timestamp: entry.value.first.timestamp, pm25Value: average);
//       }).toList();
//     }
//   }
//
//   Future<void> _fetchHistoryData() async {
//     if (!mounted) return;
//     final l10n = AppLocalizations.of(context);
//     if (l10n == null) {
//       Future.delayed(const Duration(milliseconds: 100), () => _fetchHistoryData());
//       return;
//     }
//
//     setState(() {
//       _isLoadingChart = true;
//       _chartErrorMessage = '';
//       _aggregatedData = [];
//       _touchedIndex = null;
//     });
//
//     try {
//       final historyRef = FirebaseDatabase.instance.ref('cacThietBiQuanTrac/${widget.stationId}');
//       final now = DateTime.now();
//       final startTimeFilter = now.subtract(const Duration(days: 7));
//       final snapshot = await historyRef.orderByChild('time').startAt(startTimeFilter.millisecondsSinceEpoch).once();
//
//       if (!mounted || snapshot.snapshot.value == null) {
//         setState(() {
//           _isLoadingChart = false;
//           _chartErrorMessage = l10n.noHistoricalData ?? 'Không có dữ liệu lịch sử.';
//         });
//         return;
//       }
//
//       final Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
//       List<HistoricalDataPoint> fetchedPoints = [];
//
//       data.forEach((key, record) {
//         if (record is Map) {
//           final int? timestampMs = record['time'] as int?;
//           final num? pm25Value = record['pm25'] as num?;
//           if (timestampMs != null && pm25Value != null) {
//             final double pm25 = pm25Value.toDouble() / 100.0;
//             fetchedPoints.add(HistoricalDataPoint(
//               timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
//               pm25Value: pm25,
//             ));
//           }
//         }
//       });
//
//       List<HistoricalDataPoint> finalData;
//       if (_selectedTimeRange == ChartTimeRange.hour) {
//         final last24hData = fetchedPoints.where((p) => p.timestamp.isAfter(now.subtract(const Duration(hours: 24)))).toList();
//         finalData = _aggregateData(last24hData, _selectedTimeRange);
//       } else {
//         finalData = _aggregateData(fetchedPoints, _selectedTimeRange);
//       }
//
//       finalData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
//
//       setState(() {
//         _aggregatedData = finalData;
//         _isLoadingChart = false;
//         _prepareChartData();
//       });
//     } catch (e, s) {
//       if (mounted) {
//         print('[HistoryChartWidget] Error: $e\n$s');
//         setState(() => _isLoadingChart = false);
//       }
//     }
//   }
//
//   void _prepareChartData() {
//     if (!mounted) return;
//     final l10n = AppLocalizations.of(context);
//
//     if (_aggregatedData.isEmpty) {
//       setState(() {
//         _averageValue = 0;
//         _maxY = (_selectedDataType == ChartDataType.aqi) ? 200 : 50;
//         _displayDateRange = _selectedTimeRange == ChartTimeRange.hour ? (l10n?.last24Hours ?? "24 giờ qua") : (l10n?.last7Days ?? "7 ngày qua");
//         if (_chartErrorMessage.isEmpty && !_isLoadingChart) {
//           _chartErrorMessage = l10n?.noDataForTimeRange ?? "Không có dữ liệu cho khoảng thời gian này.";
//         }
//       });
//       return;
//     }
//
//     final displayValues = _aggregatedData.map((p) {
//       return _selectedDataType == ChartDataType.aqi ? AQIUtils.calculateAQI(p.pm25Value) : p.pm25Value;
//     }).toList();
//
//     double sum = displayValues.reduce((a, b) => a + b).toDouble();
//     double maxValue = displayValues.reduce(max).toDouble();
//
//     setState(() {
//       _averageValue = sum / displayValues.length;
//       _maxY = (maxValue / 50).ceil() * 50.0;
//       if (_maxY < 50) _maxY = 50;
//
//       final DateFormat formatter;
//       if (_selectedTimeRange == ChartTimeRange.hour) {
//         formatter = DateFormat('HH:00 dd/MM/yyyy');
//       } else {
//         formatter = DateFormat('dd/MM/yyyy');
//       }
//       _displayDateRange = '${formatter.format(_aggregatedData.first.timestamp)} - ${formatter.format(_aggregatedData.last.timestamp)}';
//       _chartErrorMessage = '';
//     });
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context);
//     // << 1. Lấy thông tin theme để sử dụng >>
//     final theme = Theme.of(context);
//     final textTheme = theme.textTheme;
//     final colorScheme = theme.colorScheme;
//
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       elevation: 2.0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
//       // << Nền card sẽ tự động đổi màu theo theme >>
//       color: theme.cardColor,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildTimeRangeDropdown(l10n),
//                 _buildDataTypeToggle(l10n),
//               ],
//             ),
//             const SizedBox(height: 24),
//             SizedBox(
//               height: 250,
//               child: _isLoadingChart
//                   ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
//                   : _aggregatedData.isEmpty || _chartErrorMessage.isNotEmpty
//                   ? Center(child: Text(_chartErrorMessage.isNotEmpty ? _chartErrorMessage : (l10n?.noDataToDisplay ?? 'Không có dữ liệu để hiển thị.'), style: textTheme.bodyLarge))
//                   : BarChart(
//                 BarChartData(
//                   maxY: _maxY,
//                   barGroups: _generateBarGroups(),
//                   groupsSpace: 6,
//                   // << 2. Cập nhật màu cho lưới và viền biểu đồ >>
//                   gridData: FlGridData(
//                     show: true,
//                     drawVerticalLine: true,
//                     horizontalInterval: 50,
//                     verticalInterval: 1,
//                     getDrawingHorizontalLine: (value) => FlLine(
//                       color: theme.dividerColor.withOpacity(0.1),
//                       strokeWidth: 1,
//                     ),
//                     getDrawingVerticalLine: (value) => FlLine(
//                       color: theme.dividerColor.withOpacity(0.1),
//                       strokeWidth: 1,
//                     ),
//                   ),
//                   borderData: FlBorderData(
//                     show: true,
//                     border: Border(
//                       bottom: BorderSide(color: theme.dividerColor, width: 1.5),
//                       left: BorderSide(color: theme.dividerColor, width: 1.5),
//                       right: const BorderSide(color: Colors.transparent),
//                       top: const BorderSide(color: Colors.transparent),
//                     ),
//                   ),
//                   titlesData: FlTitlesData(
//                     bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitles, reservedSize: 30)),
//                     leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 38, interval: 50, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: textTheme.bodySmall))),
//                     topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   ),
//                   barTouchData: BarTouchData(
//                     touchCallback: (event, response) {
//                       setState(() {
//                         if (event.isInterestedForInteractions && response?.spot != null) {
//                           _touchedIndex = response!.spot!.touchedBarGroupIndex;
//                         } else {
//                           _touchedIndex = null;
//                         }
//                       });
//                     },
//                     touchTooltipData: BarTouchTooltipData(
//                       getTooltipColor: (group) => Colors.black.withOpacity(0.8),
//                       tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       tooltipMargin: 8,
//                       getTooltipItem: (group, groupIndex, rod, rodIndex) {
//                         if (_aggregatedData.isEmpty || groupIndex >= _aggregatedData.length) return null;
//                         final dataPoint = _aggregatedData[groupIndex];
//                         final displayValue = _selectedDataType == ChartDataType.aqi
//                             ? AQIUtils.calculateAQI(dataPoint.pm25Value)
//                             : dataPoint.pm25Value;
//                         return BarTooltipItem(
//                           displayValue.toStringAsFixed(1),
//                           const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             if (!_isLoadingChart && _aggregatedData.isNotEmpty)
//               Column(
//                 children: [
//                   Center(
//                     child: Text(
//                       _displayDateRange,
//                       // << 3. Cập nhật màu chữ >>
//                       style: textTheme.bodyMedium,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Center(
//                     child: Text(
//                       '${_selectedDataType == ChartDataType.aqi ? "AQI" : "PM2.5"} ${l10n?.average ?? "trung bình"}: ${_averageValue.toStringAsFixed(1)}',
//                       // << 4. Cập nhật màu chữ >>
//                       style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   List<BarChartGroupData> _generateBarGroups() {
//     return List.generate(_aggregatedData.length, (i) {
//       final point = _aggregatedData[i];
//       final isTouched = i == _touchedIndex;
//       final aqiValue = AQIUtils.calculateAQI(point.pm25Value);
//       final displayHeight = _selectedDataType == ChartDataType.aqi ? aqiValue : point.pm25Value;
//       return BarChartGroupData(
//         x: i,
//         barRods: [
//           BarChartRodData(
//             toY: displayHeight.toDouble(),
//             color: AQIUtils.getAQIColor(aqiValue.round()),
//             width: isTouched ? 22 : 18,
//             borderRadius: const BorderRadius.all(Radius.circular(6)),
//           ),
//         ],
//       );
//     });
//   }
//
//   Widget _buildTimeRangeDropdown(AppLocalizations? l10n) {
//     // << 5. Cập nhật dropdown >>
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;
//
//     return Container(
//       height: 40,
//       decoration: BoxDecoration(
//         color: isDarkMode ? Colors.blueGrey[700] : Colors.white, // << Màu nền dropdown
//         borderRadius: BorderRadius.circular(8.0),
//         border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1),
//         boxShadow: [
//           if (!isDarkMode)
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 4,
//               offset: const Offset(0, 2),
//             ),
//         ],
//       ),
//       child: PopupMenuButton<ChartTimeRange>(
//         onSelected: (ChartTimeRange newValue) {
//           if (newValue != _selectedTimeRange) {
//             setState(() => _selectedTimeRange = newValue);
//             _fetchHistoryData();
//           }
//         },
//         offset: const Offset(0, 42),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
//         // << Nền của menu popup >>
//         color: theme.cardColor,
//         itemBuilder: (BuildContext context) => <PopupMenuEntry<ChartTimeRange>>[
//           PopupMenuItem<ChartTimeRange>(
//             value: ChartTimeRange.day,
//             // << Màu chữ trong menu popup >>
//             child: Text(l10n?.day ?? 'Ngày', style: theme.textTheme.bodyLarge),
//           ),
//           PopupMenuItem<ChartTimeRange>(
//             value: ChartTimeRange.hour,
//             child: Text(l10n?.hour ?? 'Giờ', style: theme.textTheme.bodyLarge),
//           ),
//         ],
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12.0),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 _selectedTimeRange == ChartTimeRange.day ? (l10n?.day ?? 'Ngày') : (l10n?.hour ?? 'Giờ'),
//                 // << Màu chữ dropdown >>
//                 style: theme.textTheme.bodyLarge?.copyWith(
//                     color: isDarkMode ? Colors.white : Colors.black87),
//               ),
//               const SizedBox(width: 8),
//               // << Màu icon dropdown >>
//               Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white70 : Colors.grey),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDataTypeToggle(AppLocalizations? l10n) {
//     // << 6. Cập nhật nút AQI/PM2.5 >>
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;
//
//     // Màu cho nút được chọn
//     final Color selectedFillColor = isDarkMode ? Colors.blueGrey[700]! : theme.colorScheme.primary;
//     // Màu cho nút không được chọn
//     final Color unselectedColor = isDarkMode ? Colors.white70 : theme.colorScheme.primary;
//
//     return SizedBox(
//       height: 40,
//       child: ToggleButtons(
//         isSelected: [_selectedDataType == ChartDataType.aqi, _selectedDataType == ChartDataType.pm25],
//         onPressed: (int index) {
//           final type = index == 0 ? ChartDataType.aqi : ChartDataType.pm25;
//           if (_selectedDataType != type) {
//             setState(() => _selectedDataType = type);
//             _prepareChartData();
//           }
//         },
//         borderRadius: BorderRadius.circular(8.0),
//         selectedColor: Colors.white, // Chữ của nút được chọn luôn là màu trắng
//         color: unselectedColor, // Chữ của nút không được chọn
//         fillColor: selectedFillColor, // Nền của nút được chọn
//         splashColor: selectedFillColor.withOpacity(0.12),
//         renderBorder: true,
//         borderColor: unselectedColor,
//         selectedBorderColor: selectedFillColor,
//         constraints: const BoxConstraints(minWidth: 80.0),
//         children: const [
//           Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('AQI')),
//           Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('PM2.5')),
//         ],
//       ),
//     );
//   }
//
//   Widget _bottomTitles(double value, TitleMeta meta) {
//     final int index = value.toInt();
//     if (index < 0 || index >= _aggregatedData.length) {
//       return const SizedBox.shrink();
//     }
//
//     final int skipInterval = _selectedTimeRange == ChartTimeRange.hour ? 4 : 2;
//     if (index % skipInterval != 0 && index != _aggregatedData.length -1) {
//       return const SizedBox.shrink();
//     }
//
//     final point = _aggregatedData[index];
//     String text = _selectedTimeRange == ChartTimeRange.hour
//         ? DateFormat('H:00').format(point.timestamp)
//         : DateFormat('dd/MM').format(point.timestamp);
//
//     // << 7. Cập nhật màu cho trục X của biểu đồ >>
//     return SideTitleWidget(
//       axisSide: meta.axisSide,
//       space: 4,
//       child: Text(text, style: Theme.of(context).textTheme.bodySmall),
//     );
//   }
// }

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../../../models/AQIUtils.dart';

enum ChartDataType { aqi, pm25 }
enum ChartTimeRange { hour, day }

// MODIFIED: pm25Value có thể là null để biểu thị không có dữ liệu
class HistoricalDataPoint {
  final DateTime timestamp;
  final double? pm25Value;

  HistoricalDataPoint({required this.timestamp, this.pm25Value});
}

class HistoryChartWidget extends StatefulWidget {
  final String stationId;

  const HistoryChartWidget({Key? key, required this.stationId}) : super(key: key);

  @override
  _HistoryChartWidgetState createState() => _HistoryChartWidgetState();
}

class _HistoryChartWidgetState extends State<HistoryChartWidget> {
  ChartDataType _selectedDataType = ChartDataType.aqi;
  ChartTimeRange _selectedTimeRange = ChartTimeRange.hour;

  // Dữ liệu này sẽ luôn có 24 hoặc 7 điểm, một số có thể không có giá trị
  List<HistoricalDataPoint> _chartData = [];
  bool _isLoadingChart = true;
  String _chartErrorMessage = '';
  String _displayDateRange = '';
  double _averageValue = 0;
  double _maxY = 50;

  int? _touchedIndex;
  String? _touchedMessage; // NEW: Thêm message khi chạm vào cột

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndPrepareData();
    });
  }

  // NEW: Hàm chính để điều phối việc lấy và chuẩn bị dữ liệu
  Future<void> _fetchAndPrepareData() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoadingChart = true;
      _chartErrorMessage = '';
      _touchedIndex = null;
      _touchedMessage = null;
    });

    try {
      final now = DateTime.now();

      // Xác định khoảng thời gian cần lấy dữ liệu từ Firebase
      final Duration fetchDuration = _selectedTimeRange == ChartTimeRange.hour
          ? const Duration(hours: 24)
          : const Duration(days: 7);

      final startTimeFilter = now.subtract(fetchDuration);

      final historyRef = FirebaseDatabase.instance.ref('cacThietBiQuanTrac/${widget.stationId}');
      final snapshot = await historyRef.orderByChild('time').startAt(startTimeFilter.millisecondsSinceEpoch).endAt(now.millisecondsSinceEpoch).once();

      List<HistoricalDataPoint> fetchedPoints = [];
      if (snapshot.snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, record) {
          if (record is Map) {
            final int? timestampMs = record['time'] as int?;
            final num? pm25Value = record['pm25'] as num?;
            if (timestampMs != null && pm25Value != null) {
              fetchedPoints.add(HistoricalDataPoint(
                timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
                pm25Value: pm25Value.toDouble() / 100.0,
              ));
            }
          }
        });
      }

      // Tạo khung biểu đồ và điền dữ liệu vào
      final generatedData = _generateChartDataWithPlaceholders(fetchedPoints);

      setState(() {
        _chartData = generatedData;
        _isLoadingChart = false;
        _prepareChartDisplayInfo();
      });

    } catch (e, s) {
      if (mounted) {
        print('[HistoryChartWidget] Error: $e\n$s');
        setState(() {
          _isLoadingChart = false;
          _chartErrorMessage = l10n?.errorLoadingData ?? 'Lỗi khi tải dữ liệu.';
        });
      }
    }
  }

  // NEW: Hàm tạo "khung" biểu đồ và điền dữ liệu
  List<HistoricalDataPoint> _generateChartDataWithPlaceholders(List<HistoricalDataPoint> fetchedData) {
    final List<HistoricalDataPoint> placeholderData = [];
    final now = DateTime.now();

    if (_selectedTimeRange == ChartTimeRange.hour) {
      final Map<int, List<double>> hourlyData = {};
      for (var p in fetchedData) {
        final hourKey = DateTime(p.timestamp.year, p.timestamp.month, p.timestamp.day, p.timestamp.hour).millisecondsSinceEpoch;
        if(hourlyData[hourKey] == null) hourlyData[hourKey] = [];
        hourlyData[hourKey]!.add(p.pm25Value!);
      }

      for (int i = 23; i >= 0; i--) {
        final targetHour = now.subtract(Duration(hours: i));
        final slotTimestamp = DateTime(targetHour.year, targetHour.month, targetHour.day, targetHour.hour);
        final hourKey = slotTimestamp.millisecondsSinceEpoch;

        if (hourlyData.containsKey(hourKey)) {
          final values = hourlyData[hourKey]!;
          final avg = values.reduce((a, b) => a + b) / values.length;
          placeholderData.add(HistoricalDataPoint(timestamp: slotTimestamp, pm25Value: avg));
        } else {
          placeholderData.add(HistoricalDataPoint(timestamp: slotTimestamp, pm25Value: null));
        }
      }
    } else { // ChartTimeRange.day
      final Map<int, List<double>> dailyData = {};
      for (var p in fetchedData) {
        final dayKey = DateTime(p.timestamp.year, p.timestamp.month, p.timestamp.day).millisecondsSinceEpoch;
        if(dailyData[dayKey] == null) dailyData[dayKey] = [];
        dailyData[dayKey]!.add(p.pm25Value!);
      }

      for (int i = 6; i >= 0; i--) {
        final targetDay = now.subtract(Duration(days: i));
        final slotTimestamp = DateTime(targetDay.year, targetDay.month, targetDay.day);
        final dayKey = slotTimestamp.millisecondsSinceEpoch;

        if (dailyData.containsKey(dayKey)) {
          final values = dailyData[dayKey]!;
          final avg = values.reduce((a, b) => a + b) / values.length;
          placeholderData.add(HistoricalDataPoint(timestamp: slotTimestamp, pm25Value: avg));
        } else {
          placeholderData.add(HistoricalDataPoint(timestamp: slotTimestamp, pm25Value: null));
        }
      }
    }
    return placeholderData;
  }

  // NEW: Hàm chuẩn bị các thông tin hiển thị (trung bình, dải ngày, trục Y)
  void _prepareChartDisplayInfo() {
    if (!mounted) return;

    // Lọc ra các điểm có dữ liệu để tính toán
    final validData = _chartData.where((p) => p.pm25Value != null).toList();
    final displayValues = validData.map((p) {
      return _selectedDataType == ChartDataType.aqi
          ? AQIUtils.calculateAQI(p.pm25Value!)
          : p.pm25Value!;
    }).toList();

    if (displayValues.isEmpty) {
      _averageValue = 0;
      _maxY = (_selectedDataType == ChartDataType.aqi) ? 200 : 50;
    } else {
      _averageValue = displayValues.reduce((a, b) => a + b) / displayValues.length;
      final maxValue = displayValues.reduce(max);
      _maxY = (maxValue / 50).ceil() * 50.0;
      if (_maxY < 50) _maxY = 50;
    }

    // Cập nhật dải ngày tháng hiển thị
    final now = DateTime.now();
    if (_selectedTimeRange == ChartTimeRange.hour) {
      final start = now.subtract(const Duration(hours: 23));
      _displayDateRange = "${DateFormat('HH:00 dd/MM/yyyy').format(start)} - ${DateFormat('HH:00 dd/MM/yyyy').format(now)}";
    } else { // Day
      final start = now.subtract(const Duration(days: 6));
      _displayDateRange = "${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(now)}";
    }
  }


  @override
  Widget build(BuildContext context) {
    // ...Phần build UI giữ nguyên cấu trúc cũ...
    // Các hàm helper cho UI sẽ được sửa đổi bên dưới
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeRangeDropdown(l10n, theme),
                _buildDataTypeToggle(l10n, theme),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: _isLoadingChart
                  ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                  : _chartErrorMessage.isNotEmpty
                  ? Center(child: Text(_chartErrorMessage, style: textTheme.bodyLarge))
                  : BarChart(
                BarChartData(
                  maxY: _maxY,
                  barGroups: _generateBarGroups(theme),
                  groupsSpace: 6,
                  gridData: FlGridData(show: false), // Tắt lưới cho gọn
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor, width: 1.5),
                      left: BorderSide(color: theme.dividerColor, width: 1.5),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitles, reservedSize: 30)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 38, interval: 50, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: textTheme.bodySmall))),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barTouchData: _buildBarTouchData(l10n, theme),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryInfo(l10n, textTheme),
          ],
        ),
      ),
    );
  }

  // MODIFIED: Cập nhật hàm tạo các cột biểu đồ
  List<BarChartGroupData> _generateBarGroups(ThemeData theme) {
    return List.generate(_chartData.length, (i) {
      final point = _chartData[i];
      final isTouched = i == _touchedIndex;

      double displayHeight = 0;
      Color barColor = theme.dividerColor.withOpacity(0.2); // Màu mặc định cho cột không có dữ liệu

      if (point.pm25Value != null) {
        final aqiValue = AQIUtils.calculateAQI(point.pm25Value!);
        displayHeight = (_selectedDataType == ChartDataType.aqi ? aqiValue : point.pm25Value!).toDouble();
        barColor = AQIUtils.getAQIColor(aqiValue.round());
      }

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: displayHeight,
            color: barColor,
            width: isTouched ? 22 : 18,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
          ),
        ],
      );
    });
  }

  // NEW: Hàm xử lý sự kiện chạm vào cột
  BarTouchData _buildBarTouchData(AppLocalizations? l10n, ThemeData theme) {
    return BarTouchData(
        handleBuiltInTouches: true, // Tắt tooltip mặc định
        touchCallback: (event, response) {
          if (event is PointerUpEvent || event is FlPanEndEvent) {
            // Khi người dùng nhả tay, reset trạng thái
            setState(() {
              _touchedIndex = null;
              _touchedMessage = null;
            });
            return;
          }

          if (response?.spot != null && event.isInterestedForInteractions) {
            final index = response!.spot!.touchedBarGroupIndex;
            final dataPoint = _chartData[index];

            if (dataPoint.pm25Value == null) {
              // Nếu không có dữ liệu
              setState(() {
                _touchedIndex = index;
                _touchedMessage = l10n?.noDataForTimeRange ?? "Không có dữ liệu cho khoảng thời gian này";
              });
            } else {
              // Nếu có dữ liệu, reset message để hiển thị thông tin trung bình
              setState(() {
                _touchedIndex = index;
                _touchedMessage = null;
              });
            }
          }
        },
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.transparent, // Ẩn tooltip mặc định
          getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
        )
    );
  }

  // NEW: Hàm hiển thị thông tin tóm tắt hoặc message khi chạm
  Widget _buildSummaryInfo(AppLocalizations? l10n, TextTheme textTheme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _touchedMessage != null
          ? // Hiển thị message khi chạm vào cột không có dữ liệu
      Container(
        key: const ValueKey('touched_message'),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Text(
            _touchedMessage!,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.orangeAccent),
          ),
        ),
      )
          : // Hiển thị thông tin mặc định
      Container(
        key: const ValueKey('default_info'),
        child: Column(
          children: [
            Center(
              child: Text(_displayDateRange, style: textTheme.bodyMedium),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${_selectedDataType == ChartDataType.aqi ? "AQI" : "PM2.5"} ${l10n?.average ?? "trung bình"}: ${_averageValue.toStringAsFixed(1)}',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Các hàm build UI phụ (Dropdown, Toggle) được giữ nguyên hoặc chỉnh sửa nhỏ
  Widget _buildTimeRangeDropdown(AppLocalizations? l10n, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.blueGrey[700] : Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 1),
      ),
      child: PopupMenuButton<ChartTimeRange>(
        onSelected: (ChartTimeRange newValue) {
          if (newValue != _selectedTimeRange) {
            setState(() => _selectedTimeRange = newValue);
            _fetchAndPrepareData(); // Gọi hàm mới
          }
        },
        offset: const Offset(0, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        color: theme.cardColor,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<ChartTimeRange>>[
          PopupMenuItem<ChartTimeRange>(
            value: ChartTimeRange.hour, // Đổi thứ tự
            child: Text(l10n?.hour ?? 'Giờ', style: theme.textTheme.bodyLarge),
          ),
          PopupMenuItem<ChartTimeRange>(
            value: ChartTimeRange.day,
            child: Text(l10n?.day ?? 'Ngày', style: theme.textTheme.bodyLarge),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedTimeRange == ChartTimeRange.day ? (l10n?.day ?? 'Ngày') : (l10n?.hour ?? 'Giờ'),
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white70 : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTypeToggle(AppLocalizations? l10n, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final Color selectedFillColor = isDarkMode ? Colors.blueGrey[700]! : theme.colorScheme.primary;
    final Color unselectedColor = isDarkMode ? Colors.white70 : theme.colorScheme.primary;

    return SizedBox(
      height: 40,
      child: ToggleButtons(
        isSelected: [_selectedDataType == ChartDataType.aqi, _selectedDataType == ChartDataType.pm25],
        onPressed: (int index) {
          final type = index == 0 ? ChartDataType.aqi : ChartDataType.pm25;
          if (_selectedDataType != type) {
            setState(() {
              _selectedDataType = type;
              // Chỉ cần chuẩn bị lại thông tin hiển thị, không cần fetch lại
              _prepareChartDisplayInfo();
            });
          }
        },
        borderRadius: BorderRadius.circular(8.0),
        selectedColor: Colors.white,
        color: unselectedColor,
        fillColor: selectedFillColor,
        splashColor: selectedFillColor.withOpacity(0.12),
        renderBorder: true,
        borderColor: unselectedColor,
        selectedBorderColor: selectedFillColor,
        constraints: const BoxConstraints(minWidth: 80.0),
        children: const [
          Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('AQI')),
          Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('PM2.5')),
        ],
      ),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    final int index = value.toInt();
    if (index < 0 || index >= _chartData.length) return const SizedBox.shrink();

    // Hiển thị cách nhau để đỡ rối
    if (_selectedTimeRange == ChartTimeRange.hour) {
      if (index % 4 != 0 && index != _chartData.length -1) return const SizedBox.shrink();
    } else { // Day
      if (index % 2 != 0 && index != _chartData.length -1) return const SizedBox.shrink();
    }

    final point = _chartData[index];
    String text = _selectedTimeRange == ChartTimeRange.hour
        ? DateFormat('H:00').format(point.timestamp)
        : DateFormat('dd/MM').format(point.timestamp);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}