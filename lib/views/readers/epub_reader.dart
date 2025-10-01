import 'package:flutter/material.dart';
import 'package:book_reader/models/book.dart';

class EpubReader extends StatelessWidget {
  final Book currentBook;
  final PageController pageController;
  final String epubContent;
  final bool isLoadingEpub;
  final ValueChanged<int> onPageChanged;

  const EpubReader({
    super.key,
    required this.currentBook,
    required this.pageController,
    required this.epubContent,
    required this.isLoadingEpub,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingEpub) {
      return const Center(child: CircularProgressIndicator());
    }
    return PageView.builder(
      controller: pageController,
      itemCount: currentBook.totalPages,
      onPageChanged: onPageChanged,
      itemBuilder: (context, pageIndex) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            epubContent,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        );
      },
    );
  }
}
