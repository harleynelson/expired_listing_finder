// file: lib/widgets/analysis/analysis_data_table.dart
// path: lib/widgets/analysis/analysis_data_table.dart
// approximate line: 1 (New file)

import 'package:flutter/material.dart';

/// A widget to display the analysis data in a sortable DataTable.
class AnalysisDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final List<String> headers;
  final int sortColumnIndex;
  final bool sortAscending;
  final Function(int, bool) onSort;

  const AnalysisDataTable({
    super.key,
    required this.data,
    required this.headers,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
     if (data.isEmpty) {
       return const Center(child: Text('No data to display in table.'));
     }

     final columns = headers.asMap().entries.map((entry) {
        final int index = entry.key; final String header = entry.value;
        return DataColumn(
           label: Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
           onSort: (columnIndex, ascending) => onSort(columnIndex, ascending),
           tooltip: 'Sort by $header',
           numeric: ['price', 'dom', 'sqft', 'year', 'baths', 'beds', 'stories', '#']
               .any((hint) => header.toLowerCase().contains(hint)),
        );
     }).toList();

     final rows = data.map((rowMap) {
        return DataRow(
           cells: headers.map((header) {
              final value = rowMap[header];
              return DataCell(
                 Tooltip(
                    message: value?.toString() ?? '',
                    child: Text(
                       value?.toString() ?? '',
                       overflow: TextOverflow.ellipsis,
                    ),
                 )
              );
           }).toList(),
        );
     }).toList();

     return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
           columns: columns,
           rows: rows,
           sortColumnIndex: sortColumnIndex,
           sortAscending: sortAscending,
           columnSpacing: 20.0,
           headingRowHeight: 45.0,
           dataRowMinHeight: 35.0,
           dataRowMaxHeight: 45.0,
           headingTextStyle: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
           border: TableBorder.all(
              color: Colors.grey.shade300,
              width: 1,
              style: BorderStyle.solid,
              borderRadius: BorderRadius.circular(4),
           ),
        ),
     );
  }
}