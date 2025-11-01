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
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    await databaseProvider.loadComments(widget.post.id);
  }

  void _toggleLikePost() async {
    await databaseProvider.toggleLike(widget.post.id);
  }

  void _openNewCommentBox() {
    showDialog(
      context: context,
      builder: (context) => MyInputAlertBox(
        textController: _commentController,
        hintText: "Type a comment",
        onPressed: () async {
          await _addComment();
        },
        onPressedText: "Post",
      ),
    );
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    await databaseProvider.addComment(widget.post.id, _commentController.text.trim());
    _commentController.clear();
    Navigator.pop(context);
  }

  void _showOptions() {
    String currentUid = AuthService().getCurrentUid();
    final bool isOwnPost = widget.post.uid == currentUid;

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
                  await databaseProvider.deletePost(widget.post.id);
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await databaseProvider.reportUser(widget.post.id, widget.post.uid);
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await databaseProvider.blockUser(widget.post.uid);
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

  String formatTimestamp(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final likedByCurrentUser = listeningProvider.isPostLikedByCurrentUser(widget.post.id);
    final likeCount = listeningProvider.getLikeCount(widget.post.id);
    final commentCount = listeningProvider.getComments(widget.post.id).length;

    return GestureDetector(
      onTap: widget.onPostTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
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
                        Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 40),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.post.name,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold)),
                            Text('@${widget.post.username}',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _showOptions,
                          child: Icon(Icons.more_horiz, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.post.message,
                      style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary)),
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
                        : Icon(Icons.favorite_border, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 20,
                    child: Text(likeCount > 0 ? likeCount.toString() : '',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _openNewCommentBox,
                    child: Icon(Icons.comment, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 20,
                    child: Text(commentCount > 0 ? commentCount.toString() : '',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ),
                  const Spacer(),
                  Text(formatTimestamp(widget.post.createdAt),
                      style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}