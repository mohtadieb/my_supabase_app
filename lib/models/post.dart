class Post {
  final String? id;
  final String userId;
  final String name;
  final String username;
  final String message;
  final DateTime createdAt;
  final int likeCount;
  final List<String> likedBy; // ✅ list of user IDs who liked

  Post({
    this.id,
    required this.userId,
    required this.name,
    required this.username,
    required this.message,
    required this.createdAt,
    required this.likeCount,
    required this.likedBy,
  });

  // Convert a Database document to a Post object (to use in our app)
  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'].toString(),
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      message: map['message'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at']).toLocal() // ✅ convert to local time
          : DateTime.now(),
      likeCount: map['like_count'] ?? 0,
      likedBy: List<String>.from(map['liked_by'] ?? []),
    );
  }

  // Convert a Post object to a map (to store in Database)
  Map<String, dynamic> toMap() {
    return {
      // 'id': id,
      'user_id': userId,
      'name': name,
      'username': username,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      'liked_by': likedBy,
    };
  }

  Post copyWith({
    String? id,
    int? likeCount,
    List<String>? likedBy,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId,
      name: name,
      username: username,
      message: message,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}