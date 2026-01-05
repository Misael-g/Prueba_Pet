import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MisSolicitudesPage extends StatelessWidget {
  const MisSolicitudesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis solicitudes')),
      body: FutureBuilder(
        future: client
            .from('solicitudes_adopcion')
            .select('*, mascotas(nombre)')
            .order('fecha_solicitud', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final solicitudes = snapshot.data as List;

          return ListView.builder(
            itemCount: solicitudes.length,
            itemBuilder: (_, i) {
              final s = solicitudes[i];

              return ListTile(
                title: Text(s['mascotas']['nombre']),
                subtitle: Text('Estado: ${s['estado']}'),
                trailing: s['estado'] == 'pendiente'
                    ? TextButton(
                        onPressed: () async {
                          await client
                              .from('solicitudes_adopcion')
                              .update({'estado': 'cancelada', 'fecha_respuesta': DateTime.now().toIso8601String()})
                              .eq('id', s['id']);
                        },
                        child: const Text('Cancelar'),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
