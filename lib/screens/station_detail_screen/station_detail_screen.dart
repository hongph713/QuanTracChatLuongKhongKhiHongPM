import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../models/station.dart';
import '../../models/AQIUtils.dart';
import 'widgets/health_recommendation_widget.dart';
import 'widgets/history_chart_widget.dart';

class StationDetailScreen extends StatelessWidget {
  final Station station;

  const StationDetailScreen({Key? key, required this.station}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // << 1. LẤY THÔNG TIN THEME ĐỂ SỬ DỤNG TRONG TOÀN BỘ WIDGET >>
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    // Lấy các giá trị từ station
    final int aqi = station.aqi;
    final Color aqiColor = AQIUtils.getAQIColor(aqi);
    final String aqiCategory = _getAQIDescription(aqi, l10n);
    final String pm25String = station.nongDoBuiMin.toStringAsFixed(1);

    return Scaffold(
      // Màu nền của Scaffold sẽ tự động được lấy từ theme
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor, // Nền AppBar đồng bộ
            elevation: 0.5,
            // << 2. Icon quay lại sẽ tự động đổi màu theo theme >>
            iconTheme: IconThemeData(color: colorScheme.onBackground),
            title: Text(
              station.viTri,
              style: textTheme.titleMedium?.copyWith(
                // << 3. Tiêu đề AppBar sẽ tự động đổi màu theo theme >>
                color: colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
                    left: 16,
                    right: 16,
                    bottom: 16
                ),
                color: theme.scaffoldBackgroundColor, // Nền của flexibleSpace đồng bộ
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      aqi.toString(),
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: aqiColor, // Giữ lại màu AQI để nhấn mạnh
                      ),
                    ),
                    Text(
                      aqiCategory,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: aqiColor, // Giữ lại màu AQI để nhấn mạnh
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // << 4. CẬP NHẬT MÀU CHO ICON VÀ TEXT CỦA NHIỆT ĐỘ, ĐỘ ẨM >>
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.thermostat_outlined, color: colorScheme.onSurface.withOpacity(0.7), size: 20),
                        const SizedBox(width: 4),
                        Text(
                            '${station.nhietDo.toStringAsFixed(1)}°C',
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)
                        ),
                        const SizedBox(width: 24),
                        Icon(Icons.water_drop_outlined, color: colorScheme.onSurface.withOpacity(0.7), size: 20),
                        const SizedBox(width: 4),
                        Text(
                            '${station.doAm.toStringAsFixed(0)}%',
                            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // << 5. CẬP NHẬT MÀU CHO TEXT CHẤT GÂY Ô NHIỄM >>
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getMainPollutantText(l10n),
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$pm25String µg/m³',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: aqiColor, // Giữ lại màu AQI để nhấn mạnh
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                  child: Text(
                    _getHealthRecommendationTitle(l10n),
                    // << 6. CÁC TIÊU ĐỀ SECTION SẼ TỰ ĐỘNG ĐỔI MÀU >>
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                HealthRecommendationWidget(aqi: aqi),
                const SizedBox(height: 24.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _getDataHistoryTitle(l10n),
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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

  // Các hàm helper giữ nguyên, không cần thay đổi
  String _getAQIDescription(int aqi, AppLocalizations? l10n) {
    if (l10n != null) {
      if (aqi <= 50) return l10n.aqiGood ?? 'Tốt';
      if (aqi <= 100) return l10n.aqiModerate ?? 'Trung bình';
      if (aqi <= 150) return l10n.aqiUnhealthyForSensitive ?? 'Không lành mạnh cho nhóm nhạy cảm';
      if (aqi <= 200) return l10n.aqiUnhealthy ?? 'Không lành mạnh';
      if (aqi <= 300) return l10n.aqiVeryUnhealthy ?? 'Rất không lành mạnh';
      return l10n.aqiHazardous ?? 'Nguy hiểm';
    } else {
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