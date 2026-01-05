import '../../domain/entities/mascota.dart';

class MascotaModel extends Mascota {
  MascotaModel({
    required super.id,
    required super.nombre,
    required super.especie,
    super.raza,
    super.edad,
    required super.estado,
    super.imagen,
  });

  factory MascotaModel.fromJson(Map<String, dynamic> json) {
    return MascotaModel(
      id: json['id'],
      nombre: json['nombre'],
      especie: json['especie'],
      raza: json['raza'],
      edad: json['edad_anos'],
      estado: json['estado'],
      imagen: json['imagen_principal'],
    );
  }

  Map<String, dynamic> toJson(String refugioId) {
    return {
      'nombre': nombre,
      'especie': especie,
      'raza': raza,
      'edad_anos': edad,
      'estado': estado,
      'refugio_id': refugioId,
      'imagen_principal': imagen,
    };
  }
}
