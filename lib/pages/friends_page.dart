import 'package:flutter/material.dart';
import 'package:my_supabase_app/models/user.dart';
import 'package:my_supabase_app/services/auth/auth_service.dart';
import 'package:my_supabase_app/services/chat/chat_service.dart';
import '../components/my_friend_tile.dart';
import 'chat_page.dart';

class FriendsPage extends StatelessWidget {
  FriendsPage({super.key});

  final ChatService _chatService = ChatService();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Friends"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
      ),
      body: _buildUserList(context),
    );
  }

  /// Build a list of users except the current logged-in user
  Widget _buildUserList(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUserStream(), // Supabase real-time users
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading users"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data;
        if (users == null || users.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        final currentUserId = _auth.getCurrentUserId();

        // Map raw Supabase user data into your UserProfile model
        final userProfiles = users
            .where((data) => data['id'] != currentUserId)
            .map(
              (data) => UserProfile(
            id: data['id'] ?? '',
            name: data['name'] ?? '',
            username: data['username'] ?? '',
            email: data['email'] ?? '',
            profilePhotoUrl: data['profile_photo_url'] ?? '',
            bio: data['bio'] ?? '',
            createdAt: DateTime.tryParse(data['created_at'] ?? '') ??
                DateTime.now().toUtc(),
          ),
        ).toList();

        return ListView.builder(
          itemCount: userProfiles.length,
          itemBuilder: (context, index) {
            final user = userProfiles[index];

            // Tap opens ChatPage (not ProfilePage)
            return MyFriendTile(
              user: user,
              customTitle: user.name,
              key: ValueKey(user.id),
              onTap: () {
                print('Opening chat with: ${user.id} / ${user.name}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      friendId: user.id,
                      friendName: user.name,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
