/*
DATABASE PROVIDER

This provider is to separate the firestore data handling and the UI of out app.

--------------------------------------------------------------------------------

- The database service class handles data to and from supabase
- The database provider class processes the data to display in our app.

This is to make out code more modular, cleaner, and easier to read and test.
Particularly as the number of pages grow, we need this provider to properly manage
the different states of the app.

- Also, if one day, we decide to change out backend (from supabase to something else)
the it's much easier to manage and switch out different databases.

*/

import 'package:flutter/foundation.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import '../auth/auth_service.dart';
import 'database_service.dart';

class DatabaseProvider extends ChangeNotifier {

  // Get db & auth service
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();

  /* ==================== USER PROFILE ==================== */

  /// Get user profile given userId
  Future<UserProfile?> getUserProfile(String userId) => _db.getUserFromDatabase(userId);

  // DOUBLE CHECK
  // Future<void> updateBio(String bio) async {
  //   final currentUserId = _auth.getCurrentUserId();
  //   if (currentUserId.isEmpty) return;
  //
  //   try {
  //     // ✅ Delegate database update to DatabaseService
  //     await _db.updateUserBioInDatabase(bio);
  //
  //     // ✅ Update local cached user profile
  //     if (_currentUser != null) {
  //       _currentUser = _currentUser!.copyWith(bio: bio);
  //     }
  //
  //     notifyListeners();
  //   } catch (e) {
  //     debugPrint('Error updating bio: $e');
  //   }
  // }

  /// Update user bio
  Future<void> updateBio(String bio) => _db.updateUserBioInDatabase(bio);

  /* ==================== POSTS ==================== */

  //local list of posts
  List<Post> _allPosts = [];
  List<Post> _followingPosts = [];

  // get posts
  List<Post> get allPosts => _allPosts;
  List<Post> get followingPosts => _followingPosts;



  // Future<void> postMessage(String message) async {
  //   final currentUserId = _auth.getCurrentUserId();
  //   if (currentUserId.isEmpty || message.trim().isEmpty) return;
  //
  //   try {
  //     // Create the post in DB
  //     final newPost = await _db.postMessageInDatabase(message);
  //     if (newPost == null) return;
  //
  //     // Update local lists
  //     _allPosts.insert(0, newPost);
  //
  //     // Update following posts if needed
  //     final followingIds = await _db.getFollowingUserIds(currentUserId);
  //     if (followingIds.contains(newPost.userId)) {
  //       _followingPosts.insert(0, newPost);
  //     }
  //
  //     notifyListeners();
  //   } catch (e) {
  //     debugPrint('Error posting message: $e');
  //   }
  // }

  /// post message
  Future<void> postMessage(String message) async {
    // post message in database
    await _db.postMessageInDatabase(message);

    await loadAllPosts();
  }

  /// fetch all posts
  // DOUBLE CHECK
  Future<void> loadAllPosts() async {
    try {
      // // ✅ 1. Fetch blocked users first
      // await loadBlockedUsers();
      // final blockedIds = _blockedUsers.map((u) => u.id).toSet();

      // ✅ 2. Fetch all posts
      final allPosts = await _db.getAllPostsFromDatabase();

      // update local data
      _allPosts = allPosts;

      // ✅ 3. Initialize local like data
      initializeLikeMap();

      // // ✅ 4. Filter out blocked users' posts
      // _allPosts = _allPosts.where((post) => !blockedIds.contains(post.userId)).toList();

      // // ✅ 5. Load following posts (also filtered)
      // await loadFollowingPosts();

      // Update UI
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading posts: $e');
    }
  }

  /// filter and return posts for given UserId
  List<Post> getUserPosts(String userId) {
    return _allPosts.where((post) => post.userId == userId).toList();
  }

  /// EXTRA ///
  /// Returns a list of posts that the current user has liked
  List<Post> getPostsLikedByCurrentUser(List<Post> allPosts) {
    final currentUserId = _auth.getCurrentUserId();

    return allPosts.where((post) => post.likedBy.contains(currentUserId)).toList();
  }

  Future<void> loadFollowingPosts() async {
    final currentUserId = _auth.getCurrentUserId();
    if (currentUserId.isEmpty) return;

    try {
      final followingIds = await _db.getFollowingUserIds(currentUserId);

      _followingPosts =
          _allPosts.where((p) => followingIds.contains(p.userId)).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading following posts: $e');
    }
  }

  /// delete post
  Future<void> deletePost(String postId) async {
    try {
      // Call the service to delete from database
      await _db.deletePostFromDatabase(postId);

      // // Update local state
      // _allPosts.removeWhere((post) => post.id == postId);

      // reload data from database (notifies listeners)
      await loadAllPosts();

    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }

  /* ==================== LIKES ==================== */
  // Local map to track like counts for each post
  Map<String, int> _likeCounts = {
    // for each postId: like count
  };

  // local list to track posts liked by current user
  List<String> _likedPosts = [];

  // does current user like this post?
  bool isPostLikedByCurrentUser(String postId) => _likedPosts.contains(postId);

  // get like count of a post
  int getLikeCount(String postId) => _likeCounts[postId] ?? 0;

  /// initialize like map locally
  void initializeLikeMap() {
    // get current user ID
    final currentUserId = _auth.getCurrentUserId();

    // clear liked posts ( for when a new user signs in, clear local data)
    _likeCounts.clear();
    _likedPosts.clear();

    // for each post get like data
    for (var post in _allPosts) {
      // update like count map
      _likeCounts[post.id!] = post.likeCount;

      // if the current user already likes this post
      if (post.likedBy.contains(currentUserId)) {
        // add this post id to local list of liked posts
        _likedPosts.add(post.id!);
      }
    }
  }

  /// Toggle like for a post
  Future<void> toggleLike(String postId) async {
    /*

    The first part will update local values first so that the UI feels
    immediate and responsive. We will update the UI optimistically, and revert
    back if anything goes wrong while writing to the database.

    Optimistically updating the local values like this is important because:
    reading and writing from the database takes some time (1-2 seconds, depending
    on the internet connection). So we don't want to give the user a slow lagged
    experience.

     */

    // store original values
    final likedPostsOriginal = _likedPosts;
    final likeCountsOriginal = _likeCounts;

    // perform like / unlike
    if(_likedPosts.contains(postId)) {
      _likedPosts.remove(postId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) - 1;
    } else {
      _likedPosts.add(postId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
    }

    // update UI locally
    notifyListeners();

    /*

    now let's try to update it in our database

     */

    // Attempt like in database
    try {
      await _db.toggleLikeInDatabase(postId);
    }
    // revert back to initial state if update fails
    catch (e) {
      _likedPosts = likedPostsOriginal;
      _likeCounts = likeCountsOriginal;
    }

    // update UI again
    notifyListeners();
  }


/* ==================== COMMENTS ==================== */
  final Map<String, List<Comment>> _comments = {};
  List<Comment> getComments(String postId) => _comments[postId] ?? [];

  Future<void> loadComments(String postId) async {
    try {
      _comments[postId] = await _db.getComments(postId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading comments: $e');
    }
  }

  Future<void> addComment(String postId, String message) async {
    if (message.trim().isEmpty) return;

    try {
      final newComment = await _db.addComment(postId, message);
      if (newComment != null) {
        _comments[postId] = [...getComments(postId), newComment];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _db.deleteComment(commentId);
      _comments[postId] =
          getComments(postId).where((c) => c.id != commentId).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting comment: $e');
    }
  }

  /* ==================== FOLLOWERS / FOLLOWING ==================== */
  final Map<String, List<String>> _followers = {};
  final Map<String, List<String>> _following = {};
  final Map<String, int> _followerCount = {};
  final Map<String, int> _followingCount = {};
  final Map<String, List<UserProfile>> _followerProfiles = {};
  final Map<String, List<UserProfile>> _followingProfiles = {};

  int getFollowerCount(String userId) => _followerCount[userId] ?? 0;
  int getFollowingCount(String userId) => _followingCount[userId] ?? 0;

  Future<void> loadUserFollowers(String userId) async {
    final followerIds = await _db.getFollowerUserIds(userId);
    _followers[userId] = followerIds;
    _followerCount[userId] = followerIds.length;
    notifyListeners();
  }

  Future<void> loadUserFollowing(String userId) async {
    final followingIds = await _db.getFollowingUserIds(userId);
    _following[userId] = followingIds;
    _followingCount[userId] = followingIds.length;
    notifyListeners();
  }

  Future<void> loadUserFollowerProfiles(String userId) async {
    final followerIds = _followers[userId] ?? [];
    final profiles = await Future.wait(followerIds.map((id) async {
      final data = await _db.getUserFromDatabase(id);
      return data!;
    }));
    _followerProfiles[userId] = profiles;
    notifyListeners();
  }

  Future<void> loadUserFollowingProfiles(String userId) async {
    final followingIds = _following[userId] ?? [];
    final profiles = await Future.wait(followingIds.map((id) async {
      final data = await _db.getUserFromDatabase(id);
      return data!;
    }));
    _followingProfiles[userId] = profiles;
    notifyListeners();
  }

  List<UserProfile> getListOfFollowersProfile(String userId) =>
      _followerProfiles[userId] ?? [];
  List<UserProfile> getListOfFollowingProfile(String userId) =>
      _followingProfiles[userId] ?? [];

  Future<void> followUser(String targetUserId) async {
    await _db.followUser(targetUserId);
    final currentUserId = _auth.getCurrentUserId();
    await loadUserFollowers(targetUserId);
    await loadUserFollowing(currentUserId);
  }

  Future<void> unfollowUser(String targetUserId) async {
    await _db.unfollowUser(targetUserId);
    final currentUserId = _auth.getCurrentUserId();
    await loadUserFollowers(targetUserId);
    await loadUserFollowing(currentUserId);
  }

  bool isFollowing(String userId) {
    final currentUserId = _auth.getCurrentUserId();
    return _followers[userId]?.contains(currentUserId) ?? false;
  }

  /* ==================== BLOCKED USERS ==================== */
  List<UserProfile> _blockedUsers = [];
  List<UserProfile> get blockedUsers => _blockedUsers;

  Future<void> loadBlockedUsers() async {
    final blockedIds = await _db.getBlockedUserIds();
    final profiles = await Future.wait(blockedIds.map((id) => _db.getUserFromDatabase(id)));
    _blockedUsers = profiles.whereType<UserProfile>().toList();
    notifyListeners();
  }

  // Future<void> blockUser(String userId) async {
  //   final currentUserId = _auth.getCurrentUserId();
  //   if (currentUserId.isEmpty) return;
  //
  //   try {
  //     // ✅ 1. Block the user in the database
  //     await _db.blockUser(userId);
  //
  //     // ✅ 2. Unfollow each other in the database
  //     await _db.unfollowUser(userId);
  //     await _db.removeFollower(userId);
  //
  //     // ✅ 3. Remove likes between the two users in the database
  //     await _db.removeLikesBetweenUsers(currentUserId, userId);
  //
  //     // ✅ 4. Update local state instantly (no hot restart needed)
  //     _allPosts.removeWhere((post) => post.userId == userId);
  //     _followingPosts.removeWhere((post) => post.userId == userId);
  //
  //     // Remove from following/follower maps in memory
  //     _following[currentUserId]?.remove(userId);
  //     _followers[userId]?.remove(currentUserId);
  //
  //     // Clean up local like maps
  //     _likedByMap.forEach((postId, likedBy) {
  //       likedBy.remove(userId);
  //     });
  //     _likeCounts.removeWhere((postId, _) {
  //       final likedBy = _likedByMap[postId];
  //       return likedBy != null && likedBy.contains(userId);
  //     });
  //
  //     // ✅ 5. Reload data from database for consistency
  //     await loadBlockedUsers();
  //     await loadUserFollowing(currentUserId);
  //     await loadUserFollowers(currentUserId);
  //
  //     notifyListeners(); // refresh UI immediately
  //   } catch (e) {
  //     debugPrint('Error blocking user: $e');
  //   }
  // }

  Future<void> unblockUser(String userId) async {
    await _db.unblockUser(userId);
    _blockedUsers.removeWhere((user) => user.id == userId);
    await loadAllPosts();
    notifyListeners();
  }

  Future<void> reportUser(String postId, String userId) async {
    await _db.reportUser(postId, userId);
  }

  // Future<void> deleteUser(String userId) async {
  //   await _db.deleteUser(userId);
  //   if (_currentUser?.id == userId) {
  //     _currentUser = null;
  //   }
  //   notifyListeners();
  // }

  /* ==================== SEARCH USERS ==================== */
  List<UserProfile> _searchResults = [];
  List<UserProfile> get searchResults => _searchResults;

  Future<void> searchUsers(String searchTerm) async {
    if (searchTerm.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      final results = await _db.searchUsers(searchTerm); // call service
      final currentUserId = _auth.getCurrentUserId();

      // Filter out current user
      _searchResults = results.where((u) => u.id != currentUserId).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error searching users: $e');
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // /* ==================== LOG OUT ==================== */
  // void clearAllCachedData() {
  //   _currentUser = null;
  //   _allPosts.clear();
  //   _followingPosts.clear();
  //   _likeCounts.clear();
  //   _likedByMap.clear();
  //   _comments.clear();
  //   _followers.clear();
  //   _following.clear();
  //   _searchResults.clear();
  //   _blockedUsers.clear();
  //   notifyListeners();
  // }

  /* ==================== TIME ==================== */

  DateTime? _serverNow;
  DateTime get serverNow => _serverNow ?? DateTime.now().toUtc();

  Future<void> syncServerTime() async {
    final fetchedTime = await _db.getServerTime();
    if (fetchedTime != null) {
      _serverNow = fetchedTime;
      notifyListeners();
    }
  }
}