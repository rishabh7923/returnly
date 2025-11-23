import 'package:flutter/material.dart';
import 'package:libraryapp/screens/home/home_screen.dart';
import 'package:libraryapp/screens/home/all_books_screen.dart';
import 'package:libraryapp/screens/scan/scan_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const SizedBox.shrink(); 
      case 2:
        return const AllBooksScreen();
      default:
        return const HomeScreen();
    }
  }

  void _handleNavigation(int index) async {
    if (index == 1) {
      // Open scanner in a new full screen without changing the selected tab
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ScanScreen(),
          fullscreenDialog: true,
        ),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(_currentIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: _handleNavigation,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              label: 'Books',
            ),
          ],
        ),
      ),
    );
  }
}
