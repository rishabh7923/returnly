import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:libraryapp/models/borrowed_books.dart';
import 'package:libraryapp/screens/book/book_detail_screen.dart';
import 'package:libraryapp/screens/home/widgets/book_card.dart';

class AllBooksScreen extends StatelessWidget {
  const AllBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final borrowedBooksBox = Hive.box<BorrowedBooks>('borrowedBooks');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Books',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ValueListenableBuilder(
        valueListenable: borrowedBooksBox.listenable(),
        builder: (context, box, _) {
          final bookEntries = box.keys.map((key) {
            final book = box.get(key);
            return {'key': key, 'book': book};
          }).where((entry) => 
            entry['book'] != null && 
            !(entry['book'] as BorrowedBooks).isReturned
          ).toList();

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

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: bookEntries.length,
            itemBuilder: (context, index) {
              final entry = bookEntries[index];
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
    );
  }
}
