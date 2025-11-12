import 'package:flutter/material.dart';
import 'package:my_supabase_app/services/auth/auth_service.dart';
import 'package:my_supabase_app/services/chat/chat_service.dart';
import '../components/my_chat_bubble.dart';
import '../components/my_chat_text_field.dart';

/// ChatPage handles a one-on-one conversation between the current user
/// and a friend. It supports real-time updates via Supabase streams,
/// optimistic UI updates for instant feedback, and keeps messages
/// in chronological order (oldest at top, newest at bottom).
class ChatPage extends StatefulWidget {
  final String friendId;
  final String friendName;

  const ChatPage({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  /// Local cache of messages
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();

    // Scroll to bottom when the input field gains focus
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), scrollDown);
      }
    });

    // Start listening to messages as soon as the page loads
    _listenToMessages();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Smoothly scrolls the chat to the bottom
  void scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Listen to messages from Supabase stream and merge them into
  /// the local _messages list, ensuring chronological order
  void _listenToMessages() async {
    final currentUserId = _authService.getCurrentUserId();
    if (currentUserId == null) return;

    _chatService.getMessages(currentUserId, widget.friendId).listen((messageBatch) {
      setState(() {
        // Merge new messages with existing messages
        final all = [..._messages, ...messageBatch];

        // Remove duplicates by message ID
        final ids = <String>{};
        _messages = all.where((m) => ids.add(m['id'])).toList()

        // Sort messages by creation time (oldest → newest)
          ..sort((a, b) => DateTime.parse(a['created_at'])
              .compareTo(DateTime.parse(b['created_at'])));
      });

      // Scroll to bottom after new messages arrive
      scrollDown();
    });
  }

  /// Sends a message using optimistic UI update for instant feedback
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = _authService.getCurrentUserId();
    if (currentUserId == null) return;

    final now = DateTime.now().toUtc();

    // 1️⃣ Add an optimistic message to the UI immediately
    final optimisticMessage = {
      'id': 'temp-${now.millisecondsSinceEpoch}', // temporary ID
      'chat_room_id': '',
      'sender_id': currentUserId,
      'receiver_id': widget.friendId,
      'message': text,
      'created_at': now.toIso8601String(),
    };

    setState(() {
      _messages.add(optimisticMessage);
      _messages.sort((a, b) => DateTime.parse(a['created_at'])
          .compareTo(DateTime.parse(b['created_at'])));
    });

    _messageController.clear();
    scrollDown();

    // 2️⃣ Send message to Supabase
    try {
      final dbMessage = await _chatService.sendMessage(widget.friendId, text);

      if (dbMessage != null) {
        setState(() {
          // Remove optimistic message and replace with actual DB message
          _messages.removeWhere((m) => m['id'] == optimisticMessage['id']);
          _messages.add(dbMessage);

          // Ensure messages remain sorted
          _messages.sort((a, b) => DateTime.parse(a['created_at'])
              .compareTo(DateTime.parse(b['created_at'])));
        });
      }
    } catch (e) {
      print('Error sending message: $e');

      // Remove optimistic message if sending fails
      setState(() {
        _messages.removeWhere((m) => m['id'] == optimisticMessage['id']);
      });
    }

    scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.getCurrentUserId();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friendName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          // Expanded message list
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
              controller: _scrollController,
              reverse: true, // 🔹 Keep newest messages at bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                // Because the list is reversed, fetch from the end
                final msg = _messages[_messages.length - 1 - index];
                final isCurrentUser = msg['sender_id'] == currentUserId;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                  child: Align(
                    alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: ChatBubble(
                      message: msg['message'] ?? '',
                      isCurrentUser: isCurrentUser,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
            child: MyChatTextField(
              controller: _messageController,
              focusNode: _focusNode,
              onSendPressed: _sendMessage,
              onEmojiPressed: () {
                print("Emoji button pressed");
              },
              onAttachmentPressed: () {
                print("Attachment button pressed");
              },
            ),
          ),
        ],
      ),
    );
  }
}
