/*
FOLLOW BUTTON

This is a follow / unfollow button, depending on whose profile page we are
currently viewing.

--------------------------------------------------------------------------------

To use this widget, you need:

- a function (e.g. toggleFollow() when the button is pressed)
- isFollowing (e.g. false -> then we will show follow button instead of unfollow button)
*/

import 'package:flutter/material.dart';

class MyFollowButton extends StatelessWidget {
  final void Function()? onPressed;
  final bool isFollowing;

  const MyFollowButton({
    super.key,
    required this.onPressed,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14), // rounded button corners
        child: MaterialButton(
          padding: const EdgeInsets.all(16),
          onPressed: onPressed,
          // Button color changes based on follow state
          color: isFollowing
              ? Theme.of(context).colorScheme.primary // already following
              : Colors.blue, // not following yet
          child: Text(
            isFollowing ? "Unfollow" : "Follow",
            style: TextStyle(
              color: Theme.of(context).colorScheme.tertiary, // text color
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}