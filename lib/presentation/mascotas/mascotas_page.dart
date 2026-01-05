import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../data/datasources/mascotas_remote_ds.dart';
import '../../data/datasources/refugio_remote_ds.dart';
import '../../data/models/mascota_model.dart';
import 'add_mascota_page.dart';
import 'edit_mascota_page.dart';

class MascotasPage extends StatefulWidget {
  const MascotasPage({super.key});

  @override
  State<MascotasPage> createState() => _MascotasPageState();
}

class _MascotasPageState extends State<MascotasPage> {
  List<MascotaModel> _mascotas = [];
  bool _isLoading = true;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _loadMascotas();
  }

  Future<void> _loadMascotas() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser!;

      final refugioDs = RefugioRemoteDatasource(client);
      final refugio = await refugioDs.getRefugioByPerfilId(user.id);

      if (refugio != null) {
        final mascotasDs = MascotasRemoteDatasource(client);
        final mascotas = await mascotasDs.getMascotasByRefugio(refugio.id);
        setState(() => _mascotas = mascotas);
      }
    } catch (e) {
      debugPrint('Error cargando mascotas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<MascotaModel> get _mascotasFiltradas {
    if (_filtroEstado == 'todos') {
      return _mascotas.where((m) => m.activo).toList();
    }
    return _mascotas.where((m) => m.activo && m.estado == _filtroEstado).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Mascotas'),
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
                  _buildFilterChip('Todos', 'todos'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Disponibles', 'disponible'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pendientes', 'pendiente'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Adoptados', 'adoptado'),
                ],
              ),
            ),
          ),

          // Lista de mascotas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mascotasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay mascotas',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Agrega tu primera mascota',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMascotas,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _mascotasFiltradas.length,
                          itemBuilder: (context, index) {
                            final mascota = _mascotasFiltradas[index];
                            return _buildMascotaCard(mascota);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddMascotaPage(),
            ),
          );
          if (result == true) {
            _loadMascotas();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroEstado == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filtroEstado = value);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildMascotaCard(MascotaModel mascota) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditMascotaPage(mascota: mascota),
            ),
          );
          if (result == true) {
            _loadMascotas();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: mascota.imagenPrincipal != null
                    ? Image.network(
                        mascota.imagenPrincipal!,
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
              const SizedBox(width: 12),
              
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mascota.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${mascota.especie.toUpperCase()}${mascota.raza != null ? ' • ${mascota.raza}' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mascota.edadTexto,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEstadoChip(mascota.estado),
                  ],
                ),
              ),
              
              // Botones de acción
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditMascotaPage(mascota: mascota),
                        ),
                      );
                      if (result == true) {
                        _loadMascotas();
                      }
                    },
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmarEliminar(mascota),
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color color;
    String label;
    
    switch (estado) {
      case 'disponible':
        color = Colors.green;
        label = 'Disponible';
        break;
      case 'pendiente':
        color = Colors.orange;
        label = 'Pendiente';
        break;
      case 'adoptado':
        color = Colors.blue;
        label = 'Adoptado';
        break;
      case 'retirado':
        color = Colors.grey;
        label = 'Retirado';
        break;
      default:
        color = Colors.grey;
        label = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
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

  Future<void> _confirmarEliminar(MascotaModel mascota) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Mascota'),
        content: Text('¿Estás seguro de eliminar a ${mascota.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final client = SupabaseConfig.client;
        final mascotasDs = MascotasRemoteDatasource(client);
        await mascotasDs.deleteMascota(mascota.id);
        _loadMascotas();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}