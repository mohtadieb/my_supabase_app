import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_supabase_app/services/auth/auth_service.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _auth = AuthService();

  /// Stream all users from 'profiles'
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((rows) {
      print('User rows: $rows');
      return rows.map((row) => row as Map<String, dynamic>).toList();
    });
  }

  /// Send a message and return the inserted DB record
  Future<Map<String, dynamic>?> sendMessage(
      String receiverId, String message) async {
    final senderId = _auth.getCurrentUserId();
    if (senderId == null || receiverId.isEmpty) return null;

    // 1️⃣ Find existing chat room (symmetric check)
    final existingRoom = await _supabase
        .from('chat_rooms')
        .select('id')
        .or(
      'and(user1_id.eq.$senderId,user2_id.eq.$receiverId),and(user1_id.eq.$receiverId,user2_id.eq.$senderId)',
    )
        .maybeSingle();

    late final String chatRoomId;

    if (existingRoom != null) {
      chatRoomId = existingRoom['id'];
      print('Using existing chat room: $chatRoomId');
    } else {
      // 2️⃣ Create a new chat room if none exists
      final newRoom = await _supabase
          .from('chat_rooms')
          .insert({'user1_id': senderId, 'user2_id': receiverId})
          .select()
          .maybeSingle();

      if (newRoom == null) {
        print('Error: failed to create new chat room');
        return null;
      }

      chatRoomId = newRoom['id'];
      print('Created new chat room: $chatRoomId');
    }

    // 3️⃣ Insert message
    final insertRes = await _supabase.from('messages').insert({
      'chat_room_id': chatRoomId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }).select().maybeSingle();

    print('Message inserted: $insertRes');
    return insertRes;
  }

  /// Stream messages between two users
  Stream<List<Map<String, dynamic>>> getMessages(
      String currentUserId, String friendId) async* {
    // Get chat room ID (symmetric)
    final room = await _supabase
        .from('chat_rooms')
        .select('id')
        .or(
      'and(user1_id.eq.$currentUserId,user2_id.eq.$friendId),and(user1_id.eq.$friendId,user2_id.eq.$currentUserId)',
    )
        .maybeSingle();

    if (room == null) {
      print('No chat room exists yet.');
      yield [];
      return;
    }

    final chatRoomId = room['id'];
    print('Streaming messages for chatRoomId: $chatRoomId');

    // Stream messages in real-time
    yield* _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_room_id', chatRoomId)
        .order('created_at')
        .map((rows) {
      print('Message batch: $rows');
      return rows.map((row) => row as Map<String, dynamic>).toList();
    });
  }
}
