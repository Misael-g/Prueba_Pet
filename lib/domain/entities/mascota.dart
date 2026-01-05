class Mascota {
  final String id;
  final String nombre;
  final String especie;
  final String? raza;
  final int? edad;
  final String estado;
  final String? imagen;

  Mascota({
    required this.id,
    required this.nombre,
    required this.especie,
    this.raza,
    this.edad,
    required this.estado,
    this.imagen,
  });
}
