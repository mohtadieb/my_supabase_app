/*
POST PAGE

Displays an individual post with all its comments.
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/my_post_tile.dart';
import '../components/my_comment_tile.dart';
import '../models/post.dart';
import '../services/database/database_provider.dart';
import '../helper/navigate_pages.dart';

class PostPage extends StatefulWidget {
  final Post post;

  const PostPage({super.key, required this.post});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  late final DatabaseProvider listeningProvider;
  late final DatabaseProvider databaseProvider;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // access provider after context is available
    listeningProvider = Provider.of<DatabaseProvider>(context, listen: true);
    databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

    // load comments for this post
    WidgetsBinding.instance.addPostFrameCallback((_) {
      databaseProvider.loadComments(widget.post.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allComments = listeningProvider.getComments(widget.post.id);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          // Post tile
          MyPostTile(
            post: widget.post,
            onUserTap: () => goUserPage(context, widget.post.uid),
            onPostTap: () {},
          ),

          const Divider(),

          // Comment list
          Expanded(
            child: allComments.isEmpty
                ? Center(
              child: Text(
                "No comments yet...",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            )
                : ListView.builder(
              itemCount: allComments.length,
              itemBuilder: (context, index) {
                final comment = allComments[index];
                return MyCommentTile(
                  comment: comment,
                  onUserTap: () => goUserPage(context, comment.uid),
                );
              },
            ),
          ),

          // Add comment input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      fillColor: Theme.of(context).colorScheme.secondary,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                  onPressed: () async {
                    final text = _commentController.text.trim();
                    if (text.isEmpty) return;

                    await databaseProvider.addComment(widget.post.id, text);
                    _commentController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}