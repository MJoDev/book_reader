import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';

class FileService {
  static Future<FilePickerResult?> pickFile() async {
    try {
      print('Opening file picker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf', 'doc', 'docx'],
        allowMultiple: false,
        withData: true,
      );
      
      if (result != null) {
        final file = result.files.single;
        print('File picked: ${file.name}');
        print('File size: ${file.size}');
        print('Has bytes: ${file.bytes != null}');
        print('File path: ${file.path}');
      } else {
        print('No file selected');
      }
      
      return result;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  static Future<Book?> processFile(PlatformFile file) async {
    try {
      print('Processing file: ${file.name}');
      print('File details - bytes: ${file.bytes != null}, path: ${file.path}');
      
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
        print('Unsupported file format: $fileExtension');
        return null;
      }

      File savedFile;
      
      // Handle both bytes and file path scenarios
      if (file.bytes != null) {
        // Save from bytes
        final appDir = await getApplicationDocumentsDirectory();
        savedFile = File('${appDir.path}/${file.name}');
        await savedFile.writeAsBytes(file.bytes!);
        print('File saved from bytes to: ${savedFile.path}');
      } else if (file.path != null) {
        // Copy from original path
        final appDir = await getApplicationDocumentsDirectory();
        savedFile = File('${appDir.path}/${file.name}');
        final originalFile = File(file.path!);
        await originalFile.copy(savedFile.path);
        print('File copied from path to: ${savedFile.path}');
      } else {
        print('No file data available - both bytes and path are null');
        return null;
      }

      // Verify file was saved
      if (!await savedFile.exists()) {
        print('Failed to save file');
        return null;
      }

      final fileSize = await savedFile.length();
      print('Saved file size: $fileSize bytes');

      // Extract basic info
      final totalPages = await _estimateTotalPages(format, savedFile);
      print('Estimated total pages: $totalPages');

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
      print('Error processing file: $e');
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
            print('Error reading DOCX: $e');
            return 50;
          }
      }
    } catch (e) {
      print('Error estimating pages: $e');
      return 100; // Default fallback
    }
  }
}