import 'package:flutter/material.dart';
import '../services/file_service.dart';
import '../services/database_service.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';
import 'reader_screen.dart';
import 'package:logger/logger.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final Logger _logger = Logger();
  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _logger.d('LibraryScreen initState called');
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      _logger.i('Loading books from database...');
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final books = await _databaseService.getBooks();
      _logger.i('Loaded ${books.length} books');
      
      setState(() {
        _books = books;
        _filteredBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading books: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading books: $e';
      });
    }
  }

  void _filterBooks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBooks = _books;
      } else {
        _filteredBooks = _books.where((book) {
          return book.title.toLowerCase().contains(query.toLowerCase()) ||
                 book.author.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _endSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _filteredBooks = _books;
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('Building LibraryScreen, isLoading: $_isLoading, books: ${_books.length}');
    
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search books...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _filterBooks,
              )
            : const Text('My Library'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _endSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your library...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Error Loading Library',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadBooks,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _filteredBooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSearching ? Icons.search_off : Icons.menu_book, 
                          size: 64, 
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching ? 'No books found' : 'No books in library',
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSearching 
                            ? 'Try different search terms'
                            : 'Tap the + button to add a book',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      return BookCard(
                        book: _filteredBooks[index],
                        onTap: () => _openBook(_filteredBooks[index]),
                      );
                    },
                  ),
      floatingActionButton: _isSearching ? null : FloatingActionButton(
        onPressed: _addBook,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addBook() async {
    try {
      _logger.i('Adding book...');
      final result = await FileService.pickFile();
      if (result != null && result.files.single.bytes != null) {
        _logger.i('File selected, processing...');
        final book = await FileService.processFile(result.files.single);
        if (book != null) {
          _logger.i('Book processed, inserting into database...');
          await _databaseService.insertBook(book);
          await _loadBooks();
          _logger.i('Book added successfully');
        } else {
          _logger.w('Failed to process book');
        }
      } else {
        _logger.w('No file selected or file bytes are null');
      }
    } catch (e) {
      _logger.e('Error adding book: $e');
      setState(() {
        _errorMessage = 'Error adding book: $e';
      });
    }
  }

  void _openBook(Book book) {
    _logger.i('Opening book: ${book.title}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(book: book),
      ),
    ).then((_) {
      _logger.i('Returned from reader screen, reloading books...');
      _loadBooks();
    });
  }


}