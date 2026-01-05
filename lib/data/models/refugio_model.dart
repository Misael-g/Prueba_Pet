import '../../domain/entities/refugio.dart';

class RefugioModel extends Refugio {
  RefugioModel({
    required super.id,
    required super.perfilId,
    required super.nombreRefugio,
    super.direccion,
    super.latitud,
    super.longitud,
    super.telefonoContacto,
    super.emailContacto,
    super.descripcion,
    super.horarioAtencion,
    super.verificado,
    super.createdAt,
    super.updatedAt,
  });

  factory RefugioModel.fromJson(Map<String, dynamic> json) {
    return RefugioModel(
      id: json['id'] ?? '',
      perfilId: json['perfil_id'] ?? '',
      nombreRefugio: json['nombre_refugio'] ?? '',
      direccion: json['direccion'],
      latitud: json['latitud']?.toDouble(),
      longitud: json['longitud']?.toDouble(),
      telefonoContacto: json['telefono_contacto'],
      emailContacto: json['email_contacto'],
      descripcion: json['descripcion'],
      horarioAtencion: json['horario_atencion'],
      verificado: json['verificado'] ?? false,
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
      'perfil_id': perfilId,
      'nombre_refugio': nombreRefugio,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'telefono_contacto': telefonoContacto,
      'email_contacto': emailContacto,
      'descripcion': descripcion,
      'horario_atencion': horarioAtencion,
      'verificado': verificado,
    };
  }
}