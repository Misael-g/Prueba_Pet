import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/datasources/solicitudes_remote_ds.dart';
import '../../data/models/mascota_model.dart';
import '../../data/models/solicitud_adopcion_model.dart';

class SolicitarAdopcionPage extends StatefulWidget {
  final MascotaModel mascota;

  const SolicitarAdopcionPage({super.key, required this.mascota});

  @override
  State<SolicitarAdopcionPage> createState() => _SolicitarAdopcionPageState();
}

class _SolicitarAdopcionPageState extends State<SolicitarAdopcionPage> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _experienciaController = TextEditingController();
  final _otrosAnimalesController = TextEditingController();

  String? _tipoVivienda;
  bool _tienePatio = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _motivoController.dispose();
    _experienciaController.dispose();
    _otrosAnimalesController.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final client = SupabaseConfig.client;
      final user = client.auth.currentUser!;

      final solicitud = SolicitudAdopcionModel(
        id: const Uuid().v4(),
        mascotaId: widget.mascota.id,
        adoptanteId: user.id,
        refugioId: widget.mascota.refugioId,
        estado: 'pendiente',
        motivoAdopcion: _motivoController.text.trim(),
        experienciaMascotas: _experienciaController.text.trim().isEmpty
            ? null
            : _experienciaController.text.trim(),
        tipoVivienda: _tipoVivienda,
        tienePatio: _tienePatio,
        otrosAnimales: _otrosAnimalesController.text.trim().isEmpty
            ? null
            : _otrosAnimalesController.text.trim(),
        fechaSolicitud: DateTime.now(),
      );

      final solicitudesDs = SolicitudesRemoteDatasource(client);
      await solicitudesDs.crearSolicitud(solicitud);

      if (!mounted) return;
      SnackbarHelper.showSuccess(
        context,
        '¡Solicitud enviada! El refugio la revisará pronto.',
      );
      Navigator.of(context).pop();
      Navigator.of(context).pop(); // Volver al home
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
        title: const Text('Solicitud de Adopción'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información de la mascota
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: widget.mascota.imagenPrincipal != null
                          ? Image.network(
                              widget.mascota.imagenPrincipal!,
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
                            widget.mascota.nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.mascota.raza ?? widget.mascota.especie.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.mascota.edadTexto,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instrucciones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Por favor, completa el formulario. El refugio revisará tu solicitud y se pondrá en contacto contigo.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Motivo de adopción
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.favorite, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          '¿Por qué quieres adoptar?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _motivoController,
                      decoration: const InputDecoration(
                        labelText: 'Motivo de adopción *',
                        border: OutlineInputBorder(),
                        hintText: 'Cuéntanos por qué quieres adoptar...',
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Este campo es requerido';
                        }
                        if (value.trim().length < 20) {
                          return 'Por favor, proporciona más información (mín. 20 caracteres)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Experiencia
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pets, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Tu experiencia con mascotas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _experienciaController,
                      decoration: const InputDecoration(
                        labelText: 'Experiencia (opcional)',
                        border: OutlineInputBorder(),
                        hintText: '¿Has tenido mascotas antes? Cuéntanos...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Vivienda
            Card(
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
                          'Tu hogar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _tipoVivienda,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de vivienda',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.apartment),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'casa', child: Text('Casa')),
                        DropdownMenuItem(value: 'departamento', child: Text('Departamento')),
                        DropdownMenuItem(value: 'quinta', child: Text('Quinta')),
                        DropdownMenuItem(value: 'otro', child: Text('Otro')),
                      ],
                      onChanged: (value) {
                        setState(() => _tipoVivienda = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('¿Tienes patio o jardín?'),
                      value: _tienePatio,
                      onChanged: (value) {
                        setState(() => _tienePatio = value ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Otros animales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pets_outlined, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Otras mascotas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otrosAnimalesController,
                      decoration: const InputDecoration(
                        labelText: '¿Tienes otras mascotas? (opcional)',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: Un perro y dos gatos',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botón enviar
            ElevatedButton(
              onPressed: _isLoading ? null : _enviarSolicitud,
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
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send),
                        SizedBox(width: 8),
                        Text(
                          'Enviar Solicitud',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}