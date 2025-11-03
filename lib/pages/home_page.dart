import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../services/database/database_provider.dart';
import '../components/my_input_alert_box.dart';
import '../components/my_post_tile.dart';
import '../helper/navigate_pages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

  final TextEditingController _messageController = TextEditingController();
  late final TabController _tabController;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load posts once after the first frame
    databaseProvider.loadAllPosts();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void openPostMessageBox() {
    final TextEditingController _messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => MyInputAlertBox(
        textController: _messageController,
        hintText: "What's on your mind?",
        onPressed: () async {
          final text = _messageController.text.trim();
          if (text.isEmpty) return;

          await context.read<DatabaseProvider>().postMessage(text);

          _messageController.clear();
        },
        onPressedText: "Post",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: openPostMessageBox,
        child: const Icon(Icons.add),
      ),
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
            child: Consumer<DatabaseProvider>(
              builder: (context, dbProvider, _) {
                final allPosts = dbProvider.allPosts;
                final followingPosts = dbProvider.followingPosts;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostList(allPosts),
                    _buildPostList(followingPosts),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList(List<Post> posts) {
    if (posts.isEmpty) return const Center(child: Text("Nothing here.."));

    return ListView.builder(
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