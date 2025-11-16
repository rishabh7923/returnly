class OpenLibraryItem {
  String title;
  String author;

  int? cover_i;
  String? rating;
  String? pages;
  String? publishYear;
  String? description;

  OpenLibraryItem({
    required this.title,
    required this.author,
    this.cover_i,
    this.rating,
    this.pages,
    this.publishYear,
    this.description,
  });

  OpenLibraryItem.fromJson(Map<String, dynamic> json)
      : title = json['docs'][0]['title'],
        author = json['docs'][0]['author_name'][0],
        rating = json['docs'][0]['ratings_average'] != null
            ? (json['docs'][0]['ratings_average'] as num).toStringAsFixed(1)
            : null,
        cover_i = json['docs'][0]['cover_i'],
        pages = json['docs'][0]['number_of_pages_median']?.toString(),
        publishYear = json['docs'][0]['first_publish_year']?.toString(),
        description = json['docs'][0]['first_sentence'] != null && json['docs'][0]['first_sentence'].isNotEmpty
            ? json['docs'][0]['first_sentence'][0]
            : null;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'rating': rating,
      'pages': pages,
      'publish_year': publishYear,
      'cover_i': cover_i,
      'description': description,
    };
  }
}