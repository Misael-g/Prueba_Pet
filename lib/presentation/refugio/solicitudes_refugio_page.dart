import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/datasources/solicitudes_remote_ds.dart';
import '../../data/datasources/refugio_remote_ds.dart';
import '../../data/models/solicitud_adopcion_model.dart';
import 'package:intl/intl.dart';

class SolicitudesRefugioPage extends StatefulWidget {
  const SolicitudesRefugioPage({super.key});

  @override
  State<SolicitudesRefugioPage> createState() => _SolicitudesRefugioPageState();
}

class _SolicitudesRefugioPageState extends State<SolicitudesRefugioPage> {
  List<SolicitudAdopcionModel> _solicitudes = [];
  bool _isLoading = true;
  String _filtro = 'todas';

  @override
  void initState() {
    super.initState();
    _loadSolicitudes();
  }

  Future<void> _loadSolicitudes() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser!;

      final refugioDs = RefugioRemoteDatasource(client);
      final refugio = await refugioDs.getRefugioByPerfilId(user.id);

      if (refugio != null) {
        final solicitudesDs = SolicitudesRemoteDatasource(client);
        final solicitudes = await solicitudesDs.getSolicitudesByRefugio(refugio.id);
        setState(() => _solicitudes = solicitudes);
      }
    } catch (e) {
      debugPrint('Error cargando solicitudes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<SolicitudAdopcionModel> get _solicitudesFiltradas {
    if (_filtro == 'todas') return _solicitudes;
    return _solicitudes.where((s) => s.estado == _filtro).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de Adopción'),
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todas', 'todas'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pendientes', 'pendiente'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Aprobadas', 'aprobada'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rechazadas', 'rechazada'),
                ],
              ),
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _solicitudesFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay solicitudes',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSolicitudes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _solicitudesFiltradas.length,
                          itemBuilder: (context, index) {
                            return _buildSolicitudCard(_solicitudesFiltradas[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtro == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _filtro = value),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildSolicitudCard(SolicitudAdopcionModel solicitud) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con mascota
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: solicitud.imagenMascota != null
                      ? Image.network(
                          solicitud.imagenMascota!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.pets),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.pets),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.nombreMascota ?? 'Mascota',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        solicitud.nombreAdoptante ?? 'Adoptante',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      if (solicitud.emailAdoptante != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          solicitud.emailAdoptante!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildEstadoChip(solicitud.estado),
              ],
            ),
            
            const Divider(height: 24),
            
            // Información del adoptante
            if (solicitud.motivoAdopcion != null) ...[
              const Text(
                'Motivo de Adopción:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                solicitud.motivoAdopcion!,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
            ],
            
            if (solicitud.experienciaMascotas != null) ...[
              Row(
                children: [
                  const Icon(Icons.pets, size: 16, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Experiencia: ${solicitud.experienciaMascotas}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            if (solicitud.tipoVivienda != null) ...[
              Row(
                children: [
                  const Icon(Icons.home, size: 16, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vivienda: ${solicitud.tipoVivienda}${solicitud.tienePatio == true ? ' (con patio)' : ''}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            if (solicitud.otrosAnimales != null && solicitud.otrosAnimales!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.pets_outlined, size: 16, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Otras mascotas: ${solicitud.otrosAnimales}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Fecha
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  solicitud.fechaSolicitud != null
                      ? DateFormat('dd/MM/yyyy').format(solicitud.fechaSolicitud!)
                      : 'Sin fecha',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            
            // Observaciones del refugio (si están aprobadas/rechazadas)
            if (solicitud.observacionesRefugio != null && solicitud.observacionesRefugio!.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Observaciones:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                solicitud.observacionesRefugio!,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
            
            // Botones de acción (solo si está pendiente)
            if (solicitud.estaPendiente) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _mostrarDialogoRechazar(solicitud),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoAprobar(solicitud),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aprobar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    String label;
    
    switch (estado) {
      case 'pendiente':
        color = Colors.orange;
        label = 'Pendiente';
        break;
      case 'aprobada':
        color = Colors.green;
        label = 'Aprobada';
        break;
      case 'rechazada':
        color = Colors.red;
        label = 'Rechazada';
        break;
      case 'cancelada':
        color = Colors.grey;
        label = 'Cancelada';
        break;
      default:
        color = Colors.grey;
        label = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoAprobar(SolicitudAdopcionModel solicitud) async {
    final observacionesController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Aprobar la solicitud de ${solicitud.nombreAdoptante} para ${solicitud.nombreMascota}?'),
            const SizedBox(height: 16),
            TextField(
              controller: observacionesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                border: OutlineInputBorder(),
                hintText: 'Mensaje para el adoptante...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final client = SupabaseConfig.client;
        final solicitudesDs = SolicitudesRemoteDatasource(client);
        await solicitudesDs.updateEstadoSolicitud(
          solicitud.id,
          'aprobada',
          observacionesController.text.trim().isEmpty 
              ? null 
              : observacionesController.text.trim(),
        );
        
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Solicitud aprobada');
          _loadSolicitudes();
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Error: $e');
        }
      }
    }
  }

  Future<void> _mostrarDialogoRechazar(SolicitudAdopcionModel solicitud) async {
    final observacionesController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Solicitud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Rechazar la solicitud de ${solicitud.nombreAdoptante}?'),
            const SizedBox(height: 16),
            TextField(
              controller: observacionesController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                border: OutlineInputBorder(),
                hintText: 'Explica por qué se rechaza...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final client = SupabaseConfig.client;
        final solicitudesDs = SolicitudesRemoteDatasource(client);
        await solicitudesDs.updateEstadoSolicitud(
          solicitud.id,
          'rechazada',
          observacionesController.text.trim().isEmpty 
              ? null 
              : observacionesController.text.trim(),
        );
        
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Solicitud rechazada');
          _loadSolicitudes();
        }
      } catch (e) {
        if (mounted) {
          SnackbarHelper.showError(context, 'Error: $e');
        }
      }
    }
  }
}