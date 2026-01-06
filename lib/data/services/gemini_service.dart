import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Servicio para comunicarse con la API de Google Gemini
/// Especializado para el contexto de adopción de mascotas
class GeminiService {
  // Lee la API key desde el archivo .env
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY no configurada en el archivo .env');
    }
    return key;
  }

  // URL base de la API de Gemini (modelo flash para respuestas rápidas)
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  // Contexto especializado para PetAdopt
  static const String _systemPrompt = '''
Eres un asistente virtual experto en adopción de mascotas llamado "PetAdopt AI".
Tu misión es ayudar a los adoptantes a encontrar la mascota perfecta y brindar información útil sobre:

- Cuidado de mascotas (perros, gatos, otros)
- Preparación del hogar para una nueva mascota
- Salud animal básica (NO diagnósticos médicos)
- Comportamiento y entrenamiento
- Responsabilidades de la adopción
- Costos aproximados del cuidado de mascotas
- Consejos para la primera semana con tu nueva mascota

IMPORTANTE:
- Sé amigable, empático y alentador
- Si te preguntan sobre diagnósticos médicos, recomienda visitar a un veterinario
- Responde en español de manera clara y concisa
- Si no sabes algo, admítelo honestamente
- Enfócate siempre en promover la adopción responsable

Tu tono debe ser: cálido, profesional y motivador.
''';

  /// Envía un mensaje a Gemini con el contexto de PetAdopt
  /// 
  /// [message] - El mensaje del usuario
  /// [conversationHistory] - Historial de la conversación (opcional)
  /// Returns - La respuesta de la IA
  Future<String> sendMessage(
    String message, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');

      // Construimos el contenido con el historial
      final List<Map<String, dynamic>> contents = [];

      // Agregamos el prompt del sistema como primer mensaje
      contents.add({
        'role': 'user',
        'parts': [
          {'text': _systemPrompt}
        ]
      });
      
      contents.add({
        'role': 'model',
        'parts': [
          {'text': 'Entendido. Soy PetAdopt AI, tu asistente especializado en adopción de mascotas. ¿En qué puedo ayudarte hoy?'}
        ]
      });

      // Agregamos el historial de conversación si existe
      if (conversationHistory != null) {
        for (var msg in conversationHistory) {
          contents.add({
            'role': msg['role'],
            'parts': [
              {'text': msg['text']}
            ]
          });
        }
      }

      // Agregamos el mensaje actual del usuario
      contents.add({
        'role': 'user',
        'parts': [
          {'text': message}
        ]
      });

      final body = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2048,
          'topP': 0.8,
          'topK': 40,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
        ]
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data == null || data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('Respuesta inválida de la API');
        }

        final candidate = data['candidates'][0];

        if (candidate['content'] == null) {
          throw Exception('No hay contenido en la respuesta');
        }

        final content = candidate['content'];
        String? text;

        if (content['parts'] != null && content['parts'].isNotEmpty) {
          text = content['parts'][0]['text'];
        } else if (content['text'] != null) {
          text = content['text'];
        }

        if (text == null || text.isEmpty) {
          throw Exception('No se encontró texto en la respuesta');
        }

        return text;
      } else if (response.statusCode == 429) {
        throw Exception('Has excedido el límite de solicitudes. Por favor, espera un momento.');
      } else if (response.statusCode == 403) {
        throw Exception('API Key inválida o sin permisos. Verifica tu configuración.');
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('La solicitud tardó demasiado. Por favor, intenta de nuevo.');
      }
      throw Exception('Error al comunicarse con PetAdopt AI: $e');
    }
  }

  /// Genera sugerencias de mensajes para el usuario
  List<String> getSuggestedMessages() {
    return [
      '¿Qué necesito para adoptar un perro?',
      '¿Cómo preparo mi casa para un gato?',
      'Consejos para la primera semana con mi mascota',
      '¿Cuánto cuesta mantener una mascota?',
    ];
  }
}
