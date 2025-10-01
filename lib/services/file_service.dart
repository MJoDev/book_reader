import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import 'package:logger/logger.dart';

class FileService {
  static final Logger _logger = Logger();

  static Future<FilePickerResult?> pickFile() async {
    try {
      _logger.i('Opening file picker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf', 'doc', 'docx'],
        allowMultiple: false,
        withData: true,
      );
      
      if (result != null) {
        final file = result.files.single;
        _logger.i('File picked: ${file.name}');
        _logger.i('File size: ${file.size}');
        _logger.i('Has bytes: ${file.bytes != null}');
        _logger.i('File path: ${file.path}');
      } else {
        _logger.w('No file selected');
      }
      
      return result;
    } catch (e) {
      _logger.e('Error picking file: $e');
      return null;
    }
  }

  static Future<Book?> processFile(PlatformFile file) async {
    try {
      _logger.i('Processing file: ${file.name}');
      _logger.d('File details - bytes: ${file.bytes != null}, path: ${file.path}');
      
      final fileExtension = path.extension(file.name).toLowerCase();
      final fileName = path.basenameWithoutExtension(file.name);
      
      // Determine format
      BookFormat format;
      if (fileExtension == '.epub') {
        format = BookFormat.epub;
      } else if (fileExtension == '.pdf') {
        format = BookFormat.pdf;
      } else if (fileExtension == '.docx' || fileExtension == '.doc') {
        format = BookFormat.docx;
      } else {
        _logger.w('Unsupported file format: $fileExtension');
        return null;
      }

      File savedFile;
      
      // Handle both bytes and file path scenarios
      if (file.bytes != null) {
        // Save from bytes
        final appDir = await getApplicationDocumentsDirectory();
        savedFile = File('${appDir.path}/${file.name}');
        await savedFile.writeAsBytes(file.bytes!);
        _logger.i('File saved from bytes to: ${savedFile.path}');
      } else if (file.path != null) {
        // Copy from original path
        final appDir = await getApplicationDocumentsDirectory();
        savedFile = File('${appDir.path}/${file.name}');
        final originalFile = File(file.path!);
        await originalFile.copy(savedFile.path);
        _logger.i('File copied from path to: ${savedFile.path}');
      } else {
        _logger.e('No file data available - both bytes and path are null');
        return null;
      }

      // Verify file was saved
      if (!await savedFile.exists()) {
        _logger.e('Failed to save file');
        return null;
      }

      final fileSize = await savedFile.length();
      _logger.d('Saved file size: $fileSize bytes');

      // Extract basic info
      final totalPages = await _estimateTotalPages(format, savedFile);
      _logger.d('Estimated total pages: $totalPages');

      return Book(
        title: fileName,
        author: 'Unknown Author',
        filePath: savedFile.path,
        format: format,
        totalPages: totalPages,
        dateAdded: DateTime.now(),
        lastRead: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Error processing file: $e');
      return null;
    }
  }

  static Future<int> _estimateTotalPages(BookFormat format, File file) async {
    try {
      switch (format) {
        case BookFormat.pdf:
          // For PDF, we can use a rough estimate based on file size
          final fileSize = await file.length();
          return (fileSize / 50000).ceil(); // Rough estimate: 50KB per page
        
        case BookFormat.epub:
          return 200; // Default estimate for EPUB
        
        case BookFormat.docx:
          try {
            return (10000 / 2000).ceil(); // Estimate based on average words per page
          } catch (e) {
            _logger.e('Error reading DOCX: $e');
            return 50;
          }
      }
    } catch (e) {
      _logger.e('Error estimating pages: $e');
      return 100; // Default fallback
    }
  }
}