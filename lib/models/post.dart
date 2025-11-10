class Post {
  final String id;
  final String userId;
  final String name;
  final String username;
  final String message;
  final String? imageUrl; // 🆕 optional image
  final DateTime createdAt;
  final int likeCount;
  final List<String> likedBy;

  Post({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    required this.message,
    this.imageUrl, // 🆕
    required this.createdAt,
    required this.likeCount,
    required this.likedBy,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'].toString(),
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      message: map['message'] ?? '',
      imageUrl: map['image_url'], // 🆕
      createdAt: DateTime.parse(map['created_at']).toLocal(),
      likeCount: map['like_count'] ?? 0,
      likedBy: List<String>.from(map['liked_by'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'user_id': userId,
      'name': name,
      'username': username,
      'message': message,
      'image_url': imageUrl, // 🆕
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      'liked_by': likedBy,
    };
    if (id.isNotEmpty) map['id'] = id;
    return map;
  }

  Post copyWith({
    String? id,
    String? message,
    String? imageUrl, // 🆕
    int? likeCount,
    List<String>? likedBy,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId,
      name: name,
      username: username,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl, // 🆕
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}
