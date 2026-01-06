import 'package:equatable/equatable.dart';

/// Modelo que representa un mensaje en el chat
class ChatMessage extends Equatable {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  /// Crea un mensaje del usuario
  factory ChatMessage.user(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  /// Crea un mensaje de la IA
  factory ChatMessage.ai(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  /// Crea un mensaje de error
  factory ChatMessage.error(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    );
  }

  /// Convierte el mensaje a formato para el historial de Gemini
  Map<String, String> toHistoryFormat() {
    return {
      'role': isUser ? 'user' : 'model',
      'text': text,
    };
  }

  @override
  List<Object?> get props => [id, text, isUser, timestamp, isError];
}
