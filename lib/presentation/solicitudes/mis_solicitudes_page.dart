import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/datasources/solicitudes_remote_ds.dart';
import '../../data/models/solicitud_adopcion_model.dart';
import 'package:intl/intl.dart';

class MisSolicitudesPage extends StatefulWidget {
  const MisSolicitudesPage({super.key});

  @override
  State<MisSolicitudesPage> createState() => _MisSolicitudesPageState();
}

class _MisSolicitudesPageState extends State<MisSolicitudesPage> {
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

      final solicitudesDs = SolicitudesRemoteDatasource(client);
      final solicitudes = await solicitudesDs.getSolicitudesByAdoptante(user.id);
      setState(() => _solicitudes = solicitudes);
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
        title: const Text('Mis Solicitudes'),
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
                              'No tienes solicitudes',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '¡Empieza buscando tu mascota ideal!',
                              style: TextStyle(color: Colors.grey),
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
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.pets, size: 40),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.pets, size: 40),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.nombreMascota ?? 'Mascota',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEstadoChip(solicitud.estado),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Fecha de solicitud
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Solicitado: ${solicitud.fechaSolicitud != null ? DateFormat('dd/MM/yyyy').format(solicitud.fechaSolicitud!) : 'Sin fecha'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            
            // Fecha de respuesta (si hay)
            if (solicitud.fechaRespuesta != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Respondido: ${DateFormat('dd/MM/yyyy').format(solicitud.fechaRespuesta!)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            
            // Motivo (resumen)
            if (solicitud.motivoAdopcion != null) ...[
              const SizedBox(height: 12),
              Text(
                'Tu motivo:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                solicitud.motivoAdopcion!.length > 100
                    ? '${solicitud.motivoAdopcion!.substring(0, 100)}...'
                    : solicitud.motivoAdopcion!,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
            
            // Observaciones del refugio
            if (solicitud.observacionesRefugio != null && solicitud.observacionesRefugio!.isNotEmpty) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: solicitud.estaAprobada 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: solicitud.estaAprobada 
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 16,
                          color: solicitud.estaAprobada ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mensaje del refugio:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: solicitud.estaAprobada ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      solicitud.observacionesRefugio!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
            
            // Botón cancelar (solo si está pendiente)
            if (solicitud.estaPendiente) ...[
              const Divider(height: 24),
              OutlinedButton.icon(
                onPressed: () => _confirmarCancelar(solicitud),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar Solicitud'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
            
            // Mensaje de aprobación
            if (solicitud.estaAprobada) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.celebration, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¡Felicidades! Tu solicitud fue aprobada. El refugio se pondrá en contacto contigo.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
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
    IconData icon;
    
    switch (estado) {
      case 'pendiente':
        color = Colors.orange;
        label = 'Pendiente';
        icon = Icons.pending;
        break;
      case 'aprobada':
        color = Colors.green;
        label = 'Aprobada';
        icon = Icons.check_circle;
        break;
      case 'rechazada':
        color = Colors.red;
        label = 'Rechazada';
        icon = Icons.cancel;
        break;
      case 'cancelada':
        color = Colors.grey;
        label = 'Cancelada';
        icon = Icons.block;
        break;
      default:
        color = Colors.grey;
        label = estado;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCancelar(SolicitudAdopcionModel solicitud) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Solicitud'),
        content: Text(
          '¿Estás seguro de cancelar tu solicitud para ${solicitud.nombreMascota}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
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
          'cancelada',
          'Cancelada por el adoptante',
        );
        
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Solicitud cancelada');
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