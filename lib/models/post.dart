class Post {
  final String id;
  final String userId;
  final String name;
  final String username;
  final String message;
  final DateTime createdAt;
  final int likeCount;
  final List<String> likedBy; // list of user IDs who liked

  Post({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    required this.message,
    required this.createdAt,
    required this.likeCount,
    required this.likedBy,
  });

  // ✅ Convert from Supabase record → Dart object
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'].toString(),
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.parse(map['created_at']).toLocal(),
      likeCount: map['like_count'] ?? 0,
      likedBy: List<String>.from(map['liked_by'] ?? []),
    );
  }

  // ✅ Convert Dart object → insert/update map
  Map<String, dynamic> toMap() {
    final map = {
      'user_id': userId,
      'name': name,
      'username': username,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      'liked_by': likedBy,
    };

    // ⚙️ include id only if it's a valid (non-empty) value
    if (id.isNotEmpty) map['id'] = id;

    return map;
  }

  // ✅ Useful for local updates
  Post copyWith({
    String? id,
    String? message,
    int? likeCount,
    List<String>? likedBy,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId,
      name: name,
      username: username,
      message: message ?? this.message,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}