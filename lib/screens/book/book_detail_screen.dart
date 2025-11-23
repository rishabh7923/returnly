import 'dart:io';
import 'dart:async';
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every second to show real-time countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
              'Are you sure you want to mark "${widget.book.title}" as returned?',
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
      widget.book.isReturned = true;
      widget.book.returnDate = DateTime.now();
      await borrowedBooksBox.put(widget.bookKey, widget.book);

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
    
    // Calculate total fine so far
    double calculateTotalFine() {
      if (book.borrowedDate == null || book.returnDate == null) return 0.0;
      final now = DateTime.now();
      if (now.isBefore(book.returnDate!)) return 0.0; // No fine if not overdue
      final overdueDays = now.difference(book.returnDate!).inDays;
      return overdueDays * book.finePerDay;
    }
    
    final totalFine = calculateTotalFine();

    return Scaffold(
      appBar: AppBar(
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
              if (mounted) {
                setState(() {});
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Section: Cover (Left) + Info (Right)
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Book Cover (Left)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: book.customImagePath != null
                                    ? Image.file(
                                        File(book.customImagePath!),
                                        height: 160,
                                        width: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const BookCoverPlaceholder(
                                              height: 160,
                                              width: 120,
                                            ),
                                      )
                                    : coverId != null
                                        ? CachedNetworkImage(
                                          imageUrl:
                                              'https://covers.openlibrary.org/b/id/$coverId-L.jpg',
                                          height: 160,
                                          width: 120,
                                          fit: BoxFit.cover,
                                          errorWidget:
                                              (context, url, error) =>
                                                  const BookCoverPlaceholder(
                                                    height: 160,
                                                    width: 120,
                                                  ),
                                        )
                                        : const BookCoverPlaceholder(
                                          height: 160,
                                          width: 120,
                                        ),
                              ),

                          const SizedBox(width: 15),

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
                                Text(
                                  book.author,
                                  style: Theme.of(context).textTheme.titleSmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),

                                // Star Rating Display
                                if (book.rating != null)
                                  Row(
                                    children: [
                                      ...List.generate(5, (index) {
                                        final rating = double.tryParse(book.rating!) ?? 0.0;
                                        if (index < rating.floor()) {
                                          return const Icon(
                                            Icons.star,
                                            color: Colors.orange,
                                            size: 18,
                                          );
                                        } else if (index < rating) {
                                          return const Icon(
                                            Icons.star_half,
                                            color: Colors.orange,
                                            size: 18,
                                          );
                                        } else {
                                          return const Icon(
                                            Icons.star_border,
                                            color: Colors.orange,
                                            size: 18,
                                          );
                                        }
                                      }),
                                      const SizedBox(width: 6),
                                      Text(
                                        book.rating!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 12),

                                // Book Details (Pages, Year, ISBN)
                                if (book.pages != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.menu_book,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Pages: ${book.pages}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                if (book.publishYear != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Published: ${book.publishYear}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                
                                if (book.upc.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.qr_code,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'ISBN: ${book.upc}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Toggle buttons - full width
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  // This represents "Not Returned" - current state
                                },
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  bottomLeft: Radius.circular(7),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(7),
                                      bottomLeft: Radius.circular(7),
                                    ),
                                    border: Border.all(
                                      color: Colors.orange.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.book,
                                        size: 18,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Not Returned',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: _markAsReturned,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(7),
                                  bottomRight: Radius.circular(7),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(7),
                                      bottomRight: Radius.circular(7),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Returned',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Borrowing Details
              Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              // Borrower Name and Total Fine - side by side
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Borrower Name (if available)
                                    if (book.borrowerName != null && book.borrowerName!.isNotEmpty)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                size: 18,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Borrowed From',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    book.borrowerName!,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    // Total Fine
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: totalFine > 0 ? Colors.red.shade50 : Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.warning_amber,
                                            size: 18,
                                            color: totalFine > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Fine',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              totalFine > 0 ? '₹${totalFine.toStringAsFixed(2)}' : '₹0.00',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: totalFine > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          
                          // Dates and Fine
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Borrowed At',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(book.borrowedDate),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.attach_money,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Fine',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${book.finePerDay.toStringAsFixed(2)}/day',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.event,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Due On',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(book.returnDate),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Progress bar attached to bottom
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress > 0.8
                                ? Colors.red
                                : progress > 0.5
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Time left below progress bar
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          book.timeLeftBeforeReturn(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notes (if available)
                  if (book.notes != null &&
                      book.notes!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.note,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Notes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                book.notes!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
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
