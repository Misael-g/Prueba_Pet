// lib/presentation/adoptante/mapa_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math'; 

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final MapController _mapController = MapController();
  
  // Estado
  Position? _userLocation;
  bool _isLoading = true;
  String? _errorMessage;
  List<RefugioConDistancia> _refugios = [];
  RefugioConDistancia? _selectedRefugio;
  double _radioFiltro = 10.0; // km
  
  // Centro por defecto (Quito)
  final LatLng _defaultCenter = LatLng(-0.211, -78.491);

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _obtenerUbicacion();
    await _cargarRefugios();
  }

  // ═══════════════════════════════════════════════════════════
  // OBTENER UBICACIÓN DEL USUARIO
  // ═══════════════════════════════════════════════════════════
  
  Future<void> _obtenerUbicacion() async {
    try {
      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Los servicios de ubicación están deshabilitados';
          _isLoading = false;
        });
        return;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Permisos de ubicación denegados';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Permisos de ubicación denegados permanentemente';
          _isLoading = false;
        });
        return;
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener ubicación: $e';
        _isLoading = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CARGAR REFUGIOS DESDE SUPABASE
  // ═══════════════════════════════════════════════════════════
  
  Future<void> _cargarRefugios() async {
    try {
      final response = await Supabase.instance.client
          .from('refugios')
          .select()
          .not('latitud', 'is', null)
          .not('longitud', 'is', null)
          .eq('verificado', true);

      final refugios = (response as List)
          .map((json) => RefugioConDistancia.fromJson(json))
          .toList();

      // Calcular distancia si tenemos ubicación del usuario
      if (_userLocation != null) {
        for (var refugio in refugios) {
          refugio.distancia = _calcularDistancia(
            _userLocation!.latitude,
            _userLocation!.longitude,
            refugio.latitud,
            refugio.longitud,
          );
        }
        // Ordenar por distancia
        refugios.sort((a, b) => a.distancia!.compareTo(b.distancia!));
      }

      setState(() {
        _refugios = refugios;
      });
    } catch (e) {
      debugPrint('Error cargando refugios: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CALCULAR DISTANCIA (HAVERSINE)
  // ═══════════════════════════════════════════════════════════
  
  double _calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Radio de la Tierra en km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // ═══════════════════════════════════════════════════════════
  // CENTRAR MAPA
  // ═══════════════════════════════════════════════════════════
  
  void _centrarEnUsuario() {
    if (_userLocation != null) {
      _mapController.move(
        LatLng(_userLocation!.latitude, _userLocation!.longitude),
        14.0,
      );
    }
  }

  void _centrarEnRefugio(RefugioConDistancia refugio) {
    _mapController.move(
      LatLng(refugio.latitud, refugio.longitud),
      15.0,
    );
    setState(() {
      _selectedRefugio = refugio;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mapa de Refugios'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando mapa...'),
              SizedBox(height: 8),
              Text(
                'Obteniendo tu ubicación',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mapa de Refugios'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_off,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _inicializar();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final refugiosFiltrados = _refugios
        .where((r) => r.distancia == null || r.distancia! <= _radioFiltro)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Refugios'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Stack(
        children: [
          // ═══════════════════════════════════════════════════
          // MAPA
          // ═══════════════════════════════════════════════════
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation != null
                  ? LatLng(_userLocation!.latitude, _userLocation!.longitude)
                  : _defaultCenter,
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              // Tiles de OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.purebapet_app',
              ),
              
              // Círculo de área de búsqueda
              if (_userLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(
                        _userLocation!.latitude,
                        _userLocation!.longitude,
                      ),
                      radius: _radioFiltro * 1000, // Convertir km a metros
                      useRadiusInMeter: true,
                      color: Colors.blue.withOpacity(0.15),
                      borderColor: Colors.blue.withOpacity(0.5),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              // Marcadores de refugios
              MarkerLayer(
                markers: [
                  // Marcador del usuario
                  if (_userLocation != null)
                    Marker(
                      point: LatLng(
                        _userLocation!.latitude,
                        _userLocation!.longitude,
                      ),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  
                  // Marcadores de refugios
                  ...refugiosFiltrados.map((refugio) => Marker(
                        point: LatLng(refugio.latitud, refugio.longitud),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _centrarEnRefugio(refugio),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),

          // ═══════════════════════════════════════════════════
          // CONTADOR DE REFUGIOS
          // ═══════════════════════════════════════════════════
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${refugiosFiltrados.length} ${refugiosFiltrados.length == 1 ? "refugio" : "refugios"} cercanos',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════
          // FILTROS DE RADIO
          // ═══════════════════════════════════════════════════
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Radio de búsqueda:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [5.0, 10.0, 15.0, 20.0].map((radio) {
                        final isSelected = _radioFiltro == radio;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$radio km'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _radioFiltro = radio;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════
          // BOTÓN CENTRAR EN USUARIO
          // ═══════════════════════════════════════════════════
          Positioned(
            bottom: 40,
            right: 16,
            child: FloatingActionButton(
              onPressed: _centrarEnUsuario,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // ═══════════════════════════════════════════════════
          // PANEL DE INFORMACIÓN DEL REFUGIO
          // ═══════════════════════════════════════════════════
          if (_selectedRefugio != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Barra superior con botón cerrar
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedRefugio = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Contenido del panel
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre del refugio
                            Text(
                              _selectedRefugio!.nombreRefugio,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Dirección
                            _buildInfoRow(
                              Icons.location_on,
                              'Dirección',
                              _selectedRefugio!.direccion ?? 'No disponible',
                            ),
                            const SizedBox(height: 12),

                            // Distancia
                            if (_selectedRefugio!.distancia != null)
                              _buildInfoRow(
                                Icons.directions_walk,
                                'Distancia',
                                '${_selectedRefugio!.distancia!.toStringAsFixed(2)} km de tu ubicación',
                                color: Colors.blue,
                              ),
                            const SizedBox(height: 12),

                            // Teléfono
                            _buildInfoRow(
                              Icons.phone,
                              'Teléfono',
                              _selectedRefugio!.telefonoContacto ?? 'No disponible',
                              color: Colors.green,
                            ),
                            const SizedBox(height: 12),

                            // Horario
                            if (_selectedRefugio!.horarioAtencion != null)
                              _buildInfoRow(
                                Icons.access_time,
                                'Horario',
                                _selectedRefugio!.horarioAtencion!,
                              ),
                            const SizedBox(height: 12),

                            // Descripción
                            if (_selectedRefugio!.descripcion != null) ...[
                              const Divider(height: 24),
                              const Text(
                                'Acerca de',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedRefugio!.descripcion!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Botón ver mascotas
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navegar a lista de mascotas del refugio
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.pets),
                          label: const Text('Ver Mascotas'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color ?? Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: color ?? Colors.black87,
                  fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
// MODELO DE DATOS
// ═══════════════════════════════════════════════════════════════

class RefugioConDistancia {
  final String id;
  final String nombreRefugio;
  final String? direccion;
  final double latitud;
  final double longitud;
  final String? telefonoContacto;
  final String? emailContacto;
  final String? descripcion;
  final String? horarioAtencion;
  final bool verificado;
  double? distancia; // Se calcula en el cliente

  RefugioConDistancia({
    required this.id,
    required this.nombreRefugio,
    this.direccion,
    required this.latitud,
    required this.longitud,
    this.telefonoContacto,
    this.emailContacto,
    this.descripcion,
    this.horarioAtencion,
    required this.verificado,
    this.distancia,
  });

  factory RefugioConDistancia.fromJson(Map<String, dynamic> json) {
    return RefugioConDistancia(
      id: json['id'] as String,
      nombreRefugio: json['nombre_refugio'] as String,
      direccion: json['direccion'] as String?,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      telefonoContacto: json['telefono_contacto'] as String?,
      emailContacto: json['email_contacto'] as String?,
      descripcion: json['descripcion'] as String?,
      horarioAtencion: json['horario_atencion'] as String?,
      verificado: json['verificado'] as bool? ?? false,
    );
  }
}