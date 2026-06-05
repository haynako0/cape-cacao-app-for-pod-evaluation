import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/history_entry.dart';
import '../onnx_service.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final historyProvider = context.watch<HistoryProvider>();
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final List<HistoryEntry> entries = historyProvider.historyEntries;
    final int totalScans = entries.length;
    final List<Detection> allDetections = entries.expand((e) => e.detections).toList();
    final int totalDetections = allDetections.length;

    final Map<String, int> classCounts = {};
    final Map<String, double> totalConfidence = {};
    for (Detection d in allDetections) {
      final label = d.label.toUpperCase().trim();
      classCounts[label] = (classCounts[label] ?? 0) + 1;
      totalConfidence[label] = (totalConfidence[label] ?? 0) + d.confidence;
    }

    final Map<String, double> avgConfidence = {};
    totalConfidence.forEach((key, value) {
      avgConfidence[key] = (value / classCounts[key]!) * 100;
    });

    String mostCommonLabel = settings.translate('no_detections');
    int mostCommonCount = 0;
    classCounts.forEach((key, value) {
      if (value > mostCommonCount) {
        mostCommonCount = value;
        mostCommonLabel = key;
      }
    });

    final scansWithDetections = entries.where((e) => e.detections.isNotEmpty).length;
    final detectionRate = totalScans > 0 ? (scansWithDetections / totalScans * 100) : 0.0;

    final Map<int, int> last7DaysDetections = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final count = entries
          .where((e) => e.date.isAfter(dayStart) && e.date.isBefore(dayEnd))
          .fold(0, (sum, e) => sum + e.detections.length);
      last7DaysDetections[6 - i] = count; 
    }

    if (totalScans == 0) {
      return _buildEmptyState(context, colorScheme, textTheme, settings);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCategoryContainer(
            context,
            title: settings.translate('performance_overview'), 
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildKpiItem(
                        context, 
                        settings.translate('total_scans'), 
                        "$totalScans", 
                        Icons.qr_code_scanner_rounded, 
                        colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiItem(
                        context, 
                        settings.translate('detections_title'), 
                        "$totalDetections", 
                        Icons.bug_report_rounded, 
                        colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildKpiItem(
                        context, 
                        settings.translate('detection_rate'), 
                        "${detectionRate.toStringAsFixed(1)}%", 
                        Icons.analytics_rounded, 
                        colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiItem(
                        context, 
                        settings.translate('most_detected'),
                        mostCommonLabel, 
                        Icons.layers_rounded, 
                        _getClassColor(mostCommonLabel), 
                        isHighlighted: false, 
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          
          _buildCategoryContainer(
            context,
            title: settings.translate('disease_distribution'),
            child: _buildPieChartContent(classCounts, totalDetections, colorScheme, textTheme),
          ),

          const SizedBox(height: 16),

          _buildCategoryContainer(
            context,
            title: settings.translate('model_confidence'),
            child: _buildBarChartContent(avgConfidence, colorScheme, textTheme),
          ),

          const SizedBox(height: 16),

          _buildCategoryContainer(
            context,
            title: settings.translate('weekly_activity'),
            child: _buildLineChartContent(last7DaysDetections, colorScheme, textTheme, settings),
          ),
          
          const SizedBox(height: 80), 
        ],
      ),
    );
  }

  Widget _buildCategoryContainer(BuildContext context, {required String title, required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      color: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme, TextTheme textTheme, SettingsProvider settings) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.query_stats_rounded, size: 80, color: colorScheme.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            settings.translate('history_no_history'),
            style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            settings.translate('history_prompt'),
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem(
    BuildContext context, 
    String title, 
    String value, 
    IconData icon, 
    Color color,
    {bool isHighlighted = false}
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    final bgColor = isHighlighted 
        ? color.withValues(alpha: 0.15) 
        : colorScheme.surfaceContainer; 
    final iconColor = color;
    final textColor = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted 
          ? Border.all(color: color.withValues(alpha: 0.5), width: 1)
          : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: textColor,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartContent(Map<String, int> classCounts, int total, ColorScheme colorScheme, TextTheme textTheme) {
    if (classCounts.isEmpty) return const SizedBox();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: classCounts.entries.map((entry) {
                final color = _getClassColor(entry.key);
                final percentage = (entry.value / total) * 100;
                
                return PieChartSectionData(
                  color: color,
                  value: entry.value.toDouble(),
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: textTheme.labelSmall?.copyWith(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold
                  ),
                  showTitle: percentage > 5, 
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: classCounts.keys.map((label) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: _getClassColor(label), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label, 
                      style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBarChartContent(Map<String, double> avgConfidence, ColorScheme colorScheme, TextTheme textTheme) {
    if (avgConfidence.isEmpty) return const SizedBox();

    return Container(
      height: 200, 
      padding: const EdgeInsets.only(right: 16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value.toInt().toString(),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final keys = avgConfidence.keys.toList();
                  if (value.toInt() >= keys.length) return const Text('');
                  final name = keys[value.toInt()];
                  final shortName = name.length > 3 ? name.substring(0, 3) : name;
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        shortName, 
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold, 
                          color: colorScheme.onSurfaceVariant
                        )
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: avgConfidence.entries.toList().asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: _getClassColor(entry.value.key),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLineChartContent(Map<int, int> trendData, ColorScheme colorScheme, TextTheme textTheme, SettingsProvider settings) {
    double maxY = 5;
    if (trendData.isNotEmpty) {
      final maxVal = trendData.values.reduce(max);
      if (maxVal > 0) maxY = (maxVal + (maxVal * 0.2)).toDouble();
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.only(right: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 10 ? (maxY / 5).roundToDouble() : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: maxY > 10 ? (maxY / 5).roundToDouble() : 1,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox(); 
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value.toInt().toString(),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value == 6) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          settings.translate('today'), 
                          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)
                        ),
                      ),
                    );
                  }
                  if (value == 0 || value == 3) {
                     final daysAgo = 6 - value.toInt();
                     return Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: FittedBox(
                         fit: BoxFit.scaleDown,
                         child: Text("-${daysAgo}d", style: textTheme.labelSmall)
                       ),
                     );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: trendData.entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              color: colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.3),
                    colorScheme.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getClassColor(String label) {
    final cleanLabel = label.toUpperCase().trim();
    switch (cleanLabel) {
      case 'HEALTHY': return Colors.green;
      case 'BLACKPOD': return Colors.orange.shade800;
      case 'MIRID': return Colors.purple;
      case 'PODBORER': return Colors.brown;
      default: return Colors.grey;
    }
  }
}