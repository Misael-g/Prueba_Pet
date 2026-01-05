class Perfil {
  final String id;
  final String email;
  final String? nombreCompleto;
  final String? telefono;
  final String rol; // adoptante o refugio
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Perfil({
    required this.id,
    required this.email,
    this.nombreCompleto,
    this.telefono,
    required this.rol,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  bool get esRefugio => rol == 'refugio';
  bool get esAdoptante => rol == 'adoptante';
}