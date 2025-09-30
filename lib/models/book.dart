class Book {
  final int? id;
  final String title;
  final String author;
  final String filePath;
  final BookFormat format;
  final String? coverPath;
  final int totalPages;
  final int currentPage;
  final double progress;
  final DateTime dateAdded;
  final DateTime lastRead;
  final List<String> tags;

  Book({
    this.id,
    required this.title,
    required this.author,
    required this.filePath,
    required this.format,
    this.coverPath,
    required this.totalPages,
    this.currentPage = 0,
    this.progress = 0.0,
    required this.dateAdded,
    required this.lastRead,
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'format': format.toString().split('.').last,
      'coverPath': coverPath,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'progress': progress,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
      'lastRead': lastRead.millisecondsSinceEpoch,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      author: map['author'],
      filePath: map['filePath'],
      format: BookFormat.values.firstWhere(
        (e) => e.toString().split('.').last == map['format'],
        orElse: () => BookFormat.epub,
      ),
      coverPath: map['coverPath'],
      totalPages: map['totalPages'],
      currentPage: map['currentPage'],
      progress: map['progress'],
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['dateAdded']),
      lastRead: DateTime.fromMillisecondsSinceEpoch(map['lastRead']),
    );
  }

  Book copyWith({
    int? currentPage,
    double? progress,
    DateTime? lastRead,
    List<String>? tags,
  }) {
    return Book(
      id: id,
      title: title,
      author: author,
      filePath: filePath,
      format: format,
      coverPath: coverPath,
      totalPages: totalPages,
      currentPage: currentPage ?? this.currentPage,
      progress: progress ?? this.progress,
      dateAdded: dateAdded,
      lastRead: lastRead ?? this.lastRead,
      tags: tags ?? this.tags,
    );
  }
}

enum BookFormat { epub, pdf, docx }