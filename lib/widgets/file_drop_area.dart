// file: lib/widgets/file_drop_area.dart
// path: lib/widgets/file_drop_area.dart
// approximate line: 1
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart'; // For drag and drop from OS
import 'package:file_selector/file_selector.dart'; // For XFile
import 'package:flutter/foundation.dart' show kDebugMode; // For kDebugMode
import 'package:path/path.dart' as path; // For path.basename

// --- FileDropArea Widget (Layout Updated: Centered Horizontal Group + Centered Text) ---
class FileDropArea extends StatefulWidget {
  final String title;
  final Set<String> fileSet;
  final Color baseBackgroundColor;
  final VoidCallback onFilesSelected;
  final Function(List<XFile> files) onFilesDropped;
  final Function(String filePath) onFileDeleted;

  const FileDropArea({
    super.key,
    required this.title,
    required this.fileSet,
    required this.baseBackgroundColor,
    required this.onFilesSelected,
    required this.onFilesDropped,
    required this.onFileDeleted,
  });

  @override
  State<FileDropArea> createState() => _FileDropAreaState();
}

class _FileDropAreaState extends State<FileDropArea> {
  bool _isDraggingOver = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
     if (kDebugMode) print('[${DateTime.now()}] FileDropArea(${widget.title}): initState');
  }

  @override
  void dispose() {
     if (kDebugMode) print('[${DateTime.now()}] FileDropArea(${widget.title}): dispose');
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     if (kDebugMode) print('[${DateTime.now()}] FileDropArea(${widget.title}): Build START (Dragging: $_isDraggingOver)');
    final backgroundColor = _isDraggingOver
        ? Color.alphaBlend(Colors.black.withOpacity(0.15), widget.baseBackgroundColor)
        : widget.baseBackgroundColor;
    final borderColor = _isDraggingOver ? Colors.blueAccent : Colors.grey.shade400;
    final borderWidth = _isDraggingOver ? 3.0 : 1.5;
    final fileList = widget.fileSet.toList()..sort();

    // --- Main Card Structure ---
    Widget dropTargetChild = Card(
         margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
         elevation: _isDraggingOver ? 6.0 : 2.0,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(12.0),
           side: BorderSide(color: borderColor, width: borderWidth),
         ),
         clipBehavior: Clip.antiAlias,
         child: Container(
           padding: const EdgeInsets.all(16.0),
           color: backgroundColor,
           child: Column( // Main outer column
             mainAxisAlignment: MainAxisAlignment.center,
             // Center the children (the Row and the File List section) horizontally
             crossAxisAlignment: CrossAxisAlignment.center,
             children: <Widget>[
               // --- Top Section: Centered Row [Icon | Column[Text, Button]] ---
               Row(
                 // Make Row only as wide as needed
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.center, // Vertically align items in the row
                 children: [
                   // Icon
                   Icon(
                     _isDraggingOver ? Icons.file_download_done_outlined : Icons.upload_file_outlined,
                     size: 50.0,
                     color: _isDraggingOver ? Colors.blueAccent : Colors.grey.shade600,
                   ),
                   const SizedBox(width: 16.0), // Spacing between icon and text column
                   // Column for Text and Button
                   Column(
                     // **MODIFIED**: Center text blocks and button within this inner column
                     crossAxisAlignment: CrossAxisAlignment.center,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text(
                         widget.title,
                         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                         // **MODIFIED**: Center align text content
                         textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: 4.0),
                       Text(
                         _isDraggingOver ? 'Drop CSV file(s) here' : 'Drag & drop or select files',
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                           color: _isDraggingOver ? Colors.blueAccent : Colors.grey.shade700,
                         ),
                          // **MODIFIED**: Center align text content
                         textAlign: TextAlign.center,
                       ),
                       const SizedBox(height: 12.0),
                       // Button is centered because the column's crossAxisAlignment is center
                       ElevatedButton.icon(
                         icon: const Icon(Icons.folder_open, size: 18),
                         label: const Text('Select Files'),
                         onPressed: widget.onFilesSelected,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.blueAccent,
                           foregroundColor: Colors.white,
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(8.0),
                           ),
                           padding: const EdgeInsets.symmetric(
                               horizontal: 16, vertical: 10),
                           elevation: 2,
                         ),
                       ),
                     ],
                   ),
                 ],
               ), // End of Top Section Row

               // --- File List Section (if files exist) ---
               if (fileList.isNotEmpty) ...[
                 const SizedBox(height: 16.0),
                 // Make divider stretch full width (or use padding/margins)
                 const Divider(height: 1, thickness: 1),
                 Padding(
                   padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                   child: Text(
                     'Selected Files (${fileList.length}):',
                     style: Theme.of(context).textTheme.titleSmall,
                     textAlign: TextAlign.center,
                   ),
                 ),
                 ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: _scrollController, // Use the dedicated controller
                      child: SingleChildScrollView(
                        controller: _scrollController, // Use the dedicated controller
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          alignment: WrapAlignment.center,
                          children: fileList.map((filePath) {
                            final fileName = path.basename(filePath);
                            return InputChip(
                              key: ValueKey(filePath),
                              label: Text(fileName),
                              labelStyle: const TextStyle(fontSize: 12.0),
                              onDeleted: () => widget.onFileDeleted(filePath),
                              deleteIconColor: Colors.red.shade300,
                              backgroundColor: Colors.blue.shade50,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
               ],
               // Add some space at the bottom if no files are selected
               if (fileList.isEmpty) const SizedBox(height: 10),
             ],
           ),
         ),
      );

     if (kDebugMode) print('[${DateTime.now()}] FileDropArea(${widget.title}): Build END');

    // --- DropTarget Wrapper ---
    return DropTarget(
      onDragEntered: (details) {
         if (kDebugMode) print('[${DateTime.now()}] FileDropArea(${widget.title}): onDragEntered');
        if (mounted) setState(() => _isDraggingOver = true);
      },
      onDragExited: (details) {
         if (kDebugMode) print('[${DateTime.now()}] FileDropArea(${widget.title}): onDragExited');
        if (mounted) setState(() => _isDraggingOver = false);
      },
      onDragDone: (details) {
        if (kDebugMode) print('[${DateTime.now()}] FileDropArea(${widget.title}): onDragDone START');
        widget.onFilesDropped(details.files);
        if (mounted) {
             if (kDebugMode) print('[${DateTime.now()}] FileDropArea(${widget.title}): onDragDone calling local setState to reset dragging');
             setState(() => _isDraggingOver = false);
             if (kDebugMode) print('[${DateTime.now()}] FileDropArea(${widget.title}): onDragDone local setState finished');
        } else {
             if (kDebugMode) print('[${DateTime.now()}] FileDropArea(${widget.title}): onDragDone widget not mounted, skipping local setState');
        }
         if (kDebugMode) print('[${DateTime.now()}] FileDropArea(${widget.title}): onDragDone END');
      },
      child: dropTargetChild,
    );
  }
}
