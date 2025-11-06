/*
POST PAGE

This page displays:

- individual's posts
- comments on this post

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

  // providers
  late final DatabaseProvider listeningProvider = Provider.of<DatabaseProvider>(context);
  late final DatabaseProvider databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    databaseProvider.loadComments(widget.post.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {

    // listen to all comments for this post
    final allComments = listeningProvider.getComments(widget.post.id);

    // SCAFFOLD
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      // App bar
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),

      // Body
      body: Column(
        children: [
          // Post tile
          MyPostTile(
            post: widget.post,
            onUserTap: () => goUserPage(context, widget.post.userId),
            onPostTap: () {},
          ),

          const Divider(
            color: Colors.transparent,
          ),

          // Comment list
          allComments.isEmpty
              ?
          Center(
            child: Text(
              "No comments yet...",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
              :
          ListView.builder(
            itemCount: allComments.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              // get each comment
              final comment = allComments[index];

              // return as comment tile UI
              return MyCommentTile(
                comment: comment,
                onUserTap: () => goUserPage(context, comment.userId),
              );
            },
          ),

          // DOUBLE CHECK
          // Add comment input
          // Padding(
          //   padding: const EdgeInsets.all(8.0),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: TextField(
          //           controller: _commentController,
          //           decoration: InputDecoration(
          //             hintText: "Add a comment...",
          //             fillColor: Theme.of(context).colorScheme.secondary,
          //             filled: true,
          //             border: OutlineInputBorder(
          //               borderRadius: BorderRadius.circular(12),
          //               borderSide: BorderSide.none,
          //             ),
          //             contentPadding: const EdgeInsets.symmetric(
          //                 horizontal: 12, vertical: 8),
          //           ),
          //         ),
          //       ),
          //       IconButton(
          //         icon: Icon(Icons.send,
          //             color: Theme.of(context).colorScheme.primary),
          //         onPressed: () async {
          //           final text = _commentController.text.trim();
          //           if (text.isEmpty) return;
          //
          //           await databaseProvider.addComment(widget.post.id, text);
          //           _commentController.clear();
          //         },
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}