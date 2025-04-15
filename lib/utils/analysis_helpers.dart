// file: lib/utils/analysis_helpers.dart
// path: lib/utils/analysis_helpers.dart
// approximate line: 1 (New file)

import 'dart:math'; // For min/max/pow
import 'package:collection/collection.dart'; // For median, grouping, etc.
import 'package:fl_chart/fl_chart.dart'; // For FlSpot
import 'package:intl/intl.dart'; // For number formatting

// --- Data Classes for Stats ---

/// Stores stats for a numeric column.
class NumericStats {
  final int count;
  final double? average;
  final double? median;
  final double? minVal;
  final double? maxVal;
  final String key; // Store the key for formatting purposes

  NumericStats({
    required this.count,
    this.average,
    this.median,
    this.minVal,
    this.maxVal,
    required this.key,
  });

  /// Factory to create an empty/NA state.
  factory NumericStats.empty(String key) {
    return NumericStats(count: 0, key: key);
  }

  /// Helper to format values based on the key.
  String format(double? value) {
    if (value == null) return 'N/A';
    final keyLower = key.toLowerCase();
    if (keyLower.contains('price')) return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(value);
    if (keyLower.contains('sqft') || keyLower == 'dom' || keyLower.contains('year')) return NumberFormat.decimalPattern().format(value);
    return value.toStringAsFixed(2); // Default
  }

  // Convenience getters for formatted stats
  String get formattedCount => NumberFormat.decimalPattern().format(count);
  String get formattedAverage => format(average);
  String get formattedMedian => format(median);
  String get formattedMin => format(minVal);
  String get formattedMax => format(maxVal);
}

/// Stores stats for Price/Sqft.
class PricePerSqftStats {
  final int count;
  final double? average;
  final double? median;
  final double? minVal;
  final double? maxVal;

  PricePerSqftStats({
    required this.count,
    this.average,
    this.median,
    this.minVal,
    this.maxVal,
  });

    /// Factory to create an empty/NA state.
  factory PricePerSqftStats.empty() {
    return PricePerSqftStats(count: 0);
  }

  /// Formats price per square foot values.
  String format(double? value) {
    if (value == null) return 'N/A';
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value); // Price/sqft often has decimals
  }

  String get formattedCount => NumberFormat.decimalPattern().format(count);
  String get formattedAverage => format(average);
  String get formattedMedian => format(median);
  String get formattedMin => format(minVal);
  String get formattedMax => format(maxVal);
}

// --- Parsing Helper Functions ---

/// Safely parses a dynamic value into a double, removing common currency symbols and commas.
double? parseDouble(dynamic value) {
  if (value == null) return null;
  final cleanedString = value.toString()
      .replaceAll(RegExp(r'[$,]'), '')
      .trim();
  if (cleanedString.isEmpty) return null;
  return double.tryParse(cleanedString);
}

/// Safely parses a dynamic value into an integer.
int? parseInt(dynamic value) {
  if (value == null) return null;
  final cleanedString = value.toString().trim();
   if (cleanedString.isEmpty) return null;
  return int.tryParse(cleanedString);
}

// --- Statistics Calculation Functions ---

/// Calculates basic numeric statistics (count, avg, median, min, max) for a given key in the data.
NumericStats calculateNumericStats(List<Map<String, dynamic>> data, String key) {
  final values = data
      .map((row) => parseDouble(row[key])) // Use public helper
      .whereNotNull() // Filter out nulls
      .toList();

  if (values.isEmpty) {
    return NumericStats.empty(key);
  }

  values.sort();
  final double sum = values.sum;
  final double average = sum / values.length;
  final double median = (values.length % 2 == 1)
      ? values[values.length ~/ 2]
      : (values[values.length ~/ 2 - 1] + values[values.length ~/ 2]) / 2.0;
  final double minVal = values.first;
  final double maxVal = values.last;

  return NumericStats(
    key: key,
    count: values.length,
    average: average,
    median: median,
    minVal: minVal,
    maxVal: maxVal,
  );
}

/// Calculates price per square foot statistics.
PricePerSqftStats calculatePricePerSqftStats(List<Map<String, dynamic>> data, String priceKey, String sqftKey) {
   final priceSqftValues = <double>[];
   int validPairCount = 0;
   for (final row in data) {
      final price = parseDouble(row[priceKey]); // Use public helper
      final sqft = parseDouble(row[sqftKey]);   // Use public helper
      if (price != null && sqft != null && sqft > 0) { // Ensure sqft is positive
         priceSqftValues.add(price / sqft);
         validPairCount++;
      }
   }
   if (priceSqftValues.isEmpty) {
    return PricePerSqftStats.empty();
   }
  priceSqftValues.sort();
  final double sum = priceSqftValues.sum;
  final double average = sum / priceSqftValues.length;
  final double median = (priceSqftValues.length % 2 == 1)
      ? priceSqftValues[priceSqftValues.length ~/ 2]
      : (priceSqftValues[priceSqftValues.length ~/ 2 - 1] + priceSqftValues[priceSqftValues.length ~/ 2]) / 2.0;
  final double minVal = priceSqftValues.first;
  final double maxVal = priceSqftValues.last;

  return PricePerSqftStats(
    count: validPairCount, // Count of valid pairs used
    average: average,
    median: median,
    minVal: minVal,
    maxVal: maxVal,
  );
}

/// Calculates the frequency distribution for values in a specific column.
Map<String, int> calculateDistribution(List<Map<String, dynamic>> data, String key) {
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

// --- Chart Data Preparation Functions ---

/// Prepares data for an "Average Value by Category" bar chart.
Map<String, double> prepareAverageByCategoryData(
    List<Map<String, dynamic>> data,
    String categoryKey,
    String numericKey) {
  final groupedData = groupBy(data, (Map row) => row[categoryKey]?.toString().trim() ?? '');

  final averageData = <String, double>{};
  groupedData.forEach((category, rows) {
    if (category.isEmpty) return; // Skip blank categories

    final numericValues = rows
        .map((row) => parseDouble(row[numericKey])) // Use public helper
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

/// Prepares data points (FlSpot) for a scatter plot.
List<FlSpot> prepareScatterData(
    List<Map<String, dynamic>> data,
    String xKey,
    String yKey) {
  final spots = <FlSpot>[];
  for (final row in data) {
    final xVal = parseDouble(row[xKey]); // Use public helper
    final yVal = parseDouble(row[yKey]); // Use public helper
    if (xVal != null && yVal != null) {
      spots.add(FlSpot(xVal, yVal));
    }
  }
  return spots;
}