import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../models/user.dart';

class DatabaseService {
  final supabase = Supabase.instance.client;

  /* ==================== USER PROFILE ==================== */
  Future<void> saveUserInfo({
    required String name,
    required String email,
    required String userId, // add this
  }) async {
    // Generate a safe username
    String username = email.split('@').first.trim();
    if (username.isEmpty) {
      username = 'user_$userId';
    }

    final userMap = {
      'id': userId,
      'name': name.trim(),
      'email': email.trim(),
      'username': username,
      'bio': '',
      'profile_photo_url': '',
      'created_at': DateTime.now().toIso8601String(),
    };

    print('Inserting user: $userMap');

    try {
      await supabase.from('profiles').insert(userMap);
    } catch (e, st) {
      print("Error saving user info: $e\n$st");
    }
  }

  Future<UserProfile?> getUser(String uid) async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', uid) // ✅ primary key now `id`
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromMap(data);
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }

  Future<void> updateUserBio(String bio) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await supabase.from('profiles').update({'bio': bio}).eq('id', uid);
    } catch (e) {
      print("Error updating bio: $e");
    }
  }

  /* ==================== DELETE USER ==================== */
  Future<void> deleteUser(String uid) async {
    try {
      await supabase.from('posts').delete().eq('uid', uid);
      await supabase.from('comments').delete().eq('uid', uid);
      await supabase.from('post_likes').delete().eq('uid', uid);
      await supabase
          .from('follows')
          .delete()
          .or('follower_id.eq.$uid,followed_id.eq.$uid');
      await supabase
          .from('blocks')
          .delete()
          .or('blocker_id.eq.$uid,blocked_id.eq.$uid');
      await supabase.from('profiles').delete().eq('id', uid); // ✅ changed
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  /* ==================== POSTS ==================== */
  Future<void> postMessage(String message) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null || message.trim().isEmpty) return;

    final user = await getUser(uid);
    if (user == null) return;

    final post = Post(
      id: '',
      uid: uid,
      name: user.name,
      username: user.username,
      message: message.trim(),
      createdAt: DateTime.now(),
      likeCount: 0,
      likedBy: [],
    );

    try {
      await supabase.from('posts').insert(post.toMap());
    } catch (e) {
      print("Error posting message: $e");
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await supabase.from('posts').delete().eq('id', postId);
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  Future<List<Post>> getAllPosts() async {
    try {
      final List data = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      return data.map((e) => Post.fromMap(e)).toList();
    } catch (e) {
      print("Error fetching posts: $e");
      return [];
    }
  }

  /* ==================== LIKES ==================== */
  Future<void> toggleLike(String postId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final List existing = await supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('uid', uid);

      if (existing.isNotEmpty) {
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('uid', uid);
      } else {
        await supabase.from('post_likes').insert({
          'post_id': postId,
          'uid': uid,
        });
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  /* ==================== COMMENTS ==================== */
  Future<void> addComment(String postId, String message) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null || message.trim().isEmpty) return;

    final user = await getUser(uid);
    if (user == null) return;

    final comment = Comment(
      id: '',
      postId: postId,
      uid: uid,
      name: user.name,
      username: user.username,
      message: message.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await supabase.from('comments').insert(comment.toMap());
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await supabase.from('comments').delete().eq('id', commentId);
    } catch (e) {
      print("Error deleting comment: $e");
    }
  }

  Future<List<Comment>> getComments(String postId) async {
    try {
      final List data = await supabase
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return data.map((e) => Comment.fromMap(e)).toList();
    } catch (e) {
      print("Error fetching comments: $e");
      return [];
    }
  }

  /* ==================== REPORT / BLOCK ==================== */
  Future<void> reportUser(String postId, String userId) async {
    final currentUser = supabase.auth.currentUser?.id;
    if (currentUser == null) return;

    try {
      await supabase.from('reports').insert({
        'reported_by': currentUser,
        'message_id': postId,
        'message_owner_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("Error reporting user: $e");
    }
  }

  Future<void> blockUser(String userId) async {
    final currentUser = supabase.auth.currentUser?.id;
    if (currentUser == null) return;

    try {
      await supabase.from('blocks').insert({
        'blocker_id': currentUser,
        'blocked_id': userId,
      });
    } catch (e) {
      print("Error blocking user: $e");
    }
  }

  Future<void> unblockUser(String userId) async {
    final currentUser = supabase.auth.currentUser?.id;
    if (currentUser == null) return;

    try {
      await supabase
          .from('blocks')
          .delete()
          .eq('blocker_id', currentUser)
          .eq('blocked_id', userId);
    } catch (e) {
      print("Error unblocking user: $e");
    }
  }

  Future<List<String>> getBlockedUids() async {
    final currentUser = supabase.auth.currentUser?.id;
    if (currentUser == null) return [];

    try {
      final List data = await supabase
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', currentUser);

      return data.map((e) => e['blocked_id'] as String).toList();
    } catch (e) {
      print("Error getting blocked users: $e");
      return [];
    }
  }

  /* ==================== FOLLOW / UNFOLLOW ==================== */
  Future<void> followUser(String targetUid) async {
    final currentUser = supabase.auth.currentUser?.id;
    if (currentUser == null) return;

    try {
      await supabase.from('follows').insert({
        'follower_id': currentUser,
        'followed_id': targetUid,
      });
    } catch (e) {
      print("Error following user: $e");
    }
  }

  Future<void> unfollowUser(String targetUid) async {
    final currentUser = supabase.auth.currentUser?.id;
    if (currentUser == null) return;

    try {
      await supabase
          .from('follows')
          .delete()
          .eq('follower_id', currentUser)
          .eq('followed_id', targetUid);
    } catch (e) {
      print("Error unfollowing user: $e");
    }
  }

  Future<List<String>> getFollowerUids(String uid) async {
    try {
      final List data = await supabase
          .from('follows')
          .select('follower_id')
          .eq('followed_id', uid);

      return data.map((e) => e['follower_id'] as String).toList();
    } catch (e) {
      print("Error getting followers: $e");
      return [];
    }
  }

  Future<List<String>> getFollowingUids(String uid) async {
    try {
      final List data = await supabase
          .from('follows')
          .select('followed_id')
          .eq('follower_id', uid);

      return data.map((e) => e['followed_id'] as String).toList();
    } catch (e) {
      print("Error getting following: $e");
      return [];
    }
  }

  /* ==================== SEARCH USERS ==================== */
  Future<List<UserProfile>> searchUsers(String searchTerm) async {
    if (searchTerm.isEmpty) return [];

    try {
      final List data = await supabase
          .from('profiles')
          .select()
          .ilike('username', '%$searchTerm%');

      return data.map((e) => UserProfile.fromMap(e)).toList();
    } catch (e) {
      print("Error searching users: $e");
      return [];
    }
  }
}
