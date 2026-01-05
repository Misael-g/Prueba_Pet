import '../../domain/entities/mascota.dart';
import '../../domain/repositories/mascotas_repository.dart';
import '../datasources/mascotas_remote_ds.dart';

class MascotasRepositoryImpl implements MascotasRepository {
  final MascotasRemoteDatasource remoteDatasource;

  MascotasRepositoryImpl(this.remoteDatasource);

  @override
  Future<List<Mascota>> getMascotas() {
    return remoteDatasource.getMascotas();
  }

  @override
  Future<List<Mascota>> getMascotasByRefugio(String refugioId) {
    return remoteDatasource.getMascotasByRefugio(refugioId);
  }

  @override
  Future<Mascota?> getMascotaById(String id) {
    return remoteDatasource.getMascotaById(id);
  }

  @override
  Future<void> addMascota(Mascota mascota) async {
    // Convertir a modelo si es necesario
    await remoteDatasource.addMascota(mascota as dynamic);
  }

  @override
  Future<void> updateMascota(String id, Map<String, dynamic> data) {
    return remoteDatasource.updateMascota(id, data);
  }

  @override
  Future<void> deleteMascota(String id) {
    return remoteDatasource.deleteMascota(id);
  }

  @override
  Future<List<Mascota>> searchMascotas({
    String? especie,
    String? tamanio,
    String? sexo,
  }) {
    return remoteDatasource.searchMascotas(
      especie: especie,
      tamanio: tamanio,
      sexo: sexo,
    );
  }
}
