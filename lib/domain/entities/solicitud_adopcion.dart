class SolicitudAdopcion {
  final String id;
  final String mascotaId;
  final String adoptanteId;
  final String refugioId;
  final String estado;
  final String? motivo;
  final DateTime fecha;

  SolicitudAdopcion({
    required this.id,
    required this.mascotaId,
    required this.adoptanteId,
    required this.refugioId,
    required this.estado,
    this.motivo,
    required this.fecha,
  });
}
