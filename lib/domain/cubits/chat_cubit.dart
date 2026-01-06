import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/chat_message.dart';
import 'chat_state.dart';
import '../../../data/services/gemini_service.dart';

/// Cubit que maneja la lógica de negocio del chat con IA
class ChatCubit extends Cubit<ChatState> {
  final GeminiService _geminiService;

  ChatCubit(this._geminiService) : super(const ChatInitial()) {
    _initialize();
  }

  /// Inicializa el chat con un mensaje de bienvenida
  void _initialize() {
    final welcomeMessage = ChatMessage.ai(
      '¡Hola! 🐾 Soy tu asistente de PetAdopt. '
      'Estoy aquí para ayudarte con información sobre adopción de mascotas, '
      'cuidados, comportamiento y todo lo que necesites saber para darle un hogar amoroso a tu futuro compañero. '
      '\n\n¿En qué puedo ayudarte hoy?'
    );
    
    emit(ChatReady([welcomeMessage]));
  }

  /// Envía un mensaje del usuario y obtiene la respuesta de la IA
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Crear mensaje del usuario
    final userMessage = ChatMessage.user(text);
    final currentMessages = List<ChatMessage>.from(state.messages);
    currentMessages.add(userMessage);

    // Emitir estado de carga
    emit(ChatLoading(currentMessages));

    try {
      // Construir historial de conversación (excluyendo el mensaje de bienvenida)
      final conversationHistory = currentMessages
          .where((msg) => msg != currentMessages.first) // Excluir mensaje de bienvenida
          .map((msg) => msg.toHistoryFormat())
          .toList();

      // Remover el último mensaje (el que acabamos de agregar) del historial
      // ya que lo enviaremos como mensaje actual
      if (conversationHistory.isNotEmpty) {
        conversationHistory.removeLast();
      }

      // Enviar mensaje a Gemini
      final response = await _geminiService.sendMessage(
        text,
        conversationHistory: conversationHistory.isEmpty ? null : conversationHistory,
      );

      // Crear mensaje de respuesta de la IA
      final aiMessage = ChatMessage.ai(response);
      currentMessages.add(aiMessage);

      // Emitir estado exitoso
      emit(ChatReady(currentMessages));
    } catch (e) {
      // Crear mensaje de error
      final errorMessage = ChatMessage.error(
        'Lo siento, ocurrió un error al procesar tu mensaje. '
        'Por favor, intenta de nuevo.\n\nError: ${e.toString()}'
      );
      currentMessages.add(errorMessage);

      // Emitir estado de error
      emit(ChatError(currentMessages, e.toString()));
    }
  }

  /// Reintenta el último mensaje en caso de error
  void retryLastMessage() {
    final messages = state.messages;
    if (messages.length >= 2) {
      // Buscar el último mensaje del usuario
      ChatMessage? lastUserMessage;
      for (var i = messages.length - 1; i >= 0; i--) {
        if (messages[i].isUser) {
          lastUserMessage = messages[i];
          break;
        }
      }

      if (lastUserMessage != null) {
        // Eliminar el mensaje de error
        final newMessages = messages.where((msg) => !msg.isError).toList();
        emit(ChatReady(newMessages));
        
        // Reenviar el último mensaje del usuario
        sendMessage(lastUserMessage.text);
      }
    }
  }

  /// Limpia el historial del chat
  void clearChat() {
    _initialize();
  }

  /// Obtiene sugerencias de mensajes
  List<String> getSuggestions() {
    return _geminiService.getSuggestedMessages();
  }
}
