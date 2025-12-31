// lib/screens/chat_bot_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart'; // Ensure kAccentOrange is here
import '../api/chat_repository.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});
  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final ChatRepository _repository = ChatRepository();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {"text": "Namaste! I am your Bank Assistant. How can I help you today?", "isUser": false},
  ];
  bool _isTyping = false;

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add({"text": text, "isUser": true});
      _isTyping = true;
    });
    _scrollToBottom();

    // Call Repository logic
    final response = await _repository.getBotResponse(text);

    setState(() {
      _isTyping = false;
      _messages.add({"text": response, "isUser": false});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bank Assistant", style: TextStyle(color: Colors.white)),
        backgroundColor: kAccentOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _ChatBubble(text: msg['text'], isUser: msg['isUser']);
              },
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.centerLeft,
      child: const Text("Assistant is thinking...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: "Ask about Transfer, Nominee, FD...", border: InputBorder.none),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          CircleAvatar(
            backgroundColor: kAccentOrange,
            child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _handleSend),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isUser ? Colors.blue.withOpacity(0.2) : kAccentOrange.withOpacity(0.2)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}