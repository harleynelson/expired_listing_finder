
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:math'; // For min/max/pow
import 'package:collection/collection.dart'; // For median, grouping, etc.
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart

// --- Helper Functions for Analysis (parseDouble, parseInt, calculateNumericStats, etc. - Unchanged) ---
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  // Remove common currency symbols, commas, and whitespace
  final cleanedString = value.toString()
      .replaceAll(RegExp(r'[$,]'), '')
      .trim();
  if (cleanedString.isEmpty) return null;
  return double.tryParse(cleanedString);
}
int? _parseInt(dynamic value) {
  if (value == null) return null;
  final cleanedString = value.toString().trim();
   if (cleanedString.isEmpty) return null;
  return int.tryParse(cleanedString);
}
Map<String, String> _calculateNumericStats(List<Map<String, dynamic>> data, String key) {
  final values = data
      .map((row) => _parseDouble(row[key])) // Use helper to parse
      .whereNotNull() // Filter out nulls (failed parses or missing data)
      .toList();

  if (values.isEmpty) {
    return { 'Count': '0', 'Average': 'N/A', 'Median': 'N/A', 'Min': 'N/A', 'Max': 'N/A', };
  }

  values.sort();
  final double sum = values.sum;
  final double average = sum / values.length;
  final double median = (values.length % 2 == 1)
      ? values[values.length ~/ 2]
      : (values[values.length ~/ 2 - 1] + values[values.length ~/ 2]) / 2.0;
  final double minVal = values.first;
  final double maxVal = values.last;

  // Formatting (adjust precision as needed)
  String formatValue(double v) {
     // Basic formatting, consider intl package for better currency/number formatting
     if (key.toLowerCase().contains('price')) { return '\$${v.toStringAsFixed(0)}'; } // No decimals for price
     else if (key.toLowerCase().contains('sqft')) { return v.toStringAsFixed(0); } // No decimals for sqft
     else if (key.toLowerCase() == 'dom') { return v.toStringAsFixed(0); } // DOM as integer
     else if (key.toLowerCase().contains('year')) { return v.toStringAsFixed(0); } // Year as integer
     return v.toStringAsFixed(2); // Default to 2 decimals
  }

  return {
    'Count': values.length.toString(),
    'Average': formatValue(average),
    'Median': formatValue(median),
    'Min': formatValue(minVal),
    'Max': formatValue(maxVal),
  };
}
Map<String, String> _calculatePricePerSqftStats(List<Map<String, dynamic>> data, String priceKey, String sqftKey) {
   final priceSqftValues = <double>[];
   int validPairCount = 0;
   for (final row in data) {
      final price = _parseDouble(row[priceKey]);
      final sqft = _parseDouble(row[sqftKey]);
      if (price != null && sqft != null && sqft > 0) { // Ensure sqft is positive
         priceSqftValues.add(price / sqft);
         validPairCount++;
      }
   }
   if (priceSqftValues.isEmpty) {
    return { 'Count': '0', 'Average': 'N/A', 'Median': 'N/A', 'Min': 'N/A', 'Max': 'N/A', };
   }
  priceSqftValues.sort();
  final double sum = priceSqftValues.sum;
  final double average = sum / priceSqftValues.length;
  final double median = (priceSqftValues.length % 2 == 1)
      ? priceSqftValues[priceSqftValues.length ~/ 2]
      : (priceSqftValues[priceSqftValues.length ~/ 2 - 1] + priceSqftValues[priceSqftValues.length ~/ 2]) / 2.0;
  final double minVal = priceSqftValues.first;
  final double maxVal = priceSqftValues.last;
   String formatValue(double v) => '\$${v.toStringAsFixed(2)}'; // Price per sqft usually has decimals
  return {
    'Count': validPairCount.toString(), // Count of valid pairs used
    'Average': formatValue(average),
    'Median': formatValue(median),
    'Min': formatValue(minVal),
    'Max': formatValue(maxVal),
  };
}
Map<String, int> _calculateDistribution(List<Map<String, dynamic>> data, String key) {
  final counts = <String, int>{};
  int nullOrEmptyCount = 0;
  for (final row in data) {
    final value = row[key]?.toString().trim();
    if (value == null || value.isEmpty) {
       nullOrEmptyCount++;
       continue;
    }
    counts[value] = (counts[value] ?? 0) + 1;
  }
  // Sort by count descending
  final sortedEntries = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final sortedCounts = Map.fromEntries(sortedEntries);
  if(nullOrEmptyCount > 0) {
      sortedCounts['(Blank/Invalid)'] = nullOrEmptyCount;
  }
  return sortedCounts;
}

// --- Helper Functions for Chart Data Preparation ---

// Prepares data for a bar chart showing average numeric value per category.
Map<String, double> _prepareAverageByCategoryData(
    List<Map<String, dynamic>> data,
    String categoryKey,
    String numericKey) {
  final groupedData = groupBy(data, (Map row) => row[categoryKey]?.toString().trim() ?? '');

  final averageData = <String, double>{};
  groupedData.forEach((category, rows) {
    if (category.isEmpty) return; // Skip blank categories

    final numericValues = rows
        .map((row) => _parseDouble(row[numericKey]))
        .whereNotNull()
        .toList();

    if (numericValues.isNotEmpty) {
      averageData[category] = numericValues.average;
    }
  });

  // Sort by category name for consistent display
  final sortedEntries = averageData.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return Map.fromEntries(sortedEntries);
}

// Prepares data for a scatter plot. Returns list of (x, y) pairs.
List<FlSpot> _prepareScatterData(
    List<Map<String, dynamic>> data,
    String xKey,
    String yKey) {
  final spots = <FlSpot>[];
  for (final row in data) {
    final xVal = _parseDouble(row[xKey]);
    final yVal = _parseDouble(row[yKey]);
    if (xVal != null && yVal != null) {
      spots.add(FlSpot(xVal, yVal));
    }
  }
  return spots;
}


// --- Analysis Screen Widget ---
class AnalysisScreen extends StatefulWidget {
  final List<Map<String, dynamic>> yesData;
  final List<Map<String, dynamic>> maybeData;
  final List<String> headers;

  const AnalysisScreen({
    super.key,
    required this.yesData,
    required this.maybeData,
    required this.headers,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sorting state (unchanged)
  int _yesSortColumnIndex = 0;
  bool _yesSortAscending = true;
  late List<Map<String, dynamic>> _sortedYesData;
  int _maybeSortColumnIndex = 0;
  bool _maybeSortAscending = true;
  late List<Map<String, dynamic>> _sortedMaybeData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _sortedYesData = List.from(widget.yesData);
    _sortedMaybeData = List.from(widget.maybeData);
    _yesSortColumnIndex = widget.headers.indexOf('Potential');
    _maybeSortColumnIndex = widget.headers.indexOf('Potential');
    if (_yesSortColumnIndex < 0) _yesSortColumnIndex = 0; // Default if not found
    if (_maybeSortColumnIndex < 0) _maybeSortColumnIndex = 0; // Default if not found
    _sortData(_sortedYesData, _yesSortColumnIndex, _yesSortAscending);
    _sortData(_sortedMaybeData, _maybeSortColumnIndex, _maybeSortAscending);
     if (kDebugMode) { /* ... logging ... */ }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Sorting Logic (unchanged)
  void _sortData(List<Map<String, dynamic>> dataToSort, int columnIndex, bool ascending) {
    if (columnIndex < 0 || columnIndex >= widget.headers.length) return;
    final String sortKey = widget.headers[columnIndex];
    dataToSort.sort((a, b) {
      final aValue = a[sortKey]; final bValue = b[sortKey];
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return ascending ? -1 : 1;
      if (bValue == null) return ascending ? 1 : -1;
      final aNum = _parseDouble(aValue); final bNum = _parseDouble(bValue);
      int compareResult;
      if (aNum != null && bNum != null) { compareResult = aNum.compareTo(bNum); }
      else { compareResult = aValue.toString().toLowerCase().compareTo(bValue.toString().toLowerCase()); }
      return ascending ? compareResult : -compareResult;
    });
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        bottom: TabBar( controller: _tabController, tabs: [
            Tab(text: 'Yes (${widget.yesData.length})'),
            Tab(text: 'Maybes (${widget.maybeData.length})'),
          ],
        ),
      ),
      body: TabBarView( controller: _tabController, children: [
          // YES Tab
          _buildAnalysisTab( context: context, data: _sortedYesData, title: "Yes Potential Properties", sortColumnIndex: _yesSortColumnIndex, sortAscending: _yesSortAscending,
              onSort: (ci, asc) => setState(() { _yesSortColumnIndex = ci; _yesSortAscending = asc; _sortData(_sortedYesData, ci, asc); }) ),
          // MAYBE Tab
          _buildAnalysisTab( context: context, data: _sortedMaybeData, title: "Maybe Potential Properties", sortColumnIndex: _maybeSortColumnIndex, sortAscending: _maybeSortAscending,
              onSort: (ci, asc) => setState(() { _maybeSortColumnIndex = ci; _maybeSortAscending = asc; _sortData(_sortedMaybeData, ci, asc); }) ),
        ],
      ),
    );
  }

  // Helper widget to build the content for each tab
  Widget _buildAnalysisTab({
      required BuildContext context,
      required List<Map<String, dynamic>> data,
      required String title,
      required int sortColumnIndex,
      required bool sortAscending,
      required Function(int, bool) onSort,
    }) {
    if (data.isEmpty) {
      return Center(child: Text('No data available for "$title".'));
    }

    // --- Check for required headers ---
    final bool hasPrice = widget.headers.contains('Price');
    final bool hasSqft = widget.headers.contains('Total Finished Sqft');
    final bool hasDOM = widget.headers.contains('DOM');
    final bool hasBeds = widget.headers.contains('Bedrooms');
    final bool hasBaths = widget.headers.contains('Baths Total');
    final bool hasYear = widget.headers.contains('Year Built');
    final bool hasCity = widget.headers.contains('City');
    final bool hasStyle = widget.headers.contains('Style');

    // --- Calculate Analysis Metrics (unchanged) ---
    final priceStats = hasPrice ? _calculateNumericStats(data, 'Price') : null;
    final sqftStats = hasSqft ? _calculateNumericStats(data, 'Total Finished Sqft') : null;
    final domStats = hasDOM ? _calculateNumericStats(data, 'DOM') : null;
    final pricePerSqftStats = (hasPrice && hasSqft) ? _calculatePricePerSqftStats(data, 'Price', 'Total Finished Sqft') : null;
    final bedDistribution = hasBeds ? _calculateDistribution(data, 'Bedrooms') : null;
    final bathDistribution = hasBaths ? _calculateDistribution(data, 'Baths Total') : null;
    final yearStats = hasYear ? _calculateNumericStats(data, 'Year Built') : null;
    final cityDistribution = hasCity ? _calculateDistribution(data, 'City') : null;
    final styleDistribution = hasStyle ? _calculateDistribution(data, 'Style') : null;

    // --- Prepare Chart Data ---
    final Map<String, double> avgPriceByCityData = (hasPrice && hasCity)
        ? _prepareAverageByCategoryData(data, 'City', 'Price')
        : {};
    final List<FlSpot> priceVsSqftData = (hasPrice && hasSqft)
        ? _prepareScatterData(data, 'Total Finished Sqft', 'Price')
        : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text('Total Properties: ${data.length}'),
          const Divider(height: 30),

          // --- Aggregate Analysis Section (unchanged) ---
          Text('Aggregate Analysis:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 15),
          Wrap( spacing: 16.0, runSpacing: 16.0, children: [
              if (priceStats != null) _buildStatsCard(context, 'Price Analysis', priceStats),
              if (sqftStats != null) _buildStatsCard(context, 'Size Analysis (Sqft)', sqftStats, valueSuffix: ' sqft'),
              if (domStats != null) _buildStatsCard(context, 'Days on Market (DOM)', domStats, valueSuffix: ' days'),
              if (pricePerSqftStats != null) _buildStatsCard(context, 'Price per Sqft', pricePerSqftStats),
              if (yearStats != null) _buildStatsCard(context, 'Year Built', yearStats, skipFormatting: true),
              if (bedDistribution != null) _buildDistributionCard(context, 'Bedroom Distribution', bedDistribution),
              if (bathDistribution != null) _buildDistributionCard(context, 'Bathroom Distribution', bathDistribution),
              if (cityDistribution != null) _buildDistributionCard(context, 'City Distribution', cityDistribution),
              if (styleDistribution != null) _buildDistributionCard(context, 'Style Distribution', styleDistribution),
            ],
          ),
          const SizedBox(height: 10),

          // --- Charts Section ---
          const Divider(height: 30),
          Text('Charts:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 15),
          // Conditionally display charts
          if (avgPriceByCityData.isNotEmpty)
            _buildAvgPriceByCityChart(context, avgPriceByCityData)
          else if (hasPrice && hasCity)
             const Text('Insufficient data for Average Price by City chart.', style: TextStyle(fontStyle: FontStyle.italic)),

          const SizedBox(height: 20), // Space between charts

          if (priceVsSqftData.isNotEmpty)
             _buildPriceVsSqftChart(context, priceVsSqftData)
          else if (hasPrice && hasSqft)
             const Text('Insufficient data for Price vs. SqFt chart.', style: TextStyle(fontStyle: FontStyle.italic)),

          // TODO: Add dynamic chart generation UI here later

          const Divider(height: 30),

          // --- Data Table Section ---
          Text('Data Preview:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _buildDataTable( context: context, data: data, sortColumnIndex: sortColumnIndex, sortAscending: sortAscending, onSort: onSort, ),
        ],
      ),
    );
  }

  // --- Helper Widgets for Displaying Analysis (unchanged) ---
  Widget _buildStatsCard(BuildContext context, String title, Map<String, String> stats, {String valueSuffix = '', bool skipFormatting = false}) {
    final textTheme = Theme.of(context).textTheme;
    final List<Widget> statWidgets = [];
    stats.forEach((key, value) {
      final displayValue = (skipFormatting && (key == 'Average' || key == 'Median'))
                           ? double.tryParse(value)?.toStringAsFixed(0) ?? value
                           : value;
      statWidgets.add( Padding( padding: const EdgeInsets.symmetric(vertical: 2.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$key:', style: textTheme.bodyMedium),
              Text( '$displayValue${(key != 'Count' && value != 'N/A' && !skipFormatting) ? valueSuffix : ''}', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), ),
            ], ), ) );
      if (key != stats.keys.last) { statWidgets.add(Divider(height: 1, thickness: 0.5, color: Colors.grey.shade300)); }
    });
    return Card( elevation: 2.0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), child: Container( width: 250, padding: const EdgeInsets.all(12.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)), const Divider(height: 10, thickness: 1), ...statWidgets, ], ), ), );
  }
  Widget _buildDistributionCard(BuildContext context, String title, Map<String, int> distribution) {
     final textTheme = Theme.of(context).textTheme;
     const int maxItemsToShow = 5;
     final itemsToShow = distribution.entries.take(maxItemsToShow).toList();
     final bool hasMore = distribution.length > maxItemsToShow;
     final List<Widget> distWidgets = itemsToShow.map((entry) => Padding( padding: const EdgeInsets.symmetric(vertical: 2.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(child: Text('${entry.key}:', style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
            Text(entry.value.toString(), style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)), ], ), )).toList();
     if (hasMore) { distWidgets.add(Padding( padding: const EdgeInsets.only(top: 4.0), child: Text('... and ${distribution.length - maxItemsToShow} more', style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)), )); }
     return Card( elevation: 2.0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), child: Container( width: 250, padding: const EdgeInsets.all(12.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)), const Divider(height: 10, thickness: 1), if (distWidgets.isEmpty) const Text('No data available.', style: TextStyle(fontStyle: FontStyle.italic)) else ...distWidgets, ], ), ), );
  }

  // --- Helper Widgets for Building Charts ---

  // Builds the Average Price by City Bar Chart
  Widget _buildAvgPriceByCityChart(BuildContext context, Map<String, double> avgPriceData) {
    final List<BarChartGroupData> barGroups = [];
    double maxY = 0;
    final List<String> cities = avgPriceData.keys.toList();

    // Determine max Y value for scaling
    avgPriceData.forEach((city, avgPrice) {
      if (avgPrice > maxY) {
        maxY = avgPrice;
      }
    });
    // Add some padding to max Y
    maxY = (maxY * 1.1).ceilToDouble(); // Ensure it's slightly above max value

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
              color: Colors.blueAccent.shade100, // Lighter color
              width: 16, // Adjust bar width
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)), // Rounded top
            ),
          ],
        ),
      );
    }

    // Function to format Y-axis labels (Price)
    String formatPrice(double value) {
      if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
      return value.toStringAsFixed(0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Average Price by City", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 300, // Define chart height
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                show: true,
                // Bottom Titles (Cities)
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35, // Space for labels
                    getTitlesWidget: (double value, TitleMeta meta) { // Correct signature
                      final index = value.toInt();
                      if (index >= 0 && index < cities.length) {
                        // **FIXED**: Removed 'axisSide' parameter
                        return SideTitleWidget(
                          meta: meta, // Pass the meta data
                          space: 4,
                          child: Text(cities[index], style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
                // Left Titles (Price)
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50, // Space for labels
                    getTitlesWidget: (double value, TitleMeta meta) { // Correct signature
                       if (value <= meta.min || value >= meta.max) return Container();
                       // **FIXED**: Removed 'axisSide' parameter
                       return SideTitleWidget(
                         meta: meta, // Pass the meta data
                         space: 4,
                         child: Text(formatPrice(value), style: const TextStyle(fontSize: 10))
                       );
                    },
                  ),
                ),
                // Hide top and right titles
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false), // Hide border
              gridData: FlGridData( // Add horizontal grid lines
                 show: true,
                 drawVerticalLine: false,
                 getDrawingHorizontalLine: (value) => FlLine( color: Colors.grey.shade300, strokeWidth: 0.5, ),
              ),
              barTouchData: BarTouchData( // Add tooltips
                 touchTooltipData: BarTouchTooltipData(
                    // Use getTooltipColor
                    getTooltipColor: (BarChartGroupData group) => Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                       final cityName = cities[group.x.toInt()];
                       final avgPrice = rod.toY;
                       return BarTooltipItem(
                          '$cityName\n',
                          const TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, ),
                          children: <TextSpan>[
                             TextSpan(
                                text: formatPrice(avgPrice),
                                style: TextStyle( color: Colors.yellow.shade300, fontSize: 12, fontWeight: FontWeight.w500, ),
                             ),
                          ],
                       );
                    },
                 ),
                 touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                    // Optional: Handle touch events for interaction
                 },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Builds the Price vs SqFt Scatter Plot
  Widget _buildPriceVsSqftChart(BuildContext context, List<FlSpot> spots) {
     // Find min/max for axis scaling (optional, FLChart can auto-scale)
     double minX = double.infinity, maxX = double.negativeInfinity;
     double minY = double.infinity, maxY = double.negativeInfinity;
     for (final spot in spots) {
        if (spot.x < minX) minX = spot.x;
        if (spot.x > maxX) maxX = spot.x;
        if (spot.y < minY) minY = spot.y;
        if (spot.y > maxY) maxY = spot.y;
     }
     // Add padding if needed, ensure non-negative
     minX = max(0, minX * 0.9); maxX = (maxX * 1.1).ceilToDouble();
     minY = max(0, minY * 0.9); maxY = (maxY * 1.1).ceilToDouble();

     // Calculate reasonable intervals (aim for ~5 labels)
     final double xInterval = (maxX - minX) <= 0 ? 1000 : (maxX - minX) / 4;
     final double yInterval = (maxY - minY) <= 0 ? 100000 : (maxY - minY) / 4;


     // Format axes
     String formatSqft(double value) => '${(value / 1000).toStringAsFixed(1)}k';
     String formatPrice(double value) {
        if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
        if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
        return value.toStringAsFixed(0);
     }

     return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Price vs. Square Footage", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 350, // Define chart height
            child: ScatterChart(
              ScatterChartData(
                minX: minX, maxX: maxX, minY: minY, maxY: maxY, // Use calculated bounds
                scatterSpots: spots.map((spot) => ScatterSpot(
                    spot.x, spot.y,
                    // Use dotPainter (compatible with >= 0.66.0)
                    dotPainter: FlDotCirclePainter(radius: 3, color: Colors.teal.withOpacity(0.6))
                )).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  // Bottom Titles (SqFt)
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("SqFt"),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: xInterval, // Use calculated interval
                      getTitlesWidget: (double value, TitleMeta meta) { // Correct signature
                         if (value <= meta.min || value >= meta.max) return Container();
                         // **FIXED**: Removed 'axisSide' parameter
                         return SideTitleWidget(
                           meta: meta, // Pass the meta data
                           space: 4,
                           child: Text(formatSqft(value), style: const TextStyle(fontSize: 10))
                         );
                      },
                    ),
                  ),
                  // Left Titles (Price)
                  leftTitles: AxisTitles(
                     axisNameWidget: const Text("Price"),
                     sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: yInterval, // Use calculated interval
                        getTitlesWidget: (double value, TitleMeta meta) { // Correct signature
                           if (value <= meta.min || value >= meta.max) return Container();
                           // **FIXED**: Removed 'axisSide' parameter
                           return SideTitleWidget(
                             meta: meta, // Pass the meta data
                             space: 4,
                             child: Text(formatPrice(value), style: const TextStyle(fontSize: 10))
                           );
                        },
                     ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade400)),
                gridData: FlGridData(
                   show: true,
                   drawHorizontalLine: true,
                   drawVerticalLine: true,
                   horizontalInterval: yInterval, // Match axis interval
                   verticalInterval: xInterval, // Match axis interval
                   getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
                   getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
                ),
                scatterTouchData: ScatterTouchData( // Tooltips
                   enabled: true,
                   handleBuiltInTouches: true,
                   // Use touchCallback to handle touch events
                   touchCallback: (FlTouchEvent event, ScatterTouchResponse? touchResponse) {
                      // Optional: Handle touch events
                   },
                ),
              ),
            ),
          ),
        ],
     );
  }


  // Helper to build DataTable (unchanged)
  Widget _buildDataTable({ required BuildContext context, required List<Map<String, dynamic>> data, required int sortColumnIndex, required bool sortAscending, required Function(int, bool) onSort, }) {
     final columns = widget.headers.asMap().entries.map((entry) {
        final int index = entry.key; final String header = entry.value;
        return DataColumn( label: Text(header, style: const TextStyle(fontWeight: FontWeight.bold)), onSort: (columnIndex, ascending) => onSort(columnIndex, ascending), tooltip: 'Sort by $header',
           numeric: ['price', 'dom', 'sqft', 'year', 'baths', 'beds', 'stories', '#'].any((hint) => header.toLowerCase().contains(hint)), ); }).toList();
     final rows = data.map((rowMap) {
        return DataRow( cells: widget.headers.map((header) { final value = rowMap[header];
              return DataCell( Tooltip( message: value?.toString() ?? '', child: Text( value?.toString() ?? '', overflow: TextOverflow.ellipsis, ), ) ); }).toList(), ); }).toList();
     return SingleChildScrollView( scrollDirection: Axis.horizontal, child: DataTable( columns: columns, rows: rows, sortColumnIndex: sortColumnIndex, sortAscending: sortAscending, columnSpacing: 20.0, headingRowHeight: 45.0, dataRowMinHeight: 35.0, dataRowMaxHeight: 45.0, headingTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), border: TableBorder.all( color: Colors.grey.shade300, width: 1, style: BorderStyle.solid, borderRadius: BorderRadius.circular(4), ), ), );
  }
} // End of _AnalysisScreenState
