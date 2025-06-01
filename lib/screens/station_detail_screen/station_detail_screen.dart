import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting if needed for history

// TODO: Đảm bảo các đường dẫn import này đúng
import '../../models/station.dart';
import '../../models/AQIUtils.dart';
import 'widgets/health_recommendation_widget.dart';
import 'widgets/history_chart_widget.dart';

class StationDetailScreen extends StatelessWidget {
  final Station station;

  const StationDetailScreen({Key? key, required this.station}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int aqi = station.aqi;
    final Color aqiColor = AQIUtils.getAQIColor(aqi);
    final String aqiCategory = AQIUtils.getAQIDescription(aqi); // Đã sửa ở lần trước
    final String pm25String = station.nongDoBuiMin.toStringAsFixed(1);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0.5,
            iconTheme: IconThemeData(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
            // ĐẶT TIÊU ĐỀ CHÍNH (GHIM LẠI) Ở ĐÂY
            title: Text(
              station.viTri,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                fontSize: 17.0, // Kích thước có thể điều chỉnh cho phù hợp với AppBar
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            centerTitle: true, // Căn giữa tiêu đề ghim lại
            flexibleSpace: FlexibleSpaceBar(
              // title: Text(''), // Loại bỏ title ở đây hoặc để trống
              // titlePadding: EdgeInsets.zero, // Không cần nữa
              background: Container(
                // Padding để nội dung không bị che bởi AppBar đã thu gọn
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 10, left: 16, right: 16, bottom: 16),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // AQI Value
                    Text(
                      aqi.toString(),
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: aqiColor,
                      ),
                    ),
                    // AQI Category
                    Text(
                      aqiCategory,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: aqiColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Temperature and Humidity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.thermostat_outlined, color: Colors.grey[700], size: 20),
                        const SizedBox(width: 4),
                        Text('${station.nhietDo.toStringAsFixed(1)}°C', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                        const SizedBox(width: 24),
                        Icon(Icons.water_drop_outlined, color: Colors.grey[700], size: 20),
                        const SizedBox(width: 4),
                        Text('${station.doAm.toStringAsFixed(0)}%', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // PM2.5 Concentration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Chất gây ô nhiễm chính: PM2.5',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$pm25String µg/m³',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: aqiColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Nội dung có thể cuộn bên dưới
          SliverList(
            delegate: SliverChildListDelegate(
              [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0), // Tăng padding top cho section đầu tiên
                  child: Text(
                    'Khuyến nghị về sức khoẻ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                HealthRecommendationWidget(aqi: aqi),
                const SizedBox(height: 24.0), // Tăng khoảng cách
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Lịch sử dữ liệu',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                HistoryChartWidget(stationId: station.id),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

