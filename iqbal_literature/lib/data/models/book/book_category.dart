class BookCategory {
  final int id;
  final String name;
  final String nameUrdu;
  final String description;
  final String descriptionUrdu;
  final String icon;
  final int booksCount;

  BookCategory({
    required this.id,
    required this.name,
    required this.nameUrdu,
    required this.description,
    required this.descriptionUrdu,
    required this.icon,
    required this.booksCount,
  });

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    return BookCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      nameUrdu: json['name_urdu'] as String,
      description: json['description'] as String,
      descriptionUrdu: json['description_urdu'] as String,
      icon: json['icon'] as String,
      booksCount: json['books_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_urdu': nameUrdu,
      'description': description,
      'description_urdu': descriptionUrdu,
      'icon': icon,
      'books_count': booksCount,
    };
  }
}
