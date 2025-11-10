import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../helper/time_ago_text.dart';
import '../models/post.dart';
import '../services/database/database_provider.dart';
import '../components/my_input_alert_box.dart';
import '../services/auth/auth_service.dart';
import 'my_confirmation_box.dart';

/*

POST TILE

All posts will be displayed using this post tile widget.

--------------------------------------------------------------------------------

To use this widget, you need:

- The post
- a function for onPostTap (to go the individual post to see its comments)
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
  late final databaseProvider = Provider.of<DatabaseProvider>(
    context,
    listen: false,
  );

  // comment text controller
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // load comments for this post
    _loadComments();
  }

  @override
  void dispose() {
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

  // open comment box -> user wants to type a new comment
  void _openNewCommentBox() {
    showDialog(
      context: context,
      builder: (context) => MyInputAlertBox(
        textController: _commentController,
        hintText: "Type a comment",
        onPressed: () async {
          final comment = _commentController.text.trim();

          // Require at least 2 non-space characters
          if (comment.replaceAll(RegExp(r'\s+'), '').length < 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              // Show a snackbar or alert
            const SnackBar(content: Text("Comment must be at least 2 characters")),
            );
            return; // Don't post
          }

          await _addComment();
        },
        onPressedText: "Post",
      ),
    );
  }

  // user tapped post to add comment
  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await databaseProvider.addComment(
        widget.post.id,
        _commentController.text.trim(),
      );
    } catch (e) {
      debugPrint('Error adding comment: $e');
    } finally {
      _commentController.clear();
    }
  }

  // load comments
  Future<void> _loadComments() async {
    await databaseProvider.loadComments(widget.post.id);
  }

  /*

  SHOW OPTIONS

  Case 1: This post belongs to current user
  - Delete
  - Cancel

  Case 2: This post does not belong to current user
  - Report
  - Block
  - Cancel

   */

  void _showOptions() {
    final currentUserId = AuthService().getCurrentUserId();
    final isOwnPost = widget.post.userId == currentUserId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (isOwnPost)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Delete"),
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet first

                  // Show confirmation dialog
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Post"),
                      content: const Text("Are you sure you want to delete this post?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );

                  // If confirmed, delete post
                  if (confirm == true) {
                    await databaseProvider.deletePost(widget.post.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Post deleted!")),
                    );
                  }
                },
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.report),
                    title: const Text("Report"),
                    onTap: () {
                      Navigator.pop(context);
                      _reportPostConfirmationBox();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text("Block"),
                    onTap: () {
                      Navigator.pop(context);
                      _blockUserConfirmationBox();
                    },
                  ),
                ],
              ),
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


  void _reportPostConfirmationBox() {
    showDialog(
      context: context,
      builder: (context) => MyConfirmationBox(
        title: "Report Message",
        content: "Are you sure you want to report this message?",
        confirmText: "Report",
        onConfirm: () async {
          await databaseProvider.reportUser(
            widget.post.id,
            widget.post.userId,
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
          await databaseProvider.blockUser(widget.post.userId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User blocked!")),
          );
        },
      ),
    );
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    // does the current user like this post?
    bool likedByCurrentUser = listeningProvider.isPostLikedByCurrentUser(
      widget.post.id,
    );

    // listen to like count
    int likeCount = listeningProvider.getLikeCount(widget.post.id);

    // listen to comment count
    int commentCount = listeningProvider.getComments(widget.post.id).length;

    return GestureDetector(
      onTap: widget.onPostTap,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row: Profile picture + Name/Username + Options
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onUserTap,
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.primary,
                                size: 40,
                              ),
                              const SizedBox(width: 7),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.post.name,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    '@${widget.post.username}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
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
                    Text(
                      widget.post.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Theme.of(context).colorScheme.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleLikePost,
                      child: likedByCurrentUser
                          ? const Icon(Icons.favorite, color: Colors.red)
                          : Icon(
                        Icons.favorite_border,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 1),
                    SizedBox(
                      width: 21,
                      child: Text(
                        likeCount != 0 ? likeCount.toString() : '',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: _openNewCommentBox,
                      child: Icon(
                        Icons.comment,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 1),
                    SizedBox(
                      width: 21,
                      child: Text(
                        commentCount != 0 ? commentCount.toString() : '',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),
                    // Timestamp using TimeAgoText helper
                    TimeAgoText(
                      createdAt: widget.post.createdAt,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
