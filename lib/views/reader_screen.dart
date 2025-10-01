import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:book_reader/models/book.dart';
import 'package:book_reader/services/database_service.dart';
import 'package:book_reader/services/epub_service.dart';
import 'package:book_reader/widgets/annotation_dialog.dart';
import 'package:book_reader/widgets/book_mark_dialog.dart';
import 'package:book_reader/models/annotation.dart' as book_reader_annotation;
import 'package:book_reader/models/book_mark.dart';
import 'reader_controls.dart';
import 'readers/pdf_reader.dart';
import 'readers/epub_reader.dart';
import 'readers/docx_reader.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Book _currentBook;
  bool _showControls = true;
  String _epubContent = '';
  bool _isLoadingEpub = false;
  final PageController _pageController = PageController();
  late dynamic _pdfViewerController;
  List<Bookmark> _bookmarks = [];
  List<book_reader_annotation.Annotation> _annotations = [];
  bool _isLoading = true;

  // Add focus node for keyboard events
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
  _pdfViewerController = _currentBook.format == BookFormat.pdf ? PdfViewerController() : null;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load EPUB content if needed
    if (_currentBook.format == BookFormat.epub) {
      await _loadEpubContent();
    }

    // Load bookmarks and annotations
    await _loadBookmarks();
    await _loadAnnotations();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadEpubContent() async {
    if (_currentBook.format == BookFormat.epub) {
      setState(() {
        _isLoadingEpub = true;
      });
      final content = await EpubService.extractEpubContent(File(_currentBook.filePath));
      setState(() {
        _epubContent = content;
        _isLoadingEpub = false;
      });
    }
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await _databaseService.getBookmarks(_currentBook.id!);
    setState(() {
      _bookmarks = bookmarks;
    });
  }

  Future<void> _loadAnnotations() async {
    final annotations = await _databaseService.getAnnotations(_currentBook.id!);
    setState(() {
      _annotations = annotations;
    });
  }

  @override
  void dispose() {
    // _saveProgress(); // REMOVE this line, don't save progress in dispose
    _pageController.dispose();
    if (_pdfViewerController != null) {
      _pdfViewerController.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    await _databaseService.updateBook(_currentBook);
  }

  void _updateProgress(int currentPage) {
    final progress = currentPage / _currentBook.totalPages;
    setState(() {
      _currentBook = _currentBook.copyWith(
        currentPage: currentPage,
        progress: progress,
        lastRead: DateTime.now(),
      );
    });
  }

  void _updateEpubProgress(int page) {
    final progress = page / _currentBook.totalPages;
    setState(() {
      _currentBook = _currentBook.copyWith(
        currentPage: page,
        progress: progress,
        lastRead: DateTime.now(),
      );
    });
  }

  Future<void> _addBookmark() async {
    final currentPage = _currentBook.format == BookFormat.pdf
        ? _pdfViewerController.pageNumber
        : _currentBook.currentPage;

    final bookmark = Bookmark(
      bookId: _currentBook.id!,
      pageNumber: currentPage,
      dateCreated: DateTime.now(),
    );

    await _databaseService.insertBookmark(bookmark);
    await _loadBookmarks();

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmark added to page $currentPage'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showAddAnnotationDialog() async {
    final currentPage = _currentBook.format == BookFormat.pdf
        ? _pdfViewerController.pageNumber
        : _currentBook.currentPage;

    String? note = await showDialog<String>(
      context: context,
      builder: (context) => AnnotationDialog(
        pageNumber: currentPage,
      ),
    );

    if (note != null && note.isNotEmpty) {
      final annotation = book_reader_annotation.Annotation(
        bookId: _currentBook.id!,
        pageNumber: currentPage,
        selectedText: '', // You can extend this to capture selected text
        note: note,
        dateCreated: DateTime.now(),
        startOffset: 0,
        endOffset: 0,
      );

      await _databaseService.insertAnnotation(annotation);
      await _loadAnnotations();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annotation added'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showBookmarksDialog() {
    showDialog(
      context: context,
      builder: (context) => BookmarksDialog(
        bookmarks: _bookmarks,
        onBookmarkSelected: (bookmark) {
          _navigateToPage(bookmark.pageNumber);
          Navigator.pop(context);
        },
        onBookmarkDeleted: (bookmark) async {
          await _databaseService.deleteBookmark(bookmark.id!);
          await _loadBookmarks();
        },
      ),
    );
  }

  void _showAnnotationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AnnotationsDialog(
        annotations: _annotations,
        onAnnotationSelected: (annotation) {
          _navigateToPage(annotation.pageNumber);
          Navigator.pop(context);
        },
        onAnnotationDeleted: (annotation) async {
          await _databaseService.deleteAnnotation(annotation.id!);
          await _loadAnnotations();
        },
      ),
    );
  }

  void _navigateToPage(int pageNumber) {
    if (_currentBook.format == BookFormat.pdf) {
      _pdfViewerController.jumpToPage(pageNumber);
    } else {
      _pageController.jumpToPage(pageNumber);
    }
    _updateProgress(pageNumber);
  }


  Widget _buildReader() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (_currentBook.format) {
      case BookFormat.pdf:
        return PdfReader(
          currentBook: _currentBook,
          pdfViewerController: _pdfViewerController,
          onPageChanged: _updateProgress,
        );
      case BookFormat.epub:
        return EpubReader(
          currentBook: _currentBook,
          pageController: _pageController,
          epubContent: _epubContent,
          isLoadingEpub: _isLoadingEpub,
          onPageChanged: _updateEpubProgress,
        );
      case BookFormat.docx:
        return const DocxReader();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  // Platform check helpers
  bool get _isWindows {
    return !kIsWeb && Platform.isWindows;
  }

  bool get _isMobile {
    return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Stack(
      children: [
        _buildReader(),
        if (_showControls)
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: ReaderControls(
                currentBook: _currentBook,
                onBack: () async {
                  await _saveProgress();
                  Navigator.pop(context);
                },
                onAddBookmark: _addBookmark,
                onShowBookmarks: _showBookmarksDialog,
                onAddAnnotation: _showAddAnnotationDialog,
                onShowAnnotations: _showAnnotationsDialog,
              ),
            ),
          ),
      ],
    );

    // Windows: Use RawKeyboardListener for ESC key
    if (_isWindows) {
      return Scaffold(
        body: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              _toggleControls();
            }
          },
          child: GestureDetector(
            // Single tap does nothing on Windows
            behavior: HitTestBehavior.translucent,
            child: content,
          ),
        ),
      );
    }

    // Mobile: Use double tap to toggle controls
    if (_isMobile) {
      return Scaffold(
        body: GestureDetector(
          onDoubleTap: _toggleControls,
          child: content,
        ),
      );
    }

    // Fallback: Single tap toggles controls
    return Scaffold(
      body: GestureDetector(
        onTap: _toggleControls,
        child: content,
      ),
    );
  }
}

