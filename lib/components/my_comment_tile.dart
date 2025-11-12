/*

COMMENT TILE

This is the comment tile widget which belongs below a post. It's similar to the
post tile widget, but let's make comments look slightly different to posts.

--------------------------------------------------------------------------------

To use this widget, you need:

- the comment
- a function (for when the user taps and wants to go to the user profile of this
comment)


Displays a single comment with options to delete, report, or block depending on ownership.
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/comment.dart';
import '../services/auth/auth_service.dart';
import '../services/database/database_provider.dart';
import 'my_confirmation_box.dart';

class MyCommentTile extends StatefulWidget {
  final Comment comment;
  final void Function()? onUserTap;

  const MyCommentTile({
    super.key,
    required this.comment,
    required this.onUserTap,
  });

  @override
  State<MyCommentTile> createState() => _MyCommentTileState();
}

class _MyCommentTileState extends State<MyCommentTile> {
  // providers
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(
    context,
    listen: false,
  );

  /// Show options for this comment: delete (own), report/block (others)
  void _showOptions(BuildContext context) {

    // check if this comment is owned by the user or not
    final currentUserId = AuthService().getCurrentUserId();
    final isOwnComment = widget.comment.userId == currentUserId;

    // show options
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              // THIS COMMENT BELONGS TO USER
              if (isOwnComment) ...[

                // delete comment button
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text("Delete"),
                  onTap: () async {
                    // pop option box
                    Navigator.pop(context);

                    // handle delete action
                    await databaseProvider.deleteComment(widget.comment.id, widget.comment.postId);
                  },
                ),
                // THIS POST DOES NOT BELONG TO USER
              ] else ...[

                // report comment button
                ListTile(
                  leading: const Icon(Icons.report),
                  title: const Text("Report"),
                  onTap: () {
                    // pop option box
                    Navigator.pop(context);
                    _reportPostConfirmationBox();                  },
                ),

                // block user button
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text("Block"),
                  onTap: () {
                    // pop option box
                    Navigator.pop(context);
                    _blockUserConfirmationBox();                  },
                ),
              ],

              // Always show cancel
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _reportPostConfirmationBox() {
    showDialog(
      context: context,
      builder: (context) => MyConfirmationBox(
        title: "Report Message",
        content: "Are you sure you want to report this message?",
        confirmText: "Report",
        onConfirm: () async {
          await databaseProvider.reportUser(
            widget.comment.id,
            widget.comment.userId,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Message reported!")),
          );
        },
      ),
    );
  }

  void _blockUserConfirmationBox() {
    showDialog(
      context: context,
      builder: (context) => MyConfirmationBox(
        title: "Block User",
        content: "Are you sure you want to block this user?",
        confirmText: "Block",
        onConfirm: () async {
          await databaseProvider.blockUser(widget.comment.userId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User blocked!")),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Padding outside
      margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),

      // Padding inside
      padding: const EdgeInsets.all(21),

      decoration: BoxDecoration(
        // Color of post tile
        color: Theme.of(context).colorScheme.secondary,

        // Curve borders
        borderRadius: BorderRadius.circular(7),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: user info + options
          GestureDetector(
            onTap: widget.onUserTap,
            child: Row(
              children: [
                // Profile picture
                Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),

                const SizedBox(width: 7),

                // Name
                Text(
                  widget.comment.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(width: 7),

                // Username handle
                Text(
                  '@${widget.comment.username}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const Spacer(),

                // buttons -> more options: delete
                GestureDetector(
                  onTap: () => _showOptions(context),
                  child: Icon(
                    Icons.more_horiz,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 21),
          // Comment message
          Text(
            widget.comment.message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ],
      ),
    );
  }
}