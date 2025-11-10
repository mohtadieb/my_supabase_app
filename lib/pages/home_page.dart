import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../services/database/database_provider.dart';
import '../components/my_input_alert_box.dart';
import '../components/my_post_tile.dart';
import '../helper/navigate_pages.dart';
/*

HOME PAGE

This is the main page of the app, it displays a list of all the posts.


 */

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {

  // Providers
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
  late final listeningProvider = Provider.of<DatabaseProvider>(context);

  // Text controllers
  final TextEditingController _messageController = TextEditingController();

  late final TabController _tabController;

  // on startup
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // let's load all the post
    loadAllPosts();
  }

  // load all posts
  Future<void> loadAllPosts() async {
    await databaseProvider.loadAllPosts();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // show post message dialog box
  void _openPostMessageBox() {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => MyInputAlertBox(
        textController: messageController,
        hintText: "What's on your mind?",
        onPressed: () async {
          final message = messageController.text.trim();

          // Minimum non-space character validation
          if (message.replaceAll(RegExp(r'\s+'), '').length < 2) {
            // Show a snackbar or alert
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Your message must have at least 2 characters")),
            );
            return;
          }

          // Post in database
          await _postMessage(message);
          },
        onPressedText: "Post",
      ),
    );
  }


  // user wants to post a message
  Future<void> _postMessage(String message) async {
    await databaseProvider.postMessage(message);
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    // SCAFFOLD
    return Scaffold(

      // Floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: _openPostMessageBox,
        child: const Icon(Icons.add),
      ),

      // Body: List of all posts
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              labelColor: Theme.of(context).colorScheme.inversePrimary,
              unselectedLabelColor: Theme.of(context).colorScheme.primary,
              indicatorColor: Theme.of(context).colorScheme.secondary,
              tabs: const [
                Tab(text: "For You"),
                Tab(text: "Following"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostList(listeningProvider.allPosts),
                _buildPostList(listeningProvider.followingPosts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList(List<Post> posts) {
    // if it's empty
    return (posts.isEmpty)
        ?
    // return Nothing here...
    const Center(child: Text("Nothing here.."))
        :
     // else, return listview of posts
     ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return MyPostTile(
          post: post,
          onUserTap: () => goUserPage(context, post.userId),
          onPostTap: () => goPostPage(context, post),
        );
      },
    );
  }
}