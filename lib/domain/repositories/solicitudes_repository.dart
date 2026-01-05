import '../entities/solicitud_adopcion.dart';

abstract class SolicitudesRepository {
  Future<void> crearSolicitud(SolicitudAdopcion solicitud);
  Future<List<SolicitudAdopcion>> getSolicitudesByAdoptante(String adoptanteId);
  Future<List<SolicitudAdopcion>> getSolicitudesByRefugio(String refugioId);
  Future<void> updateEstadoSolicitud(
    String solicitudId,
    String nuevoEstado,
    String? observaciones,
  );
}