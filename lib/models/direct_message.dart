class DirectMessage {
  final String id;
  final String content;
  final String senderPubkey;
  final String recipientPubkey;
  final DateTime createdAt;
  final bool isFromMe;
  final bool isRead;

  DirectMessage({
    required this.id,
    required this.content,
    required this.senderPubkey,
    required this.recipientPubkey,
    required this.createdAt,
    required this.isFromMe,
    this.isRead = false,
  });

  DirectMessage copyWith({
    String? id,
    String? content,
    String? senderPubkey,
    String? recipientPubkey,
    DateTime? createdAt,
    bool? isFromMe,
    bool? isRead,
  }) {
    return DirectMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderPubkey: senderPubkey ?? this.senderPubkey,
      recipientPubkey: recipientPubkey ?? this.recipientPubkey,
      createdAt: createdAt ?? this.createdAt,
      isFromMe: isFromMe ?? this.isFromMe,
      isRead: isRead ?? this.isRead,
    );
  }
}