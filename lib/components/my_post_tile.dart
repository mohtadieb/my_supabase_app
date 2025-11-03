import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../services/database/database_provider.dart';
import '../components/my_input_alert_box.dart';
import '../services/auth/auth_service.dart';

class MyPostTile extends StatefulWidget {
  final Post post;
  final void Function()? onUserTap;
  final void Function()? onPostTap;

  const MyPostTile({
    super.key,
    required this.post,
    required this.onUserTap,
    required this.onPostTap,
  });

  @override
  State<MyPostTile> createState() => _MyPostTileState();
}

class _MyPostTileState extends State<MyPostTile> {
  final _commentController = TextEditingController();
  late Timer _timer;

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _timer.cancel();
    _commentController.dispose();
    super.dispose();
  }

  void _toggleLikePost() async {
    await context.read<DatabaseProvider>().toggleLike(widget.post.id);
  }

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
                  Navigator.pop(context);
                  await context.read<DatabaseProvider>().deletePost(widget.post.id);
                },
              )
            else ...[
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
              await context.read<DatabaseProvider>().blockUser(widget.post.userId);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseProvider>(
      builder: (context, dbProvider, _) {
        final likedByCurrentUser = dbProvider.isPostLikedByCurrentUser(widget.post.id);
        final likeCount = dbProvider.getLikeCount(widget.post.id);
        final commentCount = dbProvider.getComments(widget.post.id).length;

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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.post.name,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '@${widget.post.username}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
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
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.post.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 24,
                        child: Text(
                          likeCount > 0 ? likeCount.toString() : '',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _openNewCommentBox,
                        child: Icon(
                          Icons.comment,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
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
      },
    );
  }
}
