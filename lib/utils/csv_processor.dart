// file: lib/utils/csv_processor.dart
// path: lib/utils/csv_processor.dart
// approximate line: 1
import 'dart:io';       // For File access
import 'dart:convert';   // For utf8 encoding
import 'package:csv/csv.dart'; // For CSV handling
import 'package:flutter/foundation.dart' show kDebugMode; // For kDebugMode

// --- Public function to be called by compute ---
// Renamed from _processFilesIsolate
Future<Map<String, dynamic>> processCsvFilesIsolate(Map<String, List<String>> filePaths) async {
  // (This function runs in an isolate)
  final List<String> cancelledPaths = filePaths['cancelledPaths']!;
  final List<String> activePaths = filePaths['activePaths']!;
  final List<String> soldPaths = filePaths['soldPaths']!;

  if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Processing started...");

  try {
    // 1. Read and Merge Files using helper function below
    if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Reading cancelled files...");
    final allCancelled = _readAndMergeCsvsSync(cancelledPaths);
     if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Reading active files...");
    final allActive = _readAndMergeCsvsSync(activePaths);
     if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Reading sold files...");
    final allSold = _readAndMergeCsvsSync(soldPaths); // Keep the raw sold data

    if (allCancelled.isEmpty) {
       if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): No data in Cancelled/Expired files.");
       return {'success': false, 'error': 'No valid data found in Cancelled/Expired files.'};
    }
     if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): File reading complete.");

    // 2. Build Lookup Structures using helper function below
     if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Building lookup structures...");
    final activeAddresses = <String>{};
    for (final row in allActive) {
      final address = _normalizeAddress(row['Street Address']?.toString() ?? '', row['City']?.toString() ?? '');
      if (address.isNotEmpty) {
        activeAddresses.add(address);
      }
    }

    final soldAddresses = <String>{};
    for (final row in allSold) {
      final address = _normalizeAddress(row['Street Address']?.toString() ?? '', row['City']?.toString() ?? '');
      if (address.isNotEmpty) {
        soldAddresses.add(address);
      }
    }
     if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Lookup structures built.");
     if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Found ${activeAddresses.length} unique active addresses.");
     if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Found ${soldAddresses.length} unique sold addresses.");


    // 3. Filter and Prepare Results based on User Criteria
     if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Filtering and preparing results...");
    final yesResults = <Map<String, dynamic>>[];
    final maybeResults = <Map<String, dynamic>>[];
    final allHeadersSet = <String>{'Potential'}; // Start with 'Potential' column

    // Collect headers using helper function below
    _collectHeaders(allCancelled, allHeadersSet);
    _collectHeaders(allActive, allHeadersSet);
    _collectHeaders(allSold, allHeadersSet);

    // --- Define desired column order ---
    const List<String> desiredHeaderOrder = [
      'Potential', 'ML #', 'St', 'Street Address', 'City', 'Price', 'DOM',
      'Style', 'Stories', 'Bedrooms', 'Baths Total', 'Total Finished Sqft',
      'Year Built'
    ];

    // --- Create the final ordered header list ---
    final List<String> orderedHeaders = [];
    final Set<String> remainingHeaders = Set.from(allHeadersSet); // Copy all collected headers

    // Add desired headers in specified order if they exist
    for (final header in desiredHeaderOrder) {
      if (remainingHeaders.contains(header)) {
        orderedHeaders.add(header);
        remainingHeaders.remove(header); // Remove from remaining set
      } else {
         if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Warning - Desired header '$header' not found in input files.");
      }
    }

    // Add any other remaining headers (sorted alphabetically for consistency)
    final List<String> otherHeaders = remainingHeaders.toList()..sort();
    orderedHeaders.addAll(otherHeaders);

     if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Final ordered headers: $orderedHeaders");


    for (final cancelledRow in allCancelled) {
        final street = cancelledRow['Street Address']?.toString() ?? '';
        final city = cancelledRow['City']?.toString() ?? '';
        final normalizedAddress = _normalizeAddress(street, city); // Use helper

        if (normalizedAddress.isEmpty) {
            if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Skipping cancelled row with empty normalized address: $cancelledRow");
            continue; // Skip if address is invalid
        }

        final bool isActive = activeAddresses.contains(normalizedAddress);
        final bool wasSold = soldAddresses.contains(normalizedAddress); // Check if it exists in the sold list

        // Apply user's logic:
        if (!isActive && !wasSold) {
            // YES: Cancelled/Expired, NOT Active, NOT Sold
            final yesRow = <String, dynamic>{'Potential': 'Yes'}; // Add Potential field
            // Populate with all headers, using data from cancelledRow if available
            for(final header in orderedHeaders) { // Use orderedHeaders
               if (header != 'Potential') { // Skip potential, already added
                 yesRow[header] = cancelledRow[header] ?? ''; // Fill missing headers with empty string
               }
            }
            yesResults.add(yesRow);
        } else if (!isActive && wasSold) {
            // MAYBE: Cancelled/Expired, NOT Active, BUT Sold
            final maybeRow = <String, dynamic>{'Potential': 'Maybe'}; // Add Potential field
            // Populate with all headers, using data from cancelledRow if available
             for(final header in orderedHeaders) { // Use orderedHeaders
                if (header != 'Potential') { // Skip potential, already added
                  maybeRow[header] = cancelledRow[header] ?? ''; // Fill missing headers with empty string
                }
             }
            maybeResults.add(maybeRow);
        } else {
             // Neither YES nor MAYBE (e.g., it's active, or doesn't meet criteria)
             if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Skipping address $normalizedAddress (IsActive: $isActive, WasSold: $wasSold)");
        }
    }
     if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Filtering complete. Yes: ${yesResults.length}, Maybe: ${maybeResults.length}");

    // 4. Return structured data
    if (yesResults.isEmpty && maybeResults.isEmpty) {
       if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): No properties matched criteria.");
       // Return success=true but empty lists, let main isolate handle 'No results' message
       return {
         'success': true,
         'yesData': <Map<String, dynamic>>[],
         'maybeData': <Map<String, dynamic>>[],
         'soldData': allSold, // <<< MODIFIED: Return sold data
         'headers': orderedHeaders, // Still return ordered headers
         'fileNameBase': 'property_analysis_results',
       };
    }

     if (kDebugMode) print("[${DateTime.now()}] ISOLATE (csv_processor): Processing successful. Returning data.");
    return {
      'success': true,
      'yesData': yesResults,
      'maybeData': maybeResults,
      'soldData': allSold, // <<< MODIFIED: Return sold data
      'headers': orderedHeaders,
      'fileNameBase': 'property_analysis_results',
    };

  } catch (e, stackTrace) {
     if (kDebugMode) {
        print("[${DateTime.now()}] ISOLATE (csv_processor): Error during processing: $e");
        print(stackTrace);
     }
     // Ensure error message is a String
     final errorMessage = e is Error ? e.toString() : (e is Exception ? e.toString() : 'An unknown error occurred in the isolate.');
     return {'success': false, 'error': errorMessage};
  }
}

// --- Helper Functions (Private to this file) ---

// Reads and merges CSV files synchronously (for use within the isolate)
List<Map<String, dynamic>> _readAndMergeCsvsSync(List<String> filePaths) {
  final List<Map<String, dynamic>> allRows = [];
  for (final filePath in filePaths) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        if (kDebugMode) print("[csv_processor] Skipping file $filePath: Does not exist.");
        continue;
      }
      String csvString;
      try {
         csvString = file.readAsStringSync(encoding: utf8);
      } catch (e) {
         if (kDebugMode) print("[csv_processor] Warning: Failed to read $filePath as UTF-8, trying default encoding. Error: $e");
         try {
           csvString = file.readAsStringSync();
         } catch (e2) {
            if (kDebugMode) print("[csv_processor] Error reading file $filePath with default encoding either: $e2");
            continue;
         }
      }

      final List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter(
          shouldParseNumbers: false,
          allowInvalid: false,
      ).convert(csvString);

      if (rowsAsListOfValues.length < 2) {
         if (kDebugMode) print("[csv_processor] Skipping file $filePath: Not enough rows (${rowsAsListOfValues.length}).");
         continue;
      }

      final headers = rowsAsListOfValues[0].map((h) => h?.toString().trim() ?? '').toList();
      if (headers.isEmpty || headers.every((h) => h.isEmpty)) {
         if (kDebugMode) print("[csv_processor] Skipping file $filePath: Invalid or empty header row.");
         continue;
      }

      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        final rowMap = <String, dynamic>{};
        final values = rowsAsListOfValues[i];
        for (int j = 0; j < headers.length; j++) {
          if (j < values.length) {
             final value = values[j];
             rowMap[headers[j]] = (value is String) ? value.trim() : value;
          } else {
             rowMap[headers[j]] = null;
          }
        }
        if ((rowMap['Street Address']?.toString() ?? '').trim().isNotEmpty || (rowMap['City']?.toString() ?? '').trim().isNotEmpty) {
             allRows.add(rowMap);
        } else {
             if (kDebugMode) print("[csv_processor] Skipping row $i in $filePath: Address/City seem empty.");
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
          print("[csv_processor] Error reading or parsing file $filePath: $e");
          print(stackTrace);
      }
    }
  }
  if (kDebugMode) print("[csv_processor] Finished reading ${filePaths.length} files. Total rows merged: ${allRows.length}");
  return allRows;
}

// Normalizes street addresses for comparison
String _normalizeAddress(String street, String city) {
    if (street.isEmpty || city.isEmpty) return '';
    String normStreet = street.toLowerCase().trim();
    String normCity = city.toLowerCase().trim();

    // Normalize common street types
    normStreet = normStreet.replaceAll(RegExp(r'\blane\.?\b', caseSensitive: false), 'lane');
    normStreet = normStreet.replaceAll(RegExp(r'\bcourt\.?\b|\bct\.?\b', caseSensitive: false), 'court');
    normStreet = normStreet.replaceAll(RegExp(r'\broad\.?\b', caseSensitive: false), 'road');
    normStreet = normStreet.replaceAll(RegExp(r'\bstreet\.?\b', caseSensitive: false), 'street');
    normStreet = normStreet.replaceAll(RegExp(r'\bavenue\.?\b|\bave\.?\b', caseSensitive: false), 'avenue');
    normStreet = normStreet.replaceAll(RegExp(r'\bdrive\.?\b', caseSensitive: false), 'drive');
    normStreet = normStreet.replaceAll(RegExp(r'\bplace\.?\b', caseSensitive: false), 'place');
    normStreet = normStreet.replaceAll(RegExp(r'\bsquare\.?\b', caseSensitive: false), 'square');
    normStreet = normStreet.replaceAll(RegExp(r'\bboulevard\.?\b|\bblvd\.?\b', caseSensitive: false), 'boulevard');
    normStreet = normStreet.replaceAll(RegExp(r'\bparkway\.?\b|\bpkwy\.?\b', caseSensitive: false), 'parkway');
    normStreet = normStreet.replaceAll(RegExp(r'\bterrace\.?\b|\bter\.?\b', caseSensitive: false), 'terrace');
    normStreet = normStreet.replaceAll(RegExp(r'\btrail\.?\b|\btrl\.?\b', caseSensitive: false), 'trail');

    // Normalize unit/apt identifiers
    normStreet = normStreet.replaceAllMapped(RegExp(r'\bunit\s?(\d+)\b', caseSensitive: false), (match) => 'unit ${match.group(1)}');
    normStreet = normStreet.replaceAll(RegExp(r'#\s?(\d+)\b', caseSensitive: false), r'unit $1');
    normStreet = normStreet.replaceAllMapped(RegExp(r'\bapt\s?(\d+)\b', caseSensitive: false), (match) => 'apt ${match.group(1)}');

    // **NEW**: Normalize cardinal directions (preceded by space)
    normStreet = normStreet.replaceAll(RegExp(r'\s(north|n\.?)\b', caseSensitive: false), ' n');
    normStreet = normStreet.replaceAll(RegExp(r'\s(east|e\.?)\b', caseSensitive: false), ' e');
    normStreet = normStreet.replaceAll(RegExp(r'\s(south|s\.?)\b', caseSensitive: false), ' s');
    normStreet = normStreet.replaceAll(RegExp(r'\s(west|w\.?)\b', caseSensitive: false), ' w');

    // **NEW**: Remove special characters except letters, numbers, and spaces
    // We keep spaces for separation and potentially the separator later
    normStreet = normStreet.replaceAll(RegExp(r'[^\w\s]+'), ''); // \w matches letters, numbers, underscore. \s matches whitespace.
    normCity = normCity.replaceAll(RegExp(r'[^\w\s]+'), '');

    // Collapse multiple spaces and trim again
    normStreet = normStreet.replaceAll(RegExp(r'\s+'), ' ').trim();
    normCity = normCity.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Final format: ensure single letter directions are uppercase if needed
    normStreet = normStreet.replaceAll(RegExp(r'\s(n)\b'), ' N');
    normStreet = normStreet.replaceAll(RegExp(r'\s(e)\b'), ' E');
    normStreet = normStreet.replaceAll(RegExp(r'\s(s)\b'), ' S');
    normStreet = normStreet.replaceAll(RegExp(r'\s(w)\b'), ' W');


    // Return combined, ensuring city is not empty
    if (normCity.isEmpty) return '';
    return '$normStreet|$normCity';
}


// Collects unique headers from a list of data maps
void _collectHeaders(List<Map<String, dynamic>> data, Set<String> allHeaders) {
   for (final row in data) {
      allHeaders.addAll(row.keys.map((k) => k.toString()));
   }
}
