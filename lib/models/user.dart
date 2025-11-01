/*
USER PROFILE MODEL (Supabase Version with `id` as primary key)

This defines what every user profile should have, adapted for Supabase.
Includes `createdAt` for better tracking of account creation.
*/

class UserProfile {
  final String id; // <-- now matches Supabase 'profiles.id'
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

  // Supabase -> App
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '', // <-- matches 'id' column
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      bio: map['bio'] ?? '',
      profilePhotoUrl: map['profile_photo_url'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // App -> Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id, // <-- now using 'id'
      'name': name,
      'email': email,
      'username': username,
      'bio': bio,
      'profile_photo_url': profilePhotoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with updated fields
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