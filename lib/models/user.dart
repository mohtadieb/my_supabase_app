class UserProfile {
  final String id; // matches Supabase 'profiles.id'
  final String name;
  final String email;
  final String username;
  final String bio;
  final String profilePhotoUrl;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.bio,
    this.profilePhotoUrl = '',
    required this.createdAt,
  });

  // ✅ Supabase -> App
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      bio: map['bio'] ?? '',
      profilePhotoUrl: map['profile_photo_url'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // ✅ App -> Supabase
  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'email': email,
      'username': username,
      'bio': bio,
      'profile_photo_url': profilePhotoUrl,
      'created_at': createdAt.toIso8601String(),
    };

    // ⚙️ Include 'id' only if non-empty (optional for inserts)
    if (id.isNotEmpty) map['id'] = id;

    return map;
  }

  // ✅ Copy with updated fields
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? bio,
    String? profilePhotoUrl,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}