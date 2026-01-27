import '../models/chat_message_model.dart';

abstract class IChatRepository {
  Future<String> getBotResponse(String userQuery);
}