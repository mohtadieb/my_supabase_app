/*
POST MODEL (Supabase Version)

This defines what every post should have, adapted for Supabase.
*/

class Post {
  final String id;
  final String uid;
  final String name;
  final String username;
  final String message;
  final DateTime createdAt;
  final int likeCount;
  final List<String> likedBy;

  Post({
    required this.id,
    required this.uid,
    required this.name,
    required this.username,
    required this.message,
    required this.createdAt,
    required this.likeCount,
    required this.likedBy,
  });

  // Supabase -> App
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'].toString(),
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      message: map['message'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      likeCount: map['like_count'] ?? 0,
      likedBy: (map['liked_by'] is List)
          ? List<String>.from(map['liked_by'])
          : [],
    );
  }

  // App -> Supabase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      'liked_by': likedBy,
    };
  }

  // Copy with updated fields
  Post copyWith({
    String? id,
    String? uid,
    String? name,
    String? username,
    String? message,
    DateTime? createdAt,
    int? likeCount,
    List<String>? likedBy,
  }) {
    return Post(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      username: username ?? this.username,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}