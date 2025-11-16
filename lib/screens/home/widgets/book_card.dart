import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:libraryapp/models/borrowed_books.dart';
import 'package:libraryapp/screens/home/widgets/attribute_chip.dart';
import 'package:libraryapp/widgets/book_cover_placeholder.dart';

class BookCard extends StatelessWidget {
  final BorrowedBooks book;
  final VoidCallback? onTap;

  const BookCard({super.key, required this.book, this.onTap});

  @override
  Widget build(BuildContext context) {
    final rawProgress = book.calculateReturnProgress();
    double progress = 1.0; // Default to full bar if no data

    if (rawProgress is num) {
      final elapsed = rawProgress.toDouble();
      progress = elapsed;
    }

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: book.customImagePath != null
                  ? Image.file(
                      File(book.customImagePath!),
                      height: 130,
                      width: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          const BookCoverPlaceholder(height: 130, width: 90),
                    )
                  : (book.cover_i != null)
                      ? CachedNetworkImage(
                          imageUrl:
                              'https://covers.openlibrary.org/b/id/${book.cover_i}-M.jpg',
                          height: 130,
                          width: 90,
                          fit: BoxFit.cover,
                          errorWidget:
                              (context, url, error) =>
                                  const BookCoverPlaceholder(height: 130, width: 90),
                        )
                      : const BookCoverPlaceholder(height: 130, width: 90),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: SizedBox(
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book details at the top
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          book.author,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // Book details row
                      ],
                    ),

                    Column(
                      spacing: 10,
                      children: [
                        Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            final daysLate =
                                (book.returnDate != null &&
                                        now.isAfter(book.returnDate!))
                                    ? now.difference(book.returnDate!).inDays
                                    : 0;
                            final fineAmount = daysLate * book.finePerDay;

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    AttributeChip(
                                      attribute: book.rating ?? 'N/A',
                                      icon: Icons.star,
                                    ),
                                    AttributeChip(
                                      attribute: book.pages ?? 'N/A',
                                      icon: Icons.pages,
                                    ),
                                    AttributeChip(
                                      attribute: book.publishYear ?? 'N/A',
                                      icon: Icons.publish_rounded,
                                    ),
                                    AttributeChip(
                                      attribute: book.timeLeftBeforeReturn(),
                                      icon: Icons.access_time,
                                    ),
                                    if (daysLate > 0)
                                      AttributeChip(
                                        attribute:
                                            '${fineAmount.toStringAsFixed(2)}',
                                        icon: Icons.payments,
                                      ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                LinearProgressIndicator(
                                  minHeight: 5,
                                  value: progress,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey,
                                  ),
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
