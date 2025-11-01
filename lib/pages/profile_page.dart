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
  final String uid;
  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? user;
  String currentUserId = AuthService().getCurrentUid();
  bool _isLoading = true;
  bool _isFollowing = false;
  final bioTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

    user = await databaseProvider.userProfile(widget.uid);
    if (user == null) return;

    await databaseProvider.loadUserFollowers(widget.uid);
    await databaseProvider.loadUserFollowing(widget.uid);
    _isFollowing = databaseProvider.isFollowing(widget.uid);

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
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
    setState(() => _isLoading = true);
    await databaseProvider.updateBio(bioTextController.text);
    await _loadUser();
    setState(() => _isLoading = false);
  }

  Future<void> _toggleFollow() async {
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

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
        await databaseProvider.unfollowUser(widget.uid);
        setState(() => _isFollowing = false);
      }
    } else {
      await databaseProvider.followUser(widget.uid);
      setState(() => _isFollowing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseProvider>(context);
    final allUserPosts = databaseProvider.getUserPosts(widget.uid);
    final followerCount = databaseProvider.getFollowerCount(widget.uid);
    final followingCount = databaseProvider.getFollowingCount(widget.uid);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_isLoading ? '' : user?.name ?? ''),
        foregroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Text('@${user!.username}',
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
          const SizedBox(height: 28),
          Center(
            child: user!.profilePhotoUrl.isNotEmpty
                ? CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user!.profilePhotoUrl),
            )
                : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(50),
              ),
              padding: const EdgeInsets.all(25),
              child: Icon(Icons.person,
                  size: 70, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 28),
          MyProfileStats(
            postCount: allUserPosts.length,
            followerCount: followerCount,
            followingCount: followingCount,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FollowListPage(uid: widget.uid)),
            ),
          ),
          const SizedBox(height: 28),
          if (user!.id != currentUserId)
            MyFollowButton(onPressed: _toggleFollow, isFollowing: _isFollowing),
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
              padding: const EdgeInsets.all(12.0),
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