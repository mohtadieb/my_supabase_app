import 'package:flutter/material.dart';
import '../models/user.dart';

class MyFriendTile extends StatelessWidget {
  final UserProfile user;
  final String? customTitle;
  final VoidCallback onTap; // ✅ pass chat callback

  const MyFriendTile({
    super.key,
    required this.user,
    this.customTitle,
    required this.onTap,
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
        title: Text(
          customTitle ?? user.name,
          style: TextStyle(
            color: Theme.of(context).colorScheme.inversePrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '@${user.username}',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        leading: user.profilePhotoUrl.isNotEmpty
            ? CircleAvatar(
          backgroundImage: NetworkImage(user.profilePhotoUrl),
        )
            : Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
        trailing: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.primary),
        onTap: onTap, // ✅ call chat
      ),
    );
  }
}