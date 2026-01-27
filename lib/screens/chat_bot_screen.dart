// lib/screens/chat_bot_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../theme/app_colors.dart'; // Ensure kAccentOrange is here

class ChatBotScreen extends ConsumerStatefulWidget {
  const ChatBotScreen({super.key});

  @override
  ConsumerState<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends ConsumerState<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text, ref);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final isTyping = ref.watch(isBotTypingProvider);

    // Auto-scroll when new messages arrive
    ref.listen(chatProvider, (prev, next) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assistant", style: TextStyle(color: Colors.white)),
        backgroundColor: kAccentOrange,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) => _ChatBubble(message: messages[index]),
            ),
          ),
          if (isTyping) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text("Thinking...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
          left: 10, right: 10, top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10
      ),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: "Ask about your profile, FD, or transfers...", border: InputBorder.none),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          IconButton(icon: const Icon(Icons.send, color: kAccentOrange), onPressed: _handleSend),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final dynamic message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.orange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kAccentOrange.withOpacity(0.2)),
        ),
        child: Text(message.text),
      ),
    );
  }
}