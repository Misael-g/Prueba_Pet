import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mascota_model.dart';

class MascotasRemoteDatasource {
  final SupabaseClient client;

  MascotasRemoteDatasource(this.client);

  Future<List<MascotaModel>> getMascotas() async {
    final response = await client
        .from('mascotas')
        .select()
        .eq('activo', true)
        .eq('estado', 'disponible')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => MascotaModel.fromJson(json))
        .toList();
  }

  Future<List<MascotaModel>> getMascotasByRefugio(String refugioId) async {
    final response = await client
        .from('mascotas')
        .select()
        .eq('refugio_id', refugioId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => MascotaModel.fromJson(json))
        .toList();
  }

  Future<MascotaModel?> getMascotaById(String id) async {
    final response = await client
        .from('mascotas')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;

    return MascotaModel.fromJson(response);
  }

  Future<void> addMascota(MascotaModel mascota) async {
    await client.from('mascotas').insert(mascota.toJson());
  }

  Future<void> updateMascota(String id, Map<String, dynamic> data) async {
    await client.from('mascotas').update(data).eq('id', id);
  }

  Future<void> deleteMascota(String id) async {
    // Soft delete - solo marcar como inactivo
    await client.from('mascotas').update({'activo': false}).eq('id', id);
  }

  Future<List<MascotaModel>> searchMascotas({
    String? especie,
    String? tamanio,
    String? sexo,
  }) async {
    var query = client
        .from('mascotas')
        .select()
        .eq('activo', true)
        .eq('estado', 'disponible');

    if (especie != null && especie.isNotEmpty) {
      query = query.eq('especie', especie);
    }

    if (tamanio != null && tamanio.isNotEmpty) {
      query = query.eq('tamanio', tamanio);
    }

    if (sexo != null && sexo.isNotEmpty) {
      query = query.eq('sexo', sexo);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => MascotaModel.fromJson(json))
        .toList();
  }
}