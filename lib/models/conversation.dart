import 'nostr_profile.dart';

class Conversation {
  final NostrProfile profile;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.profile,
    this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  Conversation copyWith({
    NostrProfile? profile,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return Conversation(
      profile: profile ?? this.profile,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}