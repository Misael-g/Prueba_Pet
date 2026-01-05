class Mascota {
  final String id;
  final String refugioId;
  final String nombre;
  final String especie; // perro, gato, otro
  final String? raza;
  final int? edadAnos;
  final int? edadMeses;
  final String? sexo; // macho, hembra
  final String? tamanio; // pequenio, mediano, grande
  final String? color;
  final String? descripcion;
  final String? personalidad;
  final String? historia;
  final String? necesidadesEspeciales;
  final bool? buenoNinos;
  final bool? buenoGatos;
  final bool? buenoPerros;
  final String? nivelEnergia; // bajo, medio, alto
  final String estado; // disponible, pendiente, adoptado, retirado
  final String? imagenPrincipal;
  final List<String>? imagenes;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Mascota({
    required this.id,
    required this.refugioId,
    required this.nombre,
    required this.especie,
    this.raza,
    this.edadAnos,
    this.edadMeses,
    this.sexo,
    this.tamanio,
    this.color,
    this.descripcion,
    this.personalidad,
    this.historia,
    this.necesidadesEspeciales,
    this.buenoNinos,
    this.buenoGatos,
    this.buenoPerros,
    this.nivelEnergia,
    required this.estado,
    this.imagenPrincipal,
    this.imagenes,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  String get edadTexto {
    if (edadAnos != null && edadMeses != null) {
      return '$edadAnos años y $edadMeses meses';
    } else if (edadAnos != null) {
      return '$edadAnos ${edadAnos == 1 ? 'año' : 'años'}';
    } else if (edadMeses != null) {
      return '$edadMeses ${edadMeses == 1 ? 'mes' : 'meses'}';
    }
    return 'Edad no especificada';
  }
}