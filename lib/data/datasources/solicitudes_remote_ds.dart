import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/solicitud_adopcion_model.dart';

class SolicitudesRemoteDatasource {
  final SupabaseClient client;

  SolicitudesRemoteDatasource(this.client);

  // Adoptante crea solicitud
  Future<void> crearSolicitud({
    required String mascotaId,
    required String refugioId,
    String? motivo,
  }) async {
    // 1. Crear solicitud (se marca como pendiente desde el insert)
    await client.from('solicitudes_adopcion').insert({
      'mascota_id': mascotaId,
      'refugio_id': refugioId,
      'motivo_adopcion': motivo,
      'estado': 'pendiente',
      'fecha_solicitud': DateTime.now().toIso8601String(),
    });

    // 2. Cambiar mascota a pendiente
    await client.from('mascotas').update({
      'estado': 'pendiente',
    }).eq('id', mascotaId);
  }

  // Compat helper si ya tienes un model
  Future<void> crearSolicitudFromModel(SolicitudAdopcionModel solicitud) async {
    await crearSolicitud(
      mascotaId: solicitud.mascotaId,
      refugioId: solicitud.refugioId,
      motivo: solicitud.motivo,
    );
  }

  // Refugio ve solicitudes
  Future<List<SolicitudAdopcionModel>> getSolicitudesRefugio() async {
    final res = await client
        .from('solicitudes_adopcion')
        .select('*, mascotas(nombre)')
        .order('fecha_solicitud', ascending: false);

    return res
        .map<SolicitudAdopcionModel>(
          (e) => SolicitudAdopcionModel.fromJson(e),
        )
        .toList();
  }

  // Aprobar / Rechazar (operaciones compuestas)
  Future<void> actualizarEstado(
    String solicitudId,
    String estado,
  ) async {
    await client.from('solicitudes_adopcion').update({
      'estado': estado,
      'fecha_respuesta': DateTime.now().toIso8601String(),
    }).eq('id', solicitudId);
  }

  // Aprobar solicitud: aprobar la solicitada, rechazar las demás y marcar mascota como adoptada
  Future<void> aprobarSolicitud({
    required String solicitudId,
    required String mascotaId,
  }) async {
    // 1. Aprobar solicitud
    await client.from('solicitudes_adopcion').update({
      'estado': 'aprobada',
      'fecha_respuesta': DateTime.now().toIso8601String(),
    }).eq('id', solicitudId);

    // 2. Rechazar las demás solicitudes de la misma mascota
    await client.from('solicitudes_adopcion').update({
      'estado': 'rechazada',
    }).eq('mascota_id', mascotaId).neq('id', solicitudId);

    // 3. Marcar mascota como adoptada
    await client.from('mascotas').update({
      'estado': 'adoptado',
    }).eq('id', mascotaId);

    // Nota: para producción es preferible usar una función RPC/transaction en el servidor
    // para garantizar atomicidad y respetar RLS de forma segura.
  }

  // Rechazar una solicitud: si no quedan pendientes, volver a disponible
  Future<void> rechazarSolicitud({
    required String solicitudId,
    required String mascotaId,
  }) async {
    // Rechazar solicitud
    await client.from('solicitudes_adopcion').update({
      'estado': 'rechazada',
      'fecha_respuesta': DateTime.now().toIso8601String(),
    }).eq('id', solicitudId);

    // Ver si quedan solicitudes pendientes
    final pendientes = await client
        .from('solicitudes_adopcion')
        .select()
        .eq('mascota_id', mascotaId)
        .eq('estado', 'pendiente');

    // Si no quedan, la mascota vuelve a disponible
    if (pendientes.isEmpty) {
      await client.from('mascotas').update({
        'estado': 'disponible',
      }).eq('id', mascotaId);
    }
  }

  // Cancelar solicitud (adoptante cancela)
  Future<void> cancelarSolicitud({
    required String solicitudId,
    required String mascotaId,
  }) async {
    // 1. Cancelar solicitud
    await client.from('solicitudes_adopcion').update({
      'estado': 'cancelada',
      'fecha_respuesta': DateTime.now().toIso8601String(),
    }).eq('id', solicitudId);

    // 2. Verificar si quedan pendientes
    final pendientes = await client
        .from('solicitudes_adopcion')
        .select()
        .eq('mascota_id', mascotaId)
        .eq('estado', 'pendiente');

    // 3. Si no hay pendientes, mascota vuelve a disponible
    if (pendientes.isEmpty) {
      await client.from('mascotas').update({
        'estado': 'disponible',
      }).eq('id', mascotaId);
    }
  }

  // Dashboard stats para refugio
  Future<Map<String, int>> getDashboardStats() async {
    final mascotas = await client.from('mascotas').select();
    final solicitudes = await client
        .from('solicitudes_adopcion')
        .select()
        .eq('estado', 'pendiente');

    final adoptadas = mascotas.where((m) => m['estado'] == 'adoptado').length;

    return {
      'mascotas': (mascotas as List).length,
      'pendientes': (solicitudes as List).length,
      'adoptadas': adoptadas,
    };
  }
}

