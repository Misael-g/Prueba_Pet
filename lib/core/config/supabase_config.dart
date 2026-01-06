import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: true, // 👈 IMPORTANTE: Habilitar debug
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    
    // Log de inicialización
    debugPrint('═══════════════════════════════════════════');
    debugPrint('✅ Supabase inicializado');
    debugPrint('URL: ${dotenv.env['SUPABASE_URL']}');
    debugPrint('═══════════════════════════════════════════');
  }
} 

