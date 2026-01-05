import 'package:supabase_flutter/supabase_flutter.dart';

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
  ) {
    return client.auth.signUp(
      email: email,
      password: password,
      data: {
        'rol': rol, // adoptante o refugio
      },
    );
  }

  Future<void> logout() async {
    await client.auth.signOut();
  }
}
