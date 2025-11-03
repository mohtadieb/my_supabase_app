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
  // // DOUBLE CHECK
  // UserProfile? _currentUser;
  // UserProfile? get currentUser => _currentUser;
  //
  // Future<UserProfile?> getUserProfile(String userId) async {
  //   // Return cached version if already loaded
  //   if (_currentUser != null && _currentUser!.id == userId) return _currentUser;
  //
  //   try {
  //     final user = await _db.getUserFromDatabase(userId);
  //     if (user != null) {
  //       _currentUser = user;
  //       notifyListeners();
  //     }
  //     return user;
  //   } catch (e) {
  //     debugPrint('Error fetching user profile: $e');
  //     return null;
  //   }
  // }

  // Get user profile given userId
  Future<UserProfile?> getUserProfile(String userId) => _db.getUserFromDatabase(userId);

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

  // Update user bio
  Future<void> updateBio(String bio) => _db.updateUserBioInDatabase(bio);

  /* ==================== POSTS ==================== */
  List<Post> _allPosts = [];
  List<Post> _followingPosts = [];
  List<Post> get allPosts => _allPosts;
  List<Post> get followingPosts => _followingPosts;

  List<Post> getUserPosts(String userId) =>
      _allPosts.where((post) => post.userId == userId).toList();

  Future<void> postMessage(String message) async {
    final currentUserId = _auth.getCurrentUserId();
    if (currentUserId.isEmpty || message.trim().isEmpty) return;

    try {
      // Create the post in DB
      final newPost = await _db.postMessage(message);
      if (newPost == null) return;

      // Update local lists
      _allPosts.insert(0, newPost);

      // Update following posts if needed
      final followingIds = await _db.getFollowingUserIds(currentUserId);
      if (followingIds.contains(newPost.userId)) {
        _followingPosts.insert(0, newPost);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error posting message: $e');
    }
  }

  Future<void> loadAllPosts() async {
    try {
      // ✅ 1. Fetch blocked users first
      await loadBlockedUsers();
      final blockedIds = _blockedUsers.map((u) => u.id).toSet();

      // ✅ 2. Fetch all posts
      _allPosts = await _db.getAllPosts();

      // ✅ 3. Initialize likes
      await initializeLikes(_allPosts);

      // ✅ 4. Filter out blocked users' posts
      _allPosts = _allPosts.where((post) => !blockedIds.contains(post.userId)).toList();

      // ✅ 5. Load following posts (also filtered)
      await loadFollowingPosts();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading posts: $e');
    }
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

  Future<void> deletePost(String postId) async {
    try {
      // Call the service to delete from database
      await _db.deletePost(postId);

      // Update local state
      _allPosts.removeWhere((post) => post.id == postId);

      // Optionally reload posts from DB if needed
      await loadAllPosts();

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }

  /* ==================== LIKES ==================== */
  Map<String, int> _likeCounts = {};
  Map<String, List<String>> _likedByMap = {}; // postId -> list of userIds

  bool isPostLikedByCurrentUser(String postId) {
    final currentUserId = _auth.getCurrentUserId();
    return _likedByMap[postId]?.contains(currentUserId) ?? false;
  }

  int getLikeCount(String postId) => _likeCounts[postId] ?? 0;

  /// Initialize likes for a list of posts
  Future<void> initializeLikes(List<Post> posts) async {
    _likeCounts.clear();
    _likedByMap.clear();

    for (final post in posts) {
      _likeCounts[post.id] = post.likeCount;
      _likedByMap[post.id] = post.likedBy;
    }

    notifyListeners();
  }

  /// Toggle like for a post
  Future<void> toggleLike(String postId) async {
    final currentUserId = _auth.getCurrentUserId();
    if (currentUserId.isEmpty) return;

    try {
      // Call database service
      final updatedPost = await _db.toggleLike(currentUserId, postId);
      if (updatedPost == null) return;

      // Update local state
      _likeCounts[postId] = updatedPost.likeCount;
      _likedByMap[postId] = updatedPost.likedBy;

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
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

  Future<void> blockUser(String userId) async {
    final currentUserId = _auth.getCurrentUserId();
    if (currentUserId.isEmpty) return;

    try {
      // ✅ 1. Block the user in the database
      await _db.blockUser(userId);

      // ✅ 2. Unfollow each other in the database
      await _db.unfollowUser(userId);
      await _db.removeFollower(userId);

      // ✅ 3. Remove likes between the two users in the database
      await _db.removeLikesBetweenUsers(currentUserId, userId);

      // ✅ 4. Update local state instantly (no hot restart needed)
      _allPosts.removeWhere((post) => post.userId == userId);
      _followingPosts.removeWhere((post) => post.userId == userId);

      // Remove from following/follower maps in memory
      _following[currentUserId]?.remove(userId);
      _followers[userId]?.remove(currentUserId);

      // Clean up local like maps
      _likedByMap.forEach((postId, likedBy) {
        likedBy.remove(userId);
      });
      _likeCounts.removeWhere((postId, _) {
        final likedBy = _likedByMap[postId];
        return likedBy != null && likedBy.contains(userId);
      });

      // ✅ 5. Reload data from database for consistency
      await loadBlockedUsers();
      await loadUserFollowing(currentUserId);
      await loadUserFollowers(currentUserId);

      notifyListeners(); // refresh UI immediately
    } catch (e) {
      debugPrint('Error blocking user: $e');
    }
  }

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