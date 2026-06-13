import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    sender: json['sender'] as String,
    text: json['text'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

class ChatService {
  static const String _messagesKey = 'chat_messages_';

  // Get all messages for a community (from local cache)
  static Future<List<ChatMessage>> getCommunityMessages(
    String communityId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('$_messagesKey$communityId');

      if (messagesJson == null) return [];

      final List<dynamic> decoded = jsonDecode(messagesJson);
      return decoded
          .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      debugPrint('Error loading messages: $e');
      return [];
    }
  }

  // Save a new message locally and return the message
  static Future<ChatMessage> sendMessage({
    required String communityId,
    required String text,
    required String sender,
  }) async {
    try {
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: sender,
        text: text,
        timestamp: DateTime.now(),
      );

      // Get existing messages
      final messages = await getCommunityMessages(communityId);
      messages.add(message);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
      await prefs.setString('$_messagesKey$communityId', messagesJson);

      return message;
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Optional: Backend sync (future enhancement)
  // For now, messages persist locally in SharedPreferences
  static Future<void> syncMessagesWithBackend({
    required String communityId,
    required String token,
  }) async {
    try {
      // Future endpoint: POST to /api/communities/{id}/messages?batch=true
      // Placeholder for backend sync logic when API is ready
    } catch (e) {
      debugPrint('Error syncing messages: $e');
    }
  }
}

// ignore: avoid_print
void debugPrint(String message) => print('[ChatService] $message');
