import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../services/database/database_provider.dart';
import '../components/my_input_alert_box.dart';
import '../services/auth/auth_service.dart';
/*

POST TILE

All posts will be displayed using this post tile widget.

--------------------------------------------------------------------------------

To use this widget, you need:

- The post
- a function for onPostTap (to go the individual post to see it's comments)
- a function for onUserTap (to go to user's profile page)


 */


class MyPostTile extends StatefulWidget {
  final Post post;
  final void Function()? onUserTap;
  final void Function()? onPostTap;

  const MyPostTile({
    super.key,
    required this.post,
    this.onUserTap,
    required this.onPostTap,
  });

  @override
  State<MyPostTile> createState() => _MyPostTileState();
}

class _MyPostTileState extends State<MyPostTile> {

  // providers
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);


  // DOUBLE CHECK
  final _commentController = TextEditingController();
  late Timer _timer;

  // DOUBLE CHECK
  @override
  void initState() {
    super.initState();

    // Double check
    // Load comments after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DatabaseProvider>();
      provider.loadComments(widget.post.id);
    });

    // Auto-update "time ago" every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  // DOUBLE CHECK
  @override
  void dispose() {
    _timer.cancel();
    _commentController.dispose();
    super.dispose();
  }

  // user tapped like, or unlike
  void _toggleLikePost() async {
    try {
      await databaseProvider.toggleLike(widget.post.id);
    } catch (e) {
      print(e);
    }
  }

  // DOUBLE CHECK
  void _openNewCommentBox() {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => MyInputAlertBox(
        textController: commentController,
        hintText: "Type a comment",
        onPressed: () async {
          final text = commentController.text.trim();
          if (text.isEmpty) return;

          try {
            await context.read<DatabaseProvider>().addComment(
              widget.post.id,
              text,
            );
          } catch (e) {
            debugPrint('Error adding comment: $e');
          } finally {
            commentController.dispose();
          }
        },
        onPressedText: "Post",
      ),
    ).then((_) {
      if (commentController.value.text.isNotEmpty) {
        commentController.dispose();
      }
    });
  }

  // Show options for post
  void _showOptions() {
    final currentUserId = AuthService().getCurrentUserId();
    final isOwnPost = widget.post.userId == currentUserId;

    // show options
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            isOwnPost
            // THIS POST BELONGS TO USER
                ?
            // Delete button
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Delete"),
              onTap: () async {
                // pop option box
                Navigator.pop(context);

                // handle delete action
                await databaseProvider.deletePost(widget.post.id);
              },
            )
            // THIS POST DOES NOT BELONG TO USER
                :
            // Report button
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.report),
                  title: const Text("Report"),
                  onTap: () {
                    // pop option box
                    Navigator.pop(context);

                    // handle report action
                    _reportPostConfirmationBox();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text("Block"),
                  onTap: () {
                    // pop option box
                    Navigator.pop(context);

                    // handle block action
                    _blockUserConfirmationBox();
                  },
                ),
              ],
            ),

            // Always show cancel
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text("Cancel"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // DOUBLE CHECK
  void _reportPostConfirmationBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Report Message"),
        content: const Text("Are you sure you want to report this message?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await context.read<DatabaseProvider>().reportUser(
                widget.post.id,
                widget.post.userId,
              );
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Message reported!")),
              );
            },
            child: const Text("Report"),
          ),
        ],
      ),
    );
  }

  // DOUBLE CHECK
  void _blockUserConfirmationBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Block User"),
        content: const Text("Are you sure you want to block this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // await context.read<DatabaseProvider>().blockUser(widget.post.userId);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("User blocked!")),
              );
            },
            child: const Text("Block"),
          ),
        ],
      ),
    );
  }

  // DOUBLE CHECK
  String timeAgo(DateTime createdAt) {
    // Convert both to UTC to avoid timezone drift
    final now = DateTime.now().toUtc();
    final diff = DateTime.now().difference(createdAt); // already local
    final safeDiff = diff.isNegative ? Duration.zero : diff;

    if (diff.inSeconds < 60) return 'Just now';
    if (safeDiff.inMinutes < 60) return '${safeDiff.inMinutes}m ago';
    if (safeDiff.inHours < 24) return '${safeDiff.inHours}h ago';
    if (safeDiff.inDays < 7) return '${safeDiff.inDays}d ago';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }


  // BUILD UI
  @override
  Widget build(BuildContext context) {

    // does the current user like this post?
    bool likedByCurrentUser = listeningProvider.isPostLikedByCurrentUser(widget.post.id);

    // listen to like count
    int likeCount = listeningProvider.getLikeCount(widget.post.id);

    // DOUBLE CHECK
    int commentCount = listeningProvider.getComments(widget.post.id).length;


    return GestureDetector(
      onTap: widget.onPostTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  //Row
                  Row(
                    children: [
                      //Profile picture
                      Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                        size: 40,
                      ),

                      const SizedBox(width: 7),

                      GestureDetector(
                        onTap: widget.onUserTap,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text(
                              widget.post.name,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Username
                            Text(
                              '@${widget.post.username}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // buttons -> Options
                      GestureDetector(
                        onTap: _showOptions,
                        child: Icon(
                          Icons.more_horiz,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Post message
                  Text(
                    widget.post.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ],
              ),
            ),


            // like / comment row decoration
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),

              // Buttons -> Like / Comment + Timestamp
              child: Row(
                children: [

                  // Like Button
                  GestureDetector(
                    onTap: _toggleLikePost,
                    child:
                    likedByCurrentUser
                        ?
                    const Icon(Icons.favorite, color: Colors.red)
                        :
                    Icon(
                      Icons.favorite_border,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 7),

                  // Like count
                  SizedBox(
                    width: 24,
                    child: Text(
                      likeCount != 0 ? likeCount.toString() : '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Comment box
                  GestureDetector(
                    onTap: _openNewCommentBox,
                    child: Icon(
                      Icons.comment,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const SizedBox(width: 7),

                  // Comment Count
                  SizedBox(
                    width: 24,
                    child: Text(
                      commentCount > 0 ? commentCount.toString() : '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const Spacer(),

                  // Timestamp
                  Text(
                    timeAgo(widget.post.createdAt),
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
