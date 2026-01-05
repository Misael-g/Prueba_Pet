import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mascota_model.dart';

class MascotasRemoteDatasource {
  final SupabaseClient client;

  MascotasRemoteDatasource(this.client);

  Future<List<MascotaModel>> getMascotas() async {
    final res = await client
        .from('mascotas')
        .select()
        .eq('activo', true);

    return res.map<MascotaModel>((e) => MascotaModel.fromJson(e)).toList();
  }

  Future<void> addMascota(MascotaModel mascota) async {
    await client.from('mascotas').insert(mascota.toJson(
      mascota.id,
    ));
  }

  Future<void> updateMascota(String id, Map<String, dynamic> data) async {
    await client.from('mascotas').update(data).eq('id', id);
  }

  Future<void> deleteMascota(String id) async {
    await client.from('mascotas').delete().eq('id', id);
  }

  // Consulta con filtros: especie y estado
  Future<List> getMascotasFiltradas({
    String? especie,
    String? estado,
  }) async {
    var query = client.from('mascotas').select().eq('activo', true);

    if (especie != null) {
      query = query.eq('especie', especie);
    }

    if (estado != null) {
      query = query.eq('estado', estado);
    }

    return await query;
  }
}

