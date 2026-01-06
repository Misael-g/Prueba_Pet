import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../data/datasources/mascotas_remote_ds.dart';
import '../../data/models/mascota_model.dart';
import '../mascotas/detalle_mascota_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MascotaModel> _mascotas = [];
  bool _isLoading = true;
  String? _filtroEspecie;
  String? _filtroTamanio;
  String? _filtroSexo;
  String? _nombreUsuario;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadMascotas();
  }

  Future<void> _loadUserName() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        final response = await SupabaseConfig.client
            .from('perfiles')
            .select('nombre_completo')
            .eq('id', user.id)
            .single();
        
        setState(() {
          _nombreUsuario = response['nombre_completo'] ?? 'Amigo';
        });
      }
    } catch (e) {
      debugPrint('Error cargando nombre: $e');
      setState(() {
        _nombreUsuario = 'Amigo';
      });
    }
  }

  Future<void> _loadMascotas() async {
    setState(() => _isLoading = true);
    try {
      final client = SupabaseConfig.client;
      final mascotasDs = MascotasRemoteDatasource(client);
      
      final mascotas = await mascotasDs.searchMascotas(
        especie: _filtroEspecie,
        tamanio: _filtroTamanio,
        sexo: _filtroSexo,
      );
      
      setState(() => _mascotas = mascotas);
    } catch (e) {
      debugPrint('Error cargando mascotas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Especie
              const Text('Especie', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _filtroEspecie == null,
                    onSelected: (selected) {
                      setStateModal(() => _filtroEspecie = null);
                    },
                  ),
                  FilterChip(
                    label: const Text('🐕 Perros'),
                    selected: _filtroEspecie == 'perro',
                    onSelected: (selected) {
                      setStateModal(() => _filtroEspecie = selected ? 'perro' : null);
                    },
                  ),
                  FilterChip(
                    label: const Text('🐈 Gatos'),
                    selected: _filtroEspecie == 'gato',
                    onSelected: (selected) {
                      setStateModal(() => _filtroEspecie = selected ? 'gato' : null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Tamaño
              const Text('Tamaño', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _filtroTamanio == null,
                    onSelected: (selected) {
                      setStateModal(() => _filtroTamanio = null);
                    },
                  ),
                  FilterChip(
                    label: const Text('Pequeño'),
                    selected: _filtroTamanio == 'pequenio',
                    onSelected: (selected) {
                      setStateModal(() => _filtroTamanio = selected ? 'pequenio' : null);
                    },
                  ),
                  FilterChip(
                    label: const Text('Mediano'),
                    selected: _filtroTamanio == 'mediano',
                    onSelected: (selected) {
                      setStateModal(() => _filtroTamanio = selected ? 'mediano' : null);
                    },
                  ),
                  FilterChip(
                    label: const Text('Grande'),
                    selected: _filtroTamanio == 'grande',
                    onSelected: (selected) {
                      setStateModal(() => _filtroTamanio = selected ? 'grande' : null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Sexo
              const Text('Sexo', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todos'),
                    selected: _filtroSexo == null,
                    onSelected: (selected) {
                      setStateModal(() => _filtroSexo = null);
                    },
                  ),
                  FilterChip(
                    label: const Text('Macho'),
                    selected: _filtroSexo == 'macho',
                    onSelected: (selected) {
                      setStateModal(() => _filtroSexo = selected ? 'macho' : null);
                    },
                  ),
                  FilterChip(
                    label: const Text('Hembra'),
                    selected: _filtroSexo == 'hembra',
                    onSelected: (selected) {
                      setStateModal(() => _filtroSexo = selected ? 'hembra' : null);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setStateModal(() {
                          _filtroEspecie = null;
                          _filtroTamanio = null;
                          _filtroSexo = null;
                        });
                        setState(() {
                          _filtroEspecie = null;
                          _filtroTamanio = null;
                          _filtroSexo = null;
                        });
                        Navigator.pop(context);
                        _loadMascotas();
                      },
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                        _loadMascotas();
                      },
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header personalizado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, ${_nombreUsuario ?? "Amigo"} 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Encuentra tu mascota',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF26D0CE).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFF26D0CE),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Barra de búsqueda y filtros
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                _filtroEspecie != null ||
                                        _filtroTamanio != null ||
                                        _filtroSexo != null
                                    ? 'Filtros activos'
                                    : 'Buscar mascota...',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF26D0CE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.tune, color: Colors.white),
                          onPressed: _mostrarFiltros,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Categorías rápidas
            if (_filtroEspecie == null && _filtroTamanio == null && _filtroSexo == null)
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categorías',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCategoryCard(
                            'Perros',
                            '🐕',
                            Colors.orange,
                            () {
                              setState(() => _filtroEspecie = 'perro');
                              _loadMascotas();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCategoryCard(
                            'Gatos',
                            '🐈',
                            Colors.blue,
                            () {
                              setState(() => _filtroEspecie = 'gato');
                              _loadMascotas();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Grid de mascotas
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _mascotas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pets,
                                  size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron mascotas',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Intenta cambiar los filtros',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMascotas,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _mascotas.length,
                            itemBuilder: (context, index) {
                              return _buildMascotaCard(_mascotas[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      String title, String emoji, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascotaCard(MascotaModel mascota) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DetalleMascotaPage(mascotaId: mascota.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  mascota.imagenPrincipal != null
                      ? Image.network(
                          mascota.imagenPrincipal!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.pets, size: 60),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.pets, size: 60),
                        ),
                  // Badge de especie
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        mascota.especie == 'perro'
                            ? '🐕'
                            : mascota.especie == 'gato'
                                ? '🐈'
                                : '🦎',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mascota.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (mascota.raza != null)
                      Text(
                        mascota.raza!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.cake, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            mascota.edadTexto,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}