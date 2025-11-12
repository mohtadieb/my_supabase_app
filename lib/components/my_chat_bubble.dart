import 'package:flutter/material.dart';

/// A simple chat bubble that adapts to the app's current theme.
///
/// - Uses Theme.of(context).colorScheme for colors
/// - Aligns right for current user, left for friend
/// - Smooth rounded WhatsApp-style shape
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // 🟢 Sender (current user) bubble style
    final senderBg = const Color(0xFF128C7E); // WhatsApp green
    final senderText = Colors.white;

    // ⚪ Receiver bubble style (theme-aware)
    final receiverBg = colors.tertiary;
    final receiverText = colors.inversePrimary;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser ? senderBg : receiverBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
            isCurrentUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
            isCurrentUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isCurrentUser ? senderText : receiverText,
            fontSize: 16,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
