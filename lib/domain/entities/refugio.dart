class Refugio {
  final String id;
  final String perfilId;
  final String nombreRefugio;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final String? telefonoContacto;
  final String? emailContacto;
  final String? descripcion;
  final String? horarioAtencion;
  final bool verificado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Refugio({
    required this.id,
    required this.perfilId,
    required this.nombreRefugio,
    this.direccion,
    this.latitud,
    this.longitud,
    this.telefonoContacto,
    this.emailContacto,
    this.descripcion,
    this.horarioAtencion,
    this.verificado = false,
    this.createdAt,
    this.updatedAt,
  });
}