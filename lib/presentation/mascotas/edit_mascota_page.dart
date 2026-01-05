import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/datasources/storage_remote_ds.dart';
import '../../data/datasources/mascotas_remote_ds.dart';
import '../../data/models/mascota_model.dart';

class EditMascotaPage extends StatefulWidget {
  final MascotaModel mascota;

  const EditMascotaPage({super.key, required this.mascota});

  @override
  State<EditMascotaPage> createState() => _EditMascotaPageState();
}

class _EditMascotaPageState extends State<EditMascotaPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _razaController;
  late final TextEditingController _colorController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _personalidadController;
  late final TextEditingController _historiaController;
  late final TextEditingController _necesidadesController;

  late String _especie;
  String? _sexo;
  String? _tamanio;
  String? _nivelEnergia;
  late String _estado;
  int? _edadAnos;
  int? _edadMeses;
  late bool _buenoNinos;
  late bool _buenoGatos;
  late bool _buenoPerros;

  List<String> _imagenesExistentes = [];
  List<File> _imagenesNuevas = [];
  String? _imagenPrincipal;
  bool _isLoading = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.mascota.nombre);
    _razaController = TextEditingController(text: widget.mascota.raza ?? '');
    _colorController = TextEditingController(text: widget.mascota.color ?? '');
    _descripcionController = TextEditingController(text: widget.mascota.descripcion ?? '');
    _personalidadController = TextEditingController(text: widget.mascota.personalidad ?? '');
    _historiaController = TextEditingController(text: widget.mascota.historia ?? '');
    _necesidadesController = TextEditingController(text: widget.mascota.necesidadesEspeciales ?? '');

    _especie = widget.mascota.especie;
    _sexo = widget.mascota.sexo;
    _tamanio = widget.mascota.tamanio;
    _nivelEnergia = widget.mascota.nivelEnergia;
    _estado = widget.mascota.estado;
    _edadAnos = widget.mascota.edadAnos;
    _edadMeses = widget.mascota.edadMeses;
    _buenoNinos = widget.mascota.buenoNinos ?? false;
    _buenoGatos = widget.mascota.buenoGatos ?? false;
    _buenoPerros = widget.mascota.buenoPerros ?? false;

    _imagenesExistentes = List<String>.from(widget.mascota.imagenes ?? []);
    _imagenPrincipal = widget.mascota.imagenPrincipal;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    _colorController.dispose();
    _descripcionController.dispose();
    _personalidadController.dispose();
    _historiaController.dispose();
    _necesidadesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final totalImagenes = _imagenesExistentes.length + _imagenesNuevas.length;
    if (totalImagenes >= 5) {
      SnackbarHelper.showError(context, 'Máximo 5 imágenes');
      return;
    }

    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var xFile in pickedFiles) {
          if (totalImagenes + _imagenesNuevas.length < 5) {
            _imagenesNuevas.add(File(xFile.path));
          }
        }
      });
    }
  }

  void _removeImagenExistente(int index) {
    setState(() {
      final urlRemoved = _imagenesExistentes[index];
      _imagenesExistentes.removeAt(index);
      if (_imagenPrincipal == urlRemoved) {
        _imagenPrincipal = _imagenesExistentes.isNotEmpty 
            ? _imagenesExistentes[0] 
            : null;
      }
    });
  }

  void _removeImagenNueva(int index) {
    setState(() {
      _imagenesNuevas.removeAt(index);
    });
  }

  Future<void> _actualizarMascota() async {
    if (!_formKey.currentState!.validate()) return;
    
    final totalImagenes = _imagenesExistentes.length + _imagenesNuevas.length;
    if (totalImagenes == 0) {
      SnackbarHelper.showError(context, 'Debe haber al menos una foto');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = SupabaseConfig.client;
      
      // Subir nuevas imágenes
      List<String> nuevasUrls = [];
      if (_imagenesNuevas.isNotEmpty) {
        final storageDs = StorageRemoteDatasource(client);
        nuevasUrls = await storageDs.uploadMultipleImages(_imagenesNuevas);
      }

      // Combinar URLs
      final todasLasImagenes = [..._imagenesExistentes, ...nuevasUrls];

      // Si no hay imagen principal o fue eliminada, usar la primera
      if (_imagenPrincipal == null || !todasLasImagenes.contains(_imagenPrincipal)) {
        _imagenPrincipal = todasLasImagenes.first;
      }

      // Actualizar mascota
      final datos = {
        'nombre': _nombreController.text.trim(),
        'especie': _especie,
        'raza': _razaController.text.trim().isEmpty ? null : _razaController.text.trim(),
        'edad_anos': _edadAnos,
        'edad_meses': _edadMeses,
        'sexo': _sexo,
        'tamanio': _tamanio,
        'color': _colorController.text.trim().isEmpty ? null : _colorController.text.trim(),
        'descripcion': _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
        'personalidad': _personalidadController.text.trim().isEmpty ? null : _personalidadController.text.trim(),
        'historia': _historiaController.text.trim().isEmpty ? null : _historiaController.text.trim(),
        'necesidades_especiales': _necesidadesController.text.trim().isEmpty ? null : _necesidadesController.text.trim(),
        'bueno_ninos': _buenoNinos,
        'bueno_gatos': _buenoGatos,
        'bueno_perros': _buenoPerros,
        'nivel_energia': _nivelEnergia,
        'estado': _estado,
        'imagen_principal': _imagenPrincipal,
        'imagenes': todasLasImagenes,
      };

      final mascotasDs = MascotasRemoteDatasource(client);
      await mascotasDs.updateMascota(widget.mascota.id, datos);

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Mascota actualizada');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar ${widget.mascota.nombre}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Fotos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.camera_alt, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Fotos de la Mascota',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Imágenes existentes
                          ..._imagenesExistentes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final url = entry.value;
                            return _buildImagenCard(
                              imageProvider: NetworkImage(url),
                              isPrincipal: _imagenPrincipal == url,
                              onRemove: () => _removeImagenExistente(index),
                              onSetPrincipal: () {
                                setState(() => _imagenPrincipal = url);
                              },
                            );
                          }),
                          // Imágenes nuevas
                          ..._imagenesNuevas.asMap().entries.map((entry) {
                            final index = entry.key;
                            final file = entry.value;
                            return _buildImagenCard(
                              imageProvider: FileImage(file),
                              isPrincipal: false,
                              onRemove: () => _removeImagenNueva(index),
                              onSetPrincipal: null,
                            );
                          }),
                          // Botón agregar
                          if (_imagenesExistentes.length + _imagenesNuevas.length < 5)
                            GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.teal, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 40, color: Colors.teal),
                                    SizedBox(height: 8),
                                    Text('Agregar', style: TextStyle(color: Colors.teal)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Información Básica
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Información Básica', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _especie,
                      decoration: const InputDecoration(
                        labelText: 'Especie *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'perro', child: Text('🐕 Perro')),
                        DropdownMenuItem(value: 'gato', child: Text('🐈 Gato')),
                        DropdownMenuItem(value: 'otro', child: Text('🦎 Otro')),
                      ],
                      onChanged: (value) => setState(() => _especie = value!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _razaController,
                      decoration: const InputDecoration(
                        labelText: 'Raza',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _edadAnos?.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Años',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => _edadAnos = int.tryParse(v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: _edadMeses?.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Meses',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => _edadMeses = int.tryParse(v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _sexo,
                      decoration: const InputDecoration(
                        labelText: 'Sexo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'macho', child: Text('Macho')),
                        DropdownMenuItem(value: 'hembra', child: Text('Hembra')),
                      ],
                      onChanged: (value) => setState(() => _sexo = value),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _tamanio,
                      decoration: const InputDecoration(
                        labelText: 'Tamaño',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pequenio', child: Text('Pequeño')),
                        DropdownMenuItem(value: 'mediano', child: Text('Mediano')),
                        DropdownMenuItem(value: 'grande', child: Text('Grande')),
                      ],
                      onChanged: (value) => setState(() => _tamanio = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.palette),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _estado,
                      decoration: const InputDecoration(
                        labelText: 'Estado *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
                        DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                        DropdownMenuItem(value: 'adoptado', child: Text('Adoptado')),
                        DropdownMenuItem(value: 'retirado', child: Text('Retirado')),
                      ],
                      onChanged: (value) => setState(() => _estado = value!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Personalidad
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Personalidad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _personalidadController,
                      decoration: const InputDecoration(
                        labelText: 'Personalidad',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _nivelEnergia,
                      decoration: const InputDecoration(
                        labelText: 'Nivel de Energía',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.bolt),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'bajo', child: Text('⚡ Bajo')),
                        DropdownMenuItem(value: 'medio', child: Text('⚡⚡ Medio')),
                        DropdownMenuItem(value: 'alto', child: Text('⚡⚡⚡ Alto')),
                      ],
                      onChanged: (value) => setState(() => _nivelEnergia = value),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Bueno con niños'),
                      value: _buenoNinos,
                      onChanged: (v) => setState(() => _buenoNinos = v ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Bueno con gatos'),
                      value: _buenoGatos,
                      onChanged: (v) => setState(() => _buenoGatos = v ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Bueno con perros'),
                      value: _buenoPerros,
                      onChanged: (v) => setState(() => _buenoPerros = v ?? false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Historia
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.menu_book, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Historia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _historiaController,
                      decoration: const InputDecoration(
                        labelText: 'Historia',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _necesidadesController,
                      decoration: const InputDecoration(
                        labelText: 'Necesidades Especiales',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón Actualizar
            ElevatedButton(
              onPressed: _isLoading ? null : _actualizarMascota,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Actualizar Mascota', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImagenCard({
    required ImageProvider imageProvider,
    required bool isPrincipal,
    required VoidCallback onRemove,
    VoidCallback? onSetPrincipal,
  }) {
    return Stack(
      children: [
        Container(
          width: 120,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrincipal ? Border.all(color: Colors.amber, width: 3) : null,
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
        if (isPrincipal)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Principal', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        if (!isPrincipal && onSetPrincipal != null)
          Positioned(
            bottom: 4,
            right: 12,
            child: TextButton(
              onPressed: onSetPrincipal,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text('Principal', style: TextStyle(fontSize: 10)),
            ),
          ),
      ],
    );
  }
}