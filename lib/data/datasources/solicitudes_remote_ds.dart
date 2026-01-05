import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/solicitud_adopcion_model.dart';

class SolicitudesRemoteDatasource {
  final SupabaseClient client;

  SolicitudesRemoteDatasource(this.client);

  Future<void> crearSolicitud(SolicitudAdopcionModel solicitud) async {
    await client.from('solicitudes_adopcion').insert(solicitud.toJson());
  }

  Future<List<SolicitudAdopcionModel>> getSolicitudesByAdoptante(
      String adoptanteId) async {
    final response = await client
        .from('solicitudes_adopcion')
        .select('''
          *,
          mascotas(nombre, imagen_principal)
        ''')
        .eq('adoptante_id', adoptanteId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => SolicitudAdopcionModel.fromJson(json))
        .toList();
  }

  Future<List<SolicitudAdopcionModel>> getSolicitudesByRefugio(
      String refugioId) async {
    final response = await client
        .from('solicitudes_adopcion')
        .select('''
          *,
          mascotas(nombre, imagen_principal),
          perfiles(nombre_completo, email)
        ''')
        .eq('refugio_id', refugioId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => SolicitudAdopcionModel.fromJson(json))
        .toList();
  }

  Future<void> updateEstadoSolicitud(
    String solicitudId,
    String nuevoEstado,
    String? observaciones,
  ) async {
    final data = {
      'estado': nuevoEstado,
      'fecha_respuesta': DateTime.now().toIso8601String(),
    };

    if (observaciones != null) {
      data['observaciones_refugio'] = observaciones;
    }

    await client
        .from('solicitudes_adopcion')
        .update(data)
        .eq('id', solicitudId);

    // Si se aprueba, actualizar estado de la mascota
    if (nuevoEstado == 'aprobada') {
      final solicitud = await client
          .from('solicitudes_adopcion')
          .select('mascota_id')
          .eq('id', solicitudId)
          .single();

      await client
          .from('mascotas')
          .update({'estado': 'adoptado'})
          .eq('id', solicitud['mascota_id']);
    }
  }
}