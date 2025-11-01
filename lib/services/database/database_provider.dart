/*
DATABASE PROVIDER (Full Supabase Version with `id` as primary key)

Handles all app state and Supabase data operations.
*/

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/comment.dart';
import '../../models/post.dart';
import '../../models/user.dart';
import 'database_service.dart';

class DatabaseProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService();


  /* ==================== USER PROFILE ==================== */
  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  Future<UserProfile?> userProfile(String uid) async {
    if (_currentUser != null && _currentUser!.id == uid) return _currentUser;
    try {
      final response =
      await supabase.from('profiles').select().eq('id', uid).maybeSingle();
      if (response == null) return null;
      _currentUser = UserProfile.fromMap(response);
      return _currentUser;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> updateBio(String bio) async {
    final currentUid = supabase.auth.currentUser?.id;
    if (currentUid == null) return;
    try {
      await supabase.from('profiles').update({'bio': bio}).eq('id', currentUid);
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(bio: bio);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating bio: $e');
    }
  }

  /* ==================== POSTS ==================== */
  List<Post> _allPosts = [];
  List<Post> _followingPosts = [];
  List<Post> get allPosts => _allPosts;
  List<Post> get followingPosts => _followingPosts;

  List<Post> getUserPosts(String uid) {
    return _allPosts.where((post) => post.uid == uid).toList();
  }

  Future<void> postMessage(String message) async {
    await _db.postMessage(message);
    await loadAllPosts(); // refresh local state
  }

  Future<void> loadAllPosts() async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);
      _allPosts = (response as List).map((e) => Post.fromMap(e)).toList();
      await loadFollowingPosts();
      await initializeLikeMap();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading posts: $e');
    }
  }

  Future<void> loadFollowingPosts() async {
    final currentUid = supabase.auth.currentUser?.id;
    if (currentUid == null) return;

    try {
      final response = await supabase
          .from('follows')
          .select('followed_id')
          .eq('follower_id', currentUid);
      final followingIds =
      (response as List).map((e) => e['followed_id'] as String).toList();
      _followingPosts =
          _allPosts.where((p) => followingIds.contains(p.uid)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading following posts: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await supabase.from('posts').delete().eq('id', postId);
      await loadAllPosts();
    } catch (e) {
      debugPrint('Error deleting post: $e');
    }
  }

  /* ==================== LIKES ==================== */
  Map<String, int> _likeCounts = {};
  List<String> _likedPosts = [];

  bool isPostLikedByCurrentUser(String postId) => _likedPosts.contains(postId);
  int getLikeCount(String postId) => _likeCounts[postId] ?? 0;

  Future<void> initializeLikeMap() async {
    final currentUid = supabase.auth.currentUser?.id;
    if (currentUid == null) return;

    _likeCounts.clear();
    _likedPosts.clear();

    for (final post in _allPosts) {
      _likeCounts[post.id] = post.likeCount;
      final res = await supabase
          .from('post_likes')
          .select()
          .eq('post_id', post.id)
          .eq('uid', currentUid);
      if ((res as List).isNotEmpty) _likedPosts.add(post.id);
    }
  }

  Future<void> toggleLike(String postId) async {
    final currentUid = supabase.auth.currentUser?.id;
    if (currentUid == null) return;

    final originalLikes = List<String>.from(_likedPosts);
    final originalCounts = Map<String, int>.from(_likeCounts);

    if (_likedPosts.contains(postId)) {
      _likedPosts.remove(postId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) - 1;
    } else {
      _likedPosts.add(postId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
    }
    notifyListeners();

    try {
      if (_likedPosts.contains(postId)) {
        await supabase
            .from('post_likes')
            .insert({'post_id': postId, 'uid': currentUid});
      } else {
        await supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('uid', currentUid);
      }
    } catch (e) {
      _likedPosts = originalLikes;
      _likeCounts = originalCounts;
      notifyListeners();
      debugPrint('Error toggling like: $e');
    }
  }

  /* ==================== COMMENTS ==================== */
  final Map<String, List<Comment>> _comments = {};
  List<Comment> getComments(String postId) => _comments[postId] ?? [];

  Future<void> loadComments(String postId) async {
    try {
      final response = await supabase
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at');
      _comments[postId] =
          (response as List).map((e) => Comment.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading comments: $e');
    }
  }

  Future<void> addComment(String postId, String message) async {
    final currentUid = supabase.auth.currentUser?.id;
    if (currentUid == null || message.trim().isEmpty) return;

    final user = await userProfile(currentUid);
    if (user == null) return;

    try {
      await supabase.from('comments').insert({
        'post_id': postId,
        'uid': currentUid,
        'name': user.name,
        'username': user.username,
        'message': message.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
      await loadComments(postId);
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await supabase.from('comments').delete().eq('id', commentId);
      await loadComments(postId);
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

  int getFollowerCount(String uid) => _followerCount[uid] ?? 0;
  int getFollowingCount(String uid) => _followingCount[uid] ?? 0;

  Future<void> loadUserFollowers(String uid) async {
    try {
      final response =
      await supabase.from('follows').select('follower_id').eq('followed_id', uid);
      final followers =
      (response as List).map((e) => e['follower_id'] as String).toList();
      _followers[uid] = followers;
      _followerCount[uid] = followers.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading followers: $e');
    }
  }

  Future<void> loadUserFollowing(String uid) async {
    try {
      final response =
      await supabase.from('follows').select('followed_id').eq('follower_id', uid);
      final following =
      (response as List).map((e) => e['followed_id'] as String).toList();
      _following[uid] = following;
      _followingCount[uid] = following.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading following: $e');
    }
  }

  Future<void> loadUserFollowerProfiles(String uid) async {
    try {
      final followerIds = _followers[uid] ?? [];
      final profiles = await Future.wait(followerIds.map((id) async {
        final data =
        await supabase.from('profiles').select().eq('id', id).maybeSingle();
        return UserProfile.fromMap(data!);
      }));
      _followerProfiles[uid] = profiles;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading follower profiles: $e');
    }
  }

  Future<void> loadUserFollowingProfiles(String uid) async {
    try {
      final followingIds = _following[uid] ?? [];
      final profiles = await Future.wait(followingIds.map((id) async {
        final data =
        await supabase.from('profiles').select().eq('id', id).maybeSingle();
        return UserProfile.fromMap(data!);
      }));
      _followingProfiles[uid] = profiles;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading following profiles: $e');
    }
  }

  List<UserProfile> getListOfFollowersProfile(String uid) =>
      _followerProfiles[uid] ?? [];
  List<UserProfile> getListOfFollowingProfile(String uid) =>
      _followingProfiles[uid] ?? [];

  Future<void> followUser(String targetUserId) async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    try {
      await supabase
          .from('follows')
          .insert({'follower_id': currentUserId, 'followed_id': targetUserId});
      await loadUserFollowers(targetUserId);
      await loadUserFollowing(currentUserId);
    } catch (e) {
      debugPrint('Error following user: $e');
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    try {
      await supabase
          .from('follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('followed_id', targetUserId);
      await loadUserFollowers(targetUserId);
      await loadUserFollowing(currentUserId);
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
    }
  }

  bool isFollowing(String uid) {
    final currentUserId = supabase.auth.currentUser?.id;
    return _followers[uid]?.contains(currentUserId) ?? false;
  }

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
      final response = await supabase
          .from('profiles')
          .select()
          .ilike('username', '%$searchTerm%');
      _searchResults =
          (response as List).map((e) => UserProfile.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching users: $e');
    }
  }

  void clearSearchResults() {
    if (_searchResults.isNotEmpty) {
      _searchResults = [];
      notifyListeners();
    }
  }

  /* ==================== BLOCKED USERS ==================== */
  List<UserProfile> _blockedUsers = [];
  List<UserProfile> get blockedUsers => _blockedUsers;

  Future<void> loadBlockedUsers() async {
    final currentUid = supabase.auth.currentUser?.id;
    if (currentUid == null) return;

    try {
      final response =
      await supabase.from('blocks').select('blocked_id, blocker_id');
      final blockedIds = (response as List)
          .where((b) => b['blocker_id'] == currentUid)
          .map((e) => e['blocked_id'] as String)
          .toList();

      final profiles = await Future.wait(blockedIds.map((id) async {
        final profileData =
        await supabase.from('profiles').select().eq('id', id).maybeSingle();
        return UserProfile.fromMap(profileData!);
      }));

      _blockedUsers = profiles;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
    }
  }

  Future<void> blockUser(String userId) async {
    final currentUid = supabase.auth.currentUser?.id;
    if (currentUid == null) return;

    try {
      await supabase
          .from('blocks')
          .insert({'blocker_id': currentUid, 'blocked_id': userId});
      await loadBlockedUsers();
    } catch (e) {
      debugPrint('Error blocking user: $e');
    }
  }

  Future<void> reportUser(String postId, String uid) async {
    final currentUid = supabase.auth.currentUser?.id;
    if (currentUid == null) return;

    try {
      await supabase.from('reports').insert({
        'post_id': postId,
        'reported_by': currentUid,
        'reported_user': uid,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error reporting user: $e');
    }
  }

  Future<void> unblockUser(String blockedUserId) async {
    final currentUid = supabase.auth.currentUser?.id;
    if (currentUid == null) return;

    try {
      await supabase
          .from('blocks')
          .delete()
          .eq('blocker_id', currentUid)
          .eq('blocked_id', blockedUserId);
      _blockedUsers.removeWhere((user) => user.id == blockedUserId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error unblocking user: $e');
    }
  }

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
      await supabase.from('profiles').delete().eq('id', uid);
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }
}
