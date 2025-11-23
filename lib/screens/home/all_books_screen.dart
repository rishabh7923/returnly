import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:libraryapp/models/borrowed_books.dart';
import 'package:libraryapp/screens/book/book_detail_screen.dart';
import 'package:libraryapp/screens/home/widgets/book_card.dart';

class AllBooksScreen extends StatefulWidget {
  const AllBooksScreen({super.key});

  @override
  State<AllBooksScreen> createState() => _AllBooksScreenState();
}

class _AllBooksScreenState extends State<AllBooksScreen> {
  final borrowedBooksBox = Hive.box<BorrowedBooks>('borrowedBooks');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  String _sortBy = 'title'; // title, author, date, dueDate
  bool _showOverdueOnly = false;
  bool _showDueSoon = false;
  bool _showReturnedOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterBooks(List<Map<String, dynamic>> bookEntries) {
    var filtered = bookEntries;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((entry) {
        final book = entry['book'] as BorrowedBooks;
        final query = _searchQuery.toLowerCase();
        return book.title.toLowerCase().contains(query) ||
               book.author.toLowerCase().contains(query);
      }).toList();
    }

    // Apply overdue filter
    if (_showOverdueOnly) {
      filtered = filtered.where((entry) {
        final book = entry['book'] as BorrowedBooks;
        if (book.returnDate == null) return false;
        return book.returnDate!.isBefore(DateTime.now());
      }).toList();
    }

    // Apply due soon filter (within 7 days)
    if (_showDueSoon) {
      filtered = filtered.where((entry) {
        final book = entry['book'] as BorrowedBooks;
        if (book.returnDate == null) return false;
        final daysUntilDue = book.returnDate!.difference(DateTime.now()).inDays;
        return daysUntilDue >= 0 && daysUntilDue <= 7;
      }).toList();
    }

    // Apply returned books filter
    if (_showReturnedOnly) {
      filtered = filtered.where((entry) {
        final book = entry['book'] as BorrowedBooks;
        return book.isReturned == true;
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      final bookA = a['book'] as BorrowedBooks;
      final bookB = b['book'] as BorrowedBooks;

      switch (_sortBy) {
        case 'author':
          return bookA.author.toLowerCase().compareTo(bookB.author.toLowerCase());
        case 'date':
          return (bookB.borrowedDate ?? DateTime.now()).compareTo(bookA.borrowedDate ?? DateTime.now());
        case 'dueDate':
          if (bookA.returnDate == null && bookB.returnDate == null) return 0;
          if (bookA.returnDate == null) return 1;
          if (bookB.returnDate == null) return -1;
          return bookA.returnDate!.compareTo(bookB.returnDate!);
        case 'title':
        default:
          return bookA.title.toLowerCase().compareTo(bookB.title.toLowerCase());
      }
    });

    return filtered;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters & Sort',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _sortBy = 'title';
                            _showOverdueOnly = false;
                            _showDueSoon = false;
                            _showReturnedOnly = false;
                          });
                          setState(() {});
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Sort By',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Title'),
                        selected: _sortBy == 'title',
                        onSelected: (selected) {
                          setModalState(() => _sortBy = 'title');
                          setState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Author'),
                        selected: _sortBy == 'author',
                        onSelected: (selected) {
                          setModalState(() => _sortBy = 'author');
                          setState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Date Added'),
                        selected: _sortBy == 'date',
                        onSelected: (selected) {
                          setModalState(() => _sortBy = 'date');
                          setState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Due Date'),
                        selected: _sortBy == 'dueDate',
                        onSelected: (selected) {
                          setModalState(() => _sortBy = 'dueDate');
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  CheckboxListTile(
                    title: const Text('Overdue Books'),
                    value: _showOverdueOnly,
                    onChanged: (value) {
                      setModalState(() => _showOverdueOnly = value ?? false);
                      setState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Due Soon (Within 7 days)'),
                    value: _showDueSoon,
                    onChanged: (value) {
                      setModalState(() => _showDueSoon = value ?? false);
                      setState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Returned Books'),
                    value: _showReturnedOnly,
                    onChanged: (value) {
                      setModalState(() => _showReturnedOnly = value ?? false);
                      setState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Search by title or author...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              )
            : const Text(
                'All Books',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterBottomSheet,
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Books List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: borrowedBooksBox.listenable(),
              builder: (context, box, _) {
                final bookEntries = box.keys.map((key) {
                  final book = box.get(key);
                  return {'key': key, 'book': book};
                }).where((entry) {
                  if (entry['book'] == null) return false;
                  final book = entry['book'] as BorrowedBooks;
                  // Only filter out returned books if not explicitly showing them
                  if (!_showReturnedOnly && book.isReturned) return false;
                  return true;
                }).toList();

                final filteredBooks = _filterBooks(bookEntries);

                if (bookEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No books borrowed yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredBooks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No books found',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredBooks.length,
                  itemBuilder: (context, index) {
                    final entry = filteredBooks[index];
                    final book = entry['book'] as BorrowedBooks;
                    final key = entry['key'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: BookCard(
                        book: book,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailScreen(
                                book: book,
                                bookKey: key,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
