class MascotasPage extends StatelessWidget {
  const MascotasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Mascotas')),
      body: FutureBuilder(
        future: client.from('mascotas').select(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final mascotas = snapshot.data as List;

          return ListView.builder(
            itemCount: mascotas.length,
            itemBuilder: (_, i) {
              final m = mascotas[i];
              return ListTile(
                title: Text(m['nombre']),
                subtitle: Text(m['especie']),
              );
            },
          );
        },
      ),
    );
  }
}
