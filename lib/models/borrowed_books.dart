import 'package:hive_flutter/hive_flutter.dart';
part 'borrowed_books.g.dart';

@HiveType(typeId: 0)
class BorrowedBooks {
  @HiveField(0)
  String upc;

  @HiveField(1)
  String title;
  
  @HiveField(2)
  String author;
  
  @HiveField(3)
  int? cover_i;

  @HiveField(4)
  String? rating;
  
  @HiveField(5)
  String? pages;

  @HiveField(6)
  String? publishYear;

  @HiveField(7)
  DateTime? borrowedDate;
  
  @HiveField(8)
  DateTime? returnDate;
  
  @HiveField(9)
  double finePerDay;

  @HiveField(10)
  String? description;

  @HiveField(11)
  String? borrowerName;

  @HiveField(12)
  String? customImagePath;

  BorrowedBooks({
    required this.upc,
    required this.title,
    required this.author,
    required this.borrowedDate,
    required this.returnDate,
    this.finePerDay = 0.0,
    this.rating,
    this.pages,
    this.publishYear,
    this.cover_i,
    this.description,
    this.borrowerName,
    this.customImagePath,
  });

  String timeLeftBeforeReturn() {
    final now = DateTime.now();
    final difference = returnDate?.difference(now);
    if (difference == null) return "0D 0H";

    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    
    return "${days}D ${hours}H";
  }

  calculateReturnProgress() {
    // Handle null cases
    if (borrowedDate == null || returnDate == null) {
      return 0.0;
    }

    final now = DateTime.now();
    final totalDuration = returnDate!.difference(borrowedDate!);
    final elapsedDuration = now.difference(borrowedDate!);

    // Handle invalid duration
    if (totalDuration.inSeconds <= 0) {
      return 0.0;
    }

    // Calculate and clamp between 0.0 and 1.0
    final progress = elapsedDuration.inSeconds / totalDuration.inSeconds;
    return progress.clamp(0.0, 1.0);
  }
}
