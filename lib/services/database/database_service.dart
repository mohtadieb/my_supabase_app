/*

DATABASE SERVICE

This class handles all the data from and to supabase

--------------------------------------------------------------------------------

- User Profile
- Post message
- Likes
- Comments
- Account stuff (report / block / delete account)
- Follow / unfollow
- Search users

 */

import 'package:flutter/cupertino.dart';
import 'package:my_supabase_app/services/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../models/user.dart';

class DatabaseService {
  // get instance of supabase
  final _db = Supabase.instance.client;
  final _auth = Supabase.instance.client.auth;

  /* ==================== USER PROFILE ==================== */

  /// Save user in database
  Future<void> saveUserInDatabase({required String name, required String email,}) async {

    try {
    // get current userId
    String currentUserId = _auth.currentUser!.id;

    // Generate a safe username
    String username = email
        .split('@')
        .first
        .trim();
    if (username.isEmpty) {
      username = 'user_$currentUserId';
    }

    // Create user profile
    UserProfile user = UserProfile(
      id: currentUserId,
      name: name,
      email: email,
      username: username,
      bio: '',
      createdAt: DateTime.now().toUtc(),
    );

    // convert user into map so that we can store in in supabase
    final userMap = user.toMap();

    print('Inserting user: $userMap');

    // save user in database
      await _db.from('profiles').insert(userMap);
    } catch (e, st) {
      print("Error saving user info: $e\n$st");
    }
  }

  /// Get user from database
  Future<UserProfile?> getUserFromDatabase(String userId) async {
    // Retrieve user info from database
    try {
      final userData = await _db
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (userData == null) return null;

      // Convert userData to user profile
      return UserProfile.fromMap(userData);
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }

  /// Update user bio
  Future<void> updateUserBioInDatabase(String bio) async {
    // Get current user Id
    final currentUserId = _auth.currentUser!.id;

    try {
      await _db.from('profiles').update({'bio': bio}).eq('id', currentUserId);
    } catch (e) {
      print("Error updating bio: $e");
    }
  }

  /* ==================== POSTS ==================== */

  /// Create a new post and return the inserted Post object
  Future<void> postMessageInDatabase(String message) async {
    // try post message
    try {
      // get current userId
      final currentUserId = _auth.currentUser!.id;

      // Get user profile info
      final user = await getUserFromDatabase(currentUserId);
      if (user == null) throw Exception("User profile not found");

      // Insert post and return the inserted row
      Post newPost = Post(
        id: '',
        userId: currentUserId,
        name: user.name,
        username: user.username,
        message: message,
        createdAt: DateTime.now().toUtc(),
        likeCount: 0,
        likedBy: [],
      );

      // Convert to Post object to map
      Map<String, dynamic> newPostMap = newPost.toMap();

      // Add post map into database
      await _db.from('posts').insert(newPostMap).select().single();

      // catch any errors
    } catch (e) {
      print("Error posting message: $e");
    }
  }

  /// Delete a post
  Future<void> deletePostFromDatabase(String postId) async {
    try {
      await _db.from('posts').delete().eq('id', postId);
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  /// Get all posts
  Future<List<Post>> getAllPostsFromDatabase() async {
    try {
      final List data =
      await _db
      // Go to collection "posts"
          .from('posts')
      // Select all fields
          .select()
      // Chronological order
          .order('created_at', ascending: false)
      as List;

      // Return as list of posts
      return data.map((e) => Post.fromMap(e)).toList();
    } catch (e) {
      print("Error fetching all posts: $e");
      return [];
    }
  }


  /// Get individual post


  /// Toggle like for a post
  Future<void> toggleLikeInDatabase(String postId) async {
    try {
      final currentUserId = _auth.currentUser!.id;

      // Step 1: Fetch the current post (like_count + liked_by)
      final postData = await _db
          .from('posts')
          .select('id, like_count, liked_by')
          .eq('id', postId)
          .maybeSingle();

      if (postData == null) {
        print("⚠️ Post not found for id: $postId");
        return;
      }

      // Step 2: Extract current values
      List<String> likedBy = List<String>.from(postData['liked_by'] ?? []);
      int likeCount = postData['like_count'] ?? 0;

      // Step 3: Determine whether to like or unlike
      if (!likedBy.contains(currentUserId)) {
        likedBy.add(currentUserId);
        likeCount++;
      } else {
        likedBy.remove(currentUserId);
        likeCount--;
      }

      // Step 4: Update the database
      await _db
          .from('posts')
          .update({'like_count': likeCount, 'liked_by': likedBy})
          .eq('id', postId);
    } catch (e) {
      print("❌ Error toggling like: $e");
    }
  }

  /// EXTRA /// for when I use post_likes
  Future<List<String>> getLikedPostIdsFromDatabase(String userId, List<String> postIds,) async {
    final likedPostIds = <String>[];
    if (postIds.isEmpty) return likedPostIds;

    try {
      final res = await _db
          .from('post_likes')
          .select('post_id')
          .eq('user_id', userId) // ✅ updated
          .filter('post_id', 'in', '(${postIds.map((e) => "'$e'").join(",")})');

      if (res != null && res is List) {
        for (final row in res) {
          if (row['post_id'] != null) {
            likedPostIds.add(row['post_id'].toString());
          }
        }
      }
    } catch (e) {
      print("Error fetching liked posts: $e");
    }

    return likedPostIds;
  }

  //* ==================== COMMENTS ==================== */

  /// Add comment to a post
  Future<void> addCommentInDatabase(String postId, message) async {
    try {
      // get current user
      final currentUserId = _auth.currentUser!.id;

      UserProfile? user = await getUserFromDatabase(currentUserId);

      // create a new comment
      Comment newComment = Comment(
          id: '',
          postId: postId,
          userId: currentUserId,
          name: user!.name,
          username: user.username,
          message: message,
          createdAt: DateTime.now().toUtc());

      // convert comment to a map
      Map<String, dynamic> newCommentMap = newComment.toMap();

      // store in Database
      await _db.from('comments').insert(newCommentMap).select().single();
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  /// Delete comment for a post
  Future<void> deleteCommentFromDatabase(String commentId) async {
    try {
      await _db.from('comments').delete().eq('id', commentId);
    } catch (e) {
      print("Error deleting comment: $e");
    }
  }


  /// Fetch comments for a post
  Future<List<Comment>> getCommentsFromDatabase(String postId) async {
    try {
      final response = await _db
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((row) => Comment.fromMap(row))
          .toList();
    } catch (e) {
      print("Error loading comments: $e");
      return [];
    }
  }


  /* ==================== REPORT / BLOCK ==================== */

  /// Report user in database
  Future<void> reportUserInDatabase(String postId, String userId) async {
    try {
      // Get current user ID from Supabase auth
        final currentUserId = _auth.currentUser!.id;

      // Prepare report data
      final report = {
        'reported_by': currentUserId,
        'message_id': postId,
        'message_owner_id': userId,
        'created_at': DateTime.now().toUtc().toIso8601String(), // Use current timestamp
      };

      // Insert into "reports" table
      await _db.from('reports').insert(report);

    } catch (e) {
      print('Error reporting post: $e');
    }
  }

  /// Block user in database
  Future<void> blockUserInDatabase(String userId) async {
    try {
      final currentUser = _auth.currentUser!.id;

      final data = await _db.from('profiles').select('blocked_users').eq('id', currentUser).single();
      final blocked = (data['blocked_users'] ?? [])..add(userId);

      await _db.from('profiles').update({'blocked_users': blocked}).eq('id', currentUser);
    } catch (e) {
      print("Error blocking user: $e");
    }
  }

  /// Unblock user in database
  Future<void> unblockUserInDatabase(String userId) async {
    try {
      final currentUser = _auth.currentUser!.id;
      if (currentUser == null) return;

      // fetch and update blocked_users array in one go
      final data = await _db.from('profiles').select('blocked_users').eq('id', currentUser).single();
      final blocked = List<String>.from(data['blocked_users'] ?? [])..remove(userId);

      await _db.from('profiles').update({'blocked_users': blocked}).eq('id', currentUser);
    } catch (e) {
      print("Error unblocking user: $e");
    }
  }

  /// Get blocked user from database
  Future<List<String>> getBlockedUserIdsFromDatabase() async {
    try {
      final currentUser = _auth.currentUser!.id;

      final data = await _db
          .from('profiles')
          .select('blocked_users')
          .eq('id', currentUser)
          .single();

      return List<String>.from(data['blocked_users'] ?? []);
    } catch (e) {
      print("Error getting blocked users: $e");
      return [];
    }
  }

  ///EXTRA
  Future<void> removeLikesBetweenUsers(String currentUserId, String blockedUserId,) async {
    // 1️⃣ Get all post IDs by blocked user
    final blockedUserPosts = await _db
        .from('posts')
        .select('id')
        .eq('user_id', blockedUserId);

    final blockedPostIds = (blockedUserPosts as List)
        .map((p) => p['id'] as String)
        .toList();

    // 2️⃣ Get all post IDs by current user
    final currentUserPosts = await _db
        .from('posts')
        .select('id')
        .eq('user_id', currentUserId);

    final currentPostIds = (currentUserPosts as List)
        .map((p) => p['id'] as String)
        .toList();

    // 3️⃣ Remove likes that current user gave to blocked user’s posts
    if (blockedPostIds.isNotEmpty) {
      await _db
          .from('post_likes')
          .delete()
          .inFilter('post_id', blockedPostIds)
          .eq('user_id', currentUserId);
    }

    // 4️⃣ Remove likes that blocked user gave to current user’s posts
    if (currentPostIds.isNotEmpty) {
      await _db
          .from('post_likes')
          .delete()
          .inFilter('post_id', currentPostIds)
          .eq('user_id', blockedUserId);
    }

    // 5️⃣ (Optional) Update like counts if needed
    // You can call an RPC or recalculate in Dart if you maintain counts manually.
  }

  /* ==================== FOLLOW / UNFOLLOW ==================== */

  /// Follow user in database
  Future<void> followUserInDatabase(String targetUserId) async {
    final currentUserId = _auth.currentUser!.id;

    try {
      // Get the current user's following list
      final currentUserRes = await _db
          .from('profiles')
          .select('following')
          .eq('id', currentUserId)
          .single();

      List<dynamic> following = currentUserRes['following'] ?? [];

      // Add the target user if not already following
      if (!following.contains(targetUserId)) {
        following.add(targetUserId);

        await _db.from('profiles').update({'following': following}).eq('id', currentUserId);
      }

      // Get the target user's followers list
      final targetUserRes = await _db
          .from('profiles')
          .select('followers')
          .eq('id', targetUserId)
          .single();

      List<dynamic> followers = targetUserRes['followers'] ?? [];

      // Add the current user if not already in followers
      if (!followers.contains(currentUserId)) {
        followers.add(currentUserId);

        await _db.from('profiles').update({'followers': followers}).eq('id', targetUserId);
      }

      print("✅ Follow successful");
    } catch (e) {
      print("❌ Follow error: $e");
    }
  }

  /// Unfollow user in database
  Future<void> unfollowUserInDatabase(String targetUserId) async {
    final currentUserId = _auth.currentUser!.id;

    try {
      // Get the current user's following list
      final currentUserRes = await _db
          .from('profiles')
          .select('following')
          .eq('id', currentUserId)
          .single();

      List<dynamic> following = currentUserRes['following'] ?? [];

      // Remove target user if present
      following.remove(targetUserId);
      await _db.from('profiles').update({'following': following}).eq('id', currentUserId);

      // Get the target user's followers list
      final targetUserRes = await _db
          .from('profiles')
          .select('followers')
          .eq('id', targetUserId)
          .single();

      List<dynamic> followers = targetUserRes['followers'] ?? [];

      // Remove current user if present
      followers.remove(currentUserId);
      await _db.from('profiles').update({'followers': followers}).eq('id', targetUserId);

      print("✅ Unfollow successful");
    } catch (e) {
      print("❌ Unfollow error: $e");
    }
  }

  /// Get followers UserId's from database
  Future<List<String>> getFollowersFromDatabase(String userId) async {

    try {
      final response = await _db
          .from('profiles')
          .select('followers')
          .eq('id', userId)
          .maybeSingle();

      if (response == null || response['followers'] == null) {
        return [];
      }

      // Convert dynamic list → List<String>
      final followers = List<String>.from(response['followers']);
      print("✅ Followers for $userId: $followers");
      return followers;
    } catch (e) {
      print("❌ Error fetching followers: $e");
      return [];
    }
  }

  /// Get following UserId's from database
  Future<List<String>> getFollowingFromDatabase(String userId) async {

    try {
      final response = await _db
          .from('profiles')
          .select('following')
          .eq('id', userId)
          .maybeSingle();

      if (response == null || response['following'] == null) {
        return [];
      }

      // Convert dynamic list → List<String>
      final following = List<String>.from(response['following']);
      print("✅ Following for $userId: $following");
      return following;
    } catch (e) {
      print("❌ Error fetching following: $e");
      return [];
    }
  }

  /* ==================== DELETE USER ==================== */
  /// Invokes supabase function to delete user data as a batch
  Future<void> deleteUserDataFromDatabase(String userId) async {
    try {
      final result = await _db.rpc(
        'delete_user_data',
        params: {'target_user_id': userId},
      );

      print('✅ User data deleted successfully! Result: $result');
    } catch (e) {
      print('❌ Error calling delete_user_data function: $e');
    }
  }

  /* ==================== SEARCH USERS ==================== */
  Future<List<UserProfile>> searchUsers(String searchTerm) async {
    if (searchTerm.isEmpty) return [];

    try {
      final List data = await _db
          .from('profiles')
          .select()
          .ilike('username', '%$searchTerm%');

      return data.map((e) => UserProfile.fromMap(e)).toList();
    } catch (e) {
      print("Error searching users: $e");
      return [];
    }
  }

  /* ==================== TIME ==================== */

  Future<DateTime?> getServerTime() async {
    try {
      final response = await _db
          .from('posts')
          .select('now()')
          .limit(1)
          .maybeSingle();

      if (response == null || response['now'] == null) return null;

      // Supabase returns UTC time, so keep it consistent
      return DateTime.parse(response['now']).toUtc();
    } catch (e) {
      print('Error fetching server time: $e');
      return null;
    }
  }
}
