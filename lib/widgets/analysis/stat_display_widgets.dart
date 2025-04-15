// file: lib/widgets/analysis/stat_display_widgets.dart
// path: lib/widgets/analysis/stat_display_widgets.dart
// approximate line: 1 (New file)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/analysis_helpers.dart'; // Import helpers for data classes

/// A reusable card widget to display NumericStats.
class StatsCard extends StatelessWidget {
  final String title;
  final NumericStats currentStats;
  final NumericStats? soldStats;
  final TextStyle soldTextStyle;
  final String valueSuffix;
  final bool skipFormatting;

  const StatsCard({
    super.key,
    required this.title,
    required this.currentStats,
    this.soldStats,
    required this.soldTextStyle,
    this.valueSuffix = '',
    this.skipFormatting = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statsOrder = [
      {'label': 'Count', 'current': currentStats.formattedCount, 'sold': soldStats?.formattedCount},
      {'label': 'Average', 'current': currentStats.formattedAverage, 'sold': soldStats?.formattedAverage},
      {'label': 'Median', 'current': currentStats.formattedMedian, 'sold': soldStats?.formattedMedian},
      {'label': 'Min', 'current': currentStats.formattedMin, 'sold': soldStats?.formattedMin},
      {'label': 'Max', 'current': currentStats.formattedMax, 'sold': soldStats?.formattedMax},
    ];

    return _buildBaseCard(
      context: context,
      title: title,
      statWidgets: _buildStatRows(
        statsOrder: statsOrder,
        textTheme: textTheme,
        soldTextStyle: soldTextStyle,
        valueSuffix: valueSuffix,
        skipFormatting: skipFormatting,
      ),
    );
  }
}

/// A reusable card widget to display PricePerSqftStats.
class PricePerSqftStatsCard extends StatelessWidget {
  final String title;
  final PricePerSqftStats currentStats;
  final PricePerSqftStats? soldStats;
  final TextStyle soldTextStyle;

  const PricePerSqftStatsCard({
    super.key,
    required this.title,
    required this.currentStats,
    this.soldStats,
    required this.soldTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statsOrder = [
      {'label': 'Count', 'current': currentStats.formattedCount, 'sold': soldStats?.formattedCount},
      {'label': 'Average', 'current': currentStats.formattedAverage, 'sold': soldStats?.formattedAverage},
      {'label': 'Median', 'current': currentStats.formattedMedian, 'sold': soldStats?.formattedMedian},
      {'label': 'Min', 'current': currentStats.formattedMin, 'sold': soldStats?.formattedMin},
      {'label': 'Max', 'current': currentStats.formattedMax, 'sold': soldStats?.formattedMax},
    ];

    return _buildBaseCard(
      context: context,
      title: title,
      statWidgets: _buildStatRows(
        statsOrder: statsOrder,
        textTheme: textTheme,
        soldTextStyle: soldTextStyle,
        valueSuffix: '', // No suffix for Price/Sqft card itself
        skipFormatting: true, // Formatting is done by the stats class
      ),
    );
  }
}

/// A reusable card widget to display distribution data.
class DistributionCard extends StatelessWidget {
  final String title;
  final Map<String, int> currentDistribution;
  final Map<String, int>? soldDistribution;
  final TextStyle soldTextStyle;

  const DistributionCard({
    super.key,
    required this.title,
    required this.currentDistribution,
    this.soldDistribution,
    required this.soldTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const int maxItemsToShow = 5;
    final currentItemsToShow = currentDistribution.entries.take(maxItemsToShow).toList();
    final bool hasMoreCurrent = currentDistribution.length > maxItemsToShow;
    final List<Widget> distWidgets = [];

    for (final entry in currentItemsToShow) {
      final String key = entry.key;
      final String currentCount = NumberFormat.decimalPattern().format(entry.value);
      final String? soldCount = soldDistribution?[key] != null ? NumberFormat.decimalPattern().format(soldDistribution![key]) : null;

      distWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: Text('$key:', style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Flexible(
                child: Text.rich(
                  _buildCombinedValueSpan(currentCount, soldCount, soldTextStyle),
                  textAlign: TextAlign.right,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (hasMoreCurrent) {
      distWidgets.add(Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          '... and ${currentDistribution.length - maxItemsToShow} more categories.',
          style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ));
    }

    return _buildBaseCard(
      context: context,
      title: title,
      statWidgets: distWidgets.isEmpty
          ? [const Text('No data available.', style: TextStyle(fontStyle: FontStyle.italic))]
          : distWidgets,
    );
  }
}

// --- Helper Widgets (Private) ---

/// Base card structure used by all stat cards.
Widget _buildBaseCard({
  required BuildContext context,
  required String title,
  required List<Widget> statWidgets,
}) {
  final textTheme = Theme.of(context).textTheme;
  return Card(
    elevation: 2.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    child: Container(
      width: 260, // Consistent width
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Divider(height: 10, thickness: 1),
          ...statWidgets,
        ],
      ),
    ),
  );
}

/// Builds the rows for numeric stat cards.
List<Widget> _buildStatRows({
  required List<Map<String, String?>> statsOrder,
  required TextTheme textTheme,
  required TextStyle soldTextStyle,
  required String valueSuffix,
  required bool skipFormatting,
}) {
  final List<Widget> statWidgets = [];
  for (var i = 0; i < statsOrder.length; i++) {
    final statInfo = statsOrder[i];
    final String currentDisplayValue = statInfo['current'] ?? 'N/A';
    final String? soldDisplayValue = statInfo['sold']; // Can be null

    final suffix = (statInfo['label'] != 'Count' && currentDisplayValue != 'N/A' && !skipFormatting) ? valueSuffix : '';
    final soldSuffix = (statInfo['label'] != 'Count' && soldDisplayValue != null && soldDisplayValue != 'N/A' && !skipFormatting) ? valueSuffix : '';

    statWidgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${statInfo['label']}:', style: textTheme.bodyMedium),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                _buildCombinedValueSpan(
                  '$currentDisplayValue$suffix',
                  soldDisplayValue != null ? '$soldDisplayValue$soldSuffix' : null,
                  soldTextStyle
                ),
                textAlign: TextAlign.right,
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      )
    );
    if (i < statsOrder.length - 1) {
      statWidgets.add(Divider(height: 1, thickness: 0.5, color: Colors.grey.shade300));
    }
  }
  return statWidgets;
}

/// Helper to build RichText for combined value (e.g., "$100 (Sold $120)").
InlineSpan _buildCombinedValueSpan(String primaryValue, String? soldValue, TextStyle? soldTextStyle) {
  if (soldValue == null || soldValue == 'N/A') {
    return TextSpan(text: primaryValue);
  }
  return TextSpan(
    children: [
      TextSpan(text: primaryValue),
      const TextSpan(text: ' ('),
      TextSpan(text: soldValue, style: soldTextStyle),
      const TextSpan(text: ')'),
    ],
  );
}