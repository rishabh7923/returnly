import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:libraryapp/models/borrowed_books.dart';
import 'package:libraryapp/screens/home/widgets/book_card.dart';
import 'package:libraryapp/screens/scan/scan_screen.dart';
import 'package:libraryapp/screens/book/book_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final borrowedBooksBox = Hive.box<BorrowedBooks>('borrowedBooks');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        shadowColor: const Color(0xFF5D4E37).withOpacity(0.1),
        toolbarHeight: 80,
        title: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFF9E9E9E), // Grey
              backgroundImage:
                  Image.network(
                    'https://avatars.githubusercontent.com/u/57840201?v=4',
                  ).image,
            ),
            const SizedBox(width: 20), // Replace spacing parameter

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RISHABH YADAV',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5), // Replace spacing parameter
                ValueListenableBuilder(
                  valueListenable: borrowedBooksBox.listenable(),
                  builder: (context, Box box, _) {
                    return Text(
                      '${box.length} books borrowed',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF424242)), // Dark grey
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            color: const Color(0xFF424242), // Dark grey
            iconSize: 30,
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ScanScreen()),
              );
            },
          ),
        ],
      ),

      body: ValueListenableBuilder(
        valueListenable: borrowedBooksBox.listenable(),
        builder: (context, box, _) {
          final books = box.values.toList();
          
          final keys = box.keys.toList(); // Get keys for navigation
            
          if (books.isEmpty) {
            return const Center(child: Text('No books borrowed'));
          }
            
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final key = keys[index];
            
              return BookCard(
                book: book,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BookDetailScreen(book: book, bookKey: key),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
