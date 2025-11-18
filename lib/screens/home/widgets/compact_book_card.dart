import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:libraryapp/models/borrowed_books.dart';
import 'package:libraryapp/widgets/book_cover_placeholder.dart';

class CompactBookCard extends StatelessWidget {
  final BorrowedBooks book;
  final VoidCallback? onTap;

  const CompactBookCard({
    super.key,
    required this.book,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover with Status Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.customImagePath != null
                      ? Image.file(
                          File(book.customImagePath!),
                          height: 150,
                          width: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const BookCoverPlaceholder(height: 150, width: 110),
                        )
                      : (book.cover_i != null)
                          ? CachedNetworkImage(
                              imageUrl:
                                  'https://covers.openlibrary.org/b/id/${book.cover_i}-L.jpg',
                              height: 150,
                              width: 110,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const BookCoverPlaceholder(height: 150, width: 110),
                            )
                          : const BookCoverPlaceholder(height: 150, width: 110),
                ),
                if (book.returnDate != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 6),
          
          ],
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
