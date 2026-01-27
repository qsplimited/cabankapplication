// lib/providers/chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/mock_chat_repository.dart';
import '../api/i_chat_repository.dart';
import '../models/chat_message_model.dart';

// Provides the repository instance
final chatRepositoryProvider = Provider<IChatRepository>((ref) => MockChatRepository());

// Tracks if the bot is "Thinking"
final isBotTypingProvider = StateProvider<bool>((ref) => false);

// Manages the list of chat messages
final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessageModel>>((ref) {
  return ChatNotifier(ref.watch(chatRepositoryProvider));
});

class ChatNotifier extends StateNotifier<List<ChatMessageModel>> {
  final IChatRepository _repo;
  ChatNotifier(this._repo) : super([
    ChatMessageModel(
        text: "Namaste! I am your Bank Assistant. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now()
    )
  ]);

  Future<void> sendMessage(String text, WidgetRef ref) async {
    // Add user message to UI
    final userMsg = ChatMessageModel(text: text, isUser: true, timestamp: DateTime.now());
    state = [...state, userMsg];

    // Show "Typing..." indicator
    ref.read(isBotTypingProvider.notifier).state = true;

    // Get response from Mock (or Real API later)
    final response = await _repo.getBotResponse(text);

    // Add bot response to UI and hide "Typing..."
    final botMsg = ChatMessageModel(text: response, isUser: false, timestamp: DateTime.now());
    state = [...state, botMsg];
    ref.read(isBotTypingProvider.notifier).state = false;
  }
}