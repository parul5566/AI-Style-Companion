/// Chat models — match backend ChatMessageResponse + ChatConversationResponse.

class ChatMessage {
  final int? id;
  final int conversationId;
  final String role;
  final String content;
  final DateTime? createdAt;

  ChatMessage({
    this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int?,
      conversationId: json['conversation_id'] as int,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class ChatConversation {
  final int id;
  final String? title;
  final String contextType;
  final List<ChatMessage> messages;
  final DateTime? createdAt;

  ChatConversation({
    required this.id,
    this.title,
    required this.contextType,
    this.messages = const [],
    this.createdAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as int,
      title: json['title'] as String?,
      contextType: json['context_type'] as String? ?? 'general',
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
