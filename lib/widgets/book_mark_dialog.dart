import 'package:flutter/material.dart';
import 'package:book_reader/models/book_mark.dart';

class BookmarksDialog extends StatelessWidget {
  final List<Bookmark> bookmarks;
  final Function(Bookmark) onBookmarkSelected;
  final Function(Bookmark) onBookmarkDeleted;

  const BookmarksDialog({
    super.key,
    required this.bookmarks,
    required this.onBookmarkSelected,
    required this.onBookmarkDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bookmarks'),
      content: bookmarks.isEmpty
          ? const Center(
              child: Text('No bookmarks yet'),
            )
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = bookmarks[index];
                  return ListTile(
                    leading: const Icon(Icons.bookmark),
                    title: Text('Page ${bookmark.pageNumber}'),
                    subtitle: Text(
                      'Created: ${_formatDate(bookmark.dateCreated)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onBookmarkDeleted(bookmark),
                    ),
                    onTap: () => onBookmarkSelected(bookmark),
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}