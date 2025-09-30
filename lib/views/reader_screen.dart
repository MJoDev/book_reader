import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import '../models/book.dart';
import '../services/database_service.dart';
import '../services/epub_service.dart';
import 'package:book_reader/widgets/annotation_dialog.dart';
import 'package:book_reader/widgets/book_mark_dialog.dart';
import 'package:book_reader/models/annotation.dart' as book_reader_annotation;
import 'package:book_reader/models/book_mark.dart';

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
  late PdfViewerController _pdfViewerController;
  List<Bookmark> _bookmarks = [];
  List<book_reader_annotation.Annotation> _annotations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _pdfViewerController = PdfViewerController();
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
    _saveProgress();
    _pageController.dispose();
    _pdfViewerController.dispose();
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

  Widget _buildPdfReader() {
    return SfPdfViewer.file(
      File(_currentBook.filePath),
      controller: _pdfViewerController,
      initialPageNumber: _currentBook.currentPage,
      onPageChanged: (PdfPageChangedDetails details) {
        _updateProgress(details.newPageNumber);
      },
      // Enable scrolling
      scrollDirection: PdfScrollDirection.vertical,
      canShowScrollHead: true,
      canShowScrollStatus: true,
    );
  }

  Widget _buildEpubReader() {
    if (_isLoadingEpub) {
      return const Center(child: CircularProgressIndicator());
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _currentBook.totalPages,
      onPageChanged: _updateEpubProgress,
      itemBuilder: (context, pageIndex) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _epubContent,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        );
      },
    );
  }

  Widget _buildDocxReader() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'DOCX Reader',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'To be implemented with docx_to_text package',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildReader() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentBook.format) {
      case BookFormat.pdf:
        return _buildPdfReader();
      case BookFormat.epub:
        return _buildEpubReader();
      case BookFormat.docx:
        return _buildDocxReader();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
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
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        title: Text(
                          _currentBook.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.bookmark_border, color: Colors.white),
                            onPressed: _addBookmark,
                            tooltip: 'Add Bookmark',
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark, color: Colors.white),
                            onPressed: _showBookmarksDialog,
                            tooltip: 'View Bookmarks',
                          ),
                          IconButton(
                            icon: const Icon(Icons.note_add, color: Colors.white),
                            onPressed: _showAddAnnotationDialog,
                            tooltip: 'Add Annotation',
                          ),
                          IconButton(
                            icon: const Icon(Icons.notes, color: Colors.white),
                            onPressed: _showAnnotationsDialog,
                            tooltip: 'View Annotations',
                          ),
                        ],
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Text(
                              _currentBook.format == BookFormat.epub
                                  ? 'Page ${_currentBook.currentPage + 1} of ${_currentBook.totalPages}'
                                  : 'Page ${_currentBook.currentPage} of ${_currentBook.totalPages}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const Spacer(),
                            Text(
                              '${(_currentBook.progress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
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

