// file: lib/screens/file_upload_screen.dart
// path: lib/screens/file_upload_screen.dart
// approximate line: 1
import 'dart:async';
import 'dart:convert'; // For utf8 encoding
// Removed dart:io import, now handled in csv_processor.dart
import 'dart:typed_data'; // For Uint8List

import 'package:collection/collection.dart'; // For SetEquality
import 'package:csv/csv.dart'; // For ListToCsvConverter
import 'package:file_selector/file_selector.dart'; // For file selection AND saving path/location
import 'package:flutter/foundation.dart'
    show compute, kDebugMode, kIsWeb; // For platform checks and compute
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path; // For manipulating file paths

// Import the analysis screen
import 'analysis_screen.dart';
// Import the extracted widget
import '../widgets/file_drop_area.dart';
// Import the new utility file
import '../utils/csv_processor.dart';


// Main screen widget definition (Stateful)
class FileUploadScreen extends StatefulWidget {
  const FileUploadScreen({super.key});

  @override
  _FileUploadScreenState createState() => _FileUploadScreenState();
}

// State class for the main screen - manages the overall file lists
class _FileUploadScreenState extends State<FileUploadScreen> {
  // Sets store the unique file paths for each category
  final Set<String> _cancelledOrExpiredFiles = {};
  final Set<String> _activeOnMarketFiles = {};
  final Set<String> _soldFiles = {};

  // State variable to track processing status
  bool _isProcessing = false;

  // --- File Handling Callbacks ---
  // ( _handleFilesAdded, _handleFileDeleted, _selectFiles methods are unchanged)
  void _handleFilesAdded(List<XFile> files, Set<String> targetSet, String fileType) {
     if (kDebugMode) print('[${DateTime.now()}] _handleFilesAdded: START for $fileType');
    if (files.isEmpty) {
       if (kDebugMode) print('[${DateTime.now()}] _handleFilesAdded: No files received for $fileType. END');
       return;
    }
    if (kDebugMode) print('[${DateTime.now()}] _handleFilesAdded: Filtering files for $fileType...');
    final csvFiles = files.where((file) {
      final filePath = file.path;
      if (filePath.isEmpty) return false;
      try {
        return path.extension(filePath).toLowerCase() == '.csv';
      } catch (e) {
        if (kDebugMode) print("[${DateTime.now()}] _handleFilesAdded: Error getting extension for ${filePath}: $e");
        return false;
      }
    }).toList();
    if (kDebugMode) print('[${DateTime.now()}] _handleFilesAdded: Filtering complete for $fileType. Found ${csvFiles.length} CSV files.');
    if (csvFiles.isEmpty) {
       if (kDebugMode) print('[${DateTime.now()}] _handleFilesAdded: No CSV files found for $fileType.');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('No valid CSV files found.')),
         );
       }
       if (kDebugMode) print('[${DateTime.now()}] _handleFilesAdded: END (No CSVs) for $fileType');
       return;
    }
    if (mounted) {
        if (kDebugMode) print('[${DateTime.now()}] _handleFilesAdded: Calling setState for $fileType...');
        setState(() {
          if (kDebugMode) print('[${DateTime.now()}] _handleFilesAdded: Inside setState for $fileType. Adding files...');
          for (final file in csvFiles) {
            if (file.path.isNotEmpty) {
                targetSet.add(file.path);
            }
          }
           if (kDebugMode) print('[${DateTime.now()}] _handleFilesAdded: Inside setState for $fileType. File adding loop complete.');
        });
        if (kDebugMode) print('[${DateTime.now()}] _handleFilesAdded: setState call finished for $fileType.');
    } else {
       if (kDebugMode) print('[${DateTime.now()}] _handleFilesAdded: Widget not mounted, skipping setState for $fileType.');
    }
     if (kDebugMode) print('[${DateTime.now()}] _handleFilesAdded: END for $fileType');
  }

 void _handleFileDeleted(Set<String> targetSet, String filePathToRemove) {
     if (kDebugMode) print('[${DateTime.now()}] _handleFileDeleted: START for $filePathToRemove');
    if (mounted) {
        if (kDebugMode) print('[${DateTime.now()}] _handleFileDeleted: Calling setState to remove $filePathToRemove');
        setState(() {
          if (kDebugMode) print('[${DateTime.now()}] _handleFileDeleted: Inside setState, removing $filePathToRemove');
          targetSet.remove(filePathToRemove);
        });
         if (kDebugMode) print('[${DateTime.now()}] _handleFileDeleted: setState call finished for $filePathToRemove');
    } else {
        if (kDebugMode) print('[${DateTime.now()}] _handleFileDeleted: Widget not mounted, skipping setState for $filePathToRemove');
    }
     if (kDebugMode) print('[${DateTime.now()}] _handleFileDeleted: END for $filePathToRemove');
 }

  Future<void> _selectFiles(Set<String> targetSet, String fileType) async {
     if (kDebugMode) print('[${DateTime.now()}] _selectFiles: START for $fileType');
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'CSV files',
      extensions: <String>['csv'],
    );
    try {
      final List<XFile> files = await openFiles(
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
      );
      if (kDebugMode) print('[${DateTime.now()}] _selectFiles: openFiles returned ${files.length} files for $fileType.');
      _handleFilesAdded(files, targetSet, fileType);
    } catch (e) {
      if (kDebugMode) print('[${DateTime.now()}] _selectFiles: Error selecting files for $fileType: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('File selection failed: ${e.toString()}')),
         );
      }
    }
     if (kDebugMode) print('[${DateTime.now()}] _selectFiles: END for $fileType');
  }


  // --- Processing Logic ---

  void _showLoadingDialog() {
    // (unchanged)
    showDialog(
      context: context,
      barrierDismissible: false, // User must not dismiss it manually
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Processing files..."),
              ],
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    // (unchanged)
     if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
     }
  }

  // ** Main function triggered by the "Process Files" button **
  Future<void> _triggerProcessing() async {
     if (_isProcessing) return;

     if (mounted) {
       setState(() => _isProcessing = true);
     }
     _showLoadingDialog();

     if (kDebugMode) print("[${DateTime.now()}] PROCESS FILES: START");

     Map<String, dynamic>? processingResult; // To store result from isolate

     try {
       final args = {
         'cancelledPaths': _cancelledOrExpiredFiles.toList(),
         'activePaths': _activeOnMarketFiles.toList(),
         'soldPaths': _soldFiles.toList(),
       };

       // **MODIFIED**: Run processing in isolate using the imported function
       processingResult = await compute(processCsvFilesIsolate, args); // Use imported function

       _hideLoadingDialog(); // Hide loading indicator *after* compute finishes

       // Check result from isolate
       if (processingResult == null || processingResult['success'] != true || !mounted) {
          final String errorMessage = processingResult?['error'] ?? 'An unknown error occurred during processing.';
          if (kDebugMode) print("[${DateTime.now()}] PROCESS FILES: Error - $errorMessage");
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Error processing files: $errorMessage'),
               backgroundColor: Colors.red,
            ),
          );
          // Don't proceed to saving or navigation on error
          setState(() => _isProcessing = false); // Ensure processing state is reset on error
          return; // Exit the function early
       }

       // --- CSV Generation and Saving ---
       if (kDebugMode) print("[${DateTime.now()}] PROCESS FILES: Isolate successful. Generating CSV file...");

       final List<Map<String, dynamic>> yesData = processingResult['yesData'];
       final List<Map<String, dynamic>> maybeData = processingResult['maybeData'];
       final List<String> headers = processingResult['headers'];
       final String defaultFileNameBase = processingResult['fileNameBase'];

       // Combine Yes and Maybe data for the single CSV file
       final List<Map<String, dynamic>> allResults = [...yesData, ...maybeData];


       if (allResults.isEmpty) {
           if (kDebugMode) print("[${DateTime.now()}] PROCESS FILES: No results to save.");
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('No properties matched the criteria.')),
           );
           setState(() => _isProcessing = false); // Reset processing state
           return; // Exit if no results
       }

       // Convert List<Map> to List<List> for CSV converter
       final List<List<dynamic>> csvData = [
           headers,
           ...allResults.map((rowMap) {
               return headers.map((header) => rowMap[header] ?? '').toList();
           }).toList(),
       ];

       // Convert to CSV string
       final csvString = const ListToCsvConverter().convert(csvData);
       final Uint8List fileBytes = utf8.encode(csvString); // Encode as UTF-8


       if (kDebugMode) print("[${DateTime.now()}] PROCESS FILES: CSV file generated. Prompting for save location...");

       // *** Use getSaveLocation and XFile.saveTo pattern ***
       final FileSaveLocation? result = await getSaveLocation(
           suggestedName: "$defaultFileNameBase.csv", // Suggest .csv extension
           acceptedTypeGroups: [
             const XTypeGroup(
               label: 'CSV Files',
               extensions: ['csv'],
             )
           ]
       );

       if (result == null) {
         // User cancelled dialog
         if (kDebugMode) print("[${DateTime.now()}] PROCESS FILES: Save cancelled by user.");
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Save cancelled.')),
         );
         setState(() => _isProcessing = false); // Reset processing state
         return; // Exit if save is cancelled
       }

       // Create an XFile object from the generated bytes
       final XFile csvXFile = XFile.fromData(
           fileBytes,
           mimeType: 'text/csv',
           name: path.basename(result.path),
           length: fileBytes.length,
       );

       // Use the saveTo method to save the XFile to the chosen path
       if (kDebugMode) print("[${DateTime.now()}] PROCESS FILES: Saving file to ${result.path} using saveTo...");
       try {
         await csvXFile.saveTo(result.path);
         final String savedFilePath = result.path;
         if (kDebugMode) print("[${DateTime.now()}] PROCESS FILES: File saved successfully to $savedFilePath.");
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Successfully generated and saved to $savedFilePath')),
         );

         // --- Navigation ---
         if (kDebugMode) print("[${DateTime.now()}] PROCESS FILES: Navigating to Analysis Screen...");
         if (mounted) {
            if(yesData.isNotEmpty || maybeData.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AnalysisScreen(
                      yesData: yesData,
                      maybeData: maybeData,
                      headers: headers,
                    ),
                ),
              );
            } else {
               if (kDebugMode) print("[${DateTime.now()}] PROCESS FILES: Skipping navigation as there is no data to display.");
            }
         } else {
             if (kDebugMode) print("[${DateTime.now()}] PROCESS FILES: Widget not mounted, skipping navigation.");
         }

       } catch (e, stackTrace) {
          // Catch errors during the actual saving process
          if (kDebugMode) {
            print("[${DateTime.now()}] PROCESS FILES: Error during file saveTo: $e");
            print(stackTrace);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save file to ${result.path}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isProcessing = false);
          return;
       }

     } catch (e, stackTrace) {
       if (mounted) _hideLoadingDialog();
       if (kDebugMode) {
          print("[${DateTime.now()}] PROCESS FILES: Exception caught - $e");
          print(stackTrace);
       }
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred: $e'),
              backgroundColor: Colors.red,
            ),
          );
       }
     } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
        if (kDebugMode) print("[${DateTime.now()}] PROCESS FILES: END");
     }
  }


  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Build method now uses the imported FileDropArea widget
     if (kDebugMode) print('[${DateTime.now()}] _FileUploadScreenState: Build START');
    Widget body = SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Use the imported FileDropArea widget
              FileDropArea(
                key: const ValueKey('drop_area_cancelled'),
                title: 'Cancelled/Expired Listings',
                fileSet: _cancelledOrExpiredFiles,
                baseBackgroundColor: Colors.red.shade50,
                onFilesSelected: () => _selectFiles(_cancelledOrExpiredFiles, 'Cancelled/Expired Listings'),
                onFilesDropped: (files) => _handleFilesAdded(files, _cancelledOrExpiredFiles, 'Cancelled/Expired Listings'),
                onFileDeleted: (filePath) => _handleFileDeleted(_cancelledOrExpiredFiles, filePath),
              ),
              FileDropArea(
                key: const ValueKey('drop_area_active'),
                title: 'Active on Market',
                fileSet: _activeOnMarketFiles,
                baseBackgroundColor: Colors.green.shade50,
                onFilesSelected: () => _selectFiles(_activeOnMarketFiles, 'Active on Market'),
                onFilesDropped: (files) => _handleFilesAdded(files, _activeOnMarketFiles, 'Active on Market'),
                onFileDeleted: (filePath) => _handleFileDeleted(_activeOnMarketFiles, filePath),
              ),
              FileDropArea(
                 key: const ValueKey('drop_area_sold'),
                title: 'Sold',
                fileSet: _soldFiles,
                baseBackgroundColor: Colors.blue.shade50,
                onFilesSelected: () => _selectFiles(_soldFiles, 'Sold'),
                onFilesDropped: (files) => _handleFilesAdded(files, _soldFiles, 'Sold'),
                onFileDeleted: (filePath) => _handleFileDeleted(_soldFiles, filePath),
              ),

              // "Process Files" button (unchanged)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: ElevatedButton.icon(
                  icon: _isProcessing
                      ? Container( // Show progress indicator inside button when processing
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.settings_outlined),
                  label: Text(_isProcessing ? 'Processing...' : 'Process Files'),
                  // Disable button if no cancelled/expired files OR if processing is ongoing
                  onPressed: (_cancelledOrExpiredFiles.isEmpty) || _isProcessing // Require at least Cancelled/Expired
                      ? null
                      : _triggerProcessing, // Call the processing trigger function
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400, // Style for disabled state
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                     shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
     if (kDebugMode) print('[${DateTime.now()}] _FileUploadScreenState: Build END');
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV Property Analyzer'),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: body,
    );
  }
}

// --- Isolate Processing Function and Helpers REMOVED from this file ---
// (Moved to lib/utils/csv_processor.dart)
