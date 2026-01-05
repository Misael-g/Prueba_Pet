class SolicitarAdopcionPage extends StatefulWidget {
  final String mascotaId;
  final String refugioId;

  const SolicitarAdopcionPage({
    super.key,
    required this.mascotaId,
    required this.refugioId,
  });

  @override
  State<SolicitarAdopcionPage> createState() =>
      _SolicitarAdopcionPageState();
}

class _SolicitarAdopcionPageState extends State<SolicitarAdopcionPage> {
  final motivoCtrl = TextEditingController();

  Future<void> enviarSolicitud() async {
    final client = Supabase.instance.client;

    await client.from('solicitudes_adopcion').insert({
      'mascota_id': widget.mascotaId,
      'refugio_id': widget.refugioId,
      'motivo_adopcion': motivoCtrl.text,
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar adopción')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                labelText: '¿Por qué quieres adoptar?',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: enviarSolicitud,
              child: const Text('Enviar solicitud'),
            )
          ],
        ),
      ),
    );
  }
}
