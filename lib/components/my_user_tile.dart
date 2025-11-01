/*
USER LIST TILE (Supabase Ready)

Displays each user as a tile, for search results, followers, etc.
*/

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../pages/profile_page.dart';

class MyUserTile extends StatelessWidget {
  final UserProfile user;

  // Optional custom title
  final String? customTitle;

  const MyUserTile({
    super.key,
    required this.user,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(7),
      ),
      child: ListTile(
        // Title: customTitle or user name
        title: Text(
          customTitle ?? user.name,
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Subtitle: username
        subtitle: Text(
          '@${user.username}',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),

        // Leading: profile photo if available, else icon
        leading: user.profilePhotoUrl.isNotEmpty
            ? CircleAvatar(
          backgroundImage: NetworkImage(user.profilePhotoUrl),
        )
            : Icon(
          Icons.person,
          color: Theme.of(context).colorScheme.primary,
        ),

        // Trailing arrow
        trailing: Icon(
          Icons.arrow_forward,
          color: Theme.of(context).colorScheme.primary,
        ),

        // On tap: navigate to ProfilePage with Supabase UID
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(uid: user.id),
          ),
        ),
      ),
    );
  }
}