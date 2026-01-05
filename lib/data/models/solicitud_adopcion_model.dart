import '../../domain/entities/solicitud_adopcion.dart';

class SolicitudAdopcionModel extends SolicitudAdopcion {
  SolicitudAdopcionModel({
    required super.id,
    required super.mascotaId,
    required super.adoptanteId,
    required super.refugioId,
    required super.estado,
    super.motivo,
    required super.fecha,
  });

  factory SolicitudAdopcionModel.fromJson(Map<String, dynamic> json) {
    return SolicitudAdopcionModel(
      id: json['id'],
      mascotaId: json['mascota_id'],
      adoptanteId: json['adoptante_id'],
      refugioId: json['refugio_id'],
      estado: json['estado'],
      motivo: json['motivo_adopcion'],
      fecha: DateTime.parse(json['fecha_solicitud']),
    );
  }

  Map<String, dynamic> toInsert() {
    return {
      'mascota_id': mascotaId,
      'refugio_id': refugioId,
      'motivo_adopcion': motivo,
    };
  }
}
