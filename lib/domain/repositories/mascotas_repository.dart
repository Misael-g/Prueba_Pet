import '../entities/mascota.dart';

abstract class MascotasRepository {
  Future<List<Mascota>> getMascotas();
  Future<List<Mascota>> getMascotasByRefugio(String refugioId);
  Future<Mascota?> getMascotaById(String id);
  Future<void> addMascota(Mascota mascota);
  Future<void> updateMascota(String id, Map<String, dynamic> data);
  Future<void> deleteMascota(String id);
  Future<List<Mascota>> searchMascotas({
    String? especie,
    String? tamanio,
    String? sexo,
  });
}