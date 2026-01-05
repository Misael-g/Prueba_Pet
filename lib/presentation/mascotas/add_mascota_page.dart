import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/datasources/storage_remote_ds.dart';
import '../../data/datasources/mascotas_remote_ds.dart';
import '../../data/datasources/refugio_remote_ds.dart';
import '../../data/models/mascota_model.dart';

class AddMascotaPage extends StatefulWidget {
  const AddMascotaPage({super.key});

  @override
  State<AddMascotaPage> createState() => _AddMascotaPageState();
}

class _AddMascotaPageState extends State<AddMascotaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _razaController = TextEditingController();
  final _colorController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _personalidadController = TextEditingController();
  final _historiaController = TextEditingController();
  final _necesidadesController = TextEditingController();

  String _especie = 'perro';
  String? _sexo;
  String? _tamanio;
  String? _nivelEnergia;
  int? _edadAnos;
  int? _edadMeses;
  bool _buenoNinos = false;
  bool _buenoGatos = false;
  bool _buenoPerros = false;

  List<File> _imagenes = [];
  int? _imagenPrincipalIndex;
  bool _isLoading = false;

  final _picker = ImagePicker();

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
    if (_imagenes.length >= 5) {
      SnackbarHelper.showError(context, 'Máximo 5 imágenes');
      return;
    }

    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var xFile in pickedFiles) {
          if (_imagenes.length < 5) {
            _imagenes.add(File(xFile.path));
          }
        }
        if (_imagenPrincipalIndex == null && _imagenes.isNotEmpty) {
          _imagenPrincipalIndex = 0;
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagenes.removeAt(index);
      if (_imagenPrincipalIndex == index) {
        _imagenPrincipalIndex = _imagenes.isNotEmpty ? 0 : null;
      } else if (_imagenPrincipalIndex != null && 
                 _imagenPrincipalIndex! > index) {
        _imagenPrincipalIndex = _imagenPrincipalIndex! - 1;
      }
    });
  }

  Future<void> _guardarMascota() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagenes.isEmpty) {
      SnackbarHelper.showError(context, 'Agrega al menos una foto');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser!;

      // Obtener refugio del usuario
      final refugioDs = RefugioRemoteDatasource(client);
      final refugio = await refugioDs.getRefugioByPerfilId(user.id);

      if (refugio == null) {
        throw Exception('No se encontró el refugio');
      }

      // Subir imágenes
      final storageDs = StorageRemoteDatasource(client);
      final imagenesUrls = await storageDs.uploadMultipleImages(_imagenes);

      // Crear mascota
      final mascota = MascotaModel(
        id: const Uuid().v4(),
        refugioId: refugio.id,
        nombre: _nombreController.text.trim(),
        especie: _especie,
        raza: _razaController.text.trim().isEmpty 
            ? null 
            : _razaController.text.trim(),
        edadAnos: _edadAnos,
        edadMeses: _edadMeses,
        sexo: _sexo,
        tamanio: _tamanio,
        color: _colorController.text.trim().isEmpty 
            ? null 
            : _colorController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty 
            ? null 
            : _descripcionController.text.trim(),
        personalidad: _personalidadController.text.trim().isEmpty 
            ? null 
            : _personalidadController.text.trim(),
        historia: _historiaController.text.trim().isEmpty 
            ? null 
            : _historiaController.text.trim(),
        necesidadesEspeciales: _necesidadesController.text.trim().isEmpty 
            ? null 
            : _necesidadesController.text.trim(),
        buenoNinos: _buenoNinos,
        buenoGatos: _buenoGatos,
        buenoPerros: _buenoPerros,
        nivelEnergia: _nivelEnergia,
        estado: 'disponible',
        imagenPrincipal: imagenesUrls[_imagenPrincipalIndex ?? 0],
        imagenes: imagenesUrls,
      );

      final mascotasDs = MascotasRemoteDatasource(client);
      await mascotasDs.addMascota(mascota);

      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Mascota agregada exitosamente');
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
        title: const Text('Nueva Mascota'),
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
                    Row(
                      children: [
                        const Icon(Icons.camera_alt, color: Colors.teal),
                        const SizedBox(width: 8),
                        const Text(
                          'Fotos de la Mascota',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mínimo 1 foto, máximo 5. La primera será principal.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagenes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _imagenes.length) {
                            return GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.teal,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, 
                                         size: 40, 
                                         color: Colors.teal),
                                    SizedBox(height: 8),
                                    Text('Agregar',
                                         style: TextStyle(color: Colors.teal)),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Stack(
                            children: [
                              Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: _imagenPrincipalIndex == index
                                      ? Border.all(
                                          color: Colors.amber,
                                          width: 3,
                                        )
                                      : null,
                                  image: DecorationImage(
                                    image: FileImage(_imagenes[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (_imagenPrincipalIndex == index)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, 
                                             size: 12, 
                                             color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          'Principal',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              if (_imagenPrincipalIndex != index)
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() => _imagenPrincipalIndex = index);
                                    },
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                    child: const Text(
                                      'Principal',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
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
                        Text(
                          'Información Básica',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Mascota *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
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
                      onChanged: (value) {
                        setState(() => _especie = value!);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _razaController,
                      decoration: const InputDecoration(
                        labelText: 'Raza (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pets_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Años',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _edadAnos = int.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Meses',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _edadMeses = int.tryParse(value);
                            },
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
                      onChanged: (value) {
                        setState(() => _sexo = value);
                      },
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
                      onChanged: (value) {
                        setState(() => _tamanio = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _colorController,
                      decoration: const InputDecoration(
                        labelText: 'Color (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.palette),
                      ),
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
                        Text(
                          'Personalidad y Comportamiento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        hintText: 'Describe a la mascota...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _personalidadController,
                      decoration: const InputDecoration(
                        labelText: 'Personalidad',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Juguetón, tranquilo, curioso...',
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
                      onChanged: (value) {
                        setState(() => _nivelEnergia = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Bueno con niños'),
                      value: _buenoNinos,
                      onChanged: (value) {
                        setState(() => _buenoNinos = value ?? false);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Bueno con gatos'),
                      value: _buenoGatos,
                      onChanged: (value) {
                        setState(() => _buenoGatos = value ?? false);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Bueno con perros'),
                      value: _buenoPerros,
                      onChanged: (value) {
                        setState(() => _buenoPerros = value ?? false);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Historia y Necesidades
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
                        Text(
                          'Historia y Cuidados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _historiaController,
                      decoration: const InputDecoration(
                        labelText: 'Historia (opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Cuenta su historia...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _necesidadesController,
                      decoration: const InputDecoration(
                        labelText: 'Necesidades Especiales (opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Medicamentos, cuidados especiales...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón Guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _guardarMascota,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Publicar Mascota',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}