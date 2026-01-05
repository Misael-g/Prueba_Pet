import '../../domain/entities/solicitud_adopcion.dart';
import '../../domain/repositories/solicitudes_repository.dart';
import '../datasources/solicitudes_remote_ds.dart';

class SolicitudesRepositoryImpl implements SolicitudesRepository {
  final SolicitudesRemoteDatasource remoteDatasource;

  SolicitudesRepositoryImpl(this.remoteDatasource);

  @override
  Future<void> crearSolicitud(SolicitudAdopcion solicitud) async {
    await remoteDatasource.crearSolicitud(solicitud as dynamic);
  }

  @override
  Future<List<SolicitudAdopcion>> getSolicitudesByAdoptante(
      String adoptanteId) {
    return remoteDatasource.getSolicitudesByAdoptante(adoptanteId);
  }

  @override
  Future<List<SolicitudAdopcion>> getSolicitudesByRefugio(String refugioId) {
    return remoteDatasource.getSolicitudesByRefugio(refugioId);
  }

  @override
  Future<void> updateEstadoSolicitud(
    String solicitudId,
    String nuevoEstado,
    String? observaciones,
  ) {
    return remoteDatasource.updateEstadoSolicitud(
      solicitudId,
      nuevoEstado,
      observaciones,
    );
  }
}