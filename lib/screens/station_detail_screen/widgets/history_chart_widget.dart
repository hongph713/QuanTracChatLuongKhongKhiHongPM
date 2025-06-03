import 'dart:async';
import 'dart:math'; // For min/max
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    print("[HistoryChartWidget] initState for stationId: ${widget.stationId}");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistoryData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchHistoryData() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      // Retry after a short delay if localization is not ready
      Future.delayed(const Duration(milliseconds: 100), _fetchHistoryData);
      return;
    }

    print('[HistoryChartWidget] Fetching data - Type: $_selectedDataType, Range: $_selectedTimeRange for station: ${widget.stationId}');
    setState(() {
      _isLoadingChart = true;
      _chartErrorMessage = '';
      _chartSpots = [];
      _rawHistoricalData = []; // Xóa dữ liệu cũ
    });

    try {
      // SỬA ĐƯỜNG DẪN Ở ĐÂY: Thêm '/data_points'
      final historyRef = FirebaseDatabase.instance
          .ref('cacThietBiQuanTrac/${widget.stationId}');

      DateTime now = DateTime.now();
      DateTime startTimeFilter;

      if (_selectedTimeRange == ChartTimeRange.hour) {
        startTimeFilter = now.subtract(const Duration(hours: 24));
      } else {
        startTimeFilter = now.subtract(const Duration(days: 7));
      }
      final int startTimestampFilterMs = startTimeFilter.millisecondsSinceEpoch;

      final snapshot = await historyRef.orderByChild('time').limitToLast(1000).once();

      if (!mounted) return;

      if (snapshot.snapshot.value == null) {
        print('[HistoryChartWidget] No historical data found at path: ${historyRef.path}');
        setState(() {
          _isLoadingChart = false;
          _chartErrorMessage = l10n.noHistoricalData ?? 'Không có dữ liệu lịch sử.';
          _prepareChartData();
        });
        return;
      }

      final Map<dynamic, dynamic> data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      List<HistoricalDataPoint> fetchedPoints = [];

      print('[HistoryChartWidget] Raw data received from data_points: ${data.length} entries.');

      data.forEach((pushId, record) {
        if (record is Map) {
          try {
            dynamic timeValue = record['time'];
            int? timestampMs;

            if (timeValue is int) {
              timestampMs = timeValue;
            } else if (timeValue is Map && timeValue['.sv'] == 'timestamp') {
              print('[HistoryChartWidget] Server timestamp placeholder found for pushId $pushId. Skipping for chart.');
              return;
            } else {
              print('[HistoryChartWidget] Invalid time format for pushId $pushId. Skipping. Data: $record');
              return;
            }

            final num? pm25Value = record['pm25'] as num?;

            if (pm25Value == null) {
              print('[HistoryChartWidget] Skipping record $pushId due to missing pm25. Data: $record');
              return;
            }

            if (timestampMs >= startTimestampFilterMs) {
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
        final currentL10n = AppLocalizations.of(context);
        setState(() {
          _isLoadingChart = false;
          _chartErrorMessage = currentL10n?.errorLoadingHistoryData ?? 'Lỗi tải dữ liệu lịch sử.';
          _rawHistoricalData = [];
          _prepareChartData();
        });
      }
    }
  }

  void _prepareChartData() {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);

    if (_rawHistoricalData.isEmpty) {
      setState(() {
        _chartSpots = [];
        _minX = 0; _maxX = 0; _minY = 0; _maxY = 0;
        _averageValue = 0;
        _displayDateRange = _selectedTimeRange == ChartTimeRange.hour
            ? (l10n?.last24Hours ?? "24 giờ qua")
            : (l10n?.last7Days ?? "7 ngày qua");
        if (_chartErrorMessage.isEmpty && !_isLoadingChart) {
          _chartErrorMessage = l10n?.noDataForTimeRange ?? "Không có dữ liệu cho khoảng thời gian này.";
        }
      });
      return;
    }

    List<FlSpot> spots = [];
    double sum = 0;

    _minX = _rawHistoricalData.first.timestamp.millisecondsSinceEpoch.toDouble();
    _maxX = _rawHistoricalData.last.timestamp.millisecondsSinceEpoch.toDouble();

    if (_minX == _maxX && _rawHistoricalData.length == 1) {
      _minX -= const Duration(hours: 1).inMilliseconds.toDouble();
      _maxX += const Duration(hours: 1).inMilliseconds.toDouble();
    } else if (_minX == _maxX) {
      _maxX = _minX + 1;
    }

    _minY = _rawHistoricalData.map((p) => p.value).reduce(min);
    _maxY = _rawHistoricalData.map((p) => p.value).reduce(max);

    for (var point in _rawHistoricalData) {
      spots.add(FlSpot(point.timestamp.millisecondsSinceEpoch.toDouble(), point.value));
      sum += point.value;
    }

    _minY = max(0, _minY - (_maxY - _minY) * 0.1 - 5);
    _maxY = _maxY + (_maxY - _minY) * 0.1 + 5;
    if (_minY >= _maxY) {
      _minY = max(0, _maxY - 10);
      if (_minY == _maxY) _maxY = _minY +10;
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
      if (dateTime.hour == 0) {
        return DateFormat('HH\ndd/MM').format(dateTime);
      }
      return DateFormat('HH').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                _buildTimeRangeButton(ChartTimeRange.hour, l10n?.hour ?? 'Giờ'),
                const SizedBox(width: 10),
                _buildTimeRangeButton(ChartTimeRange.day, l10n?.day ?? 'Ngày'),
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
              padding: const EdgeInsets.only(right: 16, top: 10),
              child: _isLoadingChart
                  ? const Center(child: CircularProgressIndicator())
                  : _chartSpots.isEmpty || _chartErrorMessage.isNotEmpty
                  ? Center(
                child: Text(
                  _chartErrorMessage.isNotEmpty ? _chartErrorMessage : (l10n?.noDataToDisplay ?? 'Không có dữ liệu để hiển thị.'),
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
                    horizontalInterval: (_maxY - _minY) / 4 > 0 ? (_maxY - _minY) / 4 : 10,
                    verticalInterval: (_maxX - _minX) / 5 > 0 ? (_maxX - _minX) / 5 : const Duration(hours: 4).inMilliseconds.toDouble(),
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
                        reservedSize: 35,
                        interval: (_maxX - _minX) / 4 > 0 ? (_maxX - _minX) / 4 : const Duration(hours: 6).inMilliseconds.toDouble(),
                        getTitlesWidget: (value, meta) {
                          if (value == _minX || value == _maxX || ((_maxX - _minX) > 0 && (value - _minX) % (((_maxX - _minX) / 4).floorToDouble()) == 0) ) {
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
                          if (value == _minY || value == _maxY || (_maxY - _minY > 0 && value % (((_maxY - _minY)/4).ceilToDouble()) == 0 && value.toInt() !=0) ) {
                            if (value < 0 && _minY <0) return const Text('');
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
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                  '${_selectedDataType == ChartDataType.aqi ? "AQI" : "PM2.5"} ${l10n?.average ?? "trung bình"}: ${_averageValue.toStringAsFixed(1)}',
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