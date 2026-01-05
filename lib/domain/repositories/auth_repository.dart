import 'package:supabase_flutter/supabase_flutter.dart';
import '../entities/perfil.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> register(String email, String password, String rol, String? nombreCompleto);
  Future<void> logout();
  Future<void> resetPassword(String email);
  User? getCurrentUser();
  Future<Perfil?> getCurrentPerfil();
  Stream<AuthState> get authStateChanges;
}