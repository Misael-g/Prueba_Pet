import '../../domain/entities/perfil.dart';

class PerfilModel extends Perfil {
  PerfilModel({
    required super.id,
    required super.email,
    super.nombreCompleto,
    super.telefono,
    required super.rol,
    super.avatarUrl,
    super.createdAt,
    super.updatedAt,
  });

  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    return PerfilModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nombreCompleto: json['nombre_completo'],
      telefono: json['telefono'],
      rol: json['rol'] ?? 'adoptante',
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre_completo': nombreCompleto,
      'telefono': telefono,
      'rol': rol,
      'avatar_url': avatarUrl,
    };
  }
}