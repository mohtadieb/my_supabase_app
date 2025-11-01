/*
BLOCKED USERS PAGE

Displays a list of users that have been blocked.
Allows unblocking directly from the list.
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_supabase_app/services/database/database_provider.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  late DatabaseProvider _databaseProvider;

  @override
  void initState() {
    super.initState();
    // Delay provider access to after init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      _loadBlockedUsers();
    });
  }

  Future<void> _loadBlockedUsers() async {
    await _databaseProvider.loadBlockedUsers();
  }

  void _showUnblockConfirmation(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unblock User"),
        content: const Text("Are you sure you want to unblock this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await _databaseProvider.unblockUser(userId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("User unblocked!")),
              );
            },
            child: const Text("Unblock"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in blocked users
    final blockedUsers = Provider.of<DatabaseProvider>(context).blockedUsers;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Blocked Users"),
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: blockedUsers.isEmpty
          ? const Center(
        child: Text(
          "No blocked users...",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: blockedUsers.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final user = blockedUsers[index];
          return ListTile(
            title: Text(user.name),
            subtitle: Text('@${user.username}'),
            trailing: IconButton(
              icon: const Icon(Icons.block),
              color: Colors.red,
              onPressed: () => _showUnblockConfirmation(user.id),
            ),
          );
        },
      ),
    );
  }
}