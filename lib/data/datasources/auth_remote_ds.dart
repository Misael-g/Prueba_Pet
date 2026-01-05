import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perfil_model.dart';

class AuthRemoteDatasource {
  final SupabaseClient client;

  AuthRemoteDatasource(this.client);

  Future<AuthResponse> login(String email, String password) {
    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> register(
    String email,
    String password,
    String rol,
    String? nombreCompleto,
  ) {
    return client.auth.signUp(
      email: email,
      password: password,
      data: {
        'rol': rol,
        'nombre_completo': nombreCompleto,
      },
    );
  }

  Future<void> logout() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  Future<PerfilModel?> getCurrentPerfil() async {
    final user = getCurrentUser();
    if (user == null) return null;

    final response = await client
        .from('perfiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;

    return PerfilModel.fromJson(response);
  }

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}