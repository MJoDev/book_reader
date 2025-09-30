class Bookmark {
  final int? id;
  final int bookId;
  final int pageNumber;
  final DateTime dateCreated;

  Bookmark({
    this.id,
    required this.bookId,
    required this.pageNumber,
    required this.dateCreated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'pageNumber': pageNumber,
      'dateCreated': dateCreated.millisecondsSinceEpoch,
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['id'],
      bookId: map['bookId'],
      pageNumber: map['pageNumber'],
      dateCreated: DateTime.fromMillisecondsSinceEpoch(map['dateCreated']),
    );
  }
}