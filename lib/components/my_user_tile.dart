/*
USER LIST TILE

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

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    // Container
    return Container(

      // Padding outside
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),

      // Padding inside
      padding: const EdgeInsets.all(7),

      decoration: BoxDecoration(
        // Color of tile
        color: Theme.of(context).colorScheme.secondary,

        // Curve corners
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
            builder: (context) => ProfilePage(userId: user.id),
          ),
        ),
      ),
    );
  }
}