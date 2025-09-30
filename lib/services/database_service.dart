import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';
import '../models/annotation.dart';
import '../models/book_mark.dart';

// Conditional imports for cross-platform support
import 'package:flutter/foundation.dart' show kIsWeb;

// For non-web platforms, import FFI factory
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  bool _isInitialized = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize database factory for non-web desktop platforms
    if (!kIsWeb && !_isInitialized) {
      // Check if we're on a platform that needs FFI
      try {
        databaseFactory = ffi.databaseFactoryFfi;
        _isInitialized = true;
      } catch (e) {
        // If FFI fails, fall back to default factory (for mobile)
        print('FFI initialization failed, using default factory: $e');
      }
    }
    
    String path = join(await getDatabasesPath(), 'book_reader.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onConfigure: (db) async {
        // Enable foreign key support
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        filePath TEXT NOT NULL UNIQUE,
        format TEXT NOT NULL,
        coverPath TEXT,
        totalPages INTEGER NOT NULL,
        currentPage INTEGER NOT NULL DEFAULT 0,
        progress REAL NOT NULL DEFAULT 0.0,
        dateAdded INTEGER NOT NULL,
        lastRead INTEGER NOT NULL
      )
    ''');

    await db.execute('''
    CREATE TABLE bookmarks(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bookId INTEGER NOT NULL,
      pageNumber INTEGER NOT NULL,
      dateCreated INTEGER NOT NULL,
      FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
    )
  ''');


    await db.execute('''
      CREATE TABLE annotations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        pageNumber INTEGER NOT NULL,
        selectedText TEXT NOT NULL,
        note TEXT NOT NULL,
        dateCreated INTEGER NOT NULL,
        startOffset INTEGER NOT NULL,
        endOffset INTEGER NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE book_tags(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        tag TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');
  }

  // Book operations
  Future<int> insertBook(Book book) async {
    final db = await database;
    return await db.insert('books', book.toMap());
  }

  Future<List<Book>> getBooks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('books', orderBy: 'lastRead DESC');
    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  Future<Book?> getBook(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Book.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateBook(Book book) async {
    final db = await database;
    return await db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<int> deleteBook(int id) async {
    final db = await database;
    return await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Annotation operations
  Future<int> insertAnnotation(Annotation annotation) async {
    final db = await database;
    return await db.insert('annotations', annotation.toMap());
  }

  Future<List<Annotation>> getAnnotationsForBook(int bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'annotations',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'pageNumber, dateCreated',
    );
    return List.generate(maps.length, (i) => Annotation.fromMap(maps[i]));
  }

  Future<Annotation?> getAnnotation(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'annotations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Annotation.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateAnnotation(Annotation annotation) async {
    final db = await database;
    return await db.update(
      'annotations',
      annotation.toMap(),
      where: 'id = ?',
      whereArgs: [annotation.id],
    );
  }

  Future<int> deleteAnnotation(int id) async {
    final db = await database;
    return await db.delete(
      'annotations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Book tags operations
  Future<int> addBookTag(int bookId, String tag) async {
    final db = await database;
    return await db.insert('book_tags', {
      'bookId': bookId,
      'tag': tag,
    });
  }

  Future<List<String>> getBookTags(int bookId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'book_tags',
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
    return List.generate(maps.length, (i) => maps[i]['tag'] as String);
  }

  Future<int> removeBookTag(int bookId, String tag) async {
    final db = await database;
    return await db.delete(
      'book_tags',
      where: 'bookId = ? AND tag = ?',
      whereArgs: [bookId, tag],
    );
  }

  Future<int> removeAllBookTags(int bookId) async {
    final db = await database;
    return await db.delete(
      'book_tags',
      where: 'bookId = ?',
      whereArgs: [bookId],
    );
  }

  // Search operations
  Future<List<Book>> searchBooks(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'books',
      where: 'title LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'title',
    );
    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  Future<List<Bookmark>> getBookmarks(int bookId) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    'bookmarks',
    where: 'bookId = ?',
    whereArgs: [bookId],
    orderBy: 'pageNumber ASC',
  );
  return List.generate(maps.length, (i) {
    return Bookmark.fromMap(maps[i]);
  });
}

Future<int> insertBookmark(Bookmark bookmark) async {
  final db = await database;
  return await db.insert('bookmarks', bookmark.toMap());
}

Future<int> deleteBookmark(int id) async {
  final db = await database;
  return await db.delete(
    'bookmarks',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<List<Annotation>> getAnnotations(int bookId) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    'annotations',
    where: 'bookId = ?',
    whereArgs: [bookId],
    orderBy: 'pageNumber ASC, dateCreated DESC',
  );
  return List.generate(maps.length, (i) {
    return Annotation.fromMap(maps[i]);
  });
}

  // Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _isInitialized = false;
    }
  }
}