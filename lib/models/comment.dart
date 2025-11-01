/*
COMMENT MODEL (Supabase Version)

This model defines what every comment should have in the Supabase setup.
*/

class Comment {
  final String id;
  final String postId;
  final String uid;
  final String name;
  final String username;
  final String message;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.uid,
    required this.name,
    required this.username,
    required this.message,
    required this.createdAt,
  });

  // Supabase -> App
  factory Comment.fromMap(Map<String, dynamic> data) {
    return Comment(
      id: data['id'].toString(),
      postId: data['post_id'] ?? '',
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      message: data['message'] ?? '',
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  // App -> Supabase
  Map<String, dynamic> toMap() {
    return {
      'post_id': postId,
      'uid': uid,
      'name': name,
      'username': username,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with updated fields
  Comment copyWith({
    String? id,
    String? postId,
    String? uid,
    String? name,
    String? username,
    String? message,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      username: username ?? this.username,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}