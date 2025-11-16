import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:libraryapp/models/borrowed_books.dart';
import 'package:libraryapp/screens/addbook/addbook_screen.dart';
import 'package:libraryapp/widgets/book_cover_placeholder.dart';

class BookDetailScreen extends StatefulWidget {
  final BorrowedBooks book;
  final dynamic bookKey;

  const BookDetailScreen({
    super.key,
    required this.book,
    required this.bookKey,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  double _swipeOffset = 0.0;
  static const double _swipeThreshold = 200.0;

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return d.toLocal().toIso8601String().split('T').first;
  }

  void _handleSwipe(DragUpdateDetails details) {
    setState(() {
      _swipeOffset += details.delta.dx;
      // Clamp between 0 and threshold
      _swipeOffset = _swipeOffset.clamp(0.0, _swipeThreshold);
    });
  }

  void _handleSwipeEnd(DragEndDetails details) {
    if (_swipeOffset >= _swipeThreshold) {
      _markAsReturned();
    } else {
      // Snap back
      setState(() {
        _swipeOffset = 0.0;
      });
    }
  }

  Future<void> _markAsReturned() async {
    final borrowedBooksBox = Hive.box<BorrowedBooks>('borrowedBooks');

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Mark as Returned'),
            content: Text(
              'Are you sure you want to mark "${widget.book.title}" as returned? This will remove it from your borrowed books.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await borrowedBooksBox.delete(widget.bookKey);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book marked as returned'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      // Reset swipe
      setState(() {
        _swipeOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final coverId = book.cover_i;
    final dynamic _rawProgress = book.calculateReturnProgress();
    final progress = (_rawProgress is double) ? _rawProgress : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title, overflow: TextOverflow.ellipsis),
        centerTitle: false,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AddBookScreen(
                        existingBook: book,
                        bookKey: widget.bookKey,
                      ),
                ),
              );
              // Refresh the page after returning from edit
              if (context.mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              }
            },
            tooltip: 'Edit Book',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scrollable content with bottom padding for the button
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 100.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Section: Cover (Left) + Info (Right)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Book Cover (Left)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.grey.withOpacity(0.3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: book.customImagePath != null
                              ? Image.file(
                                  File(book.customImagePath!),
                                  height: 240,
                                  width: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const BookCoverPlaceholder(
                                        height: 240,
                                        width: 160,
                                      ),
                                )
                              : coverId != null
                                  ? CachedNetworkImage(
                                    imageUrl:
                                        'https://covers.openlibrary.org/b/id/$coverId-L.jpg',
                                    height: 240,
                                    width: 160,
                                    fit: BoxFit.cover,
                                    errorWidget:
                                        (context, url, error) =>
                                            const BookCoverPlaceholder(
                                              height: 240,
                                              width: 160,
                                            ),
                                  )
                                  : const BookCoverPlaceholder(
                                    height: 240,
                                    width: 160,
                                  ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Book Info (Right)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 8),

                            Text(
                              book.author,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            if ((book.borrowerName ?? '').isNotEmpty)
                              Text(
                                'Borrowed from: ${book.borrowerName}',
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Borrowed'),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDate(book.borrowedDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Return'),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatDate(book.returnDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Fine/day'),
                                  const SizedBox(height: 6),
                                  Text(
                                    '\$${book.finePerDay.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          const Divider(),

                          const SizedBox(height: 8),

                          // ISBN and borrower details
                          if (book.upc.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'ISBN: ${book.upc}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),

                          Text(
                            'Time left: ${book.timeLeftBeforeReturn()}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),

                          LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
