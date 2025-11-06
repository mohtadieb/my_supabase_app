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
    String userId = _auth.currentUser!.id;

    // Generate a safe username
    String username = email
        .split('@')
        .first
        .trim();
    if (username.isEmpty) {
      username = 'user_$userId';
    }

    // Create user profile
    UserProfile user = UserProfile(
      id: userId,
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
    String userId = AuthService().getCurrentUserId();

    try {
      await _db.from('profiles').update({'bio': bio}).eq('id', userId);
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
      final userId = _auth.currentUser!.id;

      // Get user profile info
      final user = await getUserFromDatabase(userId);
      if (user == null) throw Exception("User profile not found");

      // Insert post and return the inserted row
      Post newPost = Post(
        id: '',
        userId: userId,
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

  /* ==================== LIKES ==================== */
  // DOUBLE CHECK
  // Future<Post?> toggleLikeInDatabase(String postId) async {
  //   try {
  //     // get current userId
  //     String userId = _auth.currentUser!.id;
  //
  //     // Go to data for this post
  //     final postData = await _db
  //         .from('posts')
  //         .select('id, like_count, liked_by')
  //         .eq('id', postId)
  //         .maybeSingle();
  //
  //     if (postData == null) return null;
  //
  //     // list of users who liked this post
  //     List<String> likedBy = List<String>.from(postData['liked_by'] ?? []);
  //
  //     // get like count
  //     int likeCount = postData['like_count'] ?? 0;
  //
  //     // execute like
  //     if (likedBy.contains(userId)) {
  //       // Unlike
  //       likedBy.remove(userId);
  //       likeCount = likeCount > 0 ? likeCount - 1 : 0;
  //     } else {
  //       // Like
  //       likedBy.add(userId);
  //       likeCount += 1;
  //     }
  //
  //     // Update the post in DB
  //     final updatedPost = await _db
  //         .from('posts')
  //         .update({
  //       'liked_by': likedBy,
  //       'like_count': likeCount,
  //     })
  //         .eq('id', postId)
  //         .select()
  //         .maybeSingle();
  //
  //     if (updatedPost == null) return null;
  //
  //     return Post.fromMap(updatedPost);
  //   } catch (e) {
  //     print('Error toggling like: $e');
  //     return null;
  //   }
  // }

  // FIREBASE VERSION
  // Future<void> toggleLikeInDatabase(String postId) async {
  //   try {
  //     // get current userId
  //     String userId = _auth.currentUser!.id;
  //
  //     // go to doc for this post
  //     DocumentReference postDoc = _db.collection('posts').doc(postId);
  //
  //     // execute like
  //     await _db.runTransaction((transaction) async {
  //       // get post data
  //       DocumentSnapshot postSnapshot = await transaction.get(postDoc);
  //
  //       // get like of users who like this post
  //       List<String> likedBy = List<String>.from(snapshot['liked_by'] ?? []);
  //
  //       // get like count
  //       int currentLikeCount = postSnapshot['like_count'];
  //
  //       // if user has not liked this post yet -> then like
  //       if (!likedBy.contains(userId)) {
  //         // add user to like list
  //         likedBy.add(userId);
  //
  //         // increment the like count
  //         currentLikeCount++;
  //
  //         // if user has already liked this post -> then unlike
  //       } else {
  //         // remove user from like list
  //         likedBy.remove(userId);
  //
  //         // decrement like count
  //         currentLikeCount--;
  //       }
  //
  //       // update in database
  //       transaction.update(postDoc, {
  //         'like_count': currentLikeCount,
  //         'liked_by': likedBy,
  //       });
  //     });
  //   } catch (e) {}
  // }

  /// Toggle like for a post
  Future<void> toggleLikeInDatabase(String postId) async {
    try {
      final userId = _auth.currentUser!.id;

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
      if (!likedBy.contains(userId)) {
        likedBy.add(userId);
        likeCount++;
      } else {
        likedBy.remove(userId);
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
      String userId = _auth.currentUser!.id;
      UserProfile? user = await getUserFromDatabase(userId);

      // create a new comment
      Comment newComment = Comment(
          id: '',
          postId: postId,
          userId: userId,
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
      final currentUserId = _db.auth.currentUser?.id;

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

  Future<void> blockUserInDatabase(String userId) async {
    try {
      final currentUser = _db.auth.currentUser?.id;
      if (currentUser == null) return;

      final data = await _db.from('profiles').select('blocked_users').eq('id', currentUser).single();
      final blocked = (data['blocked_users'] ?? [])..add(userId);

      await _db.from('profiles').update({'blocked_users': blocked}).eq('id', currentUser);
    } catch (e) {
      print("Error blocking user: $e");
    }
  }

  Future<void> unblockUserInDatabase(String userId) async {
    try {
      final currentUser = _db.auth.currentUser?.id;
      if (currentUser == null) return;

      // fetch and update blocked_users array in one go
      final data = await _db.from('profiles').select('blocked_users').eq('id', currentUser).single();
      final blocked = List<String>.from(data['blocked_users'] ?? [])..remove(userId);

      await _db.from('profiles').update({'blocked_users': blocked}).eq('id', currentUser);
    } catch (e) {
      print("Error unblocking user: $e");
    }
  }

  Future<List<String>> getBlockedUserIdsFromDatabase() async {
    try {
      final currentUser = _db.auth.currentUser?.id;
      if (currentUser == null) return [];

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
  Future<void> followUser(String targetUserId) async {
    final currentUserId = _auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _db.from('follows').insert({
        'follower_id': currentUserId,
        'followed_id': targetUserId,
      });
    } catch (e) {
      print("Error following user: $e");
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    final currentUserId = _auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _db
          .from('follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('followed_id', targetUserId);
    } catch (e) {
      print("Error unfollowing user: $e");
    }
  }

  Future<List<String>> getFollowerUserIds(String userId) async {
    try {
      final List data = await _db
          .from('follows')
          .select('follower_id')
          .eq('followed_id', userId);
      return data.map((e) => e['follower_id'] as String).toList();
    } catch (e) {
      print("Error getting followers: $e");
      return [];
    }
  }

  Future<List<String>> getFollowingUserIds(String userId) async {
    try {
      final List data = await _db
          .from('follows')
          .select('followed_id')
          .eq('follower_id', userId);
      return data.map((e) => e['followed_id'] as String).toList();
    } catch (e) {
      print("Error getting following: $e");
      return [];
    }
  }

  Future<void> removeFollower(String userId) async {
    final currentUserId = _auth.currentUser?.id;
    if (currentUserId == null) return;

    await _db.from('followers').delete().match({
      'follower_id': userId,
      'following_id': currentUserId,
    });
  }


  /* ==================== DELETE USER ==================== */
  Future<void> deleteUser(String userId) async {
    try {
      await _db.from('posts').delete().eq('userId', userId);
      await _db.from('comments').delete().eq('userId', userId);
      await _db.from('post_likes').delete().eq('userId', userId);
      await _db
          .from('follows')
          .delete()
          .or('follower_id.eq.$userId,followed_id.eq.$userId');
      await _db
          .from('blocks')
          .delete()
          .or('blocker_id.eq.$userId,blocked_id.eq.$userId');
      await _db.from('profiles').delete().eq('id', userId);
    } catch (e) {
      debugPrint('Error deleting user: $e');
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
