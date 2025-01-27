import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id; // Changed from int to String
  final String name;
  final String email;
  final String? profileImage;
  final List<int> favoriteBooks; // Changed from List<String> to List<int>
  final List<String> favoritePoems; // Changed from int to String
  final DateTime lastLoginAt;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.favoriteBooks = const [],
    this.favoritePoems = const [],
    required this.lastLoginAt,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    List<int>? favoriteBooks,
    List<String>? favoritePoems,
    DateTime? lastLoginAt,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      favoriteBooks: favoriteBooks ?? this.favoriteBooks,
      favoritePoems: favoritePoems ?? this.favoritePoems,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      name: data['name'] as String,
      email: data['email'] as String,
      profileImage: data['profile_image'] as String?,
      favoriteBooks: List<int>.from(data['favorite_books'] ?? []),
      favoritePoems: List<String>.from(data['favorite_poems'] ?? []),
      lastLoginAt: (data['last_login_at'] as Timestamp).toDate(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'].toString(),
    name: json['name'] as String,
    email: json['email'] as String,
    profileImage: json['profile_image'] as String?,
    favoriteBooks: List<int>.from(json['favorite_books'] ?? []),
    favoritePoems: List<String>.from(json['favorite_poems'] ?? []),
    lastLoginAt: DateTime.parse(json['last_login_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'profile_image': profileImage,
    'favorite_books': favoriteBooks,
    'favorite_poems': favoritePoems,
    'last_login_at': lastLoginAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'profile_image': profileImage,
    'favorite_books': favoriteBooks,
    'favorite_poems': favoritePoems,
    'last_login_at': Timestamp.fromDate(lastLoginAt),
    'created_at': Timestamp.fromDate(createdAt),
  };
}
