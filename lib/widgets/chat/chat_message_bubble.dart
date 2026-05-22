import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:music_app/domain/entities/chat_message_entity.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMe;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final incomingColor = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.92)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.9);

    final textColor = isMe ? Colors.white : colorScheme.onSurface;
    final timeColor = isMe
        ? Colors.white.withValues(alpha: 0.6)
        : colorScheme.onSurface.withValues(alpha: 0.5);

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isMe
                      ? LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe ? null : incomingColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    message.content,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: textColor,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _buildTimestamp(timeColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp(Color timeColor) {
    if (message.isOptimistic) {
      return Opacity(
        opacity: 0.5,
        child: Icon(
          Icons.access_time_rounded,
          size: 11,
          color: timeColor,
        ),
      );
    }

    return Text(
      DateFormat('HH:mm').format(message.createdAt.toLocal()),
      style: GoogleFonts.dmSans(
        fontSize: 11,
        color: timeColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}