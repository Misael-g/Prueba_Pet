class SolicitudesRefugioPage extends StatelessWidget {
  const SolicitudesRefugioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes')),
      body: FutureBuilder(
        future: client.from('solicitudes_adopcion').select(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final solicitudes = snapshot.data as List;

          return ListView.builder(
            itemCount: solicitudes.length,
            itemBuilder: (_, i) {
              final s = solicitudes[i];
              return Card(
                child: ListTile(
                  title: Text('Solicitud para mascota'),
                  subtitle: Text(s['estado']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          client
                              .from('solicitudes_adopcion')
                              .update({'estado': 'aprobada'})
                              .eq('id', s['id']);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          client
                              .from('solicitudes_adopcion')
                              .update({'estado': 'rechazada'})
                              .eq('id', s['id']);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
