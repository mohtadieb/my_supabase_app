import 'package:flutter/material.dart';
import 'package:my_supabase_app/components/my_input_alert_box.dart';
import 'package:my_supabase_app/components/my_post_tile.dart';
import 'package:my_supabase_app/helper/navigate_pages.dart';
import 'package:my_supabase_app/models/post.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/database/database_provider.dart';
import '../services/database/database_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  late final TabController _tabController;
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);


  List<Post> allPosts = [];
  List<Post> followingPosts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadAllPosts();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadAllPosts() async {
    try {
      // Load all posts
      final allPostsData = await supabase
          .from('posts')
          .select('*, profiles(id, username, name)')
          .order('created_at', ascending: false) as List;
      allPosts = allPostsData.map((e) => Post.fromMap(e)).toList();

      // Load following posts
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        final followingIdsData = await supabase
            .from('follows')
            .select('followed_id')
            .eq('follower_id', currentUserId) as List;
        final followingIds = followingIdsData.map((e) => e['followed_id'] as String).toList();

        followingPosts = allPosts.where((post) => followingIds.contains(post.uid)).toList();
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading posts: $e');
    }
  }

  void openPostMessageBox() {
    showDialog(
      context: context,
      builder: (context) => MyInputAlertBox(
        textController: _messageController,
        hintText: "What's on your mind?",
        onPressed: () async {
          await databaseProvider.postMessage(_messageController.text);
        },
        onPressedText: "Post",
      ),
    );
  }

  // Future<void> postMessage(String message) async {
  //   if (message.trim().isEmpty) return;
  //   try {
  //     final userId = supabase.auth.currentUser?.id;
  //     if (userId == null) return;
  //
  //     await supabase.from('posts').insert({
  //       'uid': userId,
  //       'message': message.trim(),
  //       'created_at': DateTime.now().toIso8601String(),
  //     });
  //
  //     _messageController.clear();
  //     await loadAllPosts();
  //   } catch (e) {
  //     debugPrint('Error posting message: $e');
  //   }
  // }

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
                Tab(text: "For you"),
                Tab(text: "Following"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostList(allPosts),
                _buildPostList(followingPosts),
              ],
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
          onUserTap: () => goUserPage(context, post.uid),
          onPostTap: () => goPostPage(context, post),
        );
      },
    );
  }
}