import '../../domain/entities/solicitud_adopcion.dart';

class SolicitudAdopcionModel extends SolicitudAdopcion {
  SolicitudAdopcionModel({
    required super.id,
    required super.mascotaId,
    required super.adoptanteId,
    required super.refugioId,
    required super.estado,
    super.motivoAdopcion,
    super.experienciaMascotas,
    super.tipoVivienda,
    super.tienePatio,
    super.otrosAnimales,
    super.observacionesRefugio,
    super.fechaSolicitud,
    super.fechaRespuesta,
    super.createdAt,
    super.updatedAt,
    super.nombreMascota,
    super.imagenMascota,
    super.nombreAdoptante,
    super.emailAdoptante,
  });

  factory SolicitudAdopcionModel.fromJson(Map<String, dynamic> json) {
    return SolicitudAdopcionModel(
      id: json['id'] ?? '',
      mascotaId: json['mascota_id'] ?? '',
      adoptanteId: json['adoptante_id'] ?? '',
      refugioId: json['refugio_id'] ?? '',
      estado: json['estado'] ?? 'pendiente',
      motivoAdopcion: json['motivo_adopcion'],
      experienciaMascotas: json['experiencia_mascotas'],
      tipoVivienda: json['tipo_vivienda'],
      tienePatio: json['tiene_patio'],
      otrosAnimales: json['otros_animales'],
      observacionesRefugio: json['observaciones_refugio'],
      fechaSolicitud: json['fecha_solicitud'] != null
          ? DateTime.parse(json['fecha_solicitud'])
          : null,
      fechaRespuesta: json['fecha_respuesta'] != null
          ? DateTime.parse(json['fecha_respuesta'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      // Datos de joins
      nombreMascota: json['mascotas']?['nombre'],
      imagenMascota: json['mascotas']?['imagen_principal'],
      nombreAdoptante: json['perfiles']?['nombre_completo'],
      emailAdoptante: json['perfiles']?['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mascota_id': mascotaId,
      'adoptante_id': adoptanteId,
      'refugio_id': refugioId,
      'estado': estado,
      'motivo_adopcion': motivoAdopcion,
      'experiencia_mascotas': experienciaMascotas,
      'tipo_vivienda': tipoVivienda,
      'tiene_patio': tienePatio,
      'otros_animales': otrosAnimales,
      'observaciones_refugio': observacionesRefugio,
      'fecha_solicitud': fechaSolicitud?.toIso8601String(),
      'fecha_respuesta': fechaRespuesta?.toIso8601String(),
    };
  }
}