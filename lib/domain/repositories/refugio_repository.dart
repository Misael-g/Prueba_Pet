import '../entities/refugio.dart';

abstract class RefugioRepository {
  Future<Refugio?> getRefugioByPerfilId(String perfilId);
  Future<void> createRefugio(Refugio refugio);
  Future<void> updateRefugio(String id, Map<String, dynamic> data);
  Future<Map<String, int>> getEstadisticas(String refugioId);
}