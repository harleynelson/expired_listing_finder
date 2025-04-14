import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts
import 'screens/file_upload_screen.dart'; // Import the screen file

void main() {
  runApp(const FileUploadApp());
}

// Root application widget
class FileUploadApp extends StatelessWidget {
  const FileUploadApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the base text theme from the current theme
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'CSV File Uploader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Apply the Inter font using google_fonts to the existing text theme
        textTheme: GoogleFonts.interTextTheme(textTheme),
        // Add visual density for a more compact layout on desktop
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Set the home screen to FileUploadScreen
      home: const FileUploadScreen(),
      debugShowCheckedModeBanner: false, // Optionally remove the debug banner
    );
  }
}
