// file: lib/screens/analysis_screen.dart
// path: lib/screens/analysis_screen.dart
// approximate line: 26 (Modified field declarations and initState)

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:math'; // For max in chart scaling
import 'package:collection/collection.dart'; // For sorting data

// Import helpers and data classes
import '../utils/analysis_helpers.dart';
// Import new widgets
import '../widgets/analysis/stat_display_widgets.dart';
import '../widgets/analysis/chart_widgets.dart';
import '../widgets/analysis/analysis_data_table.dart';


// --- Analysis Screen Widget ---
class AnalysisScreen extends StatefulWidget {
  final List<Map<String, dynamic>> yesData;
  final List<Map<String, dynamic>> maybeData;
  final List<Map<String, dynamic>> soldData;
  final List<String> headers;

  const AnalysisScreen({
    super.key,
    required this.yesData,
    required this.maybeData,
    required this.soldData,
    required this.headers,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sorting state
  int _yesSortColumnIndex = 0;
  bool _yesSortAscending = true;
  late List<Map<String, dynamic>> _sortedYesData;

  int _maybeSortColumnIndex = 0;
  bool _maybeSortAscending = true;
  late List<Map<String, dynamic>> _sortedMaybeData;

  // Pre-calculated Sold stats
  NumericStats? _soldPriceStats;
  NumericStats? _soldSqftStats;
  NumericStats? _soldDomStats;
  PricePerSqftStats? _soldPricePerSqftStats;
  NumericStats? _soldYearStats;
  Map<String, int>? _soldBedDistribution;
  Map<String, int>? _soldBathDistribution;
  Map<String, int>? _soldCityDistribution;
  Map<String, int>? _soldStyleDistribution;

  // ** MODIFIED: Removed 'late' and will initialize directly in initState **
  bool _hasPrice = false;
  bool _hasSqft = false;
  bool _hasDOM = false;
  bool _hasBeds = false;
  bool _hasBaths = false;
  bool _hasYear = false;
  bool _hasCity = false;
  bool _hasStyle = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) print("[AnalysisScreen] initState: START");
    _tabController = TabController(length: 2, vsync: this);
    _sortedYesData = List.from(widget.yesData);
    _sortedMaybeData = List.from(widget.maybeData);

    // --- ** MODIFIED: Initialize header check fields directly ** ---
    _hasPrice = widget.headers.contains('Price');
    _hasSqft = widget.headers.contains('Total Finished Sqft');
    _hasDOM = widget.headers.contains('DOM');
    _hasBeds = widget.headers.contains('Bedrooms');
    _hasBaths = widget.headers.contains('Baths Total');
    _hasYear = widget.headers.contains('Year Built');
    _hasCity = widget.headers.contains('City');
    _hasStyle = widget.headers.contains('Style');
     if (kDebugMode) print("[AnalysisScreen] initState: Header checks done.");

    // --- Calculate Sold Stats Once using imported functions ---
    // (This part remains the same, uses the now-initialized _has... fields)
    if (widget.soldData.isNotEmpty) {
       if (kDebugMode) print("[AnalysisScreen] initState: Calculating sold stats...");
      _soldPriceStats = _hasPrice ? calculateNumericStats(widget.soldData, 'Price') : null;
      _soldSqftStats = _hasSqft ? calculateNumericStats(widget.soldData, 'Total Finished Sqft') : null;
      _soldDomStats = _hasDOM ? calculateNumericStats(widget.soldData, 'DOM') : null;
      _soldPricePerSqftStats = (_hasPrice && _hasSqft) ? calculatePricePerSqftStats(widget.soldData, 'Price', 'Total Finished Sqft') : null;
      _soldYearStats = _hasYear ? calculateNumericStats(widget.soldData, 'Year Built') : null;
      _soldBedDistribution = _hasBeds ? calculateDistribution(widget.soldData, 'Bedrooms') : null;
      _soldBathDistribution = _hasBaths ? calculateDistribution(widget.soldData, 'Baths Total') : null;
      _soldCityDistribution = _hasCity ? calculateDistribution(widget.soldData, 'City') : null;
      _soldStyleDistribution = _hasStyle ? calculateDistribution(widget.soldData, 'Style') : null;
       if (kDebugMode) print("[AnalysisScreen] initState: Sold stats calculation complete.");
    } else {
       if (kDebugMode) print("[AnalysisScreen] initState: No sold data to calculate stats for.");
    }

    // --- Initial Sort ---
    // (This part remains the same)
    _yesSortColumnIndex = widget.headers.indexOf('Potential');
    _maybeSortColumnIndex = widget.headers.indexOf('Potential');
    if (_yesSortColumnIndex < 0) _yesSortColumnIndex = 0;
    if (_maybeSortColumnIndex < 0) _maybeSortColumnIndex = 0;
    _sortData(_sortedYesData, _yesSortColumnIndex, _yesSortAscending);
    _sortData(_sortedMaybeData, _maybeSortColumnIndex, _maybeSortAscending);
    if (kDebugMode) print("[AnalysisScreen] initState: Initial sort complete.");
    if (kDebugMode) print("[AnalysisScreen] initState: END");
  }

  @override
  void dispose() {
    _tabController.dispose();
     if (kDebugMode) print("[AnalysisScreen] dispose");
    super.dispose();
  }

  // --- Sorting Logic ---
  // (This part remains the same)
  void _sortData(List<Map<String, dynamic>> dataToSort, int columnIndex, bool ascending) {
    if (columnIndex < 0 || columnIndex >= widget.headers.length) return;
    final String sortKey = widget.headers[columnIndex];
     if (kDebugMode) print("[AnalysisScreen] Sorting data by '$sortKey' ${ascending ? 'ASC' : 'DESC'}");

    dataToSort.sort((a, b) {
      final aValue = a[sortKey];
      final bValue = b[sortKey];

      // Handle nulls first
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return ascending ? -1 : 1;
      if (bValue == null) return ascending ? 1 : -1;

      // Try numeric comparison
      final aNum = parseDouble(aValue); // Use imported helper
      final bNum = parseDouble(bValue); // Use imported helper
      int compareResult;

      if (aNum != null && bNum != null) {
        // Both are numbers
        compareResult = aNum.compareTo(bNum);
      } else {
        // At least one is not a number, compare as strings (case-insensitive)
        compareResult = aValue.toString().toLowerCase().compareTo(bValue.toString().toLowerCase());
      }

      // Apply ascending/descending order
      return ascending ? compareResult : -compareResult;
    });
     if (kDebugMode) print("[AnalysisScreen] Sorting complete.");
  }

  // --- Build Method ---
  // (This part remains the same)
  @override
  Widget build(BuildContext context) {
     if (kDebugMode) print("[AnalysisScreen] Build START");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Yes (${widget.yesData.length})'),
            Tab(text: 'Maybes (${widget.maybeData.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // YES Tab
          _buildAnalysisTab(
            context: context,
            data: _sortedYesData,
            title: "Yes Potential Properties",
            sortColumnIndex: _yesSortColumnIndex,
            sortAscending: _yesSortAscending,
            onSort: (ci, asc) => setState(() {
              _yesSortColumnIndex = ci;
              _yesSortAscending = asc;
              _sortData(_sortedYesData, ci, asc);
            })
          ),
          // MAYBE Tab
          _buildAnalysisTab(
            context: context,
            data: _sortedMaybeData,
            title: "Maybe Potential Properties",
            sortColumnIndex: _maybeSortColumnIndex,
            sortAscending: _maybeSortAscending,
            onSort: (ci, asc) => setState(() {
              _maybeSortColumnIndex = ci;
              _maybeSortAscending = asc;
              _sortData(_sortedMaybeData, ci, asc);
            })
           ),
        ],
      ),
    );
  }

  // --- Helper widget to build the content for each tab ---
  // (This part remains the same, uses the now-initialized _has... fields)
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
     if (kDebugMode) print("[AnalysisScreen] _buildAnalysisTab for '$title'");

    // --- Calculate Analysis Metrics for the CURRENT Tab ---
    // Use imported helper functions
    final priceStats = _hasPrice ? calculateNumericStats(data, 'Price') : null;
    final sqftStats = _hasSqft ? calculateNumericStats(data, 'Total Finished Sqft') : null;
    final domStats = _hasDOM ? calculateNumericStats(data, 'DOM') : null;
    final pricePerSqftStats = (_hasPrice && _hasSqft) ? calculatePricePerSqftStats(data, 'Price', 'Total Finished Sqft') : null;
    final yearStats = _hasYear ? calculateNumericStats(data, 'Year Built') : null;
    final bedDistribution = _hasBeds ? calculateDistribution(data, 'Bedrooms') : null;
    final bathDistribution = _hasBaths ? calculateDistribution(data, 'Baths Total') : null;
    final cityDistribution = _hasCity ? calculateDistribution(data, 'City') : null;
    final styleDistribution = _hasStyle ? calculateDistribution(data, 'Style') : null;

    // --- Prepare Chart Data ---
    // Use imported helper functions
    final Map<String, double> avgPriceByCityData = (_hasPrice && _hasCity)
        ? prepareAverageByCategoryData(data, 'City', 'Price')
        : {};
    final List<FlSpot> priceVsSqftData = (_hasPrice && _hasSqft)
        ? prepareScatterData(data, 'Total Finished Sqft', 'Price')
        : [];

    // --- Define Sold Stat Text Style ---
    const soldTextStyle = TextStyle(color: Colors.green, fontWeight: FontWeight.bold);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text('Total Properties: ${data.length}'),
          const Divider(height: 30),

          // --- Aggregate Analysis Section ---
          Text('Aggregate Analysis:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 15),
          Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            children: [
              // Use imported Stat Display Widgets
              if (priceStats != null)
                StatsCard(
                  title: 'Price Analysis',
                  currentStats: priceStats,
                  soldStats: _soldPriceStats,
                  soldTextStyle: soldTextStyle,
                ),
              if (sqftStats != null)
                StatsCard(
                  title: 'Size Analysis (Sqft)',
                  currentStats: sqftStats,
                  soldStats: _soldSqftStats,
                  soldTextStyle: soldTextStyle,
                  valueSuffix: ' sqft',
                ),
              if (domStats != null)
                StatsCard(
                  title: 'Days on Market (DOM)',
                  currentStats: domStats,
                  soldStats: _soldDomStats,
                  soldTextStyle: soldTextStyle,
                  valueSuffix: ' days',
                ),
              if (pricePerSqftStats != null)
                PricePerSqftStatsCard(
                  title: 'Price per Sqft',
                  currentStats: pricePerSqftStats,
                  soldStats: _soldPricePerSqftStats,
                  soldTextStyle: soldTextStyle,
                ),
              if (yearStats != null)
                StatsCard(
                  title: 'Year Built',
                  currentStats: yearStats,
                  soldStats: _soldYearStats,
                  soldTextStyle: soldTextStyle,
                  skipFormatting: true, // Year doesn't need currency/decimal formatting
                ),
              if (bedDistribution != null)
                DistributionCard(
                  title: 'Bedroom Distribution',
                  currentDistribution: bedDistribution,
                  soldDistribution: _soldBedDistribution,
                  soldTextStyle: soldTextStyle,
                ),
              if (bathDistribution != null)
                 DistributionCard(
                  title: 'Bathroom Distribution',
                  currentDistribution: bathDistribution,
                  soldDistribution: _soldBathDistribution,
                  soldTextStyle: soldTextStyle,
                ),
              if (cityDistribution != null)
                 DistributionCard(
                  title: 'City Distribution',
                  currentDistribution: cityDistribution,
                  soldDistribution: _soldCityDistribution,
                  soldTextStyle: soldTextStyle,
                ),
              if (styleDistribution != null)
                 DistributionCard(
                  title: 'Style Distribution',
                  currentDistribution: styleDistribution,
                  soldDistribution: _soldStyleDistribution,
                  soldTextStyle: soldTextStyle,
                ),
            ],
          ),
          const SizedBox(height: 10),

          // --- Charts Section ---
          const Divider(height: 30),
          Text('Charts:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 15),
          // Use imported Chart Widgets
          AveragePriceByCityChart(avgPriceData: avgPriceByCityData),
          const SizedBox(height: 20),
          PriceVsSqftChart(spots: priceVsSqftData),
          const Divider(height: 30),

          // --- Data Table Section ---
          Text('Data Preview:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          // Use imported Data Table Widget
          AnalysisDataTable(
            data: data,
            headers: widget.headers,
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
            onSort: onSort,
          ),
        ],
      ),
    );
  }
} // End of _AnalysisScreenState