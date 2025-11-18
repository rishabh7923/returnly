import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:libraryapp/models/borrowed_books.dart';
import 'package:libraryapp/widgets/book_cover_placeholder.dart';

class CompactBookCard extends StatelessWidget {
  final BorrowedBooks book;
  final VoidCallback? onTap;

  const CompactBookCard({super.key, required this.book, this.onTap});

  // Image dimensions
  static const double imageWidth = 130.0;
  static const double imageHeight = 130.0;
  static const double cardWidth = 120.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book Cover with Status Badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child:
                          book.customImagePath != null
                              ? Image.file(
                                File(book.customImagePath!),
                                height: imageHeight,
                                width: imageWidth,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const BookCoverPlaceholder(
                                          height: imageHeight,
                                          width: imageWidth,
                                        ),
                              )
                              : (book.cover_i != null)
                              ? CachedNetworkImage(
                                imageUrl:
                                    'https://covers.openlibrary.org/b/id/${book.cover_i}-L.jpg',
                                height: imageHeight,
                                width: imageWidth,
                                fit: BoxFit.cover,
                                errorWidget:
                                    (context, url, error) =>
                                        const BookCoverPlaceholder(
                                          height: imageHeight,
                                          width: imageWidth,
                                        ),
                              )
                              : const BookCoverPlaceholder(
                                height: imageHeight,
                                width: imageWidth,
                              ),
                    ),
                    if (book.returnDate != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(book),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStatusText(book),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Book Title
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Author
                Text(
                  book.author,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BorrowedBooks book) {
    final now = DateTime.now();
    if (book.returnDate!.isBefore(now)) {
      return Colors.red;
    }
    final daysLeft = book.returnDate!.difference(now).inDays;
    if (daysLeft <= 3) {
      return Colors.orange;
    }
    return Colors.green;
  }

  String _getStatusText(BorrowedBooks book) {
    final now = DateTime.now();
    if (book.returnDate!.isBefore(now)) {
      return 'Overdue';
    }
    final daysLeft = book.returnDate!.difference(now).inDays;
    if (daysLeft == 0) {
      return 'Due Today';
    }
    return '${daysLeft}d left';
  }
}
