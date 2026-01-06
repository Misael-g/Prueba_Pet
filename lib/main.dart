import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/supabase_config.dart';
import 'presentation/auth/login_page.dart';
import 'presentation/adoptante/main_navigation.dart';
import 'presentation/refugio/dashboard_refugio_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Inicializar Supabase (las variables ya están cargadas)
  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetAdopt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF26D0CE),
          primary: const Color(0xFF26D0CE),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF26D0CE),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = SupabaseConfig.client.auth.currentSession;

    if (session == null) {
      return const LoginPage();
    }

    // Verificar el rol del usuario
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final rol = snapshot.data!['rol'] as String?;

          if (rol == 'refugio') {
            return const DashboardRefugioPage();
          } else {
            // 🎯 Navegación con pestañas para adoptante
            return const MainNavigation();
          }
        }

        return const LoginPage();
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserProfile() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await SupabaseConfig.client
          .from('perfiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error obteniendo perfil: $e');
      return null;
    }
  }
}