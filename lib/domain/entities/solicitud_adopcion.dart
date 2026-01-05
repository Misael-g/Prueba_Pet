class SolicitudAdopcion {
  final String id;
  final String mascotaId;
  final String adoptanteId;
  final String refugioId;
  final String estado; // pendiente, aprobada, rechazada, cancelada
  final String? motivoAdopcion;
  final String? experienciaMascotas;
  final String? tipoVivienda;
  final bool? tienePatio;
  final String? otrosAnimales;
  final String? observacionesRefugio;
  final DateTime? fechaSolicitud;
  final DateTime? fechaRespuesta;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Información adicional que puede venir de joins
  final String? nombreMascota;
  final String? imagenMascota;
  final String? nombreAdoptante;
  final String? emailAdoptante;

  SolicitudAdopcion({
    required this.id,
    required this.mascotaId,
    required this.adoptanteId,
    required this.refugioId,
    required this.estado,
    this.motivoAdopcion,
    this.experienciaMascotas,
    this.tipoVivienda,
    this.tienePatio,
    this.otrosAnimales,
    this.observacionesRefugio,
    this.fechaSolicitud,
    this.fechaRespuesta,
    this.createdAt,
    this.updatedAt,
    this.nombreMascota,
    this.imagenMascota,
    this.nombreAdoptante,
    this.emailAdoptante,
  });

  bool get estaPendiente => estado == 'pendiente';
  bool get estaAprobada => estado == 'aprobada';
  bool get estaRechazada => estado == 'rechazada';
  bool get estaCancelada => estado == 'cancelada';
}