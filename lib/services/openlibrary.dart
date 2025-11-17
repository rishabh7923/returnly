import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:libraryapp/models/open_library_item.dart';

class Openlibrary {
  static Future<OpenLibraryItem> search(String upc) async {
    final url = 'https://openlibrary.org/search.json?isbn=$upc&fields=*,availability&limit=1';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      return OpenLibraryItem.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch item data');
    }
  }
}