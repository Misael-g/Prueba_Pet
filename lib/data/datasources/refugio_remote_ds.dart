import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/refugio_model.dart';

class RefugioRemoteDatasource {
  final SupabaseClient client;

  RefugioRemoteDatasource(this.client);

  Future<RefugioModel?> getRefugioByPerfilId(String perfilId) async {
    final response = await client
        .from('refugios')
        .select()
        .eq('perfil_id', perfilId)
        .maybeSingle();

    if (response == null) return null;

    return RefugioModel.fromJson(response);
  }

  Future<void> createRefugio(RefugioModel refugio) async {
    await client.from('refugios').insert(refugio.toJson());
  }

  Future<void> updateRefugio(String id, Map<String, dynamic> data) async {
    await client.from('refugios').update(data).eq('id', id);
  }

  Future<Map<String, int>> getEstadisticas(String refugioId) async {
    // Contar mascotas por estado
    final mascotasResponse = await client
        .from('mascotas')
        .select('estado')
        .eq('refugio_id', refugioId)
        .eq('activo', true);

    final mascotas = mascotasResponse as List;

    final totalMascotas = mascotas.length;
    final disponibles = mascotas.where((m) => m['estado'] == 'disponible').length;
    final adoptadas = mascotas.where((m) => m['estado'] == 'adoptado').length;

    // Contar solicitudes pendientes
    final solicitudesResponse = await client
        .from('solicitudes_adopcion')
        .select('id')
        .eq('refugio_id', refugioId)
        .eq('estado', 'pendiente');

    final pendientes = (solicitudesResponse as List).length;

    return {
      'total_mascotas': totalMascotas,
      'disponibles': disponibles,
      'adoptadas': adoptadas,
      'pendientes': pendientes,
    };
  }
}