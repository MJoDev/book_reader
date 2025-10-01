import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/book.dart';
import 'package:pdf_render/pdf_render_widgets.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  static final Logger logger = Logger();

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
  });

  Widget _buildBookPreview() {
    switch (book.format) {
      case BookFormat.pdf:
        // Check if file exists before trying to render
        final file = File(book.filePath);
        logger.i('Trying to preview PDF at: ${book.filePath}');
        if (!file.existsSync()) {
          return const Center(child: Text('PDF file not found'));
        }
        return PdfDocumentLoader.openFile(
          book.filePath,
          pageNumber: 1,
          pageBuilder: (context, textureBuilder, pageSize) => textureBuilder(),
          onError: (error) => const Center(child: Text('Failed to load PDF')),
        );
      case BookFormat.epub:
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Text(
              'EPUB Preview',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        );
      case BookFormat.docx:
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: Text(
              'DOCX Preview',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: _buildBookPreview(),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    LinearProgressIndicator(
                      value: book.progress,
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(book.progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}