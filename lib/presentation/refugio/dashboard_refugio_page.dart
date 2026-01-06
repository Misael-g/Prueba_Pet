import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../data/datasources/refugio_remote_ds.dart';
import '../../data/datasources/solicitudes_remote_ds.dart';
import '../../data/models/solicitud_adopcion_model.dart';
import '../auth/login_page.dart';
import '../mascotas/mascotas_page.dart';
import '../refugio/solicitudes_refugio_page.dart';
import '../refugio/perfil_refugio_page.dart';

class DashboardRefugioPage extends StatefulWidget {
  const DashboardRefugioPage({super.key});

  @override
  State<DashboardRefugioPage> createState() => _DashboardRefugioPageState();
}

class _DashboardRefugioPageState extends State<DashboardRefugioPage> {
  int _currentIndex = 0;
  Map<String, int> _estadisticas = {};
  List<SolicitudAdopcionModel> _solicitudesRecientes = [];
  bool _isLoading = true;
  String? _nombreRefugio;

  final List<Widget> _pages = [
    const _DashboardContent(),
    const MascotasPage(),
    const SolicitudesRefugioPage(),
    const PerfilRefugioPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (_currentIndex != 0) return; // Solo cargar si estamos en el dashboard
    
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser!;

      // Obtener refugio
      final refugioDs = RefugioRemoteDatasource(client);
      final refugio = await refugioDs.getRefugioByPerfilId(user.id);

      if (refugio != null) {
        setState(() => _nombreRefugio = refugio.nombreRefugio);
        
        // Obtener estadísticas
        final stats = await refugioDs.getEstadisticas(refugio.id);
        setState(() => _estadisticas = stats);

        // Obtener solicitudes recientes
        final solicitudesDs = SolicitudesRemoteDatasource(client);
        final solicitudes = await solicitudesDs.getSolicitudesByRefugio(refugio.id);
        setState(() => _solicitudesRecientes = solicitudes.take(5).toList());
      }
    } catch (e) {
      debugPrint('Error cargando dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si no estamos en el dashboard, mostrar la página directamente
    if (_currentIndex != 0) {
      return Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    // Dashboard
    return Scaffold(
      backgroundColor: const Color(0xFF26D0CE),
      body: SafeArea(
        child: Column(
          children: [
            // Header del refugio
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.business,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nombreRefugio ?? 'Mi Refugio',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text(
                                    'Panel de administración',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          setState(() => _currentIndex = 3);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tarjetas de estadísticas
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            _estadisticas['total_mascotas'] ?? 0,
                            'Mascotas',
                            Icons.pets,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            _estadisticas['pendientes'] ?? 0,
                            'Pendientes',
                            Icons.pending,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            _estadisticas['adoptadas'] ?? 0,
                            'Adoptadas',
                            Icons.check_circle,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildDashboardContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _loadDashboardData();
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF26D0CE),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: 'Mascotas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(int value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Solicitudes Recientes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Solicitudes Recientes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _currentIndex = 2);
              },
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_solicitudesRecientes.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'No hay solicitudes pendientes',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ..._solicitudesRecientes.map((solicitud) =>
              _buildSolicitudCard(solicitud)),
        
        const SizedBox(height: 24),
        
        // Acciones rápidas
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Agregar Mascota',
                Icons.add_circle,
                const Color(0xFF26D0CE),
                () {
                  setState(() => _currentIndex = 1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Ver Solicitudes',
                Icons.description,
                Colors.orange,
                () {
                  setState(() => _currentIndex = 2);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSolicitudCard(SolicitudAdopcionModel solicitud) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: solicitud.imagenMascota != null
              ? Image.network(
                  solicitud.imagenMascota!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[300],
                    child: const Icon(Icons.pets),
                  ),
                )
              : Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[300],
                  child: const Icon(Icons.pets),
                ),
        ),
        title: Text(
          'Solicitud para ${solicitud.nombreMascota ?? "Mascota"}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('De: ${solicitud.nombreAdoptante ?? "Usuario"}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Pendiente',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          setState(() => _currentIndex = 2);
        },
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}