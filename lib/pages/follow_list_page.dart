/*
FOLLOW LIST PAGE

This page displays a tab bar for a given uid:

- a list of all followers
- a list of all following
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/my_user_tile.dart';
import '../models/user.dart';
import '../services/database/database_provider.dart';

class FollowListPage extends StatefulWidget {
  final String uid;

  const FollowListPage({super.key, required this.uid});

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  // providers
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider = Provider.of<DatabaseProvider>(
    context,
    listen: false,
  );

  // on startup, load followers and following
  @override
  void initState() {
    super.initState();
    loadFollowerList();
    loadFollowingList();
  }

  // load followers
  Future<void> loadFollowerList() async {
    await databaseProvider.loadUserFollowerProfiles(widget.uid);
  }

  // load following
  Future<void> loadFollowingList() async {
    await databaseProvider.loadUserFollowingProfiles(widget.uid);
  }

  // build user list given a list of profiles
  Widget _buildUserList(List<UserProfile> userList, String emptyMessage) {
    if (userList.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      itemCount: userList.length,
      itemBuilder: (context, index) {
        final user = userList[index];
        return MyUserTile(user: user);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final followers = listeningProvider.getListOfFollowersProfile(widget.uid);
    final following = listeningProvider.getListOfFollowingProfile(widget.uid);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          foregroundColor: Theme.of(context).colorScheme.primary,
          bottom: TabBar(
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).colorScheme.inversePrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.primary,
            indicatorColor: Theme.of(context).colorScheme.secondary,
            tabs: const [
              Tab(text: "Followers"),
              Tab(text: "Following"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(followers, "No followers.."),
            _buildUserList(following, "No following.."),
          ],
        ),
      ),
    );
  }
}