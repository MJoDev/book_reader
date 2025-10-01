import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:book_reader/models/book.dart';
import 'dart:io';

class PdfReader extends StatelessWidget {
  final Book currentBook;
  final PdfViewerController pdfViewerController;
  final ValueChanged<int> onPageChanged;

  const PdfReader({
    super.key,
    required this.currentBook,
    required this.pdfViewerController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SfPdfViewer.file(
      File(currentBook.filePath),
      controller: pdfViewerController,
      initialPageNumber: currentBook.currentPage,
      onPageChanged: (PdfPageChangedDetails details) {
        onPageChanged(details.newPageNumber);
      },
      scrollDirection: PdfScrollDirection.vertical,
      canShowScrollHead: true,
      canShowScrollStatus: true,
    );
  }
}
