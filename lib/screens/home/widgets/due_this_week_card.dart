import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:libraryapp/models/borrowed_books.dart';
import 'package:libraryapp/screens/book/book_detail_screen.dart';
import 'package:libraryapp/widgets/book_cover_placeholder.dart';

class DueThisWeekCard extends StatelessWidget {
  final List<BorrowedBooks> books;
  final VoidCallback? onTap;

  const DueThisWeekCard({super.key, required this.books, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 150,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // LEFT SIDE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${books.length} book${books.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                backgroundColor: Colors.yellow.shade200,
                              ),
                            ),
                            const TextSpan(text: ' due this week'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // SUBTITLE
                      Text(
                        'Return soon to avoid fines',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),

                const SizedBox(width: 12),
                _StackedCovers(books: books),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StackedCovers extends StatelessWidget {
  final List<BorrowedBooks> books;
  const _StackedCovers({required this.books});

  @override
  Widget build(BuildContext context) {
    // Limit to 3 books for visual clarity
    final displayBooks = books.take(3).toList();

    // Fixed positions for each book slot (back to front, largest at front)
    final bookPositions = [
      {
        'left': 80.0,
        'top': 40.0,
        'width': 70.0,
        'height': 115.0,
      }, // Back book (smallest)
      {
        'left': 40.0,
        'top': 25.0,
        'width': 85.0,
        'height': 128.0,
      }, // Middle book
      {
        'left': 10.0,
        'top': 5.0,
        'width': 90.0,
        'height': 135.0,
      }, // Front book (largest)
    ];

    return SizedBox(
      width: 150,
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(displayBooks.length, (index) {
          final reverseIndex = displayBooks.length - 1 - index;
          final position = bookPositions[2 - reverseIndex];
          return Positioned(
            left: position['left'],
            top: position['top'],
            child: _Cover(
              imagePath: displayBooks[reverseIndex].customImagePath,
              coverId: displayBooks[reverseIndex].cover_i,
              width: position['width']!,
              height: position['height']!,
            ),
          );
        }),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final String? imagePath;
  final int? coverId;
  final double width;
  final double height;

  const _Cover({
    this.imagePath,
    this.coverId,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget img;

    if (imagePath != null) {
      img = Image.file(
        File(imagePath!),
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else if (coverId != null) {
      img = CachedNetworkImage(
        imageUrl: "https://covers.openlibrary.org/b/id/$coverId-M.jpg",
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    } else {
      img = BookCoverPlaceholder(width: width, height: height);
    }

    return ClipRRect(borderRadius: BorderRadius.circular(8), child: img);
  }
}

class DueThisWeekSection extends StatelessWidget {
  final List<Map<String, dynamic>> bookEntries;
  final List<BorrowedBooks> booksReturningThisWeek;
  final BuildContext parentContext;

  const DueThisWeekSection({
    super.key,
    required this.bookEntries,
    required this.booksReturningThisWeek,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    if (booksReturningThisWeek.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          DueThisWeekCard(
            books: booksReturningThisWeek,
            onTap: () {
              final entry = bookEntries.firstWhere(
                (e) => e['book'] == booksReturningThisWeek[0],
              );
              Navigator.push(
                parentContext,
                MaterialPageRoute(
                  builder:
                      (context) => BookDetailScreen(
                        book: booksReturningThisWeek[0],
                        bookKey: entry['key'],
                      ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
