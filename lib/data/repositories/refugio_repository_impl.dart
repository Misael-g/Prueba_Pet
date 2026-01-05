import '../../domain/entities/refugio.dart';
import '../../domain/repositories/refugio_repository.dart';
import '../datasources/refugio_remote_ds.dart';

class RefugioRepositoryImpl implements RefugioRepository {
  final RefugioRemoteDatasource remoteDatasource;

  RefugioRepositoryImpl(this.remoteDatasource);

  @override
  Future<Refugio?> getRefugioByPerfilId(String perfilId) {
    return remoteDatasource.getRefugioByPerfilId(perfilId);
  }

  @override
  Future<void> createRefugio(Refugio refugio) async {
    await remoteDatasource.createRefugio(refugio as dynamic);
  }

  @override
  Future<void> updateRefugio(String id, Map<String, dynamic> data) {
    return remoteDatasource.updateRefugio(id, data);
  }

  @override
  Future<Map<String, int>> getEstadisticas(String refugioId) {
    return remoteDatasource.getEstadisticas(refugioId);
  }
}