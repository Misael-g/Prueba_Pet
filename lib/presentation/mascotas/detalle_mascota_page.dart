import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../data/datasources/mascotas_remote_ds.dart';
import '../../data/models/mascota_model.dart';
import 'solicitar_adopcion_page.dart';

class DetalleMascotaPage extends StatefulWidget {
  final String mascotaId;

  const DetalleMascotaPage({super.key, required this.mascotaId});

  @override
  State<DetalleMascotaPage> createState() => _DetalleMascotaPageState();
}

class _DetalleMascotaPageState extends State<DetalleMascotaPage> {
  MascotaModel? _mascota;
  bool _isLoading = true;
  int _imagenActual = 0;

  @override
  void initState() {
    super.initState();
    _loadMascota();
  }

  Future<void> _loadMascota() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      final mascotasDs = MascotasRemoteDatasource(client);
      final mascota = await mascotasDs.getMascotaById(widget.mascotaId);
      setState(() => _mascota = mascota);
    } catch (e) {
      debugPrint('Error cargando mascota: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_mascota == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Mascota no encontrada'),
        ),
      );
    }

    final imagenes = _mascota!.imagenes ?? [];
    final tieneImagenes = imagenes.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con imágenes
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: tieneImagenes
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          itemCount: imagenes.length,
                          onPageChanged: (index) {
                            setState(() => _imagenActual = index);
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              imagenes[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.pets, size: 80),
                              ),
                            );
                          },
                        ),
                        if (imagenes.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                imagenes.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _imagenActual == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.pets, size: 80, color: Colors.white),
                      ),
                    ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con nombre y estado
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _mascota!.nombre,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildEstadoBadge(_mascota!.estado),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_mascota!.raza != null)
                        Text(
                          _mascota!.raza!,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // Características principales
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          '${_mascota!.edadAnos ?? 0} años',
                          'Edad',
                          Icons.cake,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          _mascota!.sexo?.toUpperCase() ?? 'N/A',
                          'Sexo',
                          Icons.wc,
                          Colors.pink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          _mascota!.tamanio?.toUpperCase() ?? 'N/A',
                          'Tamaño',
                          Icons.straighten,
                          Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Descripción
                if (_mascota!.descripcion != null) ...[
                  _buildSection(
                    'Acerca de ${_mascota!.nombre}',
                    _mascota!.descripcion!,
                    Icons.info,
                  ),
                  const SizedBox(height: 16),
                ],

                // Personalidad
                if (_mascota!.personalidad != null) ...[
                  _buildSection(
                    'Personalidad',
                    _mascota!.personalidad!,
                    Icons.psychology,
                  ),
                  const SizedBox(height: 16),
                ],

                // Historia
                if (_mascota!.historia != null) ...[
                  _buildSection(
                    'Historia',
                    _mascota!.historia!,
                    Icons.menu_book,
                  ),
                  const SizedBox(height: 16),
                ],

                // Características de convivencia
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.home, color: Colors.teal),
                              SizedBox(width: 8),
                              Text(
                                'Convivencia',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildConvivenciaItem(
                            'Bueno con niños',
                            _mascota!.buenoNinos ?? false,
                          ),
                          _buildConvivenciaItem(
                            'Bueno con gatos',
                            _mascota!.buenoGatos ?? false,
                          ),
                          _buildConvivenciaItem(
                            'Bueno con perros',
                            _mascota!.buenoPerros ?? false,
                          ),
                          if (_mascota!.nivelEnergia != null) ...[
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Icon(Icons.bolt, size: 20, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Text('Nivel de energía: '),
                                Text(
                                  _mascota!.nivelEnergia!.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // Necesidades especiales
                if (_mascota!.necesidadesEspeciales != null) ...[
                  _buildSection(
                    'Necesidades Especiales',
                    _mascota!.necesidadesEspeciales!,
                    Icons.medical_services,
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 100), // Espacio para el botón
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _mascota!.estado == 'disponible'
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SolicitarAdopcionPage(
                          mascota: _mascota!,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite),
                      SizedBox(width: 8),
                      Text(
                        'Solicitar Adopción',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    String label;

    switch (estado) {
      case 'disponible':
        color = Colors.green;
        label = 'Disponible';
        break;
      case 'adoptado':
        color = Colors.blue;
        label = 'Adoptado';
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

  Widget _buildInfoCard(String value, String label, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConvivenciaItem(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}