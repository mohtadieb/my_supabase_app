import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/my_bio_box.dart';
import '../components/my_follow_button.dart';
import '../components/my_input_alert_box.dart';
import '../components/my_post_tile.dart';
import '../components/my_profile_stats.dart';
import '../helper/navigate_pages.dart';
import '../models/user.dart';
import '../services/auth/auth_service.dart';
import '../services/database/database_provider.dart';
import 'follow_list_page.dart';

/*
PROFILE PAGE (Supabase Ready)
Displays user profile, bio, follow button, posts, followers/following counts
*/

class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);


  // user info
  UserProfile? user;
  String currentUserId = AuthService().getCurrentUserId();

  //
  bool _isFollowing = false;
  final bioTextController = TextEditingController();

  // loading..
  bool _isLoading = true;

  // on startup,
  @override
  void initState() {
    super.initState();

    // let's load user info
    loadUser();
  }

  Future<void> loadUser() async {
    user = await databaseProvider.getUserProfile(widget.userId);
    if (user == null) return;

    await databaseProvider.loadUserFollowers(widget.userId);
    await databaseProvider.loadUserFollowing(widget.userId);
    _isFollowing = databaseProvider.isFollowing(widget.userId);

    setState(() {
      _isLoading = false;
    });
  }

  void _showEditBioBox() {
    bioTextController.text = user?.bio ?? '';
    showDialog(
      context: context,
      builder: (context) => MyInputAlertBox(
        textController: bioTextController,
        hintText: "Edit bio...",
        onPressed: _saveBio,
        onPressedText: "Save",
      ),
    );
  }

  Future<void> _saveBio() async {
    setState(() => _isLoading = true);
    await databaseProvider.updateBio(bioTextController.text);
    await loadUser();
    setState(() => _isLoading = false);
  }

  Future<void> _toggleFollow() async {
    if (_isFollowing) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Unfollow"),
          content: const Text("Are you sure you want to unfollow?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
          ],
        ),
      );
      if (confirm == true) {
        await databaseProvider.unfollowUser(widget.userId);
        databaseProvider.loadFollowingPosts();
        setState(() => _isFollowing = false);
      }
    } else {
      await databaseProvider.followUser(widget.userId);
      databaseProvider.loadFollowingPosts();
      setState(() => _isFollowing = true);
    }
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    final allUserPosts = databaseProvider.getUserPosts(widget.userId);
    final followerCount = databaseProvider.getFollowerCount(widget.userId);
    final followingCount = databaseProvider.getFollowingCount(widget.userId);

    //SCAFFOLD
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      // App bar
      appBar: AppBar(

        // Username handle
        title: Text(_isLoading ? '' : user!.name),
        foregroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
      ),

      // Body
      body: _isLoading
          ?
      const Center(child: CircularProgressIndicator())
          :
      ListView(
        children: [

          const SizedBox(height: 14),

          // Username
          Center(
            child: Text(_isLoading ? '' : '@${user!.username}',
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),

          const SizedBox(height: 28),

          // Profile picture
          Center(
            child: user!.profilePhotoUrl.isNotEmpty
                ?
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user!.profilePhotoUrl),
            )
                :
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(56),
              ),
              padding: const EdgeInsets.all(28),
              child: Icon(Icons.person,
                  size: 70, color: Theme.of(context).colorScheme.primary),
            ),
          ),

          const SizedBox(height: 28),

          // Profile stats
          MyProfileStats(
            postCount: allUserPosts.length,
              followerCount: followerCount,
            followingCount: followingCount,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FollowListPage(userId: widget.userId)),
            ),
          ),

          const SizedBox(height: 28),

          // FOLLOW BUTTON
          if (user!.id != currentUserId)
            MyFollowButton(onPressed: _toggleFollow, isFollowing: _isFollowing),

          // BIO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Bio", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                if (user!.id == currentUserId)
                  GestureDetector(
                    onTap: _showEditBioBox,
                    child: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 7),

          MyBioBox(text: user!.bio),
          Padding(
            padding: const EdgeInsets.only(left: 28.0, top: 28.0),
            child: Text("Posts", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          allUserPosts.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Text("No posts yet..",
                  style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
          )
              : ListView.builder(
            itemCount: allUserPosts.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final post = allUserPosts[index];
              return MyPostTile(
                post: post,
                onUserTap: () {}, // optional: navigate to author profile
                onPostTap: () => goPostPage(context, post),
              );
            },
          ),
        ],
      ),
    );
  }
}