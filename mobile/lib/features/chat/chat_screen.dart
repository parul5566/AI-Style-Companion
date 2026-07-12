/// AI Chat screen — fashion assistant conversation.
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/chat_model.dart';
import '../../data/services/api_client.dart';
import '../../shared/widgets/widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  int? _conversationId;
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await ApiClient.getConversations();
      if (conversations.isNotEmpty) {
        final conv = ChatConversation.fromJson(conversations.first as Map<String, dynamic>);
        _conversationId = conv.id;
        _messages.addAll(conv.messages);
        _scrollToBottom();
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    // Add user message immediately
    setState(() {
      _messages.add(ChatMessage(
        conversationId: _conversationId ?? 0,
        role: 'user',
        content: text,
      ));
      _isSending = true;
    });
    _messageCtrl.clear();
    _scrollToBottom();

    try {
      final json = await ApiClient.sendChatMessage({
        'message': text,
        if (_conversationId != null) 'conversation_id': _conversationId,
      });
      final aiMsg = ChatMessage.fromJson(json);
      _conversationId = aiMsg.conversationId;
      setState(() => _messages.add(aiMsg));
    } catch (_) {
      setState(() {
        _messages.add(ChatMessage(
          conversationId: _conversationId ?? 0,
          role: 'assistant',
          content: 'Sorry, I couldn\'t respond. Please try again.',
        ));
      });
    }
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Fashion Assistant')),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const LoadingSpinner(message: 'Loading conversations...')
                : _messages.isEmpty
                    ? _buildWelcome()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isSending ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == _messages.length && _isSending) {
                            return _buildTypingIndicator();
                          }
                          return _buildMessageBubble(_messages[i]);
                        },
                      ),
          ),

          // Quick suggestions
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  'What should I wear today?',
                  'How do I style a blazer?',
                  'What colors go with navy?',
                  'Help me dress for an interview',
                ].map((q) => ActionChip(
                  label: Text(q),
                  onPressed: () {
                    _messageCtrl.text = q;
                    _sendMessage();
                  },
                  backgroundColor: AppTheme.surfaceLight,
                )).toList(),
              ),
            ),
          const SizedBox(height: 8),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.support_agent, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('Your AI Stylist', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Ask me anything about fashion, styling, or your wardrobe!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : AppTheme.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(msg.content, style: TextStyle(
          color: isUser ? Colors.white : AppTheme.textPrimary, fontSize: 14, height: 1.4,
        )),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: _DotAnimation(delay: i * 300),
          )),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageCtrl,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask your stylist...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primary),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated dot for typing indicator.
class _DotAnimation extends StatefulWidget {
  final int delay;
  const _DotAnimation({required this.delay});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Opacity(
          opacity: 0.3 + (_ctrl.value * 0.7),
          child: child,
        );
      },
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(color: AppTheme.textSecondary, shape: BoxShape.circle),
      ),
    );
  }
}
