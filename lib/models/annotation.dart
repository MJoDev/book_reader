class Annotation {
  final int? id;
  final int bookId;
  final int pageNumber;
  final String selectedText;
  final String note;
  final DateTime dateCreated;
  final int startOffset;
  final int endOffset;

  Annotation({
    this.id,
    required this.bookId,
    required this.pageNumber,
    required this.selectedText,
    required this.note,
    required this.dateCreated,
    required this.startOffset,
    required this.endOffset,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'pageNumber': pageNumber,
      'selectedText': selectedText,
      'note': note,
      'dateCreated': dateCreated.millisecondsSinceEpoch,
      'startOffset': startOffset,
      'endOffset': endOffset,
    };
  }

  factory Annotation.fromMap(Map<String, dynamic> map) {
    return Annotation(
      id: map['id'],
      bookId: map['bookId'],
      pageNumber: map['pageNumber'],
      selectedText: map['selectedText'],
      note: map['note'],
      dateCreated: DateTime.fromMillisecondsSinceEpoch(map['dateCreated']),
      startOffset: map['startOffset'],
      endOffset: map['endOffset'],
    );
  }
}