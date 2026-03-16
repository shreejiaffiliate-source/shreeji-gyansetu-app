import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../../../core/constants/app_colors.dart';

class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({super.key, required this.pdfUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: Colors.white),),
        backgroundColor: isDark ? Colors.grey[900] : AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SfPdfViewerTheme(
        data: SfPdfViewerThemeData(
          // ProgressBar color fix
          progressBarColor: AppColors.primaryCyan,
          // Background color for the viewer area
          backgroundColor: isDark ? Colors.black : Colors.grey[100],
        ),
        child: SfPdfViewer.network(
          pdfUrl,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading PDF: ${details.description}')),
            );
          },
        ),
      ),
    );
  }
}