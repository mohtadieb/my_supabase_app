import 'package:flutter/material.dart';
import 'package:my_supabase_app/pages/settings_page.dart';
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
import 'package:flutter/cupertino.dart';


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
  // Providers
  late final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
  late final listeningProvider = Provider.of<DatabaseProvider>(context);

  // user info
  UserProfile? user;
  String currentUserId = AuthService().getCurrentUserId();

  // Text controller for bio
  final bioTextController = TextEditingController();

  // loading..
  bool _isLoading = true;

  // isFollowing state
  bool _isFollowing = false;

  // on startup,
  @override
  void initState() {
    super.initState();

    // let's load user info
    loadUser();
  }

  Future<void> loadUser() async {
    // get the user profile info
    user = await databaseProvider.getUserProfile(widget.userId);

    // load followers and following for this user
    await databaseProvider.loadUserFollowers(widget.userId);
    await databaseProvider.loadUserFollowing(widget.userId);

    // update following state
    _isFollowing = databaseProvider.isFollowing(widget.userId);


    // finishes loading
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

  // Save updated bio
  Future<void> _saveBio() async {

    // start loading...
    setState(() => _isLoading = true);

    // update bio
    await databaseProvider.updateBio(bioTextController.text);

    // reload user
    await loadUser();

    // finished loading
    setState(() => _isLoading = false);
  }

  Future<void> _toggleFollow() async {
    // unfollow
    if (_isFollowing) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Unfollow"),
          content: const Text("Are you sure you want to unfollow?"),
          actions: [
            // cancel button
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
            // yes button
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
    // get user posts
    final allUserPosts = listeningProvider.getUserPosts(widget.userId);

    // listen to followers & following count
    final followerCount = listeningProvider.getFollowerCount(widget.userId);
    final followingCount = listeningProvider.getFollowingCount(widget.userId);

    // listen to is following
    _isFollowing = listeningProvider.isFollowing(widget.userId);



    //SCAFFOLD
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      // App bar
      appBar: AppBar(
        title: Text(_isLoading ? '' : user!.name),
        foregroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        actions: [
          // Only show settings icon when viewing your own profile
          if (!_isLoading && user!.id == currentUserId)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
        ],
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
              radius: 56,
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

          // Follow / Unfollow button
          // only show is the user is viewing someone else's profile
          if (user!=null && user!.id != currentUserId)
            MyFollowButton(
                onPressed: _toggleFollow,
                isFollowing: _isFollowing
            ),

          // BIO Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Bio", style: TextStyle(color: Theme.of(context).colorScheme.primary)),

                // EDIT BIO BUTTON
                // only show edit button when you're looking at your own profile
                if (user!.id == currentUserId)
                  GestureDetector(
                    onTap: _showEditBioBox,
                    child: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 7),

          // Bio Box
          MyBioBox(text: _isLoading ? '...' : user!.bio),

          Padding(
            padding: const EdgeInsets.only(left: 28.0, top: 28.0),
            child: Text("Posts", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),

          // list of posts from user
          allUserPosts.isEmpty
              ?
          // user posts is empty
          Center(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Text("No posts yet..",
                  style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
          )
              :

          // user posts is NOT empty
          ListView.builder(
            itemCount: allUserPosts.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              // get individual post
              final post = allUserPosts[index];
              return MyPostTile(
                post: post,
                onPostTap: () => goPostPage(context, post),
              );
            },
          ),
        ],
      ),
    );
  }
}