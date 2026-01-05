import '../../domain/entities/mascota.dart';

class MascotaModel extends Mascota {
  MascotaModel({
    required super.id,
    required super.refugioId,
    required super.nombre,
    required super.especie,
    super.raza,
    super.edadAnos,
    super.edadMeses,
    super.sexo,
    super.tamanio,
    super.color,
    super.descripcion,
    super.personalidad,
    super.historia,
    super.necesidadesEspeciales,
    super.buenoNinos,
    super.buenoGatos,
    super.buenoPerros,
    super.nivelEnergia,
    required super.estado,
    super.imagenPrincipal,
    super.imagenes,
    super.activo,
    super.createdAt,
    super.updatedAt,
  });

  factory MascotaModel.fromJson(Map<String, dynamic> json) {
    return MascotaModel(
      id: json['id'] ?? '',
      refugioId: json['refugio_id'] ?? '',
      nombre: json['nombre'] ?? '',
      especie: json['especie'] ?? '',
      raza: json['raza'],
      edadAnos: json['edad_anos'],
      edadMeses: json['edad_meses'],
      sexo: json['sexo'],
      tamanio: json['tamanio'],
      color: json['color'],
      descripcion: json['descripcion'],
      personalidad: json['personalidad'],
      historia: json['historia'],
      necesidadesEspeciales: json['necesidades_especiales'],
      buenoNinos: json['bueno_ninos'],
      buenoGatos: json['bueno_gatos'],
      buenoPerros: json['bueno_perros'],
      nivelEnergia: json['nivel_energia'],
      estado: json['estado'] ?? 'disponible',
      imagenPrincipal: json['imagen_principal'],
      imagenes: json['imagenes'] != null
          ? List<String>.from(json['imagenes'])
          : null,
      activo: json['activo'] ?? true,
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
      'refugio_id': refugioId,
      'nombre': nombre,
      'especie': especie,
      'raza': raza,
      'edad_anos': edadAnos,
      'edad_meses': edadMeses,
      'sexo': sexo,
      'tamanio': tamanio,
      'color': color,
      'descripcion': descripcion,
      'personalidad': personalidad,
      'historia': historia,
      'necesidades_especiales': necesidadesEspeciales,
      'bueno_ninos': buenoNinos,
      'bueno_gatos': buenoGatos,
      'bueno_perros': buenoPerros,
      'nivel_energia': nivelEnergia,
      'estado': estado,
      'imagen_principal': imagenPrincipal,
      'imagenes': imagenes,
      'activo': activo,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    final json = toJson();
    json.remove('refugio_id'); // No se debe actualizar el refugio_id
    return json;
  }
}