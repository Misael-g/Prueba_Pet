import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/perfil.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_ds.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl(this.remoteDatasource);

  @override
  Future<AuthResponse> login(String email, String password) {
    return remoteDatasource.login(email, password);
  }

  @override
  Future<AuthResponse> register(
    String email,
    String password,
    String rol,
    String? nombreCompleto,
  ) {
    return remoteDatasource.register(email, password, rol, nombreCompleto);
  }

  @override
  Future<void> logout() {
    return remoteDatasource.logout();
  }

  @override
  Future<void> resetPassword(String email) {
    return remoteDatasource.resetPassword(email);
  }

  @override
  User? getCurrentUser() {
    return remoteDatasource.getCurrentUser();
  }

  @override
  Future<Perfil?> getCurrentPerfil() {
    return remoteDatasource.getCurrentPerfil();
  }

  @override
  Stream<AuthState> get authStateChanges => remoteDatasource.authStateChanges;
}