import 'package:equatable/equatable.dart';
import '../models/chat_message.dart';

/// Estados posibles del chat
abstract class ChatState extends Equatable {
  final List<ChatMessage> messages;

  const ChatState(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// Estado inicial del chat
class ChatInitial extends ChatState {
  const ChatInitial() : super(const []);
}

/// Estado cuando el chat está listo para usar
class ChatReady extends ChatState {
  const ChatReady(super.messages);
}

/// Estado cuando la IA está procesando
class ChatLoading extends ChatState {
  const ChatLoading(super.messages);
}

/// Estado cuando ocurre un error
class ChatError extends ChatState {
  final String errorMessage;

  const ChatError(super.messages, this.errorMessage);

  @override
  List<Object?> get props => [messages, errorMessage];
}
