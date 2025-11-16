import 'package:flutter/material.dart';

class BookCoverPlaceholder extends StatelessWidget {
  final double height;
  final double width;

  const BookCoverPlaceholder({
    super.key,
    this.height = 150,
    this.width = 90,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.grey[200],
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      height: height,
      width: width,
      child: const Icon(
        Icons.menu_book_rounded,
        color: Colors.grey,
        size: 40,
      ),
      
    );
  }
}