import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    // Lấy localization một cách an toàn
    final AppLocalizations? l10n = AppLocalizations.of(context);

    final int aqi = station.aqi;
    final Color aqiColor = AQIUtils.getAQIColor(aqi);

    // Sử dụng fallback nếu l10n null
    final String aqiCategory = _getAQIDescription(aqi, l10n);
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
              background: Container(
                // Padding để nội dung không bị che bởi AppBar đã thu gọn
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
                    left: 16,
                    right: 16,
                    bottom: 16
                ),
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
                        Text(
                            '${station.nhietDo.toStringAsFixed(1)}°C',
                            style: TextStyle(fontSize: 16, color: Colors.grey[800])
                        ),
                        const SizedBox(width: 24),
                        Icon(Icons.water_drop_outlined, color: Colors.grey[700], size: 20),
                        const SizedBox(width: 4),
                        Text(
                            '${station.doAm.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 16, color: Colors.grey[800])
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // PM2.5 Concentration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getMainPollutantText(l10n),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0), // Tăng padding top cho section đầu tiên
                  child: Text(
                    _getHealthRecommendationTitle(l10n),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                HealthRecommendationWidget(aqi: aqi),
                const SizedBox(height: 24.0), // Tăng khoảng cách
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _getDataHistoryTitle(l10n),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

// Helper methods với fallback cho các text
  String _getAQIDescription(int aqi, AppLocalizations? l10n) {
    if (l10n != null) {
      // Sử dụng localized strings nếu có
      if (aqi <= 50) return l10n.aqiGood ?? 'Tốt';
      if (aqi <= 100) return l10n.aqiModerate ?? 'Trung bình';
      if (aqi <= 150) return l10n.aqiUnhealthyForSensitive ?? 'Không lành mạnh cho nhóm nhạy cảm';
      if (aqi <= 200) return l10n.aqiUnhealthy ?? 'Không lành mạnh';
      if (aqi <= 300) return l10n.aqiVeryUnhealthy ?? 'Rất không lành mạnh';
      return l10n.aqiHazardous ?? 'Nguy hiểm';
    } else {
      // Fallback cho tiếng Việt
      if (aqi <= 50) return 'Tốt';
      if (aqi <= 100) return 'Trung bình';
      if (aqi <= 150) return 'Không lành mạnh cho nhóm nhạy cảm';
      if (aqi <= 200) return 'Không lành mạnh';
      if (aqi <= 300) return 'Rất không lành mạnh';
      return 'Nguy hiểm';
    }
  }

  String _getMainPollutantText(AppLocalizations? l10n) {
    if (l10n != null) {
      return l10n.mainPollutantPM25 ?? 'Chất gây ô nhiễm chính: PM2.5';
    }
    return 'Chất gây ô nhiễm chính: PM2.5';
  }

  String _getHealthRecommendationTitle(AppLocalizations? l10n) {
    if (l10n != null) {
      return l10n.healthRecommendationsTitle ?? 'Khuyến nghị về sức khoẻ';
    }
    return 'Khuyến nghị về sức khoẻ';
  }

  String _getDataHistoryTitle(AppLocalizations? l10n) {
    if (l10n != null) {
      return l10n.dataHistoryTitle ?? 'Lịch sử dữ liệu';
    }
    return 'Lịch sử dữ liệu';
  }
}