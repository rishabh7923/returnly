import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:libraryapp/models/borrowed_books.dart';
import 'package:libraryapp/models/open_library_item.dart';
import 'package:libraryapp/services/openlibrary.dart';
import 'package:libraryapp/widgets/book_cover_placeholder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:libraryapp/screens/main_screen.dart';

class AddBookScreen extends StatefulWidget {
  final String? upc;
  final BorrowedBooks? existingBook;
  final dynamic bookKey;

  const AddBookScreen({super.key, this.upc, this.existingBook, this.bookKey})
    : assert(
        upc != null || existingBook != null,
        'Either upc or existingBook must be provided',
      );

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final borrowedBooksBox = Hive.box<BorrowedBooks>('borrowedBooks');

  // Make bookDetails nullable
  OpenLibraryItem? bookDetails;
  bool isLoading = true;
  String? customImagePath;
  final ImagePicker _picker = ImagePicker();

  // Create persistent controllers
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final upcController = TextEditingController();
  final borrowerController = TextEditingController();
  final notesController = TextEditingController();
  final borrowedDateController = TextEditingController();
  final returnDateController = TextEditingController();
  final ratingController = TextEditingController();
  final pagesController = TextEditingController();
  final publishYearController = TextEditingController();
  final fineController = TextEditingController(text: '0.0');
  final defaultReturnDate = DateTime.now().add(const Duration(days: 28));

  @override
  void initState() {
    super.initState();
    if (widget.existingBook != null) {
      // Edit mode - populate with existing data
      _populateExistingBookData();
    } else {
      // Add mode - fetch from API
      extractBookDetailsFromUPC();
    }
  }

  void _populateExistingBookData() {
    final book = widget.existingBook!;
    setState(() {
      upcController.text = book.upc;
      titleController.text = book.title;
      authorController.text = book.author;
      borrowerController.text = book.borrowerName ?? '';
      notesController.text = book.notes ?? '';
      ratingController.text = book.rating ?? '';
      pagesController.text = book.pages ?? '';
      publishYearController.text = book.publishYear ?? '';

      if (book.borrowedDate != null) {
        borrowedDateController.text =
            '${book.borrowedDate!.day}/${book.borrowedDate!.month}/${book.borrowedDate!.year}';
      }

      if (book.returnDate != null) {
        returnDateController.text =
            '${book.returnDate!.day}/${book.returnDate!.month}/${book.returnDate!.year}';
      }

      fineController.text = book.finePerDay.toString();
      customImagePath = book.customImagePath;
      isLoading = false;
    });
  }

  void extractBookDetailsFromUPC() async {
    if (widget.upc == null) return;

    try {
      // Set loading state
      setState(() {
        isLoading = true;
      });

      // Fetch book details
      bookDetails = await Openlibrary.search(widget.upc!);

      if (bookDetails != null) {
        setState(() {
          upcController.text = widget.upc!;
          titleController.text = bookDetails!.title;
          authorController.text = bookDetails!.author;
          ratingController.text = bookDetails?.rating ?? '';
          pagesController.text = bookDetails?.pages ?? '';
          publishYearController.text = bookDetails?.publishYear ?? '';

          final now = DateTime.now();
          borrowedDateController.text = '${now.day}/${now.month}/${now.year}';
          returnDateController.text =
              '${defaultReturnDate.day}/${defaultReturnDate.month}/${defaultReturnDate.year}';

          notesController.text = bookDetails?.description ?? '';

          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching book details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    upcController.dispose();
    borrowerController.dispose();
    notesController.dispose();
    borrowedDateController.dispose();
    returnDateController.dispose();
    ratingController.dispose();
    pagesController.dispose();
    publishYearController.dispose();
    fineController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.5),
                    Theme.of(context).primaryColor.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'book_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final savedImage = await File(
          image.path,
        ).copy('${directory.path}/$fileName');

        setState(() {
          customImagePath = savedImage.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'book_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final savedImage = await File(
          image.path,
        ).copy('${directory.path}/$fileName');

        setState(() {
          customImagePath = savedImage.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Choose Book Cover',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: const Text('Gallery'),
                  subtitle: const Text('Choose from your photos'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: const Text('Camera'),
                  subtitle: const Text('Take a new photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                if (customImagePath != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    title: const Text('Remove Custom Image'),
                    subtitle: const Text('Use default cover'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        customImagePath = null;
                      });
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
    );
  }

  InputDecoration _buildInputDecoration(
    String label, {
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.grey.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      labelStyle: const TextStyle(fontSize: 13),
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingBook != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Book' : 'Add Book')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Main content in a scrollable container
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: _showImageSourceDialog,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child:
                                              customImagePath != null
                                                  ? Image.file(
                                                    File(customImagePath!),
                                                    height: 120,
                                                    width: 85,
                                                    fit: BoxFit.cover,
                                                  )
                                                  : (bookDetails?.cover_i ??
                                                          widget
                                                              .existingBook
                                                              ?.cover_i) !=
                                                      null
                                                  ? Image.network(
                                                    'https://covers.openlibrary.org/b/id/${bookDetails?.cover_i ?? widget.existingBook!.cover_i}-M.jpg',
                                                    height: 120,
                                                    width: 85,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (ctx, err, stack) =>
                                                            const BookCoverPlaceholder(
                                                              height: 120,
                                                              width: 85,
                                                            ),
                                                  )
                                                  : const BookCoverPlaceholder(
                                                    height: 120,
                                                    width: 85,
                                                  ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).primaryColor,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(8),
                                                  bottomRight: Radius.circular(
                                                    10,
                                                  ),
                                                ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: titleController,
                                        decoration: _buildInputDecoration(
                                          'Title',
                                          prefixIcon: const Icon(
                                            Icons.book,
                                            size: 18,
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: authorController,
                                        decoration: _buildInputDecoration(
                                          'Author',
                                          prefixIcon: const Icon(
                                            Icons.person,
                                            size: 18,
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            TextField(
                              controller: upcController,
                              decoration: _buildInputDecoration(
                                'ISBN / UPC',
                                prefixIcon: const Icon(Icons.qr_code, size: 18),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),

                            const SizedBox(height: 20),

                            // ===== BORROWER DETAILS SECTION =====
                            _buildSectionHeader('Borrower Details'),
                            const SizedBox(height: 12),
                            TextField(
                              controller: borrowerController,
                              decoration: _buildInputDecoration(
                                'Borrowed from',
                                hint: 'Enter person name',
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  size: 18,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),

                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: borrowedDateController,
                                    readOnly: true,
                                    decoration: _buildInputDecoration(
                                      'Borrowed Date',
                                      prefixIcon: const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                    onTap: () async {
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime.now(),
                                          );

                                      if (pickedDate != null) {
                                        setState(() {
                                          borrowedDateController.text =
                                              '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: returnDateController,
                                    readOnly: true,
                                    decoration: _buildInputDecoration(
                                      'Return Date',
                                      prefixIcon: const Icon(
                                        Icons.event_available,
                                        size: 16,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                    onTap: () async {
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                            context: context,
                                            initialDate: defaultReturnDate,
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(2100),
                                          );

                                      if (pickedDate != null) {
                                        setState(() {
                                          returnDateController.text =
                                              '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            TextField(
                              controller: fineController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _buildInputDecoration(
                                'Fine per day',
                                hint: 'e.g. 5.0',
                                prefixIcon: const Icon(
                                  Icons.attach_money,
                                  size: 18,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),

                            const SizedBox(height: 20),

                            // ===== BOOK METADATA SECTION =====
                            _buildSectionHeader('Book Details'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: ratingController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: _buildInputDecoration(
                                      'Rating',
                                      hint: '4.5',
                                      prefixIcon: const Icon(
                                        Icons.star_outline,
                                        size: 18,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: pagesController,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration(
                                      'Pages',
                                      hint: '320',
                                      prefixIcon: const Icon(
                                        Icons.menu_book,
                                        size: 18,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: publishYearController,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration(
                                      'Year',
                                      hint: '2020',
                                      prefixIcon: const Icon(
                                        Icons.date_range,
                                        size: 18,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // ===== NOTES SECTION =====
                            _buildSectionHeader('Notes'),
                            const SizedBox(height: 10),
                            TextField(
                              controller: notesController,
                              decoration: _buildInputDecoration(
                                'Additional notes',
                                hint:
                                    'Any additional information about the book',
                                prefixIcon: const Icon(
                                  Icons.note_outlined,
                                  size: 18,
                                ),
                              ),
                              style: const TextStyle(fontSize: 14),
                              maxLines: 3,
                              minLines: 2,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Button fixed at bottom
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          (isEditMode || bookDetails != null)
                              ? () async {
                                // Parse borrowed date
                                DateTime? borrowedDate;
                                if (borrowedDateController.text.isNotEmpty) {
                                  final borrowedParts = borrowedDateController
                                      .text
                                      .split('/');
                                  borrowedDate = DateTime(
                                    int.parse(borrowedParts[2]),
                                    int.parse(borrowedParts[1]),
                                    int.parse(borrowedParts[0]),
                                  );
                                }

                                // Parse the return date from controller text
                                final dateParts = returnDateController.text
                                    .split('/');
                                final day = int.parse(dateParts[0]);
                                final month = int.parse(dateParts[1]);
                                final year = int.parse(dateParts[2]);
                                final returnDate = DateTime(year, month, day);

                                final parsedFine =
                                    double.tryParse(fineController.text) ?? 0.0;

                                if (isEditMode) {
                                  // Update existing book
                                  final book = widget.existingBook!;
                                  book.upc = upcController.text;
                                  book.title = titleController.text;
                                  book.author = authorController.text;
                                  book.borrowedDate = borrowedDate;
                                  book.returnDate = returnDate;
                                  book.finePerDay = parsedFine;
                                  book.rating =
                                      ratingController.text.isNotEmpty
                                          ? ratingController.text
                                          : null;
                                  book.pages =
                                      pagesController.text.isNotEmpty
                                          ? pagesController.text
                                          : null;
                                  book.publishYear =
                                      publishYearController.text.isNotEmpty
                                          ? publishYearController.text
                                          : null;
                                  book.notes = notesController.text;
                                  book.borrowerName =
                                      borrowerController.text.isNotEmpty
                                          ? borrowerController.text
                                          : null;
                                  book.customImagePath = customImagePath;

                                  await borrowedBooksBox.put(
                                    widget.bookKey,
                                    book,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Book updated successfully',
                                      ),
                                    ),
                                  );
                                } else {
                                  // Add new book
                                  await borrowedBooksBox.add(
                                    BorrowedBooks(
                                      upc:
                                          upcController.text.isNotEmpty
                                              ? upcController.text
                                              : widget.upc!,
                                      title: titleController.text,
                                      author: authorController.text,
                                      rating:
                                          ratingController.text.isNotEmpty
                                              ? ratingController.text
                                              : (bookDetails?.rating ?? '0'),
                                      cover_i: bookDetails?.cover_i,
                                      pages:
                                          pagesController.text.isNotEmpty
                                              ? pagesController.text
                                              : (bookDetails?.pages ?? '0'),
                                      publishYear:
                                          publishYearController.text.isNotEmpty
                                              ? publishYearController.text
                                              : (bookDetails?.publishYear ??
                                                  'N/A'),
                                      borrowedDate:
                                          borrowedDate ?? DateTime.now(),
                                      returnDate: returnDate,
                                      finePerDay: parsedFine,
                                      notes:
                                          notesController.text.isNotEmpty
                                              ? notesController.text
                                              : bookDetails?.description,
                                      borrowerName:
                                          borrowerController.text.isNotEmpty
                                              ? borrowerController.text
                                              : null,
                                      customImagePath: customImagePath,
                                    ),
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Book added successfully'),
                                    ),
                                  );
                                }

                                // Pop once for AddBookScreen
                                Navigator.pop(context);

                                if (!isEditMode) {
                                  // Pop again only if we are in 'add' mode (from scan screen)
                                  Navigator.pop(context);
                                }

                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const MainScreen(),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isEditMode ? Icons.save : Icons.add, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isEditMode ? 'Save Changes' : 'Add Book',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
