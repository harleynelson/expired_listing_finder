// file: lib/widgets/analysis/chart_widgets.dart
// path: lib/widgets/analysis/chart_widgets.dart
// approximate line: 1 (New file)

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// A widget to display the Average Price by City Bar Chart.
class AveragePriceByCityChart extends StatelessWidget {
  final Map<String, double> avgPriceData;

  const AveragePriceByCityChart({super.key, required this.avgPriceData});

  // Helper to format Y-axis labels (Price)
  String _formatPrice(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    if (avgPriceData.isEmpty) {
       return const Text('Insufficient data for Average Price by City chart.', style: TextStyle(fontStyle: FontStyle.italic));
    }

    final List<BarChartGroupData> barGroups = [];
    double maxY = 0;
    final List<String> cities = avgPriceData.keys.toList();

    // Determine max Y value for scaling
    avgPriceData.forEach((city, avgPrice) {
      if (avgPrice > maxY) {
        maxY = avgPrice;
      }
    });
    maxY = (maxY * 1.1).ceilToDouble(); // Add padding

    // Create bar groups
    for (int i = 0; i < cities.length; i++) {
      final cityName = cities[i];
      final avgPrice = avgPriceData[cityName] ?? 0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: avgPrice,
              color: Colors.blueAccent.shade100,
              width: 16,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Average Price by City", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < cities.length) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(cities[index], style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (double value, TitleMeta meta) {
                       if (value <= meta.min || value >= meta.max) return Container();
                       return SideTitleWidget(
                         meta: meta,
                         space: 4,
                         child: Text(_formatPrice(value), style: const TextStyle(fontSize: 10))
                       );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                 show: true,
                 drawVerticalLine: false,
                 getDrawingHorizontalLine: (value) => FlLine( color: Colors.grey.shade300, strokeWidth: 0.5, ),
              ),
              barTouchData: BarTouchData(
                 touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (BarChartGroupData group) => Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                       final cityName = cities[group.x.toInt()];
                       final avgPrice = rod.toY;
                       return BarTooltipItem(
                          '$cityName\n',
                          const TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, ),
                          children: <TextSpan>[
                             TextSpan(
                                text: _formatPrice(avgPrice),
                                style: TextStyle( color: Colors.yellow.shade300, fontSize: 12, fontWeight: FontWeight.w500, ),
                             ),
                          ],
                       );
                    },
                 ),
                 touchCallback: (FlTouchEvent event, BarTouchResponse? response) {},
              ),
            ),
          ),
        ),
      ],
    );
  }
}


/// A widget to display the Price vs Square Footage Scatter Plot.
class PriceVsSqftChart extends StatelessWidget {
  final List<FlSpot> spots;

  const PriceVsSqftChart({super.key, required this.spots});

  // Helper format functions
  String _formatSqft(double value) => '${(value / 1000).toStringAsFixed(1)}k';
  String _formatPrice(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
     if (spots.isEmpty) {
        return const Text('Insufficient data for Price vs. SqFt chart.', style: TextStyle(fontStyle: FontStyle.italic));
     }

     // Find min/max for axis scaling
     double minX = double.infinity, maxX = double.negativeInfinity;
     double minY = double.infinity, maxY = double.negativeInfinity;
     for (final spot in spots) {
        if (spot.x < minX) minX = spot.x;
        if (spot.x > maxX) maxX = spot.x;
        if (spot.y < minY) minY = spot.y;
        if (spot.y > maxY) maxY = spot.y;
     }
     minX = max(0, minX * 0.9); maxX = (maxX * 1.1).ceilToDouble();
     minY = max(0, minY * 0.9); maxY = (maxY * 1.1).ceilToDouble();
     final double xInterval = (maxX - minX) <= 0 ? 1000 : (maxX - minX) / 4;
     final double yInterval = (maxY - minY) <= 0 ? 100000 : (maxY - minY) / 4;

     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Price vs. Square Footage", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 350,
            child: ScatterChart(
              ScatterChartData(
                minX: minX, maxX: maxX, minY: minY, maxY: maxY,
                scatterSpots: spots.map((spot) => ScatterSpot(
                    spot.x, spot.y,
                    dotPainter: FlDotCirclePainter(radius: 3, color: Colors.teal.withOpacity(0.6))
                )).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("SqFt"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: xInterval,
                      getTitlesWidget: (double value, TitleMeta meta) {
                         if (value <= meta.min || value >= meta.max) return Container();
                         return SideTitleWidget(
                           meta: meta, space: 4,
                           child: Text(_formatSqft(value), style: const TextStyle(fontSize: 10))
                         );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                     axisNameWidget: const Text("Price"),
                     sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: yInterval,
                        getTitlesWidget: (double value, TitleMeta meta) {
                           if (value <= meta.min || value >= meta.max) return Container();
                           return SideTitleWidget(
                             meta: meta, space: 4,
                             child: Text(_formatPrice(value), style: const TextStyle(fontSize: 10))
                           );
                        },
                     ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade400)),
                gridData: FlGridData(
                   show: true, drawHorizontalLine: true, drawVerticalLine: true,
                   horizontalInterval: yInterval, verticalInterval: xInterval,
                   getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
                   getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
                ),
                scatterTouchData: ScatterTouchData( enabled: true, handleBuiltInTouches: true,
                   touchCallback: (FlTouchEvent event, ScatterTouchResponse? touchResponse) {},
                ),
              ),
            ),
          ),
        ],
     );
  }
}